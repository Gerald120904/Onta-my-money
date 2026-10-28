import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../models/models.dart';
import 'app_notification.dart';
import 'notification_preferences.dart';

class NotificationService {
  final AppDatabase db;

  NotificationService(this.db);

  /// Helper to format money amounts in CRC
  static String formatAmount(double amount) {
    final fmt = NumberFormat.currency(
      locale: 'es_CR',
      symbol: '₡',
      decimalDigits: 0,
    );
    return fmt.format(amount);
  }

  /// Normalizes a DateTime to midnight (start of day)
  static DateTime _normalize(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Recalculates reminders for the user based on active commitments and preferences.
  /// Idempotent: avoids duplicate notifications across restarts.
  /// Cleans up or cancels reminders when commitments are marked as paid or deleted.
  Future<void> recalculateCommitmentReminders({
    required String userId,
    required List<Commitment> commitments,
    DateTime? nowOverride,
  }) async {
    final now = nowOverride ?? DateTime.now();
    final today = _normalize(now);
    final prefs = await NotificationPreferences.load(userId);

    // 1. Existing notifications for this user
    final existingRows = await (db.select(db.localNotifications)
          ..where((n) => n.userId.equals(userId)))
        .get();

    final existingMap = {for (final row in existingRows) row.id: row};

    // 2. Identify active pending commitments
    final activePendingMap = {
      for (final c in commitments)
        if (c.status.toLowerCase() == 'pending') c.id: c
    };

    // Clean up notifications for commitments that are now paid or deleted
    for (final row in existingRows) {
      if (row.relatedEntityType == 'commitment' &&
          row.relatedEntityId != null &&
          !activePendingMap.containsKey(row.relatedEntityId)) {
        await (db.delete(db.localNotifications)
              ..where((n) => n.id.equals(row.id)))
            .go();
      }
    }

    // 3. Process active pending commitments
    for (final c in activePendingMap.values) {
      final dueDateNorm = _normalize(c.dueDate);
      final daysDiff = dueDateNorm.difference(today).inDays;
      final dateKey =
          '${c.dueDate.year}-${c.dueDate.month.toString().padLeft(2, '0')}-${c.dueDate.day.toString().padLeft(2, '0')}';
      final formattedAmount = formatAmount(c.amount);

      // A. Check if overdue
      if (daysDiff < 0 && prefs.reminderOverdue) {
        final overdueId = 'overdue_${c.id}_$dateKey';
        if (!existingMap.containsKey(overdueId)) {
          final daysOverdue = daysDiff.abs();
          final daysText = daysOverdue == 1 ? '1 día' : '$daysOverdue días';
          await _insertNotification(
            LocalNotificationsCompanion(
              id: Value(overdueId),
              userId: Value(userId),
              type: const Value('overdue'),
              title: Value('Pago vencido: ${c.title}'),
              body: Value(
                'El compromiso de $formattedAmount venció hace $daysText. Tenés pendiente realizar este pago.',
              ),
              relatedEntityType: const Value('commitment'),
              relatedEntityId: Value(c.id),
              amount: Value(c.amount),
              scheduledDate: Value(now),
              isRead: const Value(false),
              isDismissed: const Value(false),
              createdAt: Value(now),
            ),
          );
        }
      }

      // B. 7 days before
      if (daysDiff == 7 && prefs.reminder7d) {
        final notifId = 'reminder_7d_${c.id}_$dateKey';
        if (!existingMap.containsKey(notifId)) {
          await _insertNotification(
            LocalNotificationsCompanion(
              id: Value(notifId),
              userId: Value(userId),
              type: const Value('reminder_7d'),
              title: Value('Compromiso en 7 días: ${c.title}'),
              body: Value(
                  'Recordá reservar $formattedAmount para este compromiso que vence la próxima semana.'),
              relatedEntityType: const Value('commitment'),
              relatedEntityId: Value(c.id),
              amount: Value(c.amount),
              scheduledDate: Value(now),
              isRead: const Value(false),
              isDismissed: const Value(false),
              createdAt: Value(now),
            ),
          );
        }
      }

      // C. 3 days before
      if (daysDiff == 3 && prefs.reminder3d) {
        final notifId = 'reminder_3d_${c.id}_$dateKey';
        if (!existingMap.containsKey(notifId)) {
          await _insertNotification(
            LocalNotificationsCompanion(
              id: Value(notifId),
              userId: Value(userId),
              type: const Value('reminder_3d'),
              title: Value('Compromiso en 3 días: ${c.title}'),
              body: Value(
                  'Faltan 3 días para pagar $formattedAmount de ${c.title}. Comprobá tu disponible real.'),
              relatedEntityType: const Value('commitment'),
              relatedEntityId: Value(c.id),
              amount: Value(c.amount),
              scheduledDate: Value(now),
              isRead: const Value(false),
              isDismissed: const Value(false),
              createdAt: Value(now),
            ),
          );
        }
      }

      // D. 1 day before
      if (daysDiff == 1 && prefs.reminder1d) {
        final notifId = 'reminder_1d_${c.id}_$dateKey';
        if (!existingMap.containsKey(notifId)) {
          await _insertNotification(
            LocalNotificationsCompanion(
              id: Value(notifId),
              userId: Value(userId),
              type: const Value('reminder_1d'),
              title: Value('Compromiso mañana: ${c.title}'),
              body: Value(
                  'Mañana vence el pago de $formattedAmount para ${c.title}.'),
              relatedEntityType: const Value('commitment'),
              relatedEntityId: Value(c.id),
              amount: Value(c.amount),
              scheduledDate: Value(now),
              isRead: const Value(false),
              isDismissed: const Value(false),
              createdAt: Value(now),
            ),
          );
        }
      }

      // E. Due day
      if (daysDiff == 0 && prefs.reminderDueDay) {
        final notifId = 'reminder_due_${c.id}_$dateKey';
        if (!existingMap.containsKey(notifId)) {
          await _insertNotification(
            LocalNotificationsCompanion(
              id: Value(notifId),
              userId: Value(userId),
              type: const Value('reminder_due'),
              title: Value('¡Hoy vence! ${c.title}'),
              body: Value(
                  'Hoy corresponde pagar $formattedAmount de ${c.title}. Marcá el compromiso como pagado una vez realizado.'),
              relatedEntityType: const Value('commitment'),
              relatedEntityId: Value(c.id),
              amount: Value(c.amount),
              scheduledDate: Value(now),
              isRead: const Value(false),
              isDismissed: const Value(false),
              createdAt: Value(now),
            ),
          );
        }
      }
    }

    // 4. Weekly financial review reminder
    if (prefs.reminderWeeklyReview) {
      // Calculate current calendar week identifier (e.g. 2026-W42)
      final weekOfYear =
          ((today.difference(DateTime(today.year, 1, 1)).inDays) / 7).ceil();
      final weeklyReviewId =
          'weekly_review_${userId}_${today.year}_W$weekOfYear';
      if (!existingMap.containsKey(weeklyReviewId)) {
        await _insertNotification(
          LocalNotificationsCompanion(
            id: Value(weeklyReviewId),
            userId: Value(userId),
            type: const Value('weekly_review'),
            title: const Value('Revisión semanal de tu dinero'),
            body: const Value(
                'Tomate 5 minutos para revisar tus movimientos, confirmar gastos y verificar tu disponible real.'),
            relatedEntityType: const Value('review'),
            scheduledDate: Value(now),
            isRead: const Value(false),
            isDismissed: const Value(false),
            createdAt: Value(now),
          ),
        );
      }
    }
  }

  Future<void> _insertNotification(
      LocalNotificationsCompanion companion) async {
    await db.into(db.localNotifications).insertOnConflictUpdate(companion);
  }

  /// Returns active notifications for the user, sorted newest first
  Future<List<AppNotification>> getNotifications(
    String userId, {
    bool includeDismissed = false,
  }) async {
    final query = db.select(db.localNotifications)
      ..where((n) {
        var expr = n.userId.equals(userId);
        if (!includeDismissed) {
          expr = expr & n.isDismissed.equals(false);
        }
        return expr;
      })
      ..orderBy([(n) => OrderingTerm.desc(n.scheduledDate)]);

    final rows = await query.get();
    return rows
        .map((r) => AppNotification(
              id: r.id,
              userId: r.userId,
              type: r.type,
              title: r.title,
              body: r.body,
              relatedEntityType: r.relatedEntityType,
              relatedEntityId: r.relatedEntityId,
              amount: r.amount,
              scheduledDate: r.scheduledDate,
              isRead: r.isRead,
              isDismissed: r.isDismissed,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  /// Counts unread and non-dismissed notifications
  Future<int> getUnreadCount(String userId) async {
    final query = db.select(db.localNotifications)
      ..where((n) =>
          n.userId.equals(userId) &
          n.isRead.equals(false) &
          n.isDismissed.equals(false));
    final rows = await query.get();
    return rows.length;
  }

  /// Marks a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await (db.update(db.localNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .write(
      const LocalNotificationsCompanion(isRead: Value(true)),
    );
  }

  /// Marks all notifications for a user as read
  Future<void> markAllAsRead(String userId) async {
    await (db.update(db.localNotifications)
          ..where((n) => n.userId.equals(userId) & n.isDismissed.equals(false)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  /// Dismisses a notification (removes it from active view without losing history)
  Future<void> dismissNotification(String notificationId) async {
    await (db.update(db.localNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .write(
      const LocalNotificationsCompanion(isDismissed: Value(true)),
    );
  }

  /// Deletes a notification completely
  Future<void> deleteNotification(String notificationId) async {
    await (db.delete(db.localNotifications)
          ..where((n) => n.id.equals(notificationId)))
        .go();
  }

  /// Deletes all notifications for a given user
  Future<void> clearAll(String userId) async {
    await (db.delete(db.localNotifications)
          ..where((n) => n.userId.equals(userId)))
        .go();
  }
}
