class AppNotification {
  final String id;
  final String userId;
  final String type; // 'reminder_7d', 'reminder_3d', 'reminder_1d', 'reminder_due', 'overdue', 'weekly_review'
  final String title;
  final String body;
  final String? relatedEntityType; // 'commitment', 'review'
  final String? relatedEntityId;
  final double? amount;
  final DateTime scheduledDate;
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    this.amount,
    required this.scheduledDate,
    this.isRead = false,
    this.isDismissed = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? relatedEntityType,
    String? relatedEntityId,
    double? amount,
    DateTime? scheduledDate,
    bool? isRead,
    bool? isDismissed,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      amount: amount ?? this.amount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'relatedEntityType': relatedEntityType,
      'relatedEntityId': relatedEntityId,
      'amount': amount,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isRead': isRead,
      'isDismissed': isDismissed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      relatedEntityType: map['relatedEntityType'] as String?,
      relatedEntityId: map['relatedEntityId'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      isRead: map['isRead'] as bool? ?? false,
      isDismissed: map['isDismissed'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
