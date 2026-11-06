import 'package:flutter_test/flutter_test.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/services/notifications/android_reminder_scheduler.dart';
import 'package:donde_se_fue_mi_plata/services/notifications/notification_preferences.dart';

void main() {
  test('Programa importes por cuenta sin duplicar claves', () {
    final now = DateTime(2026, 10, 1, 8);
    final commitments = [
      for (final currency in ['CRC', 'USD', 'EUR'])
        Commitment(
          id: 'c_$currency',
          accountId: 'a_$currency',
          title: currency,
          amount: 1234.56,
          dueDate: DateTime(2026, 10, 10),
          status: 'pending',
        ),
    ];
    final plan = AndroidReminderScheduler.plan(
      userId: 'u1',
      commitments: commitments,
      currencyByAccount: {'a_CRC': 'CRC', 'a_USD': 'USD', 'a_EUR': 'EUR'},
      preferences: const NotificationPreferences(reminderWeeklyReview: false),
      now: now,
    );
    expect(plan.length, 15);
    expect(plan.map((r) => r.key).toSet().length, plan.length);
    expect(plan.firstWhere((r) => r.key.contains('c_CRC')).body, contains('₡'));
    expect(
        plan.firstWhere((r) => r.key.contains('c_USD')).body, contains(r'$'));
    expect(plan.firstWhere((r) => r.key.contains('c_EUR')).body, contains('€'));
    expect(AndroidReminderScheduler.idFor(plan.first.key),
        AndroidReminderScheduler.idFor(plan.first.key));
  });

  test('Pagados y preferencias desactivadas no producen avisos', () {
    final plan = AndroidReminderScheduler.plan(
      userId: 'u1',
      commitments: [
        Commitment(
            id: 'paid',
            title: 'Pagado',
            amount: 10,
            dueDate: DateTime(2026, 10, 10),
            status: 'paid'),
        Commitment(
            id: 'pending',
            title: 'Pendiente',
            amount: 20,
            dueDate: DateTime(2026, 10, 10),
            status: 'pending'),
      ],
      currencyByAccount: const {},
      preferences: const NotificationPreferences(
        reminder7d: false,
        reminder3d: false,
        reminder1d: false,
        reminderDueDay: false,
        reminderOverdue: false,
        reminderWeeklyReview: false,
      ),
      now: DateTime(2026, 10, 1),
    );
    expect(plan, isEmpty);
  });
}
