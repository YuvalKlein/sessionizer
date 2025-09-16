import 'package:equatable/equatable.dart';

enum NotificationType {
  bookingConfirmation,
  bookingReminder,
  bookingCancellation,
  scheduleChange,
  general,
}

enum NotificationStatus {
  pending,
  sent,
  failed,
  read,
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationStatus status;
  final String? userId;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    this.userId,
    this.bookingId,
    required this.createdAt,
    this.sentAt,
    this.readAt,
    this.data,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        status,
        userId,
        bookingId,
        createdAt,
        sentAt,
        readAt,
        data,
      ];

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationStatus? status,
    String? userId,
    String? bookingId,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}














