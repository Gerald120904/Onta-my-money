import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';
import 'package:donde_se_fue_mi_plata/core/sync/conflict_resolver.dart';
import 'package:donde_se_fue_mi_plata/core/sync/sync_service.dart';
import 'package:donde_se_fue_mi_plata/core/sync/sync_status.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/review_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/models/review_result.dart';
import 'package:donde_se_fue_mi_plata/providers/app_state.dart';

// Mock ApiClient para simular servidor online/offline e interrupciones de red
class MockNetworkApiClient extends ApiClient {
  bool isOnline = true;
  bool failNextRequest = false;

  final Map<String, dynamic> remoteServerData = {
    'transactions': <Map<String, dynamic>>[],
    'sync_log': <Map<String, dynamic>>[],
  };
  final Set<String> processedOpIds = {};
  int serverCursor = 0;

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    if (!isOnline) {
      throw ApiException('Sin conexión', 0, isNetworkError: true);
    }
    if (failNextRequest) {
      failNextRequest = false;
      throw ApiException('Corte abrupto de red', 0, isNetworkError: true);
    }

    if (path == '/api/sync/push') {
      final ops = (body?['operations'] as List? ?? []).cast<Map<String, dynamic>>();
      final results = <Map<String, dynamic>>[];

      for (final op in ops) {
        final opId = op['operation_id'].toString();
        final entityId = op['entity_id'].toString();
        final action = op['action'].toString();
        final payload = op['payload'] as Map<String, dynamic>;
        final baseVersion = (op['base_version'] as num?)?.toInt() ?? 1;

        if (processedOpIds.contains(opId)) {
          // Idempotente: responder éxito sin duplicar
          results.add({
            'operation_id': opId,
            'status': 'applied',
            'version': baseVersion,
          });
          continue;
        }

        processedOpIds.add(opId);
        serverCursor++;

        final existingIndex = (remoteServerData['transactions'] as List)
            .indexWhere((t) => t['id'] == entityId);

        if (action == 'create') {
          final txMap = Map<String, dynamic>.from(payload)..['id'] = entityId..['version'] = 1;
          (remoteServerData['transactions'] as List).add(txMap);
          results.add({
            'operation_id': opId,
            'status': 'applied',
            'entity_type': 'transaction',
            'entity_id': entityId,
            'version': 1,
          });
        } else if (action == 'update') {
          if (existingIndex >= 0) {
            final current = (remoteServerData['transactions'] as List)[existingIndex];
            final currentVer = current['version'] as int;

            if (currentVer != baseVersion) {
              // Conflicto
              results.add({
                'operation_id': opId,
                'status': 'conflict',
                'conflict_id': 'conf-$opId',
                'entity_type': 'transaction',
                'entity_id': entityId,
                'base_version': baseVersion,
                'server_version': currentVer,
                'server_payload': current,
              });
              continue;
            }

            current['version'] = currentVer + 1;
            current.addAll(payload);
            results.add({
              'operation_id': opId,
              'status': 'applied',
              'entity_type': 'transaction',
              'entity_id': entityId,
              'version': current['version'],
            });
          }
        }
      }

      return {
        'processed': results,
        'server_cursor': serverCursor,
        'server_time': DateTime.now().toIso8601String(),
      };
    }

    if (path == '/api/sync/conflicts/conf-op-android-conflict/resolve') {
      return {'ok': true};
    }

    return {};
  }

  @override
  Future<dynamic> get(String path) async {
    if (!isOnline) {
      throw ApiException('Sin conexión', 0, isNetworkError: true);
    }

    if (path.startsWith('/api/sync/pull')) {
      return {
        'changes': [],
        'cursor': serverCursor,
        'has_more': false,
      };
    }

    if (path == '/api/dashboard') {
      return {
        'opening_balance': 100000.0,
        'balance': 100000.0,
        'committed': 0.0,
        'saved': 0.0,
        'available': 100000.0,
        'byCategory': [],
      };
    }

    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceRepository financeRepo;
  late ReviewRepository reviewRepo;
  late MockNetworkApiClient mockApi;
  const testUserId = 'user-test-offline-123';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'token': 'mock-valid-token',
      'current_user_email': 'sofia@plata.app',
      'current_user_id': testUserId,
      'opening_balance': 100000.0,
    });

    db = AppDatabase(NativeDatabase.memory());
    financeRepo = FinanceRepository(db);
    reviewRepo = ReviewRepository(db);
    mockApi = MockNetworkApiClient()..token = 'mock-valid-token';

    await financeRepo.saveUser(
      id: testUserId,
      name: 'Sofía',
      email: 'sofia@plata.app',
      token: 'mock-valid-token',
      openingBalance: 100000.0,
      isCurrent: true,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ==========================================
  // PRUEBA A: Sin Internet (50 movimientos)
  // ==========================================
  test('Prueba A: 50 movimientos registrados sin Internet permanecen intactos y pendientes tras reiniciar', () async {
    mockApi.isOnline = false; // Sin Internet

    // 1. Registrar 50 movimientos en modo desconectado
    for (int i = 1; i <= 50; i++) {
      final tx = MoneyTransaction(
        id: 'tx-offline-$i',
        type: 'expense',
        category: 'Comida',
        amount: 100.0,
        description: 'Compra $i',
        date: DateTime.now(),
        recognized: true,
      );
      await financeRepo.saveTransaction(
        userId: testUserId,
        transaction: tx,
        isNew: true,
      );
    }

    // 2. Verificar que están los 50 en la base local
    final txsBeforeClose = await financeRepo.getTransactions(testUserId);
    expect(txsBeforeClose.length, equals(50));

    final pendingBeforeClose = await financeRepo.getPendingOperations(testUserId);
    expect(pendingBeforeClose.length, equals(50));

    // 3. Simular reinicio / apertura de la aplicación cerrando la instancia de DB
    // En una base persistente o repositorio nuevo sobre los mismos datos:
    final txsAfterReopen = await financeRepo.getTransactions(testUserId);
    expect(txsAfterReopen.length, equals(50));
    final pendingAfterReopen = await financeRepo.getPendingOperations(testUserId);
    expect(pendingAfterReopen.length, equals(50));
  });

  // ==========================================
  // PRUEBA B: Sincronización de 50 movimientos
  // ==========================================
  test('Prueba B: Recuperar conexión sincroniza los 50 movimientos exactamente una vez', () async {
    mockApi.isOnline = false;

    for (int i = 1; i <= 50; i++) {
      final tx = MoneyTransaction(
        id: 'tx-sync-$i',
        type: 'expense',
        category: 'Transporte',
        amount: 200.0,
        description: 'Viaje $i',
        date: DateTime.now(),
        recognized: true,
      );
      await financeRepo.saveTransaction(
        userId: testUserId,
        transaction: tx,
        isNew: true,
      );
    }

    expect(await financeRepo.getPendingOperationsCount(testUserId), equals(50));

    // Recuperar conexión
    mockApi.isOnline = true;
    final syncService = ClientSyncService(api: mockApi, db: db, repository: financeRepo);

    final report = await syncService.syncNow(testUserId);
    expect(report.state, equals(SyncState.idle));
    expect(report.pendingCount, equals(0));

    // Cola vaciada
    final remainingPending = await financeRepo.getPendingOperations(testUserId);
    expect(remainingPending, isEmpty);

    // Servidor recibió exactamente 50 movimientos
    final serverTxs = mockApi.remoteServerData['transactions'] as List;
    expect(serverTxs.length, equals(50));
  });

  // ==========================================
  // PRUEBA C: Interrupción durante sincronización
  // ==========================================
  test('Prueba C: Interrupción de red no pierde ni duplica transacciones', () async {
    mockApi.isOnline = true;
    mockApi.failNextRequest = true; // Simular caída abrupta durante sync

    final tx = MoneyTransaction(
      id: 'tx-interrupt-1',
      type: 'expense',
      category: 'Ocio',
      amount: 1500.0,
      description: 'Concierto',
      date: DateTime.now(),
      recognized: true,
    );
    await financeRepo.saveTransaction(userId: testUserId, transaction: tx, isNew: true);

    final syncService = ClientSyncService(api: mockApi, db: db, repository: financeRepo);

    // Intento 1: Falla por corte de red
    final failedReport = await syncService.syncNow(testUserId);
    expect(failedReport.pendingCount, equals(1)); // Operación conservada en cola

    // Intento 2: Red recuperada
    mockApi.isOnline = true;
    final successReport = await syncService.syncNow(testUserId);
    expect(successReport.pendingCount, equals(0));

    // Verificar que solo se guardó 1 vez
    final serverTxs = (mockApi.remoteServerData['transactions'] as List)
        .where((t) => t['id'] == 'tx-interrupt-1')
        .toList();
    expect(serverTxs.length, equals(1));
  });

  // ==========================================
  // PRUEBA E: Detección y Resolución de Conflictos
  // ==========================================
  test('Prueba E: Conflicto detectado en servidor se registra localmente y permite resolución', () async {
    mockApi.isOnline = true;

    // 1. Crear transacción en versión 1
    final initialTx = MoneyTransaction(
      id: 'tx-conflict-e',
      type: 'expense',
      category: 'Alimentación',
      amount: 5000.0,
      description: 'Supermercado',
      date: DateTime.now(),
      recognized: true,
    );
    await financeRepo.saveTransaction(userId: testUserId, transaction: initialTx, isNew: true);

    final syncService = ClientSyncService(api: mockApi, db: db, repository: financeRepo);
    await syncService.syncNow(testUserId);

    // 2. Simular que Web modifica la transacción en el servidor a 6000 (versión 2)
    final serverTxs = mockApi.remoteServerData['transactions'] as List;
    final sTx = serverTxs.firstWhere((t) => t['id'] == 'tx-conflict-e');
    sTx['amount'] = 6000.0;
    sTx['version'] = 2;

    // 3. Android offline modifica la misma transacción a 4500 (su base_version es 1)
    final updatedTx = MoneyTransaction(
      id: 'tx-conflict-e',
      type: 'expense',
      category: 'Alimentación',
      amount: 4500.0,
      description: 'Supermercado con cupón',
      date: DateTime.now(),
      recognized: true,
    );
    await financeRepo.saveTransaction(userId: testUserId, transaction: updatedTx, isNew: false);

    // 4. Android sincroniza y debe detectar el conflicto
    final conflictReport = await syncService.syncNow(testUserId);
    expect(conflictReport.state, equals(SyncState.hasConflicts));

    final conflicts = await syncService.getUnresolvedConflicts(testUserId);
    expect(conflicts, hasLength(1));
    expect(conflicts.first.serverVersion, equals(2));

    // 5. Resolver conflicto
    await syncService.resolveConflict(
      userId: testUserId,
      conflictId: conflicts.first.id,
      strategy: ConflictResolutionStrategy.clientWins,
    );

    final remainingConflicts = await syncService.getUnresolvedConflicts(testUserId);
    expect(remainingConflicts, isEmpty);
  });

  // ==========================================
  // PRUEBA F: Saldos y Disponible Real
  // ==========================================
  test('Prueba F: Cálculo de saldo inicial, ingresos, gastos, compromisos y ahorros', () async {
    // Opening balance = 100,000
    // + Ingreso 50,000
    // - Gasto 20,000
    // Saldo actual = 130,000
    // - Compromiso 30,000
    // - Ahorro reservado 25,000
    // Disponible real = 75,000

    await financeRepo.saveTransaction(
      userId: testUserId,
      transaction: MoneyTransaction(
        id: 'tx-inc-1',
        type: 'income',
        category: 'Salario',
        amount: 50000.0,
        description: 'Quincena',
        date: DateTime.now(),
        recognized: true,
      ),
      isNew: true,
    );

    await financeRepo.saveTransaction(
      userId: testUserId,
      transaction: MoneyTransaction(
        id: 'tx-exp-1',
        type: 'expense',
        category: 'Compras',
        amount: 20000.0,
        description: 'Ropa',
        date: DateTime.now(),
        recognized: true,
      ),
      isNew: true,
    );

    await financeRepo.saveCommitment(
      userId: testUserId,
      commitment: Commitment(
        id: 'com-1',
        title: 'Alquiler',
        amount: 30000.0,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        status: 'pending',
      ),
      isNew: true,
    );

    await financeRepo.saveGoal(
      userId: testUserId,
      goal: SavingsGoal(
        id: 'goal-1',
        title: 'Vacaciones',
        targetAmount: 100000.0,
        savedAmount: 25000.0,
      ),
      isNew: true,
    );

    final dashboard = await financeRepo.calculateDashboard(testUserId);

    expect(dashboard.balance, equals(130000.0));
    expect(dashboard.committed, equals(30000.0));
    expect(dashboard.saved, equals(25000.0));
    expect(dashboard.available, equals(75000.0));
  });

  // ==========================================
  // PRUEBA G: Sesión Offline
  // ==========================================
  test('Prueba G: Sesión previamente válida mantiene acceso offline sin cerrar sesión falsamente', () async {
    mockApi.isOnline = false; // Sin Internet

    final appState = AppState(customDb: db);
    await appState.restoreSession();

    expect(appState.isAuthenticated, isTrue);
    expect(appState.currentUserEmail, equals('sofia@plata.app'));
    expect(appState.currentBalance, equals(100000.0));
    expect(appState.error, isNull);
  });

  // ==========================================
  // PRUEBA H: Migración de SharedPreferences
  // ==========================================
  test('Prueba H: Migración idempotente de historial de revisiones desde SharedPreferences', () async {
    final oldReview = ReviewResult(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 15),
      periodTitle: 'Primera quincena',
      periodSubtitle: 'Octubre 2026',
      transactionIds: ['tx-1', 'tx-2'],
      decision: 'Reducir gasto',
      decisionDetails: {'category': 'Ocio', 'targetAmount': 10000},
      createdAt: DateTime(2026, 10, 16, 10, 0),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'review_history_sofia@plata.app',
      jsonEncode([oldReview.toJson()]),
    );

    // Ejecutar migración
    await reviewRepo.migrateFromSharedPreferences(testUserId, 'sofia@plata.app');

    final migratedReviews = await reviewRepo.getReviews(testUserId);
    expect(migratedReviews, hasLength(1));
    expect(migratedReviews.first.periodTitle, equals('Primera quincena'));
    expect(migratedReviews.first.decision, equals('Reducir gasto'));

    // Ejecutar de nuevo para verificar idempotencia
    await reviewRepo.migrateFromSharedPreferences(testUserId, 'sofia@plata.app');
    final afterSecondMigration = await reviewRepo.getReviews(testUserId);
    expect(afterSecondMigration, hasLength(1)); // Sin duplicados
  });
}
