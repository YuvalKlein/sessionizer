import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/utils/logger.dart';

/// Firebase Functions email service that calls server-side functions via HTTP
/// This bypasses CORS issues by using Firebase Functions
class FirebaseEmailService implements EmailService {
  static const String _baseUrl = 'https://us-central1-apiclientapp.cloudfunctions.net';

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
      
      final url = Uri.parse('$_baseUrl/sendEmail');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'textContent': textContent,
          'htmlContent': htmlContent,
          'fromName': fromName,
          'fromEmail': fromEmail,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Email sent successfully via Firebase Function');
        print('✅ Email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
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
      
      final url = Uri.parse('$_baseUrl/sendBookingConfirmation');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Booking confirmation email sent successfully via Firebase Function');
        print('✅ Booking confirmation email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
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
      
      final url = Uri.parse('$_baseUrl/sendInstructorBookingNotification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instructorName': instructorName,
          'instructorEmail': instructorEmail,
          'clientName': clientName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Instructor notification email sent successfully via Firebase Function');
        print('✅ Instructor notification email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
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
    try {
      AppLogger.info('📧 FirebaseEmailService.sendBookingCancellationEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendBookingCancellation');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Booking cancellation email sent successfully via Firebase Function');
        print('✅ Booking cancellation email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending booking cancellation email via Firebase Function: $e');
      print('❌ Error sending booking cancellation email via Firebase Function: $e');
      throw Exception('Failed to send booking cancellation email: $e');
    }
  }

  @override
  Future<void> sendInstructorCancellationNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendInstructorCancellationNotificationEmail called');
      AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
      AppLogger.info('📧 Client: $clientName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendInstructorCancellationNotification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instructorName': instructorName,
          'instructorEmail': instructorEmail,
          'clientName': clientName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Instructor cancellation notification email sent successfully via Firebase Function');
        print('✅ Instructor cancellation notification email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending instructor cancellation notification email via Firebase Function: $e');
      print('❌ Error sending instructor cancellation notification email via Firebase Function: $e');
      throw Exception('Failed to send instructor cancellation notification email: $e');
    }
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
    try {
      AppLogger.info('📧 FirebaseEmailService.sendBookingReminderEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      AppLogger.info('📧 Hours Before: $hoursBefore');
      
      final url = Uri.parse('$_baseUrl/sendBookingReminder');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
          'hoursBefore': hoursBefore,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Booking reminder email sent successfully via Firebase Function');
        print('✅ Booking reminder email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending booking reminder email via Firebase Function: $e');
      print('❌ Error sending booking reminder email via Firebase Function: $e');
      throw Exception('Failed to send booking reminder email: $e');
    }
  }

  @override
  Future<void> sendScheduleChangeEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String message,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendScheduleChangeEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Message: $message');
      
      final url = Uri.parse('$_baseUrl/sendScheduleChange');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'message': message,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Schedule change email sent successfully via Firebase Function');
        print('✅ Schedule change email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending schedule change email via Firebase Function: $e');
      print('❌ Error sending schedule change email via Firebase Function: $e');
      throw Exception('Failed to send schedule change email: $e');
    }
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

  @override
  Future<void> sendInstructorBookingCancellationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendInstructorBookingCancellationEmail called');
      AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
      AppLogger.info('📧 Client: $clientName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendInstructorBookingCancellation');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instructorName': instructorName,
          'instructorEmail': instructorEmail,
          'clientName': clientName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Instructor booking cancellation email sent successfully via Firebase Function');
        print('✅ Instructor booking cancellation email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending instructor booking cancellation email via Firebase Function: $e');
      print('❌ Error sending instructor booking cancellation email via Firebase Function: $e');
      throw Exception('Failed to send instructor booking cancellation email: $e');
    }
  }

  @override
  Future<void> sendClientCancellationNotificationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendClientCancellationNotificationEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendClientCancellationNotification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'sessionTitle': sessionTitle,
          'bookingDateTime': bookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Client cancellation notification email sent successfully via Firebase Function');
        print('✅ Client cancellation notification email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending client cancellation notification email via Firebase Function: $e');
      print('❌ Error sending client cancellation notification email via Firebase Function: $e');
      throw Exception('Failed to send client cancellation notification email: $e');
    }
  }

  @override
  Future<void> sendBookingRescheduleEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendBookingRescheduleEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Old Date/Time: $oldBookingDateTime');
      AppLogger.info('📧 New Date/Time: $newBookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendBookingReschedule');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'instructorName': instructorName,
          'sessionTitle': sessionTitle,
          'oldBookingDateTime': oldBookingDateTime,
          'newBookingDateTime': newBookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Booking reschedule email sent successfully via Firebase Function');
        print('✅ Booking reschedule email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending booking reschedule email via Firebase Function: $e');
      print('❌ Error sending booking reschedule email via Firebase Function: $e');
      throw Exception('Failed to send booking reschedule email: $e');
    }
  }

  @override
  Future<void> sendInstructorRescheduleNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) async {
    try {
      AppLogger.info('📧 FirebaseEmailService.sendInstructorRescheduleNotificationEmail called');
      AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
      AppLogger.info('📧 Client: $clientName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Old Date/Time: $oldBookingDateTime');
      AppLogger.info('📧 New Date/Time: $newBookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final url = Uri.parse('$_baseUrl/sendInstructorRescheduleNotification');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instructorName': instructorName,
          'instructorEmail': instructorEmail,
          'clientName': clientName,
          'sessionTitle': sessionTitle,
          'oldBookingDateTime': oldBookingDateTime,
          'newBookingDateTime': newBookingDateTime,
          'bookingId': bookingId,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Instructor reschedule notification email sent successfully via Firebase Function');
        print('✅ Instructor reschedule notification email sent successfully via Firebase Function: ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending instructor reschedule notification email via Firebase Function: $e');
      print('❌ Error sending instructor reschedule notification email via Firebase Function: $e');
      throw Exception('Failed to send instructor reschedule notification email: $e');
    }
  }
}
