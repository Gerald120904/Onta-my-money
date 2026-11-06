import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/models.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

class PlannedReminder {
  final String key;
  final DateTime when;
  final String title;
  final String body;
  final bool weekly;

  const PlannedReminder(this.key, this.when, this.title, this.body,
      {this.weekly = false});
}

class AndroidReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static bool get isSupported =>
      !kIsWeb && Platform.isAndroid;

  static int idFor(String key) {
    var hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static List<PlannedReminder> plan({
    required String userId,
    required List<Commitment> commitments,
    required Map<String, String> currencyByAccount,
    required NotificationPreferences preferences,
    required DateTime now,
  }) {
    final reminders = <PlannedReminder>[];
    for (final commitment in commitments) {
      if (commitment.status.toLowerCase() != 'pending') continue;
      final amount = NotificationService.formatAmount(commitment.amount,
          currency: currencyByAccount[commitment.accountId] ?? 'CRC');
      final due = commitment.dueDate;
      final events = <(String, int, bool)>[
        ('7d', -7, preferences.reminder7d),
        ('3d', -3, preferences.reminder3d),
        ('1d', -1, preferences.reminder1d),
        ('due', 0, preferences.reminderDueDay),
        ('overdue', 1, preferences.reminderOverdue),
      ];
      for (final (type, offset, enabled) in events) {
        if (!enabled) continue;
        final when = DateTime(due.year, due.month, due.day + offset, 9);
        if (!when.isAfter(now)) continue;
        reminders.add(PlannedReminder(
          'onta:$userId:${commitment.id}:$type',
          when,
          type == 'overdue'
              ? 'Pago vencido: ${commitment.title}'
              : 'Recordatorio: ${commitment.title}',
          'Compromiso de $amount con vencimiento el '
              '${due.day}/${due.month}/${due.year}.',
        ));
      }
    }
    if (preferences.reminderWeeklyReview) {
      final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      var nextMonday =
          DateTime(now.year, now.month, now.day + daysUntilMonday, 9);
      if (!nextMonday.isAfter(now)) {
        nextMonday = nextMonday.add(const Duration(days: 7));
      }
      reminders.add(PlannedReminder(
        'onta:$userId:weekly',
        nextMonday,
        'Revisión semanal de tu dinero',
        'Revisá tus movimientos y tu disponible real.',
        weekly: true,
      ));
    }
    return reminders;
  }

  Future<bool> _initialize({bool requestPermission = false}) async {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (!requestPermission) return true;
    if (await android?.areNotificationsEnabled() == true) return true;
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> reconcile({
    required String userId,
    required List<Commitment> commitments,
    required Map<String, String> currencyByAccount,
    required NotificationPreferences preferences,
  }) async {
    if (!isSupported) return;
    final desired = plan(
      userId: userId,
      commitments: commitments,
      currencyByAccount: currencyByAccount,
      preferences: preferences,
      now: DateTime.now(),
    );
    if (!await _initialize(requestPermission: desired.isNotEmpty)) return;
    final wantedIds = {for (final reminder in desired) idFor(reminder.key)};
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if ((notification.payload ?? '').startsWith('onta:$userId:') &&
          !wantedIds.contains(notification.id)) {
        await _plugin.cancel(notification.id);
      }
    }
    for (final reminder in desired) {
      final id = idFor(reminder.key);
      await _plugin.cancel(id);
      await _plugin.zonedSchedule(
        id,
        reminder.title,
        reminder.body,
        tz.TZDateTime.from(reminder.when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'onta_commitments',
            'Compromisos y recordatorios',
            channelDescription: 'Avisos de pagos y revisión financiera',
            importance: Importance.high,
          ),
        ),
        payload: reminder.key,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents:
            reminder.weekly ? DateTimeComponents.dayOfWeekAndTime : null,
      );
    }
  }

  Future<void> cancelForUser(String userId) async {
    if (!isSupported || !await _initialize()) return;
    for (final notification in await _plugin.pendingNotificationRequests()) {
      if ((notification.payload ?? '').startsWith('onta:$userId:')) {
        await _plugin.cancel(notification.id);
      }
    }
  }
}
