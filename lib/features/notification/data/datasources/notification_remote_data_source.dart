import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/notification/data/models/notification_model.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationRemoteDataSource {
  Future<void> sendNotification(NotificationModel notification);
  Future<void> sendBookingConfirmation(String bookingId);
  Future<void> sendBookingReminder(String bookingId, int hoursBefore);
  Future<void> sendBookingCancellation(String bookingId);
  Future<void> sendScheduleChange(String scheduleId);
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<List<NotificationModel>> getUnreadNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteOldNotifications(int daysOld);
  Future<void> scheduleBookingReminder(String bookingId, DateTime reminderTime);
  Future<void> cancelScheduledNotification(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  NotificationRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firestore = firestore,
        _messaging = messaging;

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      AppLogger.info('📤 Sending notification: ${notification.title}');
      
      // Save to Firestore
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Send push notification if user has FCM token
      if (notification.userId != null) {
        await _sendPushNotification(notification);
      }

      AppLogger.info('✅ Notification sent successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending notification: $e');
      throw ServerException('Failed to send notification: $e');
    }
  }

  @override
  Future<void> sendBookingConfirmation(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final clientId = bookingData['clientId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data()!;
      final clientName = clientData['displayName'] ?? 'Client';

      // Create notification
      final notification = NotificationModel(
        id: 'booking_confirmation_${bookingId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Confirmed! 🎉',
        body: 'Hi $clientName! Your session has been confirmed. We look forward to seeing you!',
        type: NotificationType.bookingConfirmation,
        status: NotificationStatus.pending,
        userId: clientId,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        data: {
          'bookingId': bookingId,
          'action': 'view_booking',
        },
      );

      await sendNotification(notification);
    } catch (e) {
      AppLogger.error('❌ Error sending booking confirmation: $e');
      throw ServerException('Failed to send booking confirmation: $e');
    }
  }

  @override
  Future<void> sendBookingReminder(String bookingId, int hoursBefore) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final clientId = bookingData['clientId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data()!;
      final clientName = clientData['displayName'] ?? 'Client';

      // Create reminder notification
      final notification = NotificationModel(
        id: 'booking_reminder_${bookingId}_${hoursBefore}h_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Session Reminder ⏰',
        body: 'Hi $clientName! Your session is in $hoursBefore hours. Don\'t forget!',
        type: NotificationType.bookingReminder,
        status: NotificationStatus.pending,
        userId: clientId,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        data: {
          'bookingId': bookingId,
          'hoursBefore': hoursBefore,
          'action': 'view_booking',
        },
      );

      await sendNotification(notification);
    } catch (e) {
      AppLogger.error('❌ Error sending booking reminder: $e');
      throw ServerException('Failed to send booking reminder: $e');
    }
  }

  @override
  Future<void> sendBookingCancellation(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final clientId = bookingData['clientId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await _firestore
          .collection('users')
          .doc(clientId)
          .get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data()!;
      final clientName = clientData['displayName'] ?? 'Client';

      // Create cancellation notification
      final notification = NotificationModel(
        id: 'booking_cancellation_${bookingId}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Session Cancelled',
        body: 'Hi $clientName! Your session has been cancelled. We\'re sorry for any inconvenience.',
        type: NotificationType.bookingCancellation,
        status: NotificationStatus.pending,
        userId: clientId,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        data: {
          'bookingId': bookingId,
          'action': 'view_booking',
        },
      );

      await sendNotification(notification);
    } catch (e) {
      AppLogger.error('❌ Error sending booking cancellation: $e');
      throw ServerException('Failed to send booking cancellation: $e');
    }
  }

  @override
  Future<void> sendScheduleChange(String scheduleId) async {
    try {
      // Get schedule details
      final scheduleDoc = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        throw ServerException('Schedule not found');
      }

      final scheduleData = scheduleDoc.data()!;
      final instructorId = scheduleData['instructorId'] as String?;
      
      if (instructorId == null) {
        throw ServerException('Instructor ID not found in schedule');
      }

      // Get all bookings for this schedule
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('instructorId', isEqualTo: instructorId)
          .get();

      // Send notifications to all clients with bookings
      for (final bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final clientId = bookingData['clientId'] as String?;
        
        if (clientId != null) {
          // Get client details
          final clientDoc = await _firestore
              .collection('users')
              .doc(clientId)
              .get();

          if (clientDoc.exists) {
            final clientData = clientDoc.data()!;
            final clientName = clientData['displayName'] ?? 'Client';

            final notification = NotificationModel(
              id: 'schedule_change_${scheduleId}_${clientId}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Schedule Updated',
              body: 'Hi $clientName! Your instructor has updated their schedule. Please check your upcoming sessions.',
              type: NotificationType.scheduleChange,
              status: NotificationStatus.pending,
              userId: clientId,
              createdAt: DateTime.now(),
              data: {
                'scheduleId': scheduleId,
                'action': 'view_schedule',
              },
            );

            await sendNotification(notification);
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error sending schedule change notifications: $e');
      throw ServerException('Failed to send schedule change notifications: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error getting notifications: $e');
      throw ServerException('Failed to get notifications: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error getting unread notifications: $e');
      throw ServerException('Failed to get unread notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': NotificationStatus.read.name,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('❌ Error marking notification as read: $e');
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('❌ Error marking all notifications as read: $e');
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      AppLogger.error('❌ Error deleting notification: $e');
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteOldNotifications(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('❌ Error deleting old notifications: $e');
      throw ServerException('Failed to delete old notifications: $e');
    }
  }

  @override
  Future<void> scheduleBookingReminder(String bookingId, DateTime reminderTime) async {
    // This would typically integrate with a job scheduler
    // For now, we'll just create a scheduled notification record
    try {
      final notification = NotificationModel(
        id: 'scheduled_reminder_${bookingId}_${reminderTime.millisecondsSinceEpoch}',
        title: 'Scheduled Reminder',
        body: 'This is a scheduled reminder for your upcoming session.',
        type: NotificationType.bookingReminder,
        status: NotificationStatus.pending,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        data: {
          'bookingId': bookingId,
          'scheduledFor': reminderTime.toIso8601String(),
          'action': 'view_booking',
        },
      );

      await _firestore
          .collection('scheduled_notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      AppLogger.error('❌ Error scheduling booking reminder: $e');
      throw ServerException('Failed to schedule booking reminder: $e');
    }
  }

  @override
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduled_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      AppLogger.error('❌ Error cancelling scheduled notification: $e');
      throw ServerException('Failed to cancel scheduled notification: $e');
    }
  }

  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore
          .collection('users')
          .doc(notification.userId!)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        AppLogger.warning('No FCM token found for user ${notification.userId}');
        return;
      }

      // Send push notification
      // Note: In a real implementation, you would send this to your backend
      // which would then send the push notification via FCM
      AppLogger.info('📱 Would send push notification to token: $fcmToken');
      AppLogger.info('📱 Title: ${notification.title}');
      AppLogger.info('📱 Body: ${notification.body}');
    } catch (e) {
      AppLogger.error('❌ Error sending push notification: $e');
      // Don't throw here as push notifications are not critical
    }
  }
}
