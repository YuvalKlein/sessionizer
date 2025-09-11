import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/features/notification/data/models/notification_model.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';
import 'package:myapp/core/services/email_service.dart';

abstract class NotificationRemoteDataSource {
  Future<void> sendNotification(NotificationModel notification);
  Future<void> sendBookingConfirmation(String bookingId);
  Future<void> sendBookingReminder(String bookingId, int hoursBefore);
  Future<void> sendBookingCancellation(String bookingId);
  Future<void> sendInstructorCancellationNotification(String bookingId);
  Future<void> sendInstructorBookingCancellation(String bookingId);
  Future<void> sendClientCancellationNotification(String bookingId);
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
  final EmailService _emailService;

  NotificationRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    required EmailService emailService,
  })  : _firestore = firestore,
        _messaging = messaging,
        _emailService = emailService;

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
      print('📧 sendBookingConfirmation called with bookingId: $bookingId');
      // Get booking details
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();
      print('📧 Booking document exists: ${bookingDoc.exists}');

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      print('📧 Booking data keys: ${bookingData.keys.toList()}');
      print('📧 Full booking data: $bookingData');
      final clientId = bookingData['clientId'] as String?;
      final instructorId = bookingData['instructorId'] as String?;
      print('📧 Client ID: $clientId');
      print('📧 Instructor ID: $instructorId');
      
      // Debug session and time data
      print('📧 Bookable session ID: ${bookingData['bookableSessionId']}');
      print('📧 Start time: ${bookingData['startTime']}');
      print('📧 End time: ${bookingData['endTime']}');
      print('📧 Date: ${bookingData['date']}');
      
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
      // Always use test email for now - will be replaced with real emails later
      final clientEmail = 'yuklein@gmail.com';
      
      AppLogger.info('📧 Client email: $clientEmail');
      AppLogger.info('📧 Client name: $clientName');

      // Get instructor details
      String instructorName = 'Your Instructor';
      if (instructorId != null) {
        final instructorDoc = await FirestoreCollections.user(instructorId).get();
        
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data()! as Map<String, dynamic>;
          instructorName = instructorData['displayName'] ?? 'Your Instructor';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      print('📧 Getting session details for ID: $bookableSessionId');
      if (bookableSessionId != null) {
        print('📧 Using FirestoreCollections path: ${FirestoreCollections.bookableSession(bookableSessionId).path}');
      }
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()! as Map<String, dynamic>;
          print('📧 Session data: $sessionData');
          sessionTitle = sessionData['title'] ?? 'Your Session';
          print('📧 Session title from document: $sessionTitle');
        } else {
          print('❌ Session document does not exist');
        }
      }

      // Format booking date and time - Handle both Timestamp and String types
      String? startTime;
      String? endTime;
      String? bookingDate;
      
      if (bookingData['startTime'] != null) {
        if (bookingData['startTime'] is Timestamp) {
          startTime = (bookingData['startTime'] as Timestamp).toDate().toIso8601String();
        } else {
          startTime = bookingData['startTime'] as String?;
        }
      }
      
      if (bookingData['endTime'] != null) {
        if (bookingData['endTime'] is Timestamp) {
          endTime = (bookingData['endTime'] as Timestamp).toDate().toIso8601String();
        } else {
          endTime = bookingData['endTime'] as String?;
        }
      }
      
      if (bookingData['date'] != null) {
        if (bookingData['date'] is Timestamp) {
          bookingDate = (bookingData['date'] as Timestamp).toDate().toIso8601String();
        } else {
          bookingDate = bookingData['date'] as String?;
        }
      }
      
      String formattedDateTime = 'TBD';
      if (startTime != null && endTime != null) {
        try {
          final startDateTime = DateTime.parse(startTime);
          final endDateTime = DateTime.parse(endTime);
          
          // Use the date from startTime if bookingDate is null
          final date = bookingDate != null ? DateTime.parse(bookingDate) : startDateTime;
          
          formattedDateTime = '${date.day}/${date.month}/${date.year} at ${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')} - ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
          print('📧 Formatted date/time: $formattedDateTime');
        } catch (e) {
          AppLogger.warning('Error parsing booking date/time: $e');
          print('❌ Error parsing date/time: $e');
        }
      } else {
        print('❌ Missing startTime or endTime for date formatting');
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

      // Send email notification using SendGrid
      print('📧 About to send client email to: $clientEmail');
      print('📧 Client name: $clientName');
      print('📧 Instructor name: $instructorName');
      print('📧 Session title: $sessionTitle');
      print('📧 Booking date/time: $formattedDateTime');
      print('📧 Booking ID: $bookingId');
      
      try {
        await _emailService.sendBookingConfirmationEmail(
          clientName: clientName,
          clientEmail: clientEmail,
          instructorName: instructorName,
          sessionTitle: sessionTitle,
          bookingDateTime: formattedDateTime,
          bookingId: bookingId,
        );
        print('📧 Client email sent successfully');
      } catch (e) {
        print('❌ Error sending client email: $e');
        print('❌ Error type: ${e.runtimeType}');
        rethrow;
      }

      // Send instructor notification email
      print('📧 Checking instructor email - instructorId: $instructorId');
      if (instructorId != null) {
        print('📧 Instructor ID found, getting instructor document...');
        print('📧 Using FirestoreCollections path: ${FirestoreCollections.user(instructorId).path}');
        // Get instructor email
        final instructorDoc = await FirestoreCollections.user(instructorId).get();
        
        print('📧 Instructor document exists: ${instructorDoc.exists}');
        
        // Always use test email for now - will be replaced with real emails later
        final instructorEmail = 'yuklein@gmail.com';
        
        // Get instructor name from document if it exists, otherwise use fallback
        String finalInstructorName = instructorName;
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data()! as Map<String, dynamic>;
          finalInstructorName = instructorData['displayName'] ?? instructorName;
        } else {
          print('⚠️ Instructor document does not exist, using fallback name');
          finalInstructorName = 'Instructor';
        }
        
        AppLogger.info('📧 Instructor email: $instructorEmail');
        AppLogger.info('📧 Instructor name: $finalInstructorName');
        
        print('📧 About to send instructor email to: $instructorEmail');
        try {
          await _emailService.sendInstructorBookingNotificationEmail(
            instructorName: finalInstructorName,
            instructorEmail: instructorEmail,
            clientName: clientName,
            sessionTitle: sessionTitle,
            bookingDateTime: formattedDateTime,
            bookingId: bookingId,
          );
          print('📧 Instructor email sent successfully');
        } catch (e) {
          print('❌ Error sending instructor email: $e');
          print('❌ Error type: ${e.runtimeType}');
        }
      } else {
        print('❌ No instructor ID found in booking data');
      }

    } catch (e) {
      print('❌ Error in sendBookingConfirmation: $e');
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
      // Always use test email for now - will be replaced with real emails later
      final clientEmail = 'yuklein@gmail.com';

      // Get instructor details
      final instructorId = bookingData['instructorId'] as String?;
      String instructorName = 'Your Instructor';
      if (instructorId != null) {
        final instructorDoc = await FirestoreCollections.user(instructorId).get();
        
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data()! as Map<String, dynamic>;
          instructorName = instructorData['displayName'] ?? 'Your Instructor';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      print('📧 Getting session details for ID: $bookableSessionId');
      if (bookableSessionId != null) {
        print('📧 Using FirestoreCollections path: ${FirestoreCollections.bookableSession(bookableSessionId).path}');
      }
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()! as Map<String, dynamic>;
          print('📧 Session data: $sessionData');
          sessionTitle = sessionData['title'] ?? 'Your Session';
          print('📧 Session title from document: $sessionTitle');
        } else {
          print('❌ Session document does not exist');
        }
      }

      // Format booking date and time - Handle both Timestamp and String types
      String? startTime;
      String? endTime;
      String? bookingDate;
      
      if (bookingData['startTime'] != null) {
        if (bookingData['startTime'] is Timestamp) {
          startTime = (bookingData['startTime'] as Timestamp).toDate().toIso8601String();
        } else {
          startTime = bookingData['startTime'] as String?;
        }
      }
      
      if (bookingData['endTime'] != null) {
        if (bookingData['endTime'] is Timestamp) {
          endTime = (bookingData['endTime'] as Timestamp).toDate().toIso8601String();
        } else {
          endTime = bookingData['endTime'] as String?;
        }
      }
      
      if (bookingData['date'] != null) {
        if (bookingData['date'] is Timestamp) {
          bookingDate = (bookingData['date'] as Timestamp).toDate().toIso8601String();
        } else {
          bookingDate = bookingData['date'] as String?;
        }
      }
      
      String formattedDateTime = 'TBD';
      if (startTime != null && endTime != null) {
        try {
          final startDateTime = DateTime.parse(startTime);
          final endDateTime = DateTime.parse(endTime);
          
          // Use the date from startTime if bookingDate is null
          final date = bookingDate != null ? DateTime.parse(bookingDate) : startDateTime;
          
          formattedDateTime = '${date.day}/${date.month}/${date.year} at ${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')} - ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
          print('📧 Formatted date/time: $formattedDateTime');
        } catch (e) {
          AppLogger.warning('Error parsing booking date/time: $e');
          print('❌ Error parsing date/time: $e');
        }
      } else {
        print('❌ Missing startTime or endTime for date formatting');
      }

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

      // Send email reminder using SendGrid
      await _emailService.sendBookingReminderEmail(
        clientName: clientName,
        clientEmail: clientEmail,
        instructorName: instructorName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
        hoursBefore: hoursBefore,
      );
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
      // Always use test email for now - will be replaced with real emails later
      final clientEmail = 'yuklein@gmail.com';

      // Get instructor details
      final instructorId = bookingData['instructorId'] as String?;
      String instructorName = 'Your Instructor';
      if (instructorId != null) {
        final instructorDoc = await FirestoreCollections.user(instructorId).get();
        
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data()! as Map<String, dynamic>;
          instructorName = instructorData['displayName'] ?? 'Your Instructor';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      print('📧 Getting session details for ID: $bookableSessionId');
      if (bookableSessionId != null) {
        print('📧 Using FirestoreCollections path: ${FirestoreCollections.bookableSession(bookableSessionId).path}');
      }
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()! as Map<String, dynamic>;
          print('📧 Session data: $sessionData');
          sessionTitle = sessionData['title'] ?? 'Your Session';
          print('📧 Session title from document: $sessionTitle');
        } else {
          print('❌ Session document does not exist');
        }
      }

      // Format booking date and time - Handle both Timestamp and String types
      String? startTime;
      String? endTime;
      String? bookingDate;
      
      if (bookingData['startTime'] != null) {
        if (bookingData['startTime'] is Timestamp) {
          startTime = (bookingData['startTime'] as Timestamp).toDate().toIso8601String();
        } else {
          startTime = bookingData['startTime'] as String?;
        }
      }
      
      if (bookingData['endTime'] != null) {
        if (bookingData['endTime'] is Timestamp) {
          endTime = (bookingData['endTime'] as Timestamp).toDate().toIso8601String();
        } else {
          endTime = bookingData['endTime'] as String?;
        }
      }
      
      if (bookingData['date'] != null) {
        if (bookingData['date'] is Timestamp) {
          bookingDate = (bookingData['date'] as Timestamp).toDate().toIso8601String();
        } else {
          bookingDate = bookingData['date'] as String?;
        }
      }
      
      String formattedDateTime = 'TBD';
      if (startTime != null && endTime != null) {
        try {
          final startDateTime = DateTime.parse(startTime);
          final endDateTime = DateTime.parse(endTime);
          
          // Use the date from startTime if bookingDate is null
          final date = bookingDate != null ? DateTime.parse(bookingDate) : startDateTime;
          
          formattedDateTime = '${date.day}/${date.month}/${date.year} at ${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')} - ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
          print('📧 Formatted date/time: $formattedDateTime');
        } catch (e) {
          AppLogger.warning('Error parsing booking date/time: $e');
          print('❌ Error parsing date/time: $e');
        }
      } else {
        print('❌ Missing startTime or endTime for date formatting');
      }

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

      // Send email cancellation using SendGrid
      await _emailService.sendBookingCancellationEmail(
        clientName: clientName,
        clientEmail: clientEmail,
        instructorName: instructorName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
      );
    } catch (e) {
      AppLogger.error('❌ Error sending booking cancellation: $e');
      throw ServerException('Failed to send booking cancellation: $e');
    }
  }

  @override
  Future<void> sendInstructorCancellationNotification(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final instructorId = bookingData['instructorId'] as String?;
      
      if (instructorId == null) {
        throw ServerException('Instructor ID not found in booking');
      }

      // Get instructor details
      final instructorDoc = await FirestoreCollections.user(instructorId).get();

      if (!instructorDoc.exists) {
        throw ServerException('Instructor not found');
      }

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final instructorName = instructorData['displayName'] ?? 'Instructor';
      // Always use test email for now - will be replaced with real emails later
      final instructorEmail = 'yuklein@gmail.com';

      // Get client details
      final clientId = bookingData['clientId'] as String?;
      String clientName = 'Client';
      if (clientId != null) {
        final clientDoc = await FirestoreCollections.user(clientId).get();
        if (clientDoc.exists) {
          final clientData = clientDoc.data() as Map<String, dynamic>;
          clientName = clientData['displayName'] ?? 'Client';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          sessionTitle = sessionData['title'] ?? 'Your Session';
        }
      }

      // Format date/time
      final startTime = bookingData['startTime'] as Timestamp?;
      final endTime = bookingData['endTime'] as Timestamp?;
      String formattedDateTime = 'TBD';
      
      if (startTime != null && endTime != null) {
        final start = startTime.toDate();
        final end = endTime.toDate();
        formattedDateTime = '${start.month}/${start.day}/${start.year} at ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      }

      // Send instructor cancellation notification email
      await _emailService.sendInstructorCancellationNotificationEmail(
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        clientName: clientName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
      );

      AppLogger.info('✅ Instructor cancellation notification sent successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending instructor cancellation notification: $e');
      throw ServerException('Failed to send instructor cancellation notification: $e');
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
            // Always use test email for now - will be replaced with real emails later
      final clientEmail = 'yuklein@gmail.com';

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

            // Send email notification using SendGrid
            await _emailService.sendScheduleChangeEmail(
              clientName: clientName,
              clientEmail: clientEmail,
              instructorName: instructorName,
              message: 'Your instructor has updated their schedule. Please check your upcoming sessions for any changes that might affect your bookings.',
            );
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

  @override
  Future<void> sendInstructorBookingCancellation(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await FirestoreCollections.booking(bookingId).get();

      if (!bookingDoc.exists) {
        throw ServerException('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final instructorId = bookingData['instructorId'] as String?;
      
      if (instructorId == null) {
        throw ServerException('Instructor ID not found in booking');
      }

      // Get instructor details
      final instructorDoc = await FirestoreCollections.user(instructorId).get();

      if (!instructorDoc.exists) {
        throw ServerException('Instructor not found');
      }

      final instructorData = instructorDoc.data() as Map<String, dynamic>;
      final instructorName = instructorData['displayName'] ?? 'Instructor';
      // Always use test email for now - will be replaced with real emails later
      final instructorEmail = 'yuklein@gmail.com';

      // Get client details
      final clientId = bookingData['clientId'] as String?;
      String clientName = 'Client';
      if (clientId != null) {
        final clientDoc = await FirestoreCollections.user(clientId).get();
        if (clientDoc.exists) {
          final clientData = clientDoc.data() as Map<String, dynamic>;
          clientName = clientData['displayName'] ?? 'Client';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          sessionTitle = sessionData['title'] ?? 'Your Session';
        }
      }

      // Format date/time
      final startTime = bookingData['startTime'] as Timestamp?;
      final endTime = bookingData['endTime'] as Timestamp?;
      String formattedDateTime = 'TBD';
      
      if (startTime != null && endTime != null) {
        final start = startTime.toDate();
        final end = endTime.toDate();
        formattedDateTime = '${start.month}/${start.day}/${start.year} at ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      }

      // Send instructor cancellation email (when instructor cancels)
      await _emailService.sendInstructorBookingCancellationEmail(
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        clientName: clientName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
      );

      AppLogger.info('✅ Instructor booking cancellation email sent successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending instructor booking cancellation email: $e');
      throw ServerException('Failed to send instructor booking cancellation email: $e');
    }
  }

  @override
  Future<void> sendClientCancellationNotification(String bookingId) async {
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
      // Always use test email for now - will be replaced with real emails later
      final clientEmail = 'yuklein@gmail.com';

      // Get instructor details
      final instructorId = bookingData['instructorId'] as String?;
      String instructorName = 'Instructor';
      if (instructorId != null) {
        final instructorDoc = await FirestoreCollections.user(instructorId).get();
        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data() as Map<String, dynamic>;
          instructorName = instructorData['displayName'] ?? 'Instructor';
        }
      }

      // Get bookable session details
      final bookableSessionId = bookingData['bookableSessionId'] as String?;
      String sessionTitle = 'Your Session';
      if (bookableSessionId != null) {
        final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          sessionTitle = sessionData['title'] ?? 'Your Session';
        }
      }

      // Format date/time
      final startTime = bookingData['startTime'] as Timestamp?;
      final endTime = bookingData['endTime'] as Timestamp?;
      String formattedDateTime = 'TBD';
      
      if (startTime != null && endTime != null) {
        final start = startTime.toDate();
        final end = endTime.toDate();
        formattedDateTime = '${start.month}/${start.day}/${start.year} at ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      }

      // Send client cancellation notification (when instructor cancels)
      await _emailService.sendClientCancellationNotificationEmail(
        clientName: clientName,
        clientEmail: clientEmail,
        instructorName: instructorName,
        sessionTitle: sessionTitle,
        bookingDateTime: formattedDateTime,
        bookingId: bookingId,
      );

      AppLogger.info('✅ Client cancellation notification email sent successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending client cancellation notification email: $e');
      throw ServerException('Failed to send client cancellation notification email: $e');
    }
  }

}
