import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/notification/domain/usecases/get_notifications.dart';
import 'package:myapp/features/notification/domain/usecases/mark_notification_as_read.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart' as usecase;
import 'package:myapp/features/notification/domain/usecases/send_booking_reminder.dart' as usecase;
import 'package:myapp/features/notification/domain/repositories/notification_repository.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_event.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications _getNotifications;
  final MarkNotificationAsRead _markAsRead;
  final usecase.SendBookingConfirmation _sendBookingConfirmation;
  final usecase.SendBookingReminder _sendBookingReminder;
  final NotificationRepository _repository;

  NotificationBloc({
    required GetNotifications getNotifications,
    required MarkNotificationAsRead markAsRead,
    required usecase.SendBookingConfirmation sendBookingConfirmation,
    required usecase.SendBookingReminder sendBookingReminder,
    required NotificationRepository repository,
  })  : _getNotifications = getNotifications,
        _markAsRead = markAsRead,
        _sendBookingConfirmation = sendBookingConfirmation,
        _sendBookingReminder = sendBookingReminder,
        _repository = repository,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadNotifications>(_onLoadUnreadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<SendBookingConfirmation>(_onSendBookingConfirmation);
    on<SendBookingReminder>(_onSendBookingReminder);
    on<SendBookingCancellation>(_onSendBookingCancellation);
    on<SendScheduleChange>(_onSendScheduleChange);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    final result = await _getNotifications(event.userId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        final unreadCount = notifications
            .where((n) => n.status == NotificationStatus.pending)
            .length;
        emit(NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      },
    );
  }

  Future<void> _onLoadUnreadNotifications(
    LoadUnreadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    final result = await _repository.getUnreadNotifications(event.userId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) {
        emit(NotificationLoaded(
          notifications: notifications,
          unreadCount: notifications.length,
        ));
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _markAsRead(event.notificationId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Marked as read')),
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _repository.markAllAsRead(event.userId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'All marked as read')),
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _repository.deleteNotification(event.notificationId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Notification deleted')),
    );
  }

  Future<void> _onSendBookingConfirmation(
    SendBookingConfirmation event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _sendBookingConfirmation(event.bookingId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Booking confirmation sent')),
    );
  }

  Future<void> _onSendBookingReminder(
    SendBookingReminder event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _sendBookingReminder.call(
      bookingId: event.bookingId,
      hoursBefore: event.hoursBefore,
    );
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Booking reminder sent')),
    );
  }

  Future<void> _onSendBookingCancellation(
    SendBookingCancellation event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _repository.sendBookingCancellation(event.bookingId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Booking cancellation sent')),
    );
  }

  Future<void> _onSendScheduleChange(
    SendScheduleChange event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationOperationLoading());

    final result = await _repository.sendScheduleChange(event.scheduleId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (_) => emit(const NotificationOperationSuccess(message: 'Schedule change notifications sent')),
    );
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    add(LoadNotifications(userId: event.userId));
  }
}
