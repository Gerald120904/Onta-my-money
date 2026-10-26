import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalUsers,
  LocalAccounts,
  LocalTransactions,
  LocalCommitments,
  LocalGoals,
  LocalDecisions,
  LocalReviews,
  LocalPendingOperations,
  LocalConflicts,
  LocalChangeHistory,
  LocalNotifications,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(localNotifications);
          }
          if (from < 3) {
            await m.createTable(localAccounts);
            await m.addColumn(localTransactions, localTransactions.accountId);
            await m.addColumn(localCommitments, localCommitments.accountId);
            await m.addColumn(localGoals, localGoals.accountId);
            await m.addColumn(localDecisions, localDecisions.accountId);
            await m.addColumn(localReviews, localReviews.accountId);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'onta_plata_local',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          // Fallback or OPFS status logged in debug
        },
      ),
    );
  }

  /// Factory for testing with in-memory SQLite
  factory AppDatabase.inMemory(QueryExecutor executor) {
    return AppDatabase(executor);
  }
}
