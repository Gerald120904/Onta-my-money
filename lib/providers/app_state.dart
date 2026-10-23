import 'dart:async';
import 'package:flutter/material.dart';
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
import '../services/notifications/app_notification.dart';
import '../services/notifications/notification_service.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  final AppDatabase db;
  final FinanceRepository financeRepository;
  final ReviewRepository reviewRepository;
  late final ClientSyncService syncService;
  late final NotificationService notificationService;

  static const _uuid = Uuid();

  bool loading = false;
  String? error;

  DashboardSummary? dashboard;
  List<MoneyTransaction> transactions = [];
  List<Commitment> commitments = [];
  List<SavingsGoal> goals = [];
  List<ReviewResult> reviews = [];
  List<AppNotification> notifications = [];
  int unreadNotificationsCount = 0;

  String? currentUserId;
  String? currentUserEmail;
  String? currentUserName;
  String? currentUserCreatedAt;
  double openingBalance = 0.0;

  ThemeMode themeMode = ThemeMode.system;
  int initialTabIndex = 0;
  bool autoSyncEnabled = true;

  SyncReport syncReport = const SyncReport();
  List<EntityConflict> conflicts = [];
  StreamSubscription? _syncSub;

  AppState({AppDatabase? customDb}) : this._(customDb ?? AppDatabase());

  AppState._(AppDatabase database)
      : db = database,
        financeRepository = FinanceRepository(database),
        reviewRepository = ReviewRepository(database) {
    notificationService = NotificationService(database);
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

    final themeStr = prefs.getString('app_theme_mode');
    if (themeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.system;
    }
    initialTabIndex = prefs.getInt('initial_tab_index') ?? 0;
    autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
    syncService.autoSyncEnabled = autoSyncEnabled;

    api.token = prefs.getString('token');
    currentUserEmail = prefs.getString('current_user_email');
    currentUserId = prefs.getString('current_user_id');
    currentUserName = prefs.getString('current_user_name');
    currentUserCreatedAt = prefs.getString('current_user_created_at');
    openingBalance = prefs.getDouble('opening_balance') ?? 0.0;

    // Verificar también el usuario actual en la base de datos local
    final localUser = await financeRepository.getCurrentUser();
    if (localUser != null) {
      currentUserId ??= localUser.id;
      currentUserEmail ??= localUser.email;
      currentUserName ??= localUser.name;
      api.token ??= localUser.token;
      openingBalance = localUser.openingBalance;
    }

    if (currentUserId == null || currentUserEmail == null || api.token == null) {
      reviews = [];
      transactions = [];
      commitments = [];
      goals = [];
      notifications = [];
      unreadNotificationsCount = 0;
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

    // En segundo plano, si hay conexión disponible y autoSync activo, sincronizar sin bloquear la interfaz
    _backgroundSync();
  }

  Future<void> _backgroundSync() async {
    if (currentUserId == null || !isAuthenticated) return;
    if (!autoSyncEnabled) return; // Respeta la preferencia de auto-sincronización
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

    // Recalcular recordatorios para compromisos y cargar avisos
    await notificationService.recalculateCommitmentReminders(
      userId: userId,
      commitments: commitments,
    );
    notifications = await notificationService.getNotifications(userId);
    unreadNotificationsCount = await notificationService.getUnreadCount(userId);

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
        final userName = userMap['name']?.toString() ?? 'Usuario';
        final userCreatedAt = userMap['created_at']?.toString() ?? DateTime.now().toIso8601String();
        final serverOpeningBalance = (userMap['opening_balance'] as num?)?.toDouble() ?? 0.0;

        api.token = token;
        currentUserId = userId;
        currentUserEmail = userEmail;
        currentUserName = userName;
        currentUserCreatedAt = userCreatedAt;
        openingBalance = serverOpeningBalance;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('current_user_email', userEmail);
        await prefs.setString('current_user_id', userId);
        await prefs.setString('current_user_name', userName);
        await prefs.setString('current_user_created_at', userCreatedAt);
        await prefs.setDouble('opening_balance', serverOpeningBalance);

        // Guardar usuario en la base de datos local
        await financeRepository.saveUser(
          id: userId,
          name: userName,
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
    currentUserName = null;
    currentUserCreatedAt = null;
    dashboard = null;
    transactions = [];
    commitments = [];
    goals = [];
    reviews = [];
    notifications = [];
    unreadNotificationsCount = 0;
    conflicts = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_created_at');
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

      // 2. Si hay conexión, consultar perfil y dashboard remoto para sincronizar
      if (isAuthenticated) {
        try {
          final remoteMe = await api.get('/api/me');
          if (remoteMe is Map) {
            final remoteName = remoteMe['name']?.toString();
            final remoteCreatedAt = remoteMe['created_at']?.toString();
            if (remoteName != null && remoteName.isNotEmpty) {
              currentUserName = remoteName;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('current_user_name', remoteName);
              await financeRepository.updateUserName(currentUserId!, remoteName);
            }
            if (remoteCreatedAt != null && remoteCreatedAt.isNotEmpty) {
              currentUserCreatedAt = remoteCreatedAt;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('current_user_created_at', remoteCreatedAt);
            }
          }

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

  // =========================================================
  // PREFERENCIAS Y APARIENCIA
  // =========================================================

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setInitialTabIndex(int index) async {
    initialTabIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('initial_tab_index', index);
    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', enabled);
    syncService.autoSyncEnabled = enabled;
    notifyListeners();
  }

  // =========================================================
  // GESTIÓN DE PERFIL (OFFLINE-FIRST)
  // =========================================================

  Future<void> updateUserName(String newName) async {
    final name = newName.trim();
    if (name.isEmpty) throw Exception('El nombre no puede estar vacío');
    if (currentUserId == null) throw Exception('No hay sesión activa');

    currentUserName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_name', name);

    // Actualizar base de datos local inmediatamente
    await financeRepository.updateUserName(currentUserId!, name);

    // Encolar operación de sincronización (Offline-First)
    await financeRepository.enqueueOperation(
      userId: currentUserId!,
      entityType: 'user',
      entityId: currentUserId!,
      action: 'update',
      payload: {'name': name},
    );

    notifyListeners();

    // Si hay conexión, sincronizar inmediatamente
    if (isAuthenticated) {
      try {
        await api.patch('/api/me', {'name': name});
        await syncNow();
      } catch (_) {
        // En corte de red se mantiene en cola y se sincronizará automáticamente al reconectar
      }
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    bool revokeOtherSessions = true,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Esta función requiere conexión con el servidor. Verificá tu conexión e intentá de nuevo.');
    }
    final res = await api.post('/api/me/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
      'revoke_other_sessions': revokeOtherSessions,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  // =========================================================
  // NOTIFICACIONES Y RECORDATORIOS
  // =========================================================

  Future<void> loadNotifications() async {
    if (currentUserId == null) {
      notifications = [];
      unreadNotificationsCount = 0;
      notifyListeners();
      return;
    }
    await notificationService.recalculateCommitmentReminders(
      userId: currentUserId!,
      commitments: commitments,
    );
    notifications = await notificationService.getNotifications(currentUserId!);
    unreadNotificationsCount = await notificationService.getUnreadCount(currentUserId!);
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    await notificationService.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllNotificationsAsRead() async {
    if (currentUserId == null) return;
    await notificationService.markAllAsRead(currentUserId!);
    await loadNotifications();
  }

  Future<void> dismissNotification(String id) async {
    await notificationService.dismissNotification(id);
    await loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await notificationService.deleteNotification(id);
    await loadNotifications();
  }

  Future<void> clearAllNotifications() async {
    if (currentUserId == null) return;
    await notificationService.clearAll(currentUserId!);
    await loadNotifications();
  }

  // =========================================================
  // PRIVACIDAD Y LIMPIEZA SEGURA DE CACHÉ
  // =========================================================

  Future<void> clearRegenerableCache() async {
    if (currentUserId != null) {
      final pendingCount = await financeRepository.getPendingOperationsCount(currentUserId!);
      if (pendingCount > 0) {
        throw Exception('Tenés $pendingCount cambios pendientes de sincronizar. Sincronizá antes de limpiar la caché.');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_search_cache');
    await prefs.remove('temp_filter_cache');
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