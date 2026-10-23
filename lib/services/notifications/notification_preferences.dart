import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final bool reminder7d;
  final bool reminder3d;
  final bool reminder1d;
  final bool reminderDueDay;
  final bool reminderOverdue;
  final bool reminderWeeklyReview;
  final bool browserAlertsEnabled;

  const NotificationPreferences({
    this.reminder7d = true,
    this.reminder3d = true,
    this.reminder1d = true,
    this.reminderDueDay = true,
    this.reminderOverdue = true,
    this.reminderWeeklyReview = true,
    this.browserAlertsEnabled = false,
  });

  NotificationPreferences copyWith({
    bool? reminder7d,
    bool? reminder3d,
    bool? reminder1d,
    bool? reminderDueDay,
    bool? reminderOverdue,
    bool? reminderWeeklyReview,
    bool? browserAlertsEnabled,
  }) {
    return NotificationPreferences(
      reminder7d: reminder7d ?? this.reminder7d,
      reminder3d: reminder3d ?? this.reminder3d,
      reminder1d: reminder1d ?? this.reminder1d,
      reminderDueDay: reminderDueDay ?? this.reminderDueDay,
      reminderOverdue: reminderOverdue ?? this.reminderOverdue,
      reminderWeeklyReview: reminderWeeklyReview ?? this.reminderWeeklyReview,
      browserAlertsEnabled: browserAlertsEnabled ?? this.browserAlertsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reminder7d': reminder7d,
      'reminder3d': reminder3d,
      'reminder1d': reminder1d,
      'reminderDueDay': reminderDueDay,
      'reminderOverdue': reminderOverdue,
      'reminderWeeklyReview': reminderWeeklyReview,
      'browserAlertsEnabled': browserAlertsEnabled,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      reminder7d: map['reminder7d'] as bool? ?? true,
      reminder3d: map['reminder3d'] as bool? ?? true,
      reminder1d: map['reminder1d'] as bool? ?? true,
      reminderDueDay: map['reminderDueDay'] as bool? ?? true,
      reminderOverdue: map['reminderOverdue'] as bool? ?? true,
      reminderWeeklyReview: map['reminderWeeklyReview'] as bool? ?? true,
      browserAlertsEnabled: map['browserAlertsEnabled'] as bool? ?? false,
    );
  }

  static Future<NotificationPreferences> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notif_prefs_$userId');
    if (raw == null || raw.isEmpty) {
      return const NotificationPreferences();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPreferences.fromMap(decoded);
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  static Future<void> save(String userId, NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_prefs_$userId', jsonEncode(preferences.toMap()));
  }

  Future<void> saveForUser(String userId) => NotificationPreferences.save(userId, this);
}
