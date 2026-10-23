import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/finance_repository.dart';
import 'conflict_resolver.dart';
import 'sync_status.dart';

class ClientSyncService {
  final ApiClient api;
  final AppDatabase db;
  final FinanceRepository repository;

  bool _isSyncing = false;
  SyncReport _report = const SyncReport();

  final _statusController = StreamController<SyncReport>.broadcast();
  Stream<SyncReport> get statusStream => _statusController.stream;
  SyncReport get currentReport => _report;

  ClientSyncService({
    required this.api,
    required this.db,
    required this.repository,
  });

  void _updateReport(SyncReport newReport) {
    _report = newReport;
    if (!_statusController.isClosed) {
      _statusController.add(_report);
    }
  }

  /// Ejecuta un ciclo de sincronización completo (Push -> Pull -> Status).
  Future<SyncReport> syncNow(String userId) async {
    if (_isSyncing) return _report;
    if (api.token == null || api.token!.isEmpty) {
      _updateReport(_report.copyWith(state: SyncState.offline, isOnline: false));
      return _report;
    }

    _isSyncing = true;
    _updateReport(_report.copyWith(state: SyncState.syncing));

    try {
      // 1. Obtener usuario local y cursor
      final user = await (db.select(db.localUsers)..where((u) => u.id.equals(userId))).getSingleOrNull();
      final currentCursor = user?.lastServerCursor ?? 0;

      // 2. Enviar operaciones pendientes (PUSH)
      final pendingOps = await repository.getPendingOperations(userId);

      if (pendingOps.isNotEmpty) {
        final pushPayload = {
          'device_id': api.deviceId,
          'operations': pendingOps.map((op) {
            Map<String, dynamic> payload = {};
            try {
              payload = Map<String, dynamic>.from(jsonDecode(op.payloadJson) as Map);
            } catch (_) {}

            return {
              'operation_id': op.operationId,
              'entity_type': op.entityType,
              'entity_id': op.entityId,
              'action': op.action,
              'payload': payload,
              'base_version': op.baseVersion,
              'created_at': op.createdAt.toIso8601String(),
            };
          }).toList(),
        };

        final pushResponse = await api.post('/api/sync/push', pushPayload);

        if (pushResponse is Map) {
          final processed = pushResponse['processed'] as List? ?? [];

          for (final item in processed) {
            final opId = item['operation_id']?.toString() ?? '';
            final status = item['status']?.toString();
            final version = (item['version'] as num?)?.toInt() ?? 1;

            if (status == 'applied') {
              // Operación completada exitosamente
              await repository.removeOperation(opId);
              // Actualizar versión en la entidad local si corresponde
              final entityType = item['entity_type']?.toString();
              final entityId = item['entity_id']?.toString();
              if (entityType != null && entityId != null) {
                await _updateLocalEntityVersion(entityType, entityId, version);
              }
            } else if (status == 'conflict') {
              // Conflicto detectado en el servidor
              final conflictId = item['conflict_id']?.toString() ?? opId;
              final entityType = item['entity_type']?.toString() ?? '';
              final entityId = item['entity_id']?.toString() ?? '';
              final baseVersion = (item['base_version'] as num?)?.toInt() ?? 1;
              final serverVersion = (item['server_version'] as num?)?.toInt() ?? 1;
              final serverPayload = item['server_payload'] ?? {};

              // Registrar conflicto local
              await db.into(db.localConflicts).insertOnConflictUpdate(
                    LocalConflictsCompanion(
                      id: Value(conflictId),
                      userId: Value(userId),
                      entityType: Value(entityType),
                      entityId: Value(entityId),
                      baseVersion: Value(baseVersion),
                      serverVersion: Value(serverVersion),
                      clientPayloadJson: Value(
                          pendingOps.firstWhere((p) => p.operationId == opId, orElse: () => pendingOps.first).payloadJson),
                      serverPayloadJson: Value(jsonEncode(serverPayload)),
                      status: const Value('unresolved'),
                      createdAt: Value(DateTime.now()),
                    ),
                  );
            } else {
              // Error puntual
              await repository.markOperationFailed(opId, item['message']?.toString() ?? 'Error en servidor');
            }
          }
        }
      }

      // 3. Descargar cambios desde el último cursor (PULL)
      int nextCursor = currentCursor;
      bool hasMore = true;

      while (hasMore) {
        final pullResponse = await api.get('/api/sync/pull?cursor=$nextCursor&limit=200');

        if (pullResponse is Map) {
          final changes = pullResponse['changes'] as List? ?? [];
          nextCursor = (pullResponse['cursor'] as num?)?.toInt() ?? nextCursor;
          hasMore = pullResponse['has_more'] == true;

          for (final change in changes) {
            await _applyRemoteChange(userId, Map<String, dynamic>.from(change as Map));
          }
        } else {
          hasMore = false;
        }
      }

      // 4. Actualizar cursor confirmado
      final now = DateTime.now();
      await repository.updateSyncCursor(userId, nextCursor, now);

      // 5. Contar pendientes y conflictos
      final remainingPending = await repository.getPendingOperationsCount(userId);
      final conflictsQuery = db.select(db.localConflicts)
        ..where((c) => c.userId.equals(userId) & c.status.equals('unresolved'));
      final activeConflicts = await conflictsQuery.get();

      _updateReport(
        SyncReport(
          state: activeConflicts.isNotEmpty ? SyncState.hasConflicts : SyncState.idle,
          pendingCount: remainingPending,
          conflictCount: activeConflicts.length,
          lastSyncTime: now,
          isOnline: true,
        ),
      );
    } catch (e) {
      final isNetwork = e is ApiException && e.isNetworkError;
      final remainingPending = await repository.getPendingOperationsCount(userId);

      _updateReport(
        _report.copyWith(
          state: isNetwork ? SyncState.offline : SyncState.error,
          isOnline: !isNetwork,
          pendingCount: remainingPending,
          lastError: e.toString(),
        ),
      );
    } finally {
      _isSyncing = false;
    }

    return _report;
  }

  Future<void> _updateLocalEntityVersion(String entityType, String entityId, int version) async {
    switch (entityType.toLowerCase()) {
      case 'transaction':
        await (db.update(db.localTransactions)..where((t) => t.id.equals(entityId))).write(
          LocalTransactionsCompanion(version: Value(version), syncStatus: const Value('synced')),
        );
        break;
      case 'commitment':
        await (db.update(db.localCommitments)..where((c) => c.id.equals(entityId))).write(
          LocalCommitmentsCompanion(version: Value(version), syncStatus: const Value('synced')),
        );
        break;
      case 'goal':
        await (db.update(db.localGoals)..where((g) => g.id.equals(entityId))).write(
          LocalGoalsCompanion(version: Value(version), syncStatus: const Value('synced')),
        );
        break;
      case 'decision':
        await (db.update(db.localDecisions)..where((d) => d.id.equals(entityId))).write(
          LocalDecisionsCompanion(version: Value(version), syncStatus: const Value('synced')),
        );
        break;
      case 'review':
        await (db.update(db.localReviews)..where((r) => r.id.equals(entityId))).write(
          LocalReviewsCompanion(version: Value(version), syncStatus: const Value('synced')),
        );
        break;
    }
  }

  Future<void> _applyRemoteChange(String userId, Map<String, dynamic> change) async {
    final entityType = change['entity_type']?.toString().toLowerCase() ?? '';
    final entityId = change['entity_id']?.toString() ?? '';
    final action = change['action']?.toString().toLowerCase() ?? '';
    final version = (change['version'] as num?)?.toInt() ?? 1;
    final payload = Map<String, dynamic>.from(change['payload'] as Map? ?? {});
    final now = DateTime.now();

    await db.transaction(() async {
      if (action == 'delete') {
        switch (entityType) {
          case 'transaction':
            await (db.update(db.localTransactions)..where((t) => t.id.equals(entityId) & t.userId.equals(userId))).write(
              LocalTransactionsCompanion(isDeleted: const Value(true), version: Value(version), syncStatus: const Value('synced')),
            );
            break;
          case 'commitment':
            await (db.update(db.localCommitments)..where((c) => c.id.equals(entityId) & c.userId.equals(userId))).write(
              LocalCommitmentsCompanion(isDeleted: const Value(true), version: Value(version), syncStatus: const Value('synced')),
            );
            break;
          case 'goal':
            await (db.update(db.localGoals)..where((g) => g.id.equals(entityId) & g.userId.equals(userId))).write(
              LocalGoalsCompanion(isDeleted: const Value(true), version: Value(version), syncStatus: const Value('synced')),
            );
            break;
          case 'decision':
            await (db.update(db.localDecisions)..where((d) => d.id.equals(entityId) & d.userId.equals(userId))).write(
              LocalDecisionsCompanion(isDeleted: const Value(true), version: Value(version), syncStatus: const Value('synced')),
            );
            break;
          case 'review':
            await (db.update(db.localReviews)..where((r) => r.id.equals(entityId) & r.userId.equals(userId))).write(
              LocalReviewsCompanion(isDeleted: const Value(true), version: Value(version), syncStatus: const Value('synced')),
            );
            break;
        }
        return;
      }

      // Create / Update
      switch (entityType) {
        case 'transaction':
          final amount = (payload['amount'] as num?)?.toDouble() ?? 0.0;
          final dateStr = payload['date']?.toString();
          final txDate = dateStr != null ? (DateTime.tryParse(dateStr) ?? now) : now;

          await db.into(db.localTransactions).insertOnConflictUpdate(
                LocalTransactionsCompanion(
                  id: Value(entityId),
                  userId: Value(userId),
                  type: Value(payload['type']?.toString() ?? 'expense'),
                  category: Value(payload['category']?.toString() ?? 'Otros'),
                  amount: Value(amount),
                  description: Value(payload['description']?.toString() ?? ''),
                  date: Value(txDate),
                  recognized: Value(payload['recognized'] == true || payload['recognized'] == 1),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(now),
                ),
              );
          break;

        case 'commitment':
          final amount = (payload['amount'] as num?)?.toDouble() ?? 0.0;
          final dueStr = (payload['dueDate'] ?? payload['due_date'])?.toString();
          final dueDate = dueStr != null ? (DateTime.tryParse(dueStr) ?? now) : now;

          await db.into(db.localCommitments).insertOnConflictUpdate(
                LocalCommitmentsCompanion(
                  id: Value(entityId),
                  userId: Value(userId),
                  title: Value(payload['title']?.toString() ?? 'Compromiso'),
                  amount: Value(amount),
                  dueDate: Value(dueDate),
                  status: Value(payload['status']?.toString() ?? 'pending'),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(now),
                ),
              );
          break;

        case 'goal':
          final target = (payload['targetAmount'] ?? payload['target_amount'] as num?)?.toDouble() ?? 0.0;
          final saved = (payload['savedAmount'] ?? payload['saved_amount'] as num?)?.toDouble() ?? 0.0;

          await db.into(db.localGoals).insertOnConflictUpdate(
                LocalGoalsCompanion(
                  id: Value(entityId),
                  userId: Value(userId),
                  title: Value(payload['title']?.toString() ?? 'Meta'),
                  targetAmount: Value(target),
                  savedAmount: Value(saved),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(now),
                ),
              );
          break;

        case 'decision':
          await db.into(db.localDecisions).insertOnConflictUpdate(
                LocalDecisionsCompanion(
                  id: Value(entityId),
                  userId: Value(userId),
                  action: Value(payload['action']?.toString() ?? ''),
                  note: Value(payload['note']?.toString() ?? ''),
                  createdAt: Value(DateTime.tryParse(payload['created_at']?.toString() ?? '') ?? now),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(now),
                ),
              );
          break;

        case 'review':
          await db.into(db.localReviews).insertOnConflictUpdate(
                LocalReviewsCompanion(
                  id: Value(entityId),
                  userId: Value(userId),
                  start: Value(DateTime.tryParse(payload['start']?.toString() ?? '') ?? now),
                  end: Value(DateTime.tryParse(payload['end']?.toString() ?? '') ?? now),
                  periodTitle: Value(payload['periodTitle']?.toString() ?? ''),
                  periodSubtitle: Value(payload['periodSubtitle']?.toString() ?? ''),
                  transactionIdsJson: Value(jsonEncode(payload['transactionIds'] ?? [])),
                  decision: Value(payload['decision']?.toString() ?? ''),
                  decisionDetailsJson: Value(jsonEncode(payload['decisionDetails'] ?? {})),
                  createdAt: Value(DateTime.tryParse(payload['createdAt']?.toString() ?? '') ?? now),
                  version: Value(version),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(now),
                ),
              );
          break;
      }
    });
  }

  /// Obtiene los conflictos pendientes del usuario
  Future<List<EntityConflict>> getUnresolvedConflicts(String userId) async {
    final query = db.select(db.localConflicts)
      ..where((c) => c.userId.equals(userId) & c.status.equals('unresolved'))
      ..orderBy([(c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)]);

    final rows = await query.get();
    return rows.map((r) {
      return EntityConflict.fromDb(
        id: r.id,
        userId: r.userId,
        entityType: r.entityType,
        entityId: r.entityId,
        baseVersion: r.baseVersion,
        serverVersion: r.serverVersion,
        clientPayloadJson: r.clientPayloadJson,
        serverPayloadJson: r.serverPayloadJson,
        status: r.status,
        createdAt: r.createdAt,
        resolvedAt: r.resolvedAt,
      );
    }).toList();
  }

  /// Resuelve un conflicto aplicando la estrategia elegida y sincronizando con el servidor
  Future<void> resolveConflict({
    required String userId,
    required String conflictId,
    required ConflictResolutionStrategy strategy,
    Map<String, dynamic>? mergedPayload,
  }) async {
    final conflictRow = await (db.select(db.localConflicts)..where((c) => c.id.equals(conflictId))).getSingleOrNull();
    if (conflictRow == null) return;

    final strategyStr = strategy == ConflictResolutionStrategy.clientWins
        ? 'client_wins'
        : (strategy == ConflictResolutionStrategy.serverWins ? 'server_wins' : 'merge');

    // Notificar al servidor si está disponible
    try {
      await api.post('/api/sync/conflicts/$conflictId/resolve', {
        'strategy': strategyStr,
        if (mergedPayload != null) 'merged_payload': mergedPayload,
      });
    } catch (_) {
      // Si está offline, se resolverá localmente y se propagará cuando vuelva internet
    }

    // Resolver localmente
    await db.transaction(() async {
      await (db.update(db.localConflicts)..where((c) => c.id.equals(conflictId))).write(
        LocalConflictsCompanion(
          status: Value('resolved_$strategyStr'),
          resolvedAt: Value(DateTime.now()),
        ),
      );

      // Si gana el servidor, aplicar la versión del servidor localmente
      if (strategy == ConflictResolutionStrategy.serverWins) {
        final serverPayload = Map<String, dynamic>.from(jsonDecode(conflictRow.serverPayloadJson) as Map);
        await _applyRemoteChange(userId, {
          'entity_type': conflictRow.entityType,
          'entity_id': conflictRow.entityId,
          'action': 'update',
          'version': conflictRow.serverVersion,
          'payload': serverPayload,
        });
      }
    });

    await syncNow(userId);
  }

  void dispose() {
    _statusController.close();
  }
}
