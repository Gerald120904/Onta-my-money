import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';
import 'package:donde_se_fue_mi_plata/core/sync/sync_service.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/review_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/models/review_result.dart';

/// Servidor simulado con motor de sincronización idéntico al Backend
class MockSyncServer {
  final Map<String, Map<String, dynamic>> _entities = {}; // key: "entityType:id" -> data
  final List<Map<String, dynamic>> _syncLog = [];
  final Map<String, Map<String, dynamic>> _idempotencyKeys = {};
  int _sequence = 0;

  Map<String, dynamic> handlePush({
    required String userId,
    required String? deviceId,
    required List<Map<String, dynamic>> operations,
  }) {
    final processed = <Map<String, dynamic>>[];

    for (final op in operations) {
      final opId = op['operation_id']?.toString() ?? '';
      final entityType = op['entity_type']?.toString().toLowerCase() ?? '';
      final entityId = op['entity_id']?.toString() ?? '';
      final action = op['action']?.toString().toLowerCase() ?? '';
      final payload = Map<String, dynamic>.from(op['payload'] as Map? ?? {});
      final baseVersion = (op['base_version'] as num?)?.toInt() ?? 1;

      final storageKey = '$entityType:$entityId';
      final existing = _entities[storageKey];
      final idemKey = '$userId:$opId';

      if (action == 'create') {
        if (existing != null && existing['deleted'] != true && existing['userId'] == userId) {
          final res = {
            'operation_id': opId,
            'status': 'applied',
            'entity_type': entityType,
            'entity_id': entityId,
            'version': existing['version'] ?? 1,
          };
          _idempotencyKeys[idemKey] = res;
          processed.add(res);
          continue;
        }

        final entityRecord = {
          'id': entityId,
          'userId': userId,
          'version': 1,
          'deleted': false,
          ...payload,
        };
        _entities[storageKey] = entityRecord;

        _sequence++;
        _syncLog.add({
          'sequence': _sequence,
          'user_id': userId,
          'entity_type': entityType,
          'entity_id': entityId,
          'action': 'create',
          'version': 1,
          'payload': payload,
          'created_at': DateTime.now().toIso8601String(),
        });

        final res = {
          'operation_id': opId,
          'status': 'applied',
          'entity_type': entityType,
          'entity_id': entityId,
          'version': 1,
        };
        _idempotencyKeys[idemKey] = res;
        processed.add(res);
      } else if (action == 'update') {
        if (existing == null || existing['userId'] != userId || existing['deleted'] == true) {
          processed.add({
            'operation_id': opId,
            'status': 'error',
            'message': 'No encontrado',
          });
          continue;
        }

        final currentVersion = existing['version'] as int;
        if (currentVersion != baseVersion) {
          // CONFLICTO DETECTADO POR VERSIÓN DIVERGENTE
          final conflictRes = {
            'operation_id': opId,
            'status': 'conflict',
            'conflict_id': 'conf-$opId',
            'entity_type': entityType,
            'entity_id': entityId,
            'base_version': baseVersion,
            'server_version': currentVersion,
            'server_payload': existing,
          };
          processed.add(conflictRes);
          continue;
        }

        final nextVersion = currentVersion + 1;
        existing.addAll(payload);
        existing['version'] = nextVersion;

        _sequence++;
        _syncLog.add({
          'sequence': _sequence,
          'user_id': userId,
          'entity_type': entityType,
          'entity_id': entityId,
          'action': 'update',
          'version': nextVersion,
          'payload': payload,
          'created_at': DateTime.now().toIso8601String(),
        });

        final res = {
          'operation_id': opId,
          'status': 'applied',
          'entity_type': entityType,
          'entity_id': entityId,
          'version': nextVersion,
        };
        _idempotencyKeys[idemKey] = res;
        processed.add(res);
      } else if (action == 'delete') {
        if (existing != null && existing['userId'] == userId) {
          final nextVersion = (existing['version'] as int) + 1;
          existing['deleted'] = true;
          existing['version'] = nextVersion;

          _sequence++;
          _syncLog.add({
            'sequence': _sequence,
            'user_id': userId,
            'entity_type': entityType,
            'entity_id': entityId,
            'action': 'delete',
            'version': nextVersion,
            'payload': {'deleted': true},
            'created_at': DateTime.now().toIso8601String(),
          });

          final res = {
            'operation_id': opId,
            'status': 'applied',
            'entity_type': entityType,
            'entity_id': entityId,
            'version': nextVersion,
          };
          _idempotencyKeys[idemKey] = res;
          processed.add(res);
        } else {
          processed.add({
            'operation_id': opId,
            'status': 'applied',
            'entity_type': entityType,
            'entity_id': entityId,
            'version': 0,
          });
        }
      }
    }

    return {
      'processed': processed,
      'server_cursor': _sequence,
      'server_time': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> handlePull({
    required String userId,
    required int cursor,
    int limit = 200,
  }) {
    // Filtrado estricto por user_id (aislamiento entre cuentas)
    final filtered = _syncLog
        .where((entry) => entry['user_id'] == userId && (entry['sequence'] as int) > cursor)
        .take(limit)
        .toList();

    final nextCursor = filtered.isNotEmpty ? (filtered.last['sequence'] as int) : cursor;

    return {
      'changes': filtered,
      'cursor': nextCursor,
      'has_more': false,
      'server_time': DateTime.now().toIso8601String(),
    };
  }
}

class TestBridgeClient extends ApiClient {
  final MockSyncServer server;
  final String userId;

  TestBridgeClient({required this.server, required this.userId}) {
    token = 'test-token-$userId';
    deviceId = 'test-device-$userId';
  }

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    if (path == '/api/sync/push') {
      return server.handlePush(
        userId: userId,
        deviceId: deviceId,
        operations: (body?['operations'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/api/sync/pull')) {
      final uri = Uri.parse(path);
      final cursor = int.tryParse(uri.queryParameters['cursor'] ?? '0') ?? 0;
      return server.handlePull(userId: userId, cursor: cursor);
    }
    throw UnimplementedError(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TAREA 3 — Sincronización multidispositivo integral de todas las entidades', () {
    const mainUserId = 'user-multidevice-main';
    const otherUserId = 'user-intruder-separated';

    late MockSyncServer server;

    // Dispositivo A
    late AppDatabase dbDeviceA;
    late FinanceRepository repoDeviceA;
    late ReviewRepository reviewRepoDeviceA;
    late ClientSyncService syncDeviceA;

    // Dispositivo B
    late AppDatabase dbDeviceB;
    late FinanceRepository repoDeviceB;
    late ReviewRepository reviewRepoDeviceB;
    late ClientSyncService syncDeviceB;

    setUp(() async {
      server = MockSyncServer();

      // DB A en memoria
      dbDeviceA = AppDatabase.inMemory(NativeDatabase.memory());
      repoDeviceA = FinanceRepository(dbDeviceA);
      reviewRepoDeviceA = ReviewRepository(dbDeviceA);
      syncDeviceA = ClientSyncService(
        api: TestBridgeClient(server: server, userId: mainUserId),
        db: dbDeviceA,
        repository: repoDeviceA,
      );

      // DB B en memoria (completamente separada de DB A)
      dbDeviceB = AppDatabase.inMemory(NativeDatabase.memory());
      repoDeviceB = FinanceRepository(dbDeviceB);
      reviewRepoDeviceB = ReviewRepository(dbDeviceB);
      syncDeviceB = ClientSyncService(
        api: TestBridgeClient(server: server, userId: mainUserId),
        db: dbDeviceB,
        repository: repoDeviceB,
      );
    });

    tearDown(() async {
      await dbDeviceA.close();
      await dbDeviceB.close();
    });

    test('3.1 Altas de todas las 5 entidades en Dispositivo A se sincronizan a Dispositivo B', () async {
      // 1. Crear las 5 entidades en Dispositivo A
      // a) Movimiento (Transaction)
      final txA = MoneyTransaction(
        id: 'tx-entity-001',
        type: 'expense',
        category: 'Supermercado',
        amount: 14500.0,
        description: 'Compras del mes',
        date: DateTime.parse('2026-10-23T10:00:00.000Z'),
        recognized: true,
      );
      await repoDeviceA.saveTransaction(userId: mainUserId, transaction: txA, isNew: true, deviceId: 'dev-A');

      // b) Compromiso (Commitment)
      final commA = Commitment(
        id: 'comm-entity-002',
        title: 'Alquiler departamento',
        amount: 85000.0,
        dueDate: DateTime.parse('2026-11-01T00:00:00.000Z'),
        status: 'pending',
      );
      await repoDeviceA.saveCommitment(userId: mainUserId, commitment: commA, isNew: true, deviceId: 'dev-A');

      // c) Meta de ahorro (Goal)
      final goalA = SavingsGoal(
        id: 'goal-entity-003',
        title: 'Vacaciones fin de año',
        targetAmount: 300000.0,
        savedAmount: 75000.0,
      );
      await repoDeviceA.saveGoal(userId: mainUserId, goal: goalA, isNew: true, deviceId: 'dev-A');

      // d) Decisión (Decision)
      await repoDeviceA.saveDecision(
        userId: mainUserId,
        action: 'reduce_streaming',
        note: 'Cancelar suscripciones innecesarias',
        deviceId: 'dev-A',
      );

      // e) Revisión (Review)
      final reviewA = ReviewResult(
        start: DateTime.parse('2026-10-01'),
        end: DateTime.parse('2026-10-23'),
        periodTitle: 'Octubre 2026',
        periodSubtitle: 'Semana 3',
        transactionIds: ['tx-entity-001'],
        decision: 'approved',
        decisionDetails: {'nota': 'Aprobada en reunión familiar'},
        createdAt: DateTime.parse('2026-10-23T10:30:00.000Z'),
      );
      await reviewRepoDeviceA.saveReview(mainUserId, reviewA, deviceId: 'dev-A');

      // 2. Dispositivo A sincroniza (PUSH hacia el servidor)
      final reportA = await syncDeviceA.syncNow(mainUserId);
      expect(reportA.pendingCount, equals(0), reason: 'Dispositivo A no debe tener operaciones pendientes');

      // 3. Dispositivo B sincroniza (PULL desde el servidor)
      final reportB = await syncDeviceB.syncNow(mainUserId);
      expect(reportB.pendingCount, equals(0));

      // 4. Comprobar que las 5 entidades existen en Dispositivo B con valores exactos
      // a) Transacción
      final txsB = await repoDeviceB.getTransactions(mainUserId);
      expect(txsB, hasLength(1));
      expect(txsB.first.id, equals('tx-entity-001'));
      expect(txsB.first.amount, equals(14500.0));
      expect(txsB.first.description, equals('Compras del mes'));

      // b) Compromiso
      final commsB = await repoDeviceB.getCommitments(mainUserId);
      expect(commsB, hasLength(1));
      expect(commsB.first.id, equals('comm-entity-002'));
      expect(commsB.first.amount, equals(85000.0));

      // c) Meta
      final goalsB = await repoDeviceB.getGoals(mainUserId);
      expect(goalsB, hasLength(1));
      expect(goalsB.first.id, equals('goal-entity-003'));
      expect(goalsB.first.targetAmount, equals(300000.0));
      expect(goalsB.first.savedAmount, equals(75000.0));

      // d) Decisión
      final decsB = await repoDeviceB.getDecisions(mainUserId);
      expect(decsB, hasLength(1));
      expect(decsB.first.action, equals('reduce_streaming'));
      expect(decsB.first.note, equals('Cancelar suscripciones innecesarias'));

      // e) Revisión
      final revsB = await reviewRepoDeviceB.getReviews(mainUserId);
      expect(revsB, hasLength(1));
      expect(revsB.first.periodTitle, equals('Octubre 2026'));
      expect(revsB.first.decision, equals('approved'));
    });

    test('3.2 Modificaciones en Dispositivo B se propagan a Dispositivo A', () async {
      // Setup inicial: sembrar meta en A y sincronizar a B
      final goal = SavingsGoal(
        id: 'goal-update-100',
        title: 'Mochila nueva',
        targetAmount: 50000.0,
        savedAmount: 10000.0,
      );
      await repoDeviceA.saveGoal(userId: mainUserId, goal: goal, isNew: true, deviceId: 'dev-A');
      await syncDeviceA.syncNow(mainUserId);
      await syncDeviceB.syncNow(mainUserId);

      // En Dispositivo B modificamos el ahorro de 10,000 a 35,000
      final updatedGoalB = SavingsGoal(
        id: 'goal-update-100',
        title: 'Mochila nueva',
        targetAmount: 50000.0,
        savedAmount: 35000.0,
        version: 1,
      );
      await repoDeviceB.saveGoal(userId: mainUserId, goal: updatedGoalB, isNew: false, deviceId: 'dev-B');

      // Dispositivo B hace push
      await syncDeviceB.syncNow(mainUserId);

      // Dispositivo A hace pull
      await syncDeviceA.syncNow(mainUserId);

      // Verificar que Dispositivo A tiene el valor actualizado
      final goalsA = await repoDeviceA.getGoals(mainUserId);
      expect(goalsA.first.savedAmount, equals(35000.0));
      expect(goalsA.first.version, equals(2));
    });

    test('3.3 Eliminaciones de entidades (soft delete) se sincronizan limpiamente entre dispositivos', () async {
      // Crear transacción y compromiso en A
      final tx = MoneyTransaction(
        id: 'tx-del-200',
        type: 'expense',
        category: 'Ocio',
        amount: 5000.0,
        description: 'Cine',
        date: DateTime.now(),
        recognized: true,
      );
      await repoDeviceA.saveTransaction(userId: mainUserId, transaction: tx, isNew: true);

      final comm = Commitment(
        id: 'comm-del-300',
        title: 'Tarjeta crédito',
        amount: 40000.0,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        status: 'pending',
      );
      await repoDeviceA.saveCommitment(userId: mainUserId, commitment: comm, isNew: true);

      await syncDeviceA.syncNow(mainUserId);
      await syncDeviceB.syncNow(mainUserId);

      expect((await repoDeviceB.getTransactions(mainUserId)), hasLength(1));
      expect((await repoDeviceB.getCommitments(mainUserId)), hasLength(1));

      // Eliminar transacción en Dispositivo B
      await repoDeviceB.deleteTransaction(userId: mainUserId, id: 'tx-del-200', deviceId: 'dev-B');
      // Eliminar compromiso en Dispositivo A
      await repoDeviceA.deleteCommitment(userId: mainUserId, id: 'comm-del-300', deviceId: 'dev-A');

      // Sincronizar B y luego A
      await syncDeviceB.syncNow(mainUserId);
      await syncDeviceA.syncNow(mainUserId);
      await syncDeviceB.syncNow(mainUserId);

      // Comprobar que en ambos dispositivos ambas entidades quedaron eliminadas de la vista de negocio
      expect((await repoDeviceA.getTransactions(mainUserId)), isEmpty);
      expect((await repoDeviceA.getCommitments(mainUserId)), isEmpty);
      expect((await repoDeviceB.getTransactions(mainUserId)), isEmpty);
      expect((await repoDeviceB.getCommitments(mainUserId)), isEmpty);
    });

    test('3.4 Detección de conflicto ante ediciones concurrentes sobre la misma versión', () async {
      // 1. Crear meta inicial con version 1
      final goal = SavingsGoal(
        id: 'goal-conflict-500',
        title: 'Fondo inversión',
        targetAmount: 100000.0,
        savedAmount: 20000.0,
      );
      await repoDeviceA.saveGoal(userId: mainUserId, goal: goal, isNew: true);
      await syncDeviceA.syncNow(mainUserId);
      await syncDeviceB.syncNow(mainUserId);

      // 2. Dispositivo A modifica localmente sin sincronizar todavía
      final editA = SavingsGoal(
        id: 'goal-conflict-500',
        title: 'Fondo inversión',
        targetAmount: 100000.0,
        savedAmount: 30000.0,
        version: 1,
      );
      await repoDeviceA.saveGoal(userId: mainUserId, goal: editA, isNew: false, deviceId: 'dev-A');

      // 3. Dispositivo B modifica en paralelo y sincroniza primero
      final editB = SavingsGoal(
        id: 'goal-conflict-500',
        title: 'Fondo inversión',
        targetAmount: 100000.0,
        savedAmount: 45000.0,
        version: 1,
      );
      await repoDeviceB.saveGoal(userId: mainUserId, goal: editB, isNew: false, deviceId: 'dev-B');
      final reportB = await syncDeviceB.syncNow(mainUserId);
      expect(reportB.pendingCount, equals(0));

      // 4. Dispositivo A intenta sincronizar: el servidor debe rechazar la versión desactualizada y reportar conflicto
      final reportA = await syncDeviceA.syncNow(mainUserId);
      expect(reportA.conflictCount, greaterThanOrEqualTo(1), reason: 'Debe detectarse conflicto por divergencia de versiones');

      // Verificar que el conflicto quedó registrado localmente en la base de datos de A
      final conflicts = await (dbDeviceA.select(dbDeviceA.localConflicts)
            ..where((c) => c.userId.equals(mainUserId) & c.entityId.equals('goal-conflict-500')))
          .get();
      expect(conflicts, isNotEmpty);
      expect(conflicts.first.serverVersion, equals(2));
      expect(conflicts.first.baseVersion, equals(1));
    });

    test('3.5 Aislamiento estricto entre cuentas: Usuario A no puede ver datos de Usuario B', () async {
      // Cliente de Usuario B (Intruso)
      final clientIntruder = TestBridgeClient(server: server, userId: otherUserId);
      final dbIntruder = AppDatabase.inMemory(NativeDatabase.memory());
      final repoIntruder = FinanceRepository(dbIntruder);
      final syncIntruder = ClientSyncService(
        api: clientIntruder,
        db: dbIntruder,
        repository: repoIntruder,
      );

      // Usuario B crea datos privados
      final privateTxB = MoneyTransaction(
        id: 'tx-private-userB',
        type: 'expense',
        category: 'Confidencial',
        amount: 999999.0,
        description: 'Información estrictamente confidencial de usuario B',
        date: DateTime.now(),
        recognized: true,
      );
      await repoIntruder.saveTransaction(userId: otherUserId, transaction: privateTxB, isNew: true, deviceId: 'dev-intruder');
      await syncIntruder.syncNow(otherUserId);

      // Usuario A sincroniza su cuenta
      await syncDeviceA.syncNow(mainUserId);

      // Usuario A NO debe haber recibido ningún registro de Usuario B
      final txsA = await repoDeviceA.getTransactions(mainUserId);
      expect(txsA.where((t) => t.id == 'tx-private-userB'), isEmpty);

      // Intento explícito de Usuario A de consultar sync_log del servidor con cursor 0
      final pullUserA = server.handlePull(userId: mainUserId, cursor: 0);
      final changesUserA = pullUserA['changes'] as List;
      expect(changesUserA.any((c) => c['user_id'] == otherUserId), isFalse,
          reason: 'El servidor jamás debe retornar cambios de otro user_id');

      await dbIntruder.close();
    });
  });
}
