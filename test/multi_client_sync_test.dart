import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';
import 'package:donde_se_fue_mi_plata/core/sync/conflict_resolver.dart';
import 'package:donde_se_fue_mi_plata/core/sync/sync_service.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';

// Simulación de transporte HTTP directo conectando ApiClient de los clientes al motor del backend
class DirectServerBridgeClient extends ApiClient {
  final Map<String, dynamic> Function(String path, Map<String, dynamic>? body)
      onPost;
  final dynamic Function(String path) onGet;

  DirectServerBridgeClient({required this.onPost, required this.onGet});

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return onPost(path, body);
  }

  @override
  Future<dynamic> get(String path) async {
    return onGet(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'Multi-client E2E: Dos clientes independientes sincronizan sin duplicados ni pérdida',
      () async {
    const userId = 'user-shared-account';

    // 1. Servidor central con estado
    final serverTransactions = <String, Map<String, dynamic>>{};
    final serverSyncLog = <Map<String, dynamic>>[];
    final serverConflicts = <String, Map<String, dynamic>>{};
    final idempotencyKeys = <String, Map<String, dynamic>>{};
    int serverSeq = 0;

    Map<String, dynamic> handleServerPost(
        String path, Map<String, dynamic>? body) {
      if (path == '/api/sync/push') {
        final ops =
            (body?['operations'] as List? ?? []).cast<Map<String, dynamic>>();
        final processed = <Map<String, dynamic>>[];

        for (final op in ops) {
          final opId = op['operation_id'].toString();
          final entityId = op['entity_id'].toString();
          final action = op['action'].toString();
          final payload = op['payload'] as Map<String, dynamic>;
          final baseVersion = (op['base_version'] as num?)?.toInt() ?? 1;

          if (idempotencyKeys.containsKey(opId)) {
            processed.add(idempotencyKeys[opId]!);
            continue;
          }

          if (action == 'create') {
            final tx = Map<String, dynamic>.from(payload)
              ..['id'] = entityId
              ..['version'] = 1;
            serverTransactions[entityId] = tx;

            serverSeq++;
            serverSyncLog.add({
              'sequence': serverSeq,
              'entity_type': 'transaction',
              'entity_id': entityId,
              'action': 'create',
              'version': 1,
              'payload': tx,
              'created_at': DateTime.now().toIso8601String(),
            });

            final result = {
              'operation_id': opId,
              'status': 'applied',
              'entity_type': 'transaction',
              'entity_id': entityId,
              'version': 1,
            };
            idempotencyKeys[opId] = result;
            processed.add(result);
          } else if (action == 'update') {
            final current = serverTransactions[entityId];
            if (current != null) {
              final currentVer = current['version'] as int;
              if (currentVer != baseVersion) {
                // Conflicto
                final conflictId = 'conf-$opId';
                serverConflicts[conflictId] = {
                  'id': conflictId,
                  'client_version': baseVersion,
                  'server_version': currentVer,
                  'client_payload': payload,
                  'server_payload': current,
                  'status': 'unresolved',
                };
                final result = {
                  'operation_id': opId,
                  'status': 'conflict',
                  'conflict_id': conflictId,
                  'entity_type': 'transaction',
                  'entity_id': entityId,
                  'base_version': baseVersion,
                  'server_version': currentVer,
                  'server_payload': current,
                };
                processed.add(result);
                continue;
              }

              final newVer = currentVer + 1;
              current.addAll(payload);
              current['version'] = newVer;

              serverSeq++;
              serverSyncLog.add({
                'sequence': serverSeq,
                'entity_type': 'transaction',
                'entity_id': entityId,
                'action': 'update',
                'version': newVer,
                'payload': current,
                'created_at': DateTime.now().toIso8601String(),
              });

              final result = {
                'operation_id': opId,
                'status': 'applied',
                'entity_type': 'transaction',
                'entity_id': entityId,
                'version': newVer,
              };
              idempotencyKeys[opId] = result;
              processed.add(result);
            }
          }
        }

        return {
          'processed': processed,
          'server_cursor': serverSeq,
          'server_time': DateTime.now().toIso8601String(),
        };
      }

      if (path.contains('/resolve')) {
        // Resolver conflicto
        final segments = path.split('/');
        final conflictId = segments[segments.length - 2];
        final strategy = body?['strategy']?.toString() ?? 'client_wins';

        final conf = serverConflicts[conflictId];
        if (conf != null) {
          final entityId = conf['server_payload']['id'] as String;
          final current = serverTransactions[entityId]!;
          final newVer = (current['version'] as int) + 1;

          if (strategy == 'client_wins') {
            current.addAll(conf['client_payload'] as Map<String, dynamic>);
          }
          current['version'] = newVer;

          serverSeq++;
          serverSyncLog.add({
            'sequence': serverSeq,
            'entity_type': 'transaction',
            'entity_id': entityId,
            'action': 'update',
            'version': newVer,
            'payload': current,
            'created_at': DateTime.now().toIso8601String(),
          });

          conf['status'] = 'resolved_$strategy';
        }
        return {'ok': true};
      }

      return {};
    }

    dynamic handleServerGet(String path) {
      if (path.startsWith('/api/sync/pull')) {
        final uri = Uri.parse(path);
        final cursor = int.tryParse(uri.queryParameters['cursor'] ?? '0') ?? 0;
        final changes = serverSyncLog
            .where((log) => (log['sequence'] as int) > cursor)
            .toList();
        final nextCursor =
            changes.isNotEmpty ? changes.last['sequence'] as int : cursor;

        return {
          'changes': changes,
          'cursor': nextCursor,
          'has_more': false,
        };
      }
      return {};
    }

    // 2. Crear Cliente A (Android) con BD local A
    final dbA = AppDatabase(NativeDatabase.memory());
    final repoA = FinanceRepository(dbA);
    final apiA = DirectServerBridgeClient(
        onPost: handleServerPost, onGet: handleServerGet)
      ..token = 'token-A';
    final syncA = ClientSyncService(api: apiA, db: dbA, repository: repoA);

    await repoA.saveUser(
      id: userId,
      name: 'Sofía',
      email: 'sofia@plata.app',
      token: 'token-A',
      openingBalance: 100000.0,
      isCurrent: true,
    );

    // 3. Crear Cliente B (Web) con BD local B
    final dbB = AppDatabase(NativeDatabase.memory());
    final repoB = FinanceRepository(dbB);
    final apiB = DirectServerBridgeClient(
        onPost: handleServerPost, onGet: handleServerGet)
      ..token = 'token-B';
    final syncB = ClientSyncService(api: apiB, db: dbB, repository: repoB);

    await repoB.saveUser(
      id: userId,
      name: 'Sofía',
      email: 'sofia@plata.app',
      token: 'token-B',
      openingBalance: 100000.0,
      isCurrent: true,
    );

    // 4. Cliente A registra 3 transacciones offline
    for (int i = 1; i <= 3; i++) {
      await repoA.saveTransaction(
        userId: userId,
        transaction: MoneyTransaction(
          id: 'tx-A-$i',
          type: 'expense',
          category: 'Alimentación',
          amount: i * 1000.0,
          description: 'Gasto A $i',
          date: DateTime.now(),
          recognized: true,
        ),
        isNew: true,
      );
    }

    // 5. Cliente B registra 2 transacciones offline
    for (int i = 1; i <= 2; i++) {
      await repoB.saveTransaction(
        userId: userId,
        transaction: MoneyTransaction(
          id: 'tx-B-$i',
          type: 'income',
          category: 'Salario',
          amount: i * 5000.0,
          description: 'Ingreso B $i',
          date: DateTime.now(),
          recognized: true,
        ),
        isNew: true,
      );
    }

    // 6. Sincronizar Cliente A con servidor
    await syncA.syncNow(userId);
    expect(serverTransactions.length, equals(3));

    // 7. Sincronizar Cliente B con servidor (envía sus 2 y descarga los 3 de A)
    await syncB.syncNow(userId);
    expect(serverTransactions.length, equals(5));

    final txsInB = await repoB.getTransactions(userId);
    expect(txsInB.length, equals(5)); // Contiene las 2 de B + 3 de A

    // 8. Cliente A vuelve a sincronizar (descarga los 2 de B)
    await syncA.syncNow(userId);
    final txsInA = await repoA.getTransactions(userId);
    expect(txsInA.length, equals(5)); // Contiene las 3 de A + 2 de B

    // Verificar que los IDs y montos en ambos clientes son IDÉNTICOS
    final setA = txsInA.map((t) => '${t.id}:${t.amount}').toSet();
    final setB = txsInB.map((t) => '${t.id}:${t.amount}').toSet();
    expect(setA, equals(setB));

    // ==========================================
    // ESCENARIO CONFLICTOS CONCURRENTES
    // ==========================================
    // Ambos clientes tienen la transacción 'tx-A-1' con monto 1000 y versión 1

    // Cliente A edita 'tx-A-1' a 1200
    await repoA.saveTransaction(
      userId: userId,
      transaction: MoneyTransaction(
        id: 'tx-A-1',
        type: 'expense',
        category: 'Alimentación',
        amount: 1200.0,
        description: 'Gasto A 1 modificado',
        date: DateTime.now(),
        recognized: true,
      ),
      isNew: false,
    );

    // Cliente B edita 'tx-A-1' a 1800 y sincroniza primero
    await repoB.saveTransaction(
      userId: userId,
      transaction: MoneyTransaction(
        id: 'tx-A-1',
        type: 'expense',
        category: 'Alimentación',
        amount: 1800.0,
        description: 'Gasto A 1 modificado por B',
        date: DateTime.now(),
        recognized: true,
      ),
      isNew: false,
    );
    await syncB.syncNow(userId); // B avanza servidor a version 2

    // Ahora Cliente A sincroniza -> conflicto detectado!
    final reportA = await syncA.syncNow(userId);
    expect(reportA.conflictCount, equals(1));

    final conflictsA = await syncA.getUnresolvedConflicts(userId);
    expect(conflictsA, hasLength(1));
    expect(conflictsA.first.serverVersion, equals(2));

    // Cliente A resuelve el conflicto eligiendo 'clientWins' (1200)
    await syncA.resolveConflict(
      userId: userId,
      conflictId: conflictsA.first.id,
      strategy: ConflictResolutionStrategy.clientWins,
    );

    // Cliente B sincroniza y recibe la versión ganadora (1200, versión 3)
    await syncB.syncNow(userId);

    final finalTxInA = (await repoA.getTransactions(userId))
        .firstWhere((t) => t.id == 'tx-A-1');
    final finalTxInB = (await repoB.getTransactions(userId))
        .firstWhere((t) => t.id == 'tx-A-1');

    expect(finalTxInA.amount, equals(1200.0));
    expect(finalTxInB.amount, equals(1200.0));

    await dbA.close();
    await dbB.close();
  });
}
