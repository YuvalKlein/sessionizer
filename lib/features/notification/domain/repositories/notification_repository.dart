import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  // Send notifications
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification);
  Future<Either<Failure, void>> sendBookingConfirmation(String bookingId);
  Future<Either<Failure, void>> sendBookingReminder(String bookingId, int hoursBefore);
  Future<Either<Failure, void>> sendBookingCancellation(String bookingId);
  Future<Either<Failure, void>> sendScheduleChange(String scheduleId);

  // Get notifications
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);
  Future<Either<Failure, List<NotificationEntity>>> getUnreadNotifications(String userId);

  // Update notification status
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, void>> markAllAsRead(String userId);

  // Delete notifications
  Future<Either<Failure, void>> deleteNotification(String notificationId);
  Future<Either<Failure, void>> deleteOldNotifications(int daysOld);

  // Schedule notifications
  Future<Either<Failure, void>> scheduleBookingReminder(String bookingId, DateTime reminderTime);
  Future<Either<Failure, void>> cancelScheduledNotification(String notificationId);
}














