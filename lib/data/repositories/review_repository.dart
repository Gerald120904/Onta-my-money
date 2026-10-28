import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../../models/review_result.dart';

class ReviewRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  ReviewRepository(this.db);

  Future<List<ReviewResult>> getReviews(String userId) async {
    final query = db.select(db.localReviews)
      ..where((r) => r.userId.equals(userId) & r.isDeleted.equals(false))
      ..orderBy([
        (r) => OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc)
      ]);

    final rows = await query.get();
    return rows.map((r) {
      List<String> txIds = [];
      Map<String, dynamic> details = {};

      try {
        final decodedIds = jsonDecode(r.transactionIdsJson);
        if (decodedIds is List) {
          txIds = decodedIds.map((e) => e.toString()).toList();
        }
      } catch (_) {}

      try {
        final decodedDetails = jsonDecode(r.decisionDetailsJson);
        if (decodedDetails is Map) {
          details = Map<String, dynamic>.from(decodedDetails);
        }
      } catch (_) {}

      return ReviewResult(
        start: r.start,
        end: r.end,
        periodTitle: r.periodTitle,
        periodSubtitle: r.periodSubtitle,
        transactionIds: txIds,
        decision: r.decision,
        decisionDetails: details,
        createdAt: r.createdAt,
      );
    }).toList();
  }

  Future<void> saveReview(String userId, ReviewResult result,
      {String? deviceId}) async {
    final now = DateTime.now();
    final reviewId = _uuid.v4();
    final opId = _uuid.v4();

    await db.transaction(() async {
      await db.into(db.localReviews).insertOnConflictUpdate(
            LocalReviewsCompanion(
              id: Value(reviewId),
              userId: Value(userId),
              start: Value(result.start),
              end: Value(result.end),
              periodTitle: Value(result.periodTitle),
              periodSubtitle: Value(result.periodSubtitle),
              transactionIdsJson: Value(jsonEncode(result.transactionIds)),
              decision: Value(result.decision),
              decisionDetailsJson: Value(jsonEncode(result.decisionDetails)),
              createdAt: Value(result.createdAt),
              version: const Value(1),
              syncStatus: const Value('pending'),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      final payload = result.toJson();
      await db.into(db.localPendingOperations).insert(
            LocalPendingOperationsCompanion(
              operationId: Value(opId),
              userId: Value(userId),
              deviceId: Value(deviceId),
              entityType: const Value('review'),
              entityId: Value(reviewId),
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

  Future<void> deleteReview(String userId, DateTime createdAt,
      {String? deviceId}) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    await db.transaction(() async {
      final existing = await (db.select(db.localReviews)
            ..where(
                (r) => r.userId.equals(userId) & r.createdAt.equals(createdAt)))
          .getSingleOrNull();

      if (existing == null) return;

      await (db.update(db.localReviews)..where((r) => r.id.equals(existing.id)))
          .write(
        LocalReviewsCompanion(
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
              entityType: const Value('review'),
              entityId: Value(existing.id),
              action: const Value('delete'),
              payloadJson: const Value('{}'),
              baseVersion: Value(existing.version),
              status: const Value('pending'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  /// Migración idempotente del historial de revisiones almacenado en SharedPreferences
  Future<void> migrateFromSharedPreferences(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'review_history_${email.trim().toLowerCase()}';
    final raw = prefs.getString(key);

    List<ReviewResult> toMigrate = [];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          toMigrate = decoded
              .whereType<Map>()
              .map((item) =>
                  ReviewResult.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      } catch (_) {}
    }

    // Comprobar también el reporte suelto 'latest_review'
    final oldSingle = prefs.getString('latest_review');
    if (oldSingle != null && oldSingle.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(oldSingle);
        final review =
            ReviewResult.fromJson(Map<String, dynamic>.from(decoded));
        if (!toMigrate.any((r) => r.createdAt == review.createdAt)) {
          toMigrate.add(review);
        }
      } catch (_) {}
    }

    if (toMigrate.isEmpty) return;

    // Insertar en la base de datos de manera idempotente
    await db.transaction(() async {
      for (final review in toMigrate) {
        final existing = await (db.select(db.localReviews)
              ..where((r) =>
                  r.userId.equals(userId) &
                  r.createdAt.equals(review.createdAt)))
            .getSingleOrNull();

        if (existing == null) {
          await db.into(db.localReviews).insert(
                LocalReviewsCompanion(
                  id: Value(_uuid.v4()),
                  userId: Value(userId),
                  start: Value(review.start),
                  end: Value(review.end),
                  periodTitle: Value(review.periodTitle),
                  periodSubtitle: Value(review.periodSubtitle),
                  transactionIdsJson: Value(jsonEncode(review.transactionIds)),
                  decision: Value(review.decision),
                  decisionDetailsJson:
                      Value(jsonEncode(review.decisionDetails)),
                  createdAt: Value(review.createdAt),
                  version: const Value(1),
                  syncStatus: const Value('synced'),
                  isDeleted: const Value(false),
                  updatedAt: Value(DateTime.now()),
                ),
              );
        }
      }
    });

    // Confirmar que se migraron antes de marcar la bandera de migración
    await prefs.setBool('migrated_reviews_$userId', true);
  }
}
