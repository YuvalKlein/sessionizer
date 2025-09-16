import 'package:myapp/features/notification/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.status,
    super.userId,
    super.bookingId,
    required super.createdAt,
    super.sentAt,
    super.readAt,
    super.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => NotificationStatus.pending,
      ),
      userId: map['userId'],
      bookingId: map['bookingId'],
      createdAt: DateTime.parse(map['createdAt']),
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'status': status.name,
      'userId': userId,
      'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      status: entity.status,
      userId: entity.userId,
      bookingId: entity.bookingId,
      createdAt: entity.createdAt,
      sentAt: entity.sentAt,
      readAt: entity.readAt,
      data: entity.data,
    );
  }
}














