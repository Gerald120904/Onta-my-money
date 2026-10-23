import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../models/models.dart';

class FinanceRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  FinanceRepository(this.db);

  // ==========================================
  // USUARIOS & PERFIL LOCAL
  // ==========================================

  Future<LocalUser?> getUserByEmail(String email) async {
    final query = db.select(db.localUsers)..where((u) => u.email.equals(email.trim().toLowerCase()));
    return query.getSingleOrNull();
  }

  Future<LocalUser?> getCurrentUser() async {
    final query = db.select(db.localUsers)..where((u) => u.isCurrent.equals(true));
    return query.getSingleOrNull();
  }

  Future<void> saveUser({
    required String id,
    required String name,
    required String email,
    required String? token,
    double openingBalance = 0.0,
    bool isCurrent = true,
  }) async {
    await db.transaction(() async {
      if (isCurrent) {
        // Unmark any other current user
        await (db.update(db.localUsers)..where((u) => u.isCurrent.equals(true)))
            .write(const LocalUsersCompanion(isCurrent: Value(false)));
      }

      await db.into(db.localUsers).insertOnConflictUpdate(
            LocalUsersCompanion(
              id: Value(id),
              name: Value(name),
              email: Value(email.trim().toLowerCase()),
              token: Value(token),
              openingBalance: Value(openingBalance),
              isCurrent: Value(isCurrent),
            ),
          );
    });
  }

  Future<void> updateOpeningBalance(String userId, double openingBalance) async {
    await (db.update(db.localUsers)..where((u) => u.id.equals(userId))).write(
      LocalUsersCompanion(openingBalance: Value(openingBalance)),
    );
  }

  Future<void> updateSyncCursor(String userId, int cursor, DateTime syncTime) async {
    await (db.update(db.localUsers)..where((u) => u.id.equals(userId))).write(
      LocalUsersCompanion(
        lastServerCursor: Value(cursor),
        lastSyncAt: Value(syncTime),
      ),
    );
  }

  // ==========================================
  // TRANSACCIONES LOCALES
  // ==========================================

  Future<List<MoneyTransaction>> getTransactions(String userId) async {
    final query = db.select(db.localTransactions)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    final rows = await query.get();
    return rows.map((r) {
      return MoneyTransaction(
        id: r.id,
        type: r.type,
        category: r.category,
        amount: r.amount,
        description: r.description,
        date: r.date,
        recognized: r.recognized,
        syncStatus: r.syncStatus,
        version: r.version,
      );
    }).toList();
  }

  Future<LocalTransaction?> getTransactionRaw(String id, String userId) async {
    final query = db.select(db.localTransactions)
      ..where((t) => t.id.equals(id) & t.userId.equals(userId));
    return query.getSingleOrNull();
  }

  Future<void> saveTransaction({
    required String userId,
    required MoneyTransaction transaction,
    required bool isNew,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await getTransactionRaw(transaction.id, userId);
      final currentVersion = existing?.version ?? 1;

      // 1. Guardar entidad local
      await db.into(db.localTransactions).insertOnConflictUpdate(
            LocalTransactionsCompanion(
              id: Value(transaction.id),
              userId: Value(userId),
              type: Value(transaction.type),
              category: Value(transaction.category),
              amount: Value(transaction.amount),
              description: Value(transaction.description),
              date: Value(transaction.date),
              recognized: Value(transaction.recognized),
              version: Value(currentVersion),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      // 2. Encolar operación pendiente
      final payload = transaction.toJson();
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('transaction'),
              entityId: Value(transaction.id),
              action: Value(isNew ? 'create' : 'update'),
              payloadJson: Value(jsonEncode(payload)),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // 3. Registrar auditoría local
      await db.into(db.localChangeHistory).insert(
            LocalChangeHistoryCompanion(
              id: Value(_uuid.v4()),
              userId: Value(userId),
              entityType: const Value('transaction'),
              entityId: Value(transaction.id),
              action: Value(isNew ? 'create' : 'update'),
              previousValuesJson: Value(existing != null
                  ? jsonEncode({
                      'amount': existing.amount,
                      'category': existing.category,
                      'description': existing.description,
                    })
                  : null),
              newValuesJson: Value(jsonEncode(payload)),
              deviceId: Value(deviceId),
              localTimestamp: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
    });
  }

  Future<void> deleteTransaction({
    required String userId,
    required String id,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await getTransactionRaw(id, userId);
      final currentVersion = existing?.version ?? 1;

      // Marcar eliminado lógicamente
      await (db.update(db.localTransactions)..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
        LocalTransactionsCompanion(
          isDeleted: const Value(true),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      // Encolar operación de eliminación
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('transaction'),
              entityId: Value(id),
              action: const Value('delete'),
              payloadJson: const Value('{}'),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // Historial
      await db.into(db.localChangeHistory).insert(
            LocalChangeHistoryCompanion(
              id: Value(_uuid.v4()),
              userId: Value(userId),
              entityType: const Value('transaction'),
              entityId: Value(id),
              action: const Value('delete'),
              previousValuesJson: Value(existing != null
                  ? jsonEncode({
                      'amount': existing.amount,
                      'category': existing.category,
                    })
                  : null),
              newValuesJson: const Value('{"deleted": true}'),
              deviceId: Value(deviceId),
              localTimestamp: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
    });
  }

  // ==========================================
  // COMPROMISOS LOCALES
  // ==========================================

  Future<List<Commitment>> getCommitments(String userId) async {
    final query = db.select(db.localCommitments)
      ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false))
      ..orderBy([(c) => OrderingTerm(expression: c.dueDate, mode: OrderingMode.asc)]);

    final rows = await query.get();
    return rows.map((r) {
      return Commitment(
        id: r.id,
        title: r.title,
        amount: r.amount,
        dueDate: r.dueDate,
        status: r.status,
        syncStatus: r.syncStatus,
        version: r.version,
      );
    }).toList();
  }

  Future<void> saveCommitment({
    required String userId,
    required Commitment commitment,
    required bool isNew,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localCommitments)
            ..where((c) => c.id.equals(commitment.id) & c.userId.equals(userId)))
          .getSingleOrNull();
      final currentVersion = existing?.version ?? 1;

      await db.into(db.localCommitments).insertOnConflictUpdate(
            LocalCommitmentsCompanion(
              id: Value(commitment.id),
              userId: Value(userId),
              title: Value(commitment.title),
              amount: Value(commitment.amount),
              dueDate: Value(commitment.dueDate),
              status: Value(commitment.status),
              version: Value(currentVersion),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      final payload = commitment.toJson();
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('commitment'),
              entityId: Value(commitment.id),
              action: Value(isNew ? 'create' : 'update'),
              payloadJson: Value(jsonEncode(payload)),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<void> deleteCommitment({
    required String userId,
    required String id,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localCommitments)
            ..where((c) => c.id.equals(id) & c.userId.equals(userId)))
          .getSingleOrNull();
      final currentVersion = existing?.version ?? 1;

      await (db.update(db.localCommitments)..where((c) => c.id.equals(id) & c.userId.equals(userId))).write(
        LocalCommitmentsCompanion(
          isDeleted: const Value(true),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('commitment'),
              entityId: Value(id),
              action: const Value('delete'),
              payloadJson: const Value('{}'),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  // ==========================================
  // METAS DE AHORRO LOCALES
  // ==========================================

  Future<List<SavingsGoal>> getGoals(String userId) async {
    final query = db.select(db.localGoals)
      ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false))
      ..orderBy([(g) => OrderingTerm(expression: g.title, mode: OrderingMode.asc)]);

    final rows = await query.get();
    return rows.map((r) {
      return SavingsGoal(
        id: r.id,
        title: r.title,
        targetAmount: r.targetAmount,
        savedAmount: r.savedAmount,
        syncStatus: r.syncStatus,
        version: r.version,
      );
    }).toList();
  }

  Future<void> saveGoal({
    required String userId,
    required SavingsGoal goal,
    required bool isNew,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localGoals)
            ..where((g) => g.id.equals(goal.id) & g.userId.equals(userId)))
          .getSingleOrNull();
      final currentVersion = existing?.version ?? 1;

      await db.into(db.localGoals).insertOnConflictUpdate(
            LocalGoalsCompanion(
              id: Value(goal.id),
              userId: Value(userId),
              title: Value(goal.title),
              targetAmount: Value(goal.targetAmount),
              savedAmount: Value(goal.savedAmount),
              version: Value(currentVersion),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      final payload = goal.toJson();
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('goal'),
              entityId: Value(goal.id),
              action: Value(isNew ? 'create' : 'update'),
              payloadJson: Value(jsonEncode(payload)),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<void> deleteGoal({
    required String userId,
    required String id,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localGoals)
            ..where((g) => g.id.equals(id) & g.userId.equals(userId)))
          .getSingleOrNull();
      final currentVersion = existing?.version ?? 1;

      await (db.update(db.localGoals)..where((g) => g.id.equals(id) & g.userId.equals(userId))).write(
        LocalGoalsCompanion(
          isDeleted: const Value(true),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('goal'),
              entityId: Value(id),
              action: const Value('delete'),
              payloadJson: const Value('{}'),
              baseVersion: Value(currentVersion),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  // ==========================================
  // DECISIONES
  // ==========================================

  Future<void> saveDecision({
    required String userId,
    required String action,
    required String note,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final opId = _uuid.v4();

    await db.transaction(() async {
      await db.into(db.localDecisions).insert(
            LocalDecisionsCompanion(
              id: Value(id),
              userId: Value(userId),
              action: Value(action),
              note: Value(note),
              createdAt: Value(now),
              version: const Value(1),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      final payload = {'action': action, 'note': note, 'created_at': now.toIso8601String()};
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('decision'),
              entityId: Value(id),
              action: const Value('create'),
              payloadJson: Value(jsonEncode(payload)),
              baseVersion: const Value(1),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  // ==========================================
  // CÁLCULO DE DASHBOARD LOCAL
  // ==========================================

  Future<DashboardSummary> calculateDashboard(String userId) async {
    final user = await (db.select(db.localUsers)..where((u) => u.id.equals(userId))).getSingleOrNull();
    final openingBalance = user?.openingBalance ?? 0.0;

    final txRows = await (db.select(db.localTransactions)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();

    double income = 0.0;
    double expenses = 0.0;
    final categoryTotals = <String, double>{};

    for (final t in txRows) {
      if (t.type.toLowerCase() == 'income') {
        income += t.amount;
      } else {
        expenses += t.amount;
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0.0) + t.amount;
      }
    }

    final commitmentRows = await (db.select(db.localCommitments)
          ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false) & c.status.equals('pending')))
        .get();
    final committed = commitmentRows.fold<double>(0.0, (sum, c) => sum + c.amount);

    final goalRows = await (db.select(db.localGoals)
          ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false)))
        .get();
    final saved = goalRows.fold<double>(0.0, (sum, g) => sum + g.savedAmount);

    final currentBalance = openingBalance + income - expenses;
    final available = currentBalance - committed - saved;

    final byCategory = categoryTotals.entries
        .map((e) => CategoryTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return DashboardSummary(
      balance: currentBalance,
      committed: committed,
      saved: saved,
      available: available,
      byCategory: byCategory,
    );
  }

  // ==========================================
  // COLA DE OPERACIONES PENDIENTES
  // ==========================================

  Future<List<LocalPendingOperation>> getPendingOperations(String userId) async {
    final query = db.select(db.localPendingOperations)
      ..where((op) => op.userId.equals(userId) & op.status.equals('pending'))
      ..orderBy([(op) => OrderingTerm(expression: op.createdAt, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<int> getPendingOperationsCount(String userId) async {
    final ops = await getPendingOperations(userId);
    return ops.length;
  }

  Future<void> removeOperation(String operationId) async {
    await (db.delete(db.localPendingOperations)..where((op) => op.operationId.equals(operationId))).go();
  }

  Future<void> markOperationFailed(String operationId, String error) async {
    await (db.update(db.localPendingOperations)..where((op) => op.operationId.equals(operationId))).write(
      LocalPendingOperationsCompanion(
        lastError: Value(error),
        retryCount: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ==========================================
  // HISTORIAL DE CAMBIOS Y AUDITORÍA LOCAL
  // ==========================================

  Future<List<LocalChangeHistoryData>> getChangeHistory(String userId) async {
    final query = db.select(db.localChangeHistory)
      ..where((h) => h.userId.equals(userId))
      ..orderBy([(h) => OrderingTerm(expression: h.localTimestamp, mode: OrderingMode.desc)]);
    return query.get();
  }
}
