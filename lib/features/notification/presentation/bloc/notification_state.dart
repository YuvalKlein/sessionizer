import 'package:equatable/equatable.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}

class NotificationOperationSuccess extends NotificationState {
  final String message;

  const NotificationOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class NotificationOperationLoading extends NotificationState {}













