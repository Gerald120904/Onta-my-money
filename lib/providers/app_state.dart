import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/api/api_client.dart';
import '../core/sync/conflict_resolver.dart';
import '../core/sync/sync_service.dart';
import '../core/sync/sync_status.dart';
import '../data/local/app_database.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/review_repository.dart';
import '../models/models.dart';
import '../models/review_result.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  final AppDatabase db;
  final FinanceRepository financeRepository;
  final ReviewRepository reviewRepository;
  late final ClientSyncService syncService;

  static const _uuid = Uuid();

  bool loading = false;
  String? error;

  DashboardSummary? dashboard;
  List<MoneyTransaction> transactions = [];
  List<Commitment> commitments = [];
  List<SavingsGoal> goals = [];
  List<ReviewResult> reviews = [];

  String? currentUserId;
  String? currentUserEmail;
  double openingBalance = 0.0;

  SyncReport syncReport = const SyncReport();
  List<EntityConflict> conflicts = [];
  StreamSubscription? _syncSub;

  AppState({AppDatabase? customDb})
      : db = customDb ?? AppDatabase(),
        financeRepository = FinanceRepository(customDb ?? AppDatabase()),
        reviewRepository = ReviewRepository(customDb ?? AppDatabase()) {
    syncService = ClientSyncService(
      api: api,
      db: db,
      repository: financeRepository,
    );

    _syncSub = syncService.statusStream.listen((report) {
      syncReport = report;
      notifyListeners();
    });
  }

  ReviewResult? get latestReview => reviews.isEmpty ? null : reviews.first;

  bool get isAuthenticated => api.token != null && api.token!.isNotEmpty;

  int get pendingOperationsCount => syncReport.pendingCount;

  bool get isSyncing => syncReport.state == SyncState.syncing;

  bool get hasConflicts => syncReport.conflictCount > 0;

  // =========================================================
  // SALDO LOCAL UNIFICADO
  // =========================================================

  double get totalIncome {
    return transactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold<double>(0.0, (total, t) => total + t.amount);
  }

  double get totalExpenses {
    return transactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold<double>(0.0, (total, t) => total + t.amount);
  }

  double get currentBalance {
    return openingBalance + totalIncome - totalExpenses;
  }

  double get committedAmount {
    return commitments
        .where((c) => c.status.toLowerCase() == 'pending')
        .fold<double>(0.0, (total, c) => total + c.amount);
  }

  double get savedAmount {
    return goals.fold<double>(0.0, (total, g) => total + g.savedAmount);
  }

  double get availableBalance {
    return currentBalance - committedAmount - savedAmount;
  }

  // =========================================================
  // RESTAURAR SESIÓN (OFFLINE-FIRST)
  // =========================================================

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    api.token = prefs.getString('token');
    currentUserEmail = prefs.getString('current_user_email');
    currentUserId = prefs.getString('current_user_id');
    openingBalance = prefs.getDouble('opening_balance') ?? 0.0;

    // Verificar también el usuario actual en la base de datos local
    final localUser = await financeRepository.getCurrentUser();
    if (localUser != null) {
      currentUserId ??= localUser.id;
      currentUserEmail ??= localUser.email;
      api.token ??= localUser.token;
      openingBalance = localUser.openingBalance;
    }

    if (currentUserId == null || currentUserEmail == null || api.token == null) {
      reviews = [];
      transactions = [];
      commitments = [];
      goals = [];
      dashboard = null;
      notifyListeners();
      return;
    }

    // Cargar inmediatamente desde la base local (funciona 100% offline)
    await _loadFromLocalDatabase(currentUserId!);

    // Migración idempotente de revisiones desde SharedPreferences a Drift
    await reviewRepository.migrateFromSharedPreferences(currentUserId!, currentUserEmail!);
    reviews = await reviewRepository.getReviews(currentUserId!);

    notifyListeners();

    // En segundo plano, si hay conexión disponible, sincronizar sin bloquear la interfaz
    _backgroundSync();
  }

  Future<void> _backgroundSync() async {
    if (currentUserId == null || !isAuthenticated) return;
    try {
      await syncNow();
      await refreshAll(silent: true);
    } catch (_) {
      // Si falla por red, la sesión y los datos locales se mantienen intactos
    }
  }

  Future<void> _loadFromLocalDatabase(String userId) async {
    transactions = await financeRepository.getTransactions(userId);
    commitments = await financeRepository.getCommitments(userId);
    goals = await financeRepository.getGoals(userId);
    reviews = await reviewRepository.getReviews(userId);
    dashboard = await financeRepository.calculateDashboard(userId);
    conflicts = await syncService.getUnresolvedConflicts(userId);
    final pendingCount = await financeRepository.getPendingOperationsCount(userId);

    syncReport = syncReport.copyWith(
      pendingCount: pendingCount,
      conflictCount: conflicts.length,
    );
  }

  // =========================================================
  // LOGIN & REGISTRO
  // =========================================================

  Future<void> login(String email, String password) => _run(() async {
        final data = Map<String, dynamic>.from(
          await api.post('/api/auth/login', {
            'email': email,
            'password': password,
          }),
        );

        final token = data['token'].toString();
        final userMap = Map<String, dynamic>.from(data['user'] as Map? ?? {});
        final userId = userMap['id']?.toString() ?? _uuid.v4();
        final userEmail = (userMap['email'] ?? email).toString().trim().toLowerCase();
        final serverOpeningBalance = (userMap['opening_balance'] as num?)?.toDouble() ?? 0.0;

        api.token = token;
        currentUserId = userId;
        currentUserEmail = userEmail;
        openingBalance = serverOpeningBalance;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('current_user_email', userEmail);
        await prefs.setString('current_user_id', userId);
        await prefs.setDouble('opening_balance', serverOpeningBalance);

        // Guardar usuario en la base de datos local
        await financeRepository.saveUser(
          id: userId,
          name: userMap['name']?.toString() ?? 'Usuario',
          email: userEmail,
          token: token,
          openingBalance: serverOpeningBalance,
          isCurrent: true,
        );

        // Migrar revisiones de SharedPreferences si existen
        await reviewRepository.migrateFromSharedPreferences(userId, userEmail);

        // Descargar datos iniciales
        await syncNow();
        await refreshAll(silent: true);
      });

  Future<void> register(String name, String email, String password) => _run(() async {
        await api.post('/api/auth/register', {
          'name': name,
          'email': email,
          'password': password,
          'opening_balance': 0.0,
        });
      });

  Future<void> logout({bool force = false}) async {
    if (currentUserId != null) {
      final pendingCount = await financeRepository.getPendingOperationsCount(currentUserId!);
      if (pendingCount > 0 && !force) {
        throw Exception(
          'Tenés $pendingCount cambios pendientes de sincronizar. Sincronizá antes de salir o confirmá para cerrar sesión sin borrar tus datos locales.',
        );
      }
    }

    try {
      await api.post('/api/auth/logout');
    } catch (_) {}

    api.token = null;
    currentUserEmail = null;
    currentUserId = null;
    dashboard = null;
    transactions = [];
    commitments = [];
    goals = [];
    reviews = [];
    conflicts = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_id');
    await prefs.remove('opening_balance');

    notifyListeners();
  }

  // =========================================================
  // REFRESCAR INFORMACIÓN (LOCAL-FIRST)
  // =========================================================

  Future<void> refreshAll({bool silent = false}) async {
    if (currentUserId == null) return;

    if (!silent) {
      loading = true;
      notifyListeners();
    }

    try {
      // 1. Siempre cargar primero del almacenamiento local
      await _loadFromLocalDatabase(currentUserId!);

      // 2. Si hay conexión, consultar el dashboard remoto para alinear opening_balance
      if (isAuthenticated) {
        try {
          final remoteDashboard = await api.get('/api/dashboard');
          if (remoteDashboard is Map) {
            final remoteOpening = (remoteDashboard['opening_balance'] as num?)?.toDouble();
            if (remoteOpening != null && remoteOpening != openingBalance) {
              openingBalance = remoteOpening;
              await financeRepository.updateOpeningBalance(currentUserId!, openingBalance);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('opening_balance', openingBalance);
            }
          }
        } catch (e) {
          // Si falla la red, no vaciar datos ni lanzar error destructivo
        }
      }

      error = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // TRANSACCIONES OFFLINE-FIRST
  // =========================================================

  Future<void> saveTransaction(MoneyTransaction transaction, {bool create = false}) => _run(() async {
        if (currentUserId == null) throw Exception('No hay sesión activa.');
        if (transaction.amount <= 0) throw Exception('El monto debe ser mayor que ₡0.');

        // Saldo proyectado incluyendo openingBalance
        double balanceBefore = currentBalance;
        if (!create) {
          final old = transactions.firstWhere((t) => t.id == transaction.id, orElse: () => transaction);
          if (old.id == transaction.id) {
            if (old.type.toLowerCase() == 'expense') {
              balanceBefore += old.amount;
            } else if (old.type.toLowerCase() == 'income') {
              balanceBefore -= old.amount;
            }
          }
        }

        final newType = transaction.type.toLowerCase();
        double projected = balanceBefore;
        if (newType == 'expense') {
          projected -= transaction.amount;
        } else if (newType == 'income') {
          projected += transaction.amount;
        }

        if (projected < 0) {
          final available = balanceBefore < 0 ? 0.0 : balanceBefore;
          throw Exception(
            'No podés registrar este gasto. Tu saldo disponible es de ₡${_formatAmount(available)}.',
          );
        }

        // Asignar ID estable generado desde el dispositivo si es nueva
        final txId = (create || transaction.id.isEmpty) ? _uuid.v4() : transaction.id;
        final stableTx = MoneyTransaction(
          id: txId,
          type: transaction.type,
          category: transaction.category,
          amount: transaction.amount,
          description: transaction.description,
          date: transaction.date,
          recognized: transaction.recognized,
        );

        // Guardar inmediatamente en SQLite local + cola de operaciones
        await financeRepository.saveTransaction(
          userId: currentUserId!,
          transaction: stableTx,
          isNew: create || transaction.id.isEmpty,
        );

        // Actualizar vista local reactiva
        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();

        // Sincronizar en segundo plano si hay red
        _backgroundSync();
      });

  Future<void> deleteTransaction(String id) => _run(() async {
        if (currentUserId == null) return;
        final tx = transactions.firstWhere((t) => t.id == id, orElse: () => MoneyTransaction(id: id, type: '', category: '', amount: 0, description: '', date: DateTime.now(), recognized: true));

        if (tx.type.toLowerCase() == 'income') {
          final projected = currentBalance - tx.amount;
          if (projected < 0) {
            throw Exception('No podés eliminar este ingreso porque el saldo quedaría en negativo.');
          }
        }

        await financeRepository.deleteTransaction(userId: currentUserId!, id: id);
        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();

        _backgroundSync();
      });

  // =========================================================
  // COMPROMISOS OFFLINE-FIRST
  // =========================================================

  Future<void> saveCommitment(Commitment commitment, {bool create = false}) => _run(() async {
        if (currentUserId == null) return;
        final comId = (create || commitment.id.isEmpty) ? _uuid.v4() : commitment.id;
        final stable = Commitment(
          id: comId,
          title: commitment.title,
          amount: commitment.amount,
          dueDate: commitment.dueDate,
          status: commitment.status,
        );

        await financeRepository.saveCommitment(
          userId: currentUserId!,
          commitment: stable,
          isNew: create || commitment.id.isEmpty,
        );

        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();
        _backgroundSync();
      });

  Future<void> deleteCommitment(String id) => _run(() async {
        if (currentUserId == null) return;
        await financeRepository.deleteCommitment(userId: currentUserId!, id: id);
        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();
        _backgroundSync();
      });

  // =========================================================
  // METAS OFFLINE-FIRST
  // =========================================================

  Future<void> saveGoal(SavingsGoal goal, {bool create = false}) => _run(() async {
        if (currentUserId == null) return;
        final gId = (create || goal.id.isEmpty) ? _uuid.v4() : goal.id;
        final stable = SavingsGoal(
          id: gId,
          title: goal.title,
          targetAmount: goal.targetAmount,
          savedAmount: goal.savedAmount,
        );

        await financeRepository.saveGoal(
          userId: currentUserId!,
          goal: stable,
          isNew: create || goal.id.isEmpty,
        );

        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();
        _backgroundSync();
      });

  Future<void> deleteGoal(String id) => _run(() async {
        if (currentUserId == null) return;
        await financeRepository.deleteGoal(userId: currentUserId!, id: id);
        await _loadFromLocalDatabase(currentUserId!);
        notifyListeners();
        _backgroundSync();
      });

  // =========================================================
  // DECISIONES Y REVISIONES OFFLINE-FIRST
  // =========================================================

  Future<void> saveDecision(String action, String note) => _run(() async {
        if (currentUserId == null) return;
        await financeRepository.saveDecision(
          userId: currentUserId!,
          action: action,
          note: note,
        );
        _backgroundSync();
      });

  Future<void> saveReviewResult(ReviewResult result) async {
    if (currentUserId == null) return;
    await reviewRepository.saveReview(currentUserId!, result);
    reviews = await reviewRepository.getReviews(currentUserId!);
    notifyListeners();
    _backgroundSync();
  }

  Future<void> deleteReviewResult(ReviewResult result) async {
    if (currentUserId == null) return;
    await reviewRepository.deleteReview(currentUserId!, result.createdAt);
    reviews = await reviewRepository.getReviews(currentUserId!);
    notifyListeners();
    _backgroundSync();
  }

  // =========================================================
  // MOTOR DE SINCRONIZACIÓN MANUAL & CONFLICTOS
  // =========================================================

  Future<void> syncNow() async {
    if (currentUserId == null || !isAuthenticated) return;
    syncReport = await syncService.syncNow(currentUserId!);
    await _loadFromLocalDatabase(currentUserId!);
    notifyListeners();
  }

  Future<void> resolveConflict(String conflictId, ConflictResolutionStrategy strategy, [Map<String, dynamic>? merged]) async {
    if (currentUserId == null) return;
    await syncService.resolveConflict(
      userId: currentUserId!,
      conflictId: conflictId,
      strategy: strategy,
      mergedPayload: merged,
    );
    await _loadFromLocalDatabase(currentUserId!);
    notifyListeners();
  }

  Future<List<LocalChangeHistoryData>> getChangeHistory() async {
    if (currentUserId == null) return [];
    return financeRepository.getChangeHistory(currentUserId!);
  }

  String _formatAmount(double amount) {
    final rounded = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final pos = rounded.length - i;
      buffer.write(rounded[i]);
      if (pos > 1 && (pos - 1) % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  Future<void> _run(Future<void> Function() fn) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await fn();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    syncService.dispose();
    db.close();
    super.dispose();
  }
}