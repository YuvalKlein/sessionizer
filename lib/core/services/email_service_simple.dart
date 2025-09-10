import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/utils/logger.dart';

/// Simple email service that sends emails via a webhook or external service
/// This bypasses Firebase Functions issues
class SimpleEmailService implements EmailService {
  // You can use services like EmailJS, Formspree, or any webhook service
  static const String _webhookUrl = 'https://hooks.zapier.com/hooks/catch/your-webhook-url/';
  
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
      AppLogger.info('📧 SimpleEmailService.sendEmail called');
      AppLogger.info('📧 To: $to');
      AppLogger.info('📧 Subject: $subject');
      
      // For now, just log the email content
      // In production, you would send this to a webhook service
      print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
      print('📧 To: $to');
      print('📧 Subject: $subject');
      print('📧 From: ${fromEmail ?? 'noreply@arenna.link'}');
      print('📧 From Name: ${fromName ?? 'ARENNA'}');
      print('📧 HTML Content Length: ${htmlContent.length} characters');
      print('📧 Text Content Length: ${textContent.length} characters');
      print('📧 HTML Content: $htmlContent');
      print('📧 Text Content: $textContent');
      
      AppLogger.info('✅ SimpleEmailService - Email logged successfully');
    } catch (e) {
      AppLogger.error('❌ Error in SimpleEmailService: $e');
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
      AppLogger.info('📧 SimpleEmailService.sendBookingConfirmationEmail called');
      AppLogger.info('📧 Client: $clientName ($clientEmail)');
      AppLogger.info('📧 Instructor: $instructorName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final htmlContent = _getBookingConfirmationHtml(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      );
      
      final textContent = _getBookingConfirmationText(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      );
      
      await sendEmail(
        to: clientEmail,
        subject: 'Booking Confirmed! 🎉',
        htmlContent: htmlContent,
        textContent: textContent,
        fromName: 'ARENNA',
        fromEmail: 'noreply@arenna.link',
      );
      
      AppLogger.info('✅ Booking confirmation email logged successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending booking confirmation email: $e');
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
      AppLogger.info('📧 SimpleEmailService.sendInstructorBookingNotificationEmail called');
      AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
      AppLogger.info('📧 Client: $clientName');
      AppLogger.info('📧 Session: $sessionTitle');
      AppLogger.info('📧 Date/Time: $bookingDateTime');
      AppLogger.info('📧 Booking ID: $bookingId');
      
      final htmlContent = _getInstructorNotificationHtml(
        instructorName, clientName, sessionTitle, bookingDateTime, bookingId
      );
      
      final textContent = _getInstructorNotificationText(
        instructorName, clientName, sessionTitle, bookingDateTime, bookingId
      );
      
      await sendEmail(
        to: instructorEmail,
        subject: 'New Booking Received! 📅',
        htmlContent: htmlContent,
        textContent: textContent,
        fromName: 'ARENNA',
        fromEmail: 'noreply@arenna.link',
      );
      
      AppLogger.info('✅ Instructor notification email logged successfully');
    } catch (e) {
      AppLogger.error('❌ Error sending instructor notification email: $e');
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
    // Implementation for booking cancellation
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
    // Implementation for booking reminder
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
    // Implementation for schedule change
    await sendEmail(
      to: clientEmail,
      subject: 'Schedule Change Notification',
      htmlContent: _getScheduleChangeHtml(clientName, instructorName, message),
      textContent: _getScheduleChangeText(clientName, instructorName, message),
    );
  }

  // HTML Templates
  String _getBookingConfirmationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #8B5CF6; text-align: center; margin-bottom: 30px;">🎉 Booking Confirmed!</h2>
          <p>Hi <strong>$clientName</strong>,</p>
          <p>Your session has been successfully booked!</p>
          <div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;">
            <p><strong>Instructor:</strong> $instructorName</p>
            <p><strong>Session:</strong> $sessionTitle</p>
            <p><strong>Date & Time:</strong> $bookingDateTime</p>
            <p><strong>Booking ID:</strong> $bookingId</p>
          </div>
          <p>We look forward to seeing you!</p>
          <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
        </div>
      </body>
    </html>
    ''';
  }

  String _getInstructorNotificationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #10B981; text-align: center; margin-bottom: 30px;">📅 New Booking Received!</h2>
          <p>Hi <strong>$instructorName</strong>,</p>
          <p>You have received a new booking!</p>
          <div style="background: #f0fdf4; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #10B981;">
            <p><strong>Client:</strong> $clientName</p>
            <p><strong>Session:</strong> $sessionTitle</p>
            <p><strong>Date & Time:</strong> $bookingDateTime</p>
            <p><strong>Booking ID:</strong> $bookingId</p>
          </div>
          <p>Please prepare for your session!</p>
          <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
        </div>
      </body>
    </html>
    ''';
  }

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

  // Text Templates
  String _getBookingConfirmationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
Booking Confirmed! 🎉

Hi $clientName,

Your session has been successfully booked!

Details:
- Instructor: $instructorName
- Session: $sessionTitle
- Date & Time: $bookingDateTime
- Booking ID: $bookingId

We look forward to seeing you!

ARENNA Team
    ''';
  }

  String _getInstructorNotificationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
New Booking Received! 📅

Hi $instructorName,

You have received a new booking!

Details:
- Client: $clientName
- Session: $sessionTitle
- Date & Time: $bookingDateTime
- Booking ID: $bookingId

Please prepare for your session!

ARENNA Team
    ''';
  }

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
