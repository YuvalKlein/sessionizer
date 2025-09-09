import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/core/config/firestore_collections.dart';
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
      await FirestoreCollections.notification(notification.id).set(notification.toMap());

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
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final clientId = bookingData['clientId'] as String?;
      final instructorId = bookingData['instructorId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await FirestoreCollections.user(clientId).get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data() as Map<String, dynamic>;
      final clientName = clientData['displayName'] ?? 'Client';
      final clientEmail = clientData['email'] as String? ?? 'yuklein@gmail.com'; // Default to test email

      // Get instructor details
      String instructorName = 'Your Instructor';
      if (instructorId != null) {
        final instructorDoc = await _firestore
            .collection('users')
            .doc(instructorId)
            .get();
        
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data()!;
          instructorName = instructorData['displayName'] ?? 'Your Instructor';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await _firestore
            .collection('bookable_sessions')
            .doc(bookableSessionId)
            .get();
        
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()!;
          sessionTitle = sessionData['title'] ?? 'Your Session';
        }
      }

      // Format booking date and time
      final startTime = bookingData['startTime'] as String?;
      final endTime = bookingData['endTime'] as String?;
      final bookingDate = bookingData['date'] as String?;
      
      String formattedDateTime = 'TBD';
      if (startTime != null && endTime != null && bookingDate != null) {
        try {
          final startDateTime = DateTime.parse(startTime);
          final endDateTime = DateTime.parse(endTime);
          final date = DateTime.parse(bookingDate);
          
          formattedDateTime = '${date.day}/${date.month}/${date.year} at ${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')} - ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          AppLogger.warning('Error parsing booking date/time: $e');
        }
      }

      // Create in-app notification
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

      // Send email notification using Firebase Trigger Email extension
      await _sendBookingConfirmationEmail(
        clientName: clientName,
        clientEmail: clientEmail,
        instructorName: instructorName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
      );

    } catch (e) {
      AppLogger.error('❌ Error sending booking confirmation: $e');
      throw ServerException('Failed to send booking confirmation: $e');
    }
  }

  @override
  Future<void> sendBookingReminder(String bookingId, int hoursBefore) async {
    try {
      // Get booking details
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final clientId = bookingData['clientId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await FirestoreCollections.user(clientId).get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data() as Map<String, dynamic>;
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
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final clientId = bookingData['clientId'] as String?;
      
      if (clientId == null) {
        throw ServerException('Client ID not found in booking');
      }

      // Get client details
      final clientDoc = await FirestoreCollections.user(clientId).get();

      if (!clientDoc.exists) {
        throw ServerException('Client not found');
      }

      final clientData = clientDoc.data() as Map<String, dynamic>;
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
      final scheduleDoc = await FirestoreCollections.schedule(scheduleId).get();

      if (!scheduleDoc.exists) {
        throw ServerException('Schedule not found');
      }

      final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      final instructorId = scheduleData['instructorId'] as String?;
      
      if (instructorId == null) {
        throw ServerException('Instructor ID not found in schedule');
      }

      // Get all bookings for this schedule
      final bookingsSnapshot = await FirestoreCollections.bookings
          .where('instructorId', isEqualTo: instructorId)
          .get();

      // Send notifications to all clients with bookings
      for (final bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final clientId = bookingData['clientId'] as String?;
        
        if (clientId != null) {
          // Get client details
          final clientDoc = await FirestoreCollections.user(clientId).get();

          if (clientDoc.exists) {
            final clientData = clientDoc.data() as Map<String, dynamic>;
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
      final snapshot = await FirestoreCollections.notifications
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error getting notifications: $e');
      throw ServerException('Failed to get notifications: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final snapshot = await FirestoreCollections.notifications
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error getting unread notifications: $e');
      throw ServerException('Failed to get unread notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirestoreCollections.notification(notificationId).update({
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
      final snapshot = await FirestoreCollections.notifications
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
      await FirestoreCollections.notification(notificationId).delete();
    } catch (e) {
      AppLogger.error('❌ Error deleting notification: $e');
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteOldNotifications(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await FirestoreCollections.notifications
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

      await FirestoreCollections.scheduledNotification(notification.id).set(notification.toMap());
    } catch (e) {
      AppLogger.error('❌ Error scheduling booking reminder: $e');
      throw ServerException('Failed to schedule booking reminder: $e');
    }
  }

  @override
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await FirestoreCollections.scheduledNotification(notificationId).delete();
    } catch (e) {
      AppLogger.error('❌ Error cancelling scheduled notification: $e');
      throw ServerException('Failed to cancel scheduled notification: $e');
    }
  }

  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      // Get user's FCM token
      final userDoc = await FirestoreCollections.user(notification.userId!).get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
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

  /// Send booking confirmation email using Firebase Trigger Email extension
  Future<void> _sendBookingConfirmationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 Sending booking confirmation email to: $clientEmail');
      
      // Create email document for Firebase Trigger Email extension
      final emailDoc = {
        'to': [clientEmail], // For testing, this will be yuklein@gmail.com
        'message': {
          'subject': '🎉 Booking Confirmed - $sessionTitle',
          'text': _generateEmailText(
            clientName: clientName,
            instructorName: instructorName,
            sessionTitle: sessionTitle,
            bookingDateTime: bookingDateTime,
            bookingId: bookingId,
          ),
          'html': _generateEmailHtml(
            clientName: clientName,
            instructorName: instructorName,
            sessionTitle: sessionTitle,
            bookingDateTime: bookingDateTime,
            bookingId: bookingId,
          ),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'booking_confirmation',
        'bookingId': bookingId,
      };

      // Add document to 'mail' collection to trigger email
      await _firestore
          .collection('mail')
          .add(emailDoc);

      AppLogger.info('✅ Booking confirmation email queued successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending booking confirmation email: $e');
      // Don't throw here as email is not critical for the booking process
    }
  }

  /// Generate plain text email content
  String _generateEmailText({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) {
    return '''
Hi $clientName! 🎉

Your session has been confirmed! We're excited to see you.

📅 Session Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

We look forward to seeing you soon!

Best regards,
The Sessionizer Team

---
This is an automated message. Please do not reply to this email.
''';
  }

  /// Generate HTML email content
  String _generateEmailHtml({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .session-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">🎉</span> Booking Confirmed!</h1>
        <p>Hi $clientName! Your session has been confirmed.</p>
    </div>
    
    <div class="content">
        <p>We're excited to see you! Here are your session details:</p>
        
        <div class="session-details">
            <div class="detail-row">
                <div class="detail-label">Session:</div>
                <div class="detail-value">$sessionTitle</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Instructor:</div>
                <div class="detail-value">$instructorName</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Date & Time:</div>
                <div class="detail-value">$bookingDateTime</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Booking ID:</div>
                <div class="detail-value">$bookingId</div>
            </div>
        </div>
        
        <p>We look forward to seeing you soon!</p>
        
        <p>Best regards,<br>
        <strong>The Sessionizer Team</strong></p>
    </div>
    
    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>
''';
  }
}
