import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadUnreadNotifications extends NotificationEvent {
  final String userId;

  const LoadUnreadNotifications({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MarkAsRead extends NotificationEvent {
  final String notificationId;

  const MarkAsRead({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class MarkAllAsRead extends NotificationEvent {
  final String userId;

  const MarkAllAsRead({required this.userId});

  @override
  List<Object> get props => [userId];
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class SendBookingConfirmation extends NotificationEvent {
  final String bookingId;

  const SendBookingConfirmation({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class SendBookingReminder extends NotificationEvent {
  final String bookingId;
  final int hoursBefore;

  const SendBookingReminder({
    required this.bookingId,
    required this.hoursBefore,
  });

  @override
  List<Object> get props => [bookingId, hoursBefore];
}

class SendBookingCancellation extends NotificationEvent {
  final String bookingId;

  const SendBookingCancellation({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class SendScheduleChange extends NotificationEvent {
  final String scheduleId;

  const SendScheduleChange({required this.scheduleId});

  @override
  List<Object> get props => [scheduleId];
}

class RefreshNotifications extends NotificationEvent {
  final String userId;

  const RefreshNotifications({required this.userId});

  @override
  List<Object> get props => [userId];
}













