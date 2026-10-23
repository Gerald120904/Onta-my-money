import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalUsers,
  LocalTransactions,
  LocalCommitments,
  LocalGoals,
  LocalDecisions,
  LocalReviews,
  LocalPendingOperations,
  LocalConflicts,
  LocalChangeHistory,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
