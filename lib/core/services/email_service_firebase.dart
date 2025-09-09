import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/utils/logger.dart';

/// Firebase Functions email service that calls server-side functions
/// This bypasses CORS issues by using Firebase Functions
class FirebaseEmailService implements EmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String textContent,
    required String htmlContent,
    String? fromName,
    String? fromEmail,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendEmail called');
      AppLogger.info('📧 To: $to');
      AppLogger.info('📧 Subject: $subject');
      
      final callable = _functions.httpsCallable('sendEmail');
      
      final result = await callable.call({
        'to': to,
        'subject': subject,
        'textContent': textContent,
        'htmlContent': htmlContent,
        'fromName': fromName,
        'fromEmail': fromEmail,
      });
      
      AppLogger.info('✅ Email sent successfully via Firebase Function');
      print('✅ Email sent successfully via Firebase Function: ${result.data}');
    } catch (e) {
      AppLogger.error('❌ Error sending email via Firebase Function: $e');
      print('❌ Error sending email via Firebase Function: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  @override
  Future<void> sendBookingConfirmationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendBookingConfirmationEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final callable = _functions.httpsCallable('sendBookingConfirmation');
      
      final result = await callable.call({
        'clientName': clientName,
        'clientEmail': clientEmail,
        'instructorName': instructorName,
        'sessionTitle': sessionTitle,
        'bookingDateTime': bookingDateTime,
        'bookingId': bookingId,
      });
      
      AppLogger.info('✅ Booking confirmation email sent successfully via Firebase Function');
      print('✅ Booking confirmation email sent successfully via Firebase Function: ${result.data}');
    } catch (e) {
      AppLogger.error('❌ Error sending booking confirmation email via Firebase Function: $e');
      print('❌ Error sending booking confirmation email via Firebase Function: $e');
      throw Exception('Failed to send booking confirmation email: $e');
    }
  }

  @override
  Future<void> sendInstructorBookingNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendInstructorBookingNotificationEmail called');
      AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
      AppLogger.info('📧 Client: $clientName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final callable = _functions.httpsCallable('sendInstructorNotification');
      
      final result = await callable.call({
        'instructorName': instructorName,
        'instructorEmail': instructorEmail,
        'clientName': clientName,
        'sessionTitle': sessionTitle,
        'bookingDateTime': bookingDateTime,
        'bookingId': bookingId,
      });
      
      AppLogger.info('✅ Instructor notification email sent successfully via Firebase Function');
      print('✅ Instructor notification email sent successfully via Firebase Function: ${result.data}');
    } catch (e) {
      AppLogger.error('❌ Error sending instructor notification email via Firebase Function: $e');
      print('❌ Error sending instructor notification email via Firebase Function: $e');
      throw Exception('Failed to send instructor notification email: $e');
    }
  }

  @override
  Future<void> sendBookingCancellationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    // For now, use the generic sendEmail method
    await sendEmail(
      to: clientEmail,
      subject: 'Booking Cancelled',
      htmlContent: _getBookingCancellationHtml(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
      textContent: _getBookingCancellationText(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
    );
  }

  @override
  Future<void> sendBookingReminderEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
    required int hoursBefore,
  }) async {
    // For now, use the generic sendEmail method
    await sendEmail(
      to: clientEmail,
      subject: 'Reminder: Your Session Tomorrow',
      htmlContent: _getBookingReminderHtml(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
      textContent: _getBookingReminderText(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
    );
  }

  @override
  Future<void> sendScheduleChangeEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String message,
  }) async {
    // For now, use the generic sendEmail method
    await sendEmail(
      to: clientEmail,
      subject: 'Schedule Change Notification',
      htmlContent: _getScheduleChangeHtml(clientName, instructorName, message),
      textContent: _getScheduleChangeText(clientName, instructorName, message),
    );
  }

  // HTML Templates (simplified for Firebase)
  String _getBookingCancellationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #EF4444; text-align: center; margin-bottom: 30px;">❌ Booking Cancelled</h2>
          <p>Hi <strong>$clientName</strong>,</p>
          <p>Your session has been cancelled.</p>
          <div style="background: #fef2f2; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #EF4444;">
            <p><strong>Instructor:</strong> $instructorName</p>
            <p><strong>Session:</strong> $sessionTitle</p>
            <p><strong>Date & Time:</strong> $bookingDateTime</p>
            <p><strong>Booking ID:</strong> $bookingId</p>
          </div>
          <p>If you have any questions, please contact us.</p>
          <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
        </div>
      </body>
    </html>
    ''';
  }

  String _getBookingReminderHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #F59E0B; text-align: center; margin-bottom: 30px;">⏰ Session Reminder</h2>
          <p>Hi <strong>$clientName</strong>,</p>
          <p>This is a reminder about your upcoming session!</p>
          <div style="background: #fffbeb; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #F59E0B;">
            <p><strong>Instructor:</strong> $instructorName</p>
            <p><strong>Session:</strong> $sessionTitle</p>
            <p><strong>Date & Time:</strong> $bookingDateTime</p>
            <p><strong>Booking ID:</strong> $bookingId</p>
          </div>
          <p>We look forward to seeing you tomorrow!</p>
          <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
        </div>
      </body>
    </html>
    ''';
  }

  String _getScheduleChangeHtml(
    String clientName, String instructorName, String message
  ) {
    return '''
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #F59E0B; text-align: center; margin-bottom: 30px;">📅 Schedule Change</h2>
          <p>Hi <strong>$clientName</strong>,</p>
          <p>There has been a change to your schedule.</p>
          <div style="background: #fffbeb; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #F59E0B;">
            <p><strong>Instructor:</strong> $instructorName</p>
            <p><strong>Message:</strong> $message</p>
          </div>
          <p>Please check your updated schedule.</p>
          <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
        </div>
      </body>
    </html>
    ''';
  }

  // Text Templates (simplified for Firebase)
  String _getBookingCancellationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
Booking Cancelled ❌

Hi $clientName,

Your session has been cancelled.

Details:
- Instructor: $instructorName
- Session: $sessionTitle
- Date & Time: $bookingDateTime
- Booking ID: $bookingId

If you have any questions, please contact us.

ARENNA Team
    ''';
  }

  String _getBookingReminderText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
Session Reminder ⏰

Hi $clientName,

This is a reminder about your upcoming session!

Details:
- Instructor: $instructorName
- Session: $sessionTitle
- Date & Time: $bookingDateTime
- Booking ID: $bookingId

We look forward to seeing you tomorrow!

ARENNA Team
    ''';
  }

  String _getScheduleChangeText(
    String clientName, String instructorName, String message
  ) {
    return '''
Schedule Change 📅

Hi $clientName,

There has been a change to your schedule.

Details:
- Instructor: $instructorName
- Message: $message

Please check your updated schedule.

ARENNA Team
    ''';
  }
}
