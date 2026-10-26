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

  Future<void> updateUserName(String userId, String name) async {
    await (db.update(db.localUsers)..where((u) => u.id.equals(userId))).write(
      LocalUsersCompanion(name: Value(name)),
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

  Future<List<MoneyTransaction>> getTransactions(String userId, {String? accountId}) async {
    var query = db.select(db.localTransactions)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));

    if (accountId != null && accountId.isNotEmpty) {
      query = query..where((t) => t.accountId.equals(accountId) | t.accountId.isNull());
    }

    query = query..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

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
        accountId: r.accountId,
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
              accountId: Value(transaction.accountId ?? existing?.accountId),
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
  // CUENTAS FINANCIERAS LOCALES (MONEDA INMUTABLE)
  // ==========================================

  Future<List<Account>> getAccounts(String userId) async {
    final rows = await (db.select(db.localAccounts)
          ..where((a) => a.userId.equals(userId) & a.isArchived.equals(false))
          ..orderBy([(a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.asc)]))
        .get();

    return rows.map((r) => Account(
      id: r.id,
      userId: r.userId,
      name: r.name,
      currency: r.currency, // Inmutable
      initialBalance: r.initialBalance,
      currentBalance: r.initialBalance,
      color: r.color,
      icon: r.icon,
      isDefault: r.isDefault,
      isArchived: r.isArchived,
      version: r.version,
      syncStatus: r.syncStatus,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    )).toList();
  }

  Future<LocalAccount?> getAccountRaw(String id, String userId) async {
    final query = db.select(db.localAccounts)
      ..where((a) => a.id.equals(id) & a.userId.equals(userId));
    return query.getSingleOrNull();
  }

  Future<void> saveAccount({
    required String userId,
    required Account account,
    required bool isNew,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await getAccountRaw(account.id, userId);
      final currentVersion = existing?.version ?? 1;

      // REGLA CRÍTICA: La moneda es estrictamente inmutable.
      final finalCurrency = existing != null ? existing.currency : account.currency.toUpperCase();

      await db.into(db.localAccounts).insertOnConflictUpdate(
            LocalAccountsCompanion(
              id: Value(account.id),
              userId: Value(userId),
              name: Value(account.name),
              currency: Value(finalCurrency),
              initialBalance: Value(isNew ? account.initialBalance : (existing?.initialBalance ?? account.initialBalance)),
              openingBalance: Value(isNew ? account.initialBalance : (existing?.openingBalance ?? account.initialBalance)),
              color: Value(account.color),
              icon: Value(account.icon),
              isDefault: Value(account.isDefault),
              isArchived: Value(account.isArchived),
              version: Value(currentVersion),
              syncStatus: const Value('pending'),
              createdAt: Value(existing?.createdAt ?? now),
              updatedAt: Value(now),
            ),
          );

      // Si se marca como default, desmarcar las demás
      if (account.isDefault) {
        await (db.update(db.localAccounts)..where((a) => a.userId.equals(userId) & a.id.isNotValue(account.id)))
            .write(const LocalAccountsCompanion(isDefault: Value(false)));
      }

      final payload = {
        'id': account.id,
        'user_id': userId,
        'name': account.name,
        if (isNew) 'currency': finalCurrency,
        if (isNew) 'initial_balance': account.initialBalance,
        'color': account.color,
        'icon': account.icon,
        'is_default': account.isDefault,
        'is_archived': account.isArchived,
      };

      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('account'),
              entityId: Value(account.id),
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

  Future<void> deleteAccount({
    required String userId,
    required String id,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await getAccountRaw(id, userId);
      final currentVersion = existing?.version ?? 1;

      await (db.update(db.localAccounts)..where((a) => a.id.equals(id) & a.userId.equals(userId))).write(
        LocalAccountsCompanion(
          isArchived: const Value(true),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('account'),
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
  // COMPROMISOS LOCALES
  // ==========================================

  Future<List<Commitment>> getCommitments(String userId, {String? accountId}) async {
    var query = db.select(db.localCommitments)
      ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false));

    if (accountId != null && accountId.isNotEmpty) {
      query = query..where((c) => c.accountId.equals(accountId) | c.accountId.isNull());
    }

    query = query..orderBy([(c) => OrderingTerm(expression: c.dueDate, mode: OrderingMode.asc)]);

    final rows = await query.get();
    return rows.map((r) {
      return Commitment(
        id: r.id,
        title: r.title,
        amount: r.amount,
        dueDate: r.dueDate,
        status: r.status,
        accountId: r.accountId,
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
              accountId: Value(commitment.accountId ?? existing?.accountId),
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

  Future<List<SavingsGoal>> getGoals(String userId, {String? accountId}) async {
    var query = db.select(db.localGoals)
      ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false));

    if (accountId != null && accountId.isNotEmpty) {
      query = query..where((g) => g.accountId.equals(accountId) | g.accountId.isNull());
    }

    query = query..orderBy([(g) => OrderingTerm(expression: g.title, mode: OrderingMode.asc)]);

    final rows = await query.get();
    return rows.map((r) {
      return SavingsGoal(
        id: r.id,
        title: r.title,
        targetAmount: r.targetAmount,
        savedAmount: r.savedAmount,
        accountId: r.accountId,
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
              accountId: Value(goal.accountId ?? existing?.accountId),
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
    String? accountId,
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
              accountId: Value(accountId),
              action: Value(action),
              note: Value(note),
              createdAt: Value(now),
              version: const Value(1),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      final payload = {
        'action': action,
        'note': note,
        'account_id': accountId,
        'created_at': now.toIso8601String()
      };
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

  Future<List<LocalDecision>> getDecisions(String userId, {String? accountId}) async {
    var query = db.select(db.localDecisions)
      ..where((d) => d.userId.equals(userId) & d.isDeleted.equals(false));
    if (accountId != null && accountId.isNotEmpty) {
      query = query..where((d) => d.accountId.equals(accountId) | d.accountId.isNull());
    }
    query = query..orderBy([(d) => OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> deleteDecision({
    required String userId,
    required String id,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localDecisions)
            ..where((d) => d.id.equals(id) & d.userId.equals(userId)))
          .getSingleOrNull();

      final currentVersion = existing?.version ?? 1;

      await (db.update(db.localDecisions)..where((d) => d.id.equals(id) & d.userId.equals(userId))).write(
        LocalDecisionsCompanion(
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
              entityType: const Value('decision'),
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
  // CÁLCULO DE DASHBOARD LOCAL
  // ==========================================

  Future<DashboardSummary> calculateDashboard(String userId, {String? accountId}) async {
    LocalAccount? activeAcc;
    if (accountId != null && accountId.isNotEmpty) {
      activeAcc = await getAccountRaw(accountId, userId);
    }

    if (activeAcc == null) {
      final userAccounts = await (db.select(db.localAccounts)
            ..where((a) => a.userId.equals(userId) & a.isArchived.equals(false))
            ..orderBy([(a) => OrderingTerm(expression: a.isDefault, mode: OrderingMode.desc)]))
          .get();
      if (userAccounts.isNotEmpty) {
        activeAcc = userAccounts.first;
      }
    }

    final user = await (db.select(db.localUsers)..where((u) => u.id.equals(userId))).getSingleOrNull();
    final openingBalance = activeAcc?.initialBalance ?? user?.openingBalance ?? 0.0;
    final currency = activeAcc?.currency ?? 'CRC';
    final targetAccId = activeAcc?.id;

    var txQuery = db.select(db.localTransactions)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));

    if (targetAccId != null) {
      txQuery = txQuery..where((t) => t.accountId.equals(targetAccId) | t.accountId.isNull());
    }

    final txRows = await txQuery.get();

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

    var commitmentQuery = db.select(db.localCommitments)
      ..where((c) => c.userId.equals(userId) & c.isDeleted.equals(false) & c.status.equals('pending'));
    if (targetAccId != null) {
      commitmentQuery = commitmentQuery..where((c) => c.accountId.equals(targetAccId) | c.accountId.isNull());
    }
    final commitmentRows = await commitmentQuery.get();
    final committed = commitmentRows.fold<double>(0.0, (sum, c) => sum + c.amount);

    var goalQuery = db.select(db.localGoals)
      ..where((g) => g.userId.equals(userId) & g.isDeleted.equals(false));
    if (targetAccId != null) {
      goalQuery = goalQuery..where((g) => g.accountId.equals(targetAccId) | g.accountId.isNull());
    }
    final goalRows = await goalQuery.get();
    final saved = goalRows.fold<double>(0.0, (sum, g) => sum + g.savedAmount);

    final currentBalance = openingBalance + income - expenses;
    final available = currentBalance - committed - saved;

    final byCategory = categoryTotals.entries
        .map((e) => CategoryTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return DashboardSummary(
      accountId: activeAcc?.id,
      accountName: activeAcc?.name ?? 'Cuenta Principal',
      currency: currency,
      openingBalance: openingBalance,
      income: income,
      expenses: expenses,
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

  Future<void> enqueueOperation({
    required String userId,
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
    int baseVersion = 1,
    String? deviceId,
  }) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.into(db.localPendingOperations).insert(
          LocalPendingOperationsCompanion(
            operationId: Value(opId),
            userId: Value(userId),
            deviceId: Value(deviceId),
            entityType: Value(entityType),
            entityId: Value(entityId),
            action: Value(action),
            payloadJson: Value(jsonEncode(payload)),
            baseVersion: Value(baseVersion),
            status: const Value('pending'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
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
