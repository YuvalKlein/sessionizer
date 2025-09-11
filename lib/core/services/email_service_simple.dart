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

  @override
  Future<void> sendInstructorCancellationNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    print('📧 SIMPLE EMAIL SERVICE - Instructor Cancellation Notification Email:');
    print('📧 Instructor: $instructorName ($instructorEmail)');
    print('📧 Client: $clientName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    final subject = '❌ Booking Cancelled - $sessionTitle';
    final textContent = _getInstructorCancellationText(instructorName, clientName, sessionTitle, bookingDateTime, bookingId);
    final htmlContent = _getInstructorCancellationHtml(instructorName, clientName, sessionTitle, bookingDateTime, bookingId);
    
    print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
    print('📧 To: $instructorEmail');
    print('📧 Subject: $subject');
    print('📧 From: noreply@arenna.link');
    print('📧 From Name: ARENNA');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    print('✅ SIMPLE EMAIL SERVICE - Email "sent" successfully');
  }

  String _getInstructorCancellationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''Hi $instructorName,

A booking has been cancelled by the client.

📅 Booking Details:
• Session: $sessionTitle
• Client: $clientName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

The client has cancelled this booking. You may want to check your schedule for any available slots.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.''';
  }

  String _getInstructorCancellationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Booking Cancelled</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .detail-row { display: flex; margin: 10px 0; }
          .detail-label { font-weight: bold; width: 120px; color: #666; }
          .detail-value { flex: 1; }
          .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
          .emoji { font-size: 24px; }
          .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1><span class="emoji">❌</span> Booking Cancelled</h1>
          <p>Hi $instructorName! A client has cancelled their booking.</p>
        </div>
        
        <div class="content">
          <p>A booking has been cancelled by the client:</p>
          
          <div class="booking-details">
            <div class="detail-row">
              <div class="detail-label">Session:</div>
              <div class="detail-value">$sessionTitle</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Client:</div>
              <div class="detail-value">$clientName</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Date & Time:</div>
              <div class="detail-value">$bookingDateTime</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Booking ID:</div>
              <div class="detail-value">$bookingId</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Status:</div>
              <div class="detail-value"><span class="cancelled-badge">Cancelled by Client</span></div>
            </div>
          </div>
          
          <p>The client has cancelled this booking. You may want to check your schedule for any available slots.</p>
          
          <p>Best regards,<br>
          <strong>The ARENNA Team</strong></p>
        </div>
        
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
    </html>
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
    print('📧 SIMPLE EMAIL SERVICE - Instructor Booking Cancellation Email:');
    print('📧 Instructor: $instructorName ($instructorEmail)');
    print('📧 Client: $clientName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    final subject = '❌ Booking Cancelled by You - $sessionTitle';
    final textContent = _getInstructorBookingCancellationText(instructorName, clientName, sessionTitle, bookingDateTime, bookingId);
    final htmlContent = _getInstructorBookingCancellationHtml(instructorName, clientName, sessionTitle, bookingDateTime, bookingId);
    
    print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
    print('📧 To: $instructorEmail');
    print('📧 Subject: $subject');
    print('📧 From: noreply@arenna.link');
    print('📧 From Name: ARENNA');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    print('✅ SIMPLE EMAIL SERVICE - Email "sent" successfully');
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
    print('📧 SIMPLE EMAIL SERVICE - Client Cancellation Notification Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    final subject = '❌ Booking Cancelled by Instructor - $sessionTitle';
    final textContent = _getClientCancellationNotificationText(clientName, instructorName, sessionTitle, bookingDateTime, bookingId);
    final htmlContent = _getClientCancellationNotificationHtml(clientName, instructorName, sessionTitle, bookingDateTime, bookingId);
    
    print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
    print('📧 To: $clientEmail');
    print('📧 Subject: $subject');
    print('📧 From: noreply@arenna.link');
    print('📧 From Name: ARENNA');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    print('✅ SIMPLE EMAIL SERVICE - Email "sent" successfully');
  }

  String _getInstructorBookingCancellationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''Hi $instructorName,

You have cancelled a booking.

📅 Booking Details:
• Session: $sessionTitle
• Client: $clientName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

You have cancelled this booking. The client has been notified.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.''';
  }

  String _getInstructorBookingCancellationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Booking Cancelled by You</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .detail-row { display: flex; margin: 10px 0; }
          .detail-label { font-weight: bold; width: 120px; color: #666; }
          .detail-value { flex: 1; }
          .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
          .emoji { font-size: 24px; }
          .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1><span class="emoji">❌</span> Booking Cancelled by You</h1>
          <p>Hi $instructorName! You have cancelled a booking.</p>
        </div>
        
        <div class="content">
          <p>You have cancelled the following booking:</p>
          
          <div class="booking-details">
            <div class="detail-row">
              <div class="detail-label">Session:</div>
              <div class="detail-value">$sessionTitle</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Client:</div>
              <div class="detail-value">$clientName</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Date & Time:</div>
              <div class="detail-value">$bookingDateTime</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Booking ID:</div>
              <div class="detail-value">$bookingId</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Status:</div>
              <div class="detail-value"><span class="cancelled-badge">Cancelled by You</span></div>
            </div>
          </div>
          
          <p>The client has been notified of the cancellation.</p>
          
          <p>Best regards,<br>
          <strong>The ARENNA Team</strong></p>
        </div>
        
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
    </html>
    ''';
  }

  String _getClientCancellationNotificationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''Hi $clientName,

Your booking has been cancelled by the instructor.

📅 Booking Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

The instructor has cancelled this booking. We apologize for any inconvenience this may cause.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.''';
  }

  String _getClientCancellationNotificationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Booking Cancelled by Instructor</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .detail-row { display: flex; margin: 10px 0; }
          .detail-label { font-weight: bold; width: 120px; color: #666; }
          .detail-value { flex: 1; }
          .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
          .emoji { font-size: 24px; }
          .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1><span class="emoji">❌</span> Booking Cancelled by Instructor</h1>
          <p>Hi $clientName! Your booking has been cancelled.</p>
        </div>
        
        <div class="content">
          <p>Your booking has been cancelled by the instructor:</p>
          
          <div class="booking-details">
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
            <div class="detail-row">
              <div class="detail-label">Status:</div>
              <div class="detail-value"><span class="cancelled-badge">Cancelled by Instructor</span></div>
            </div>
          </div>
          
          <p>We apologize for any inconvenience this may cause.</p>
          
          <p>Best regards,<br>
          <strong>The ARENNA Team</strong></p>
        </div>
        
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
    </html>
    ''';
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
    print('📧 SIMPLE EMAIL SERVICE - Booking Reschedule Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Old Date/Time: $oldBookingDateTime');
    print('📧 New Date/Time: $newBookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    final subject = '🔄 Booking Rescheduled - $sessionTitle';
    final textContent = _getBookingRescheduleText(clientName, instructorName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId);
    final htmlContent = _getBookingRescheduleHtml(clientName, instructorName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId);
    
    print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
    print('📧 To: $clientEmail');
    print('📧 Subject: $subject');
    print('📧 From: noreply@arenna.link');
    print('📧 From Name: ARENNA');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    print('✅ SIMPLE EMAIL SERVICE - Email "sent" successfully');
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
    print('📧 SIMPLE EMAIL SERVICE - Instructor Reschedule Notification Email:');
    print('📧 Instructor: $instructorName ($instructorEmail)');
    print('📧 Client: $clientName');
    print('📧 Session: $sessionTitle');
    print('📧 Old Date/Time: $oldBookingDateTime');
    print('📧 New Date/Time: $newBookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    final subject = '🔄 Booking Rescheduled - $sessionTitle';
    final textContent = _getInstructorRescheduleNotificationText(instructorName, clientName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId);
    final htmlContent = _getInstructorRescheduleNotificationHtml(instructorName, clientName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId);
    
    print('📧 SIMPLE EMAIL SERVICE - Email would be sent:');
    print('📧 To: $instructorEmail');
    print('📧 Subject: $subject');
    print('📧 From: noreply@arenna.link');
    print('📧 From Name: ARENNA');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    print('✅ SIMPLE EMAIL SERVICE - Email "sent" successfully');
  }

  String _getBookingRescheduleText(
    String clientName, String instructorName, String sessionTitle, 
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '''Hi $clientName,

Your booking has been rescheduled.

📅 Booking Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Old Date & Time: $oldBookingDateTime
• New Date & Time: $newBookingDateTime
• Booking ID: $bookingId

Your session has been successfully rescheduled. Please make note of the new time.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.''';
  }

  String _getBookingRescheduleHtml(
    String clientName, String instructorName, String sessionTitle, 
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Booking Rescheduled</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .detail-row { display: flex; margin: 10px 0; }
          .detail-label { font-weight: bold; width: 120px; color: #666; }
          .detail-value { flex: 1; }
          .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
          .emoji { font-size: 24px; }
          .rescheduled-badge { background: #3b82f6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
          .time-change { background: #dbeafe; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #3b82f6; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1><span class="emoji">🔄</span> Booking Rescheduled</h1>
          <p>Hi $clientName! Your booking has been rescheduled.</p>
        </div>
        
        <div class="content">
          <p>Your session has been successfully rescheduled:</p>
          
          <div class="booking-details">
            <div class="detail-row">
              <div class="detail-label">Session:</div>
              <div class="detail-value">$sessionTitle</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Instructor:</div>
              <div class="detail-value">$instructorName</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Booking ID:</div>
              <div class="detail-value">$bookingId</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Status:</div>
              <div class="detail-value"><span class="rescheduled-badge">Rescheduled</span></div>
            </div>
          </div>
          
          <div class="time-change">
            <p><strong>Time Change:</strong></p>
            <p><strong>Old Time:</strong> $oldBookingDateTime</p>
            <p><strong>New Time:</strong> $newBookingDateTime</p>
          </div>
          
          <p>Please make note of the new time for your session.</p>
          
          <p>Best regards,<br>
          <strong>The ARENNA Team</strong></p>
        </div>
        
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
    </html>
    ''';
  }

  String _getInstructorRescheduleNotificationText(
    String instructorName, String clientName, String sessionTitle, 
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '''Hi $instructorName,

A booking has been rescheduled.

📅 Booking Details:
• Session: $sessionTitle
• Client: $clientName
• Old Date & Time: $oldBookingDateTime
• New Date & Time: $newBookingDateTime
• Booking ID: $bookingId

The booking has been rescheduled. Please make note of the new time.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.''';
  }

  String _getInstructorRescheduleNotificationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '''
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Booking Rescheduled</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .detail-row { display: flex; margin: 10px 0; }
          .detail-label { font-weight: bold; width: 120px; color: #666; }
          .detail-value { flex: 1; }
          .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
          .emoji { font-size: 24px; }
          .rescheduled-badge { background: #3b82f6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
          .time-change { background: #dbeafe; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #3b82f6; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1><span class="emoji">🔄</span> Booking Rescheduled</h1>
          <p>Hi $instructorName! A booking has been rescheduled.</p>
        </div>
        
        <div class="content">
          <p>The following booking has been rescheduled:</p>
          
          <div class="booking-details">
            <div class="detail-row">
              <div class="detail-label">Session:</div>
              <div class="detail-value">$sessionTitle</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Client:</div>
              <div class="detail-value">$clientName</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Booking ID:</div>
              <div class="detail-value">$bookingId</div>
            </div>
            <div class="detail-row">
              <div class="detail-label">Status:</div>
              <div class="detail-value"><span class="rescheduled-badge">Rescheduled</span></div>
            </div>
          </div>
          
          <div class="time-change">
            <p><strong>Time Change:</strong></p>
            <p><strong>Old Time:</strong> $oldBookingDateTime</p>
            <p><strong>New Time:</strong> $newBookingDateTime</p>
          </div>
          
          <p>Please make note of the new time for your session.</p>
          
          <p>Best regards,<br>
          <strong>The ARENNA Team</strong></p>
        </div>
        
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
    </html>
    ''';
  }
}
