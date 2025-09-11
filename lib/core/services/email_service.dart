import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/config/app_config.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/core/error/exceptions.dart';

/// Email service interface for sending emails
abstract class EmailService {
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String textContent,
    required String htmlContent,
    String? fromName,
    String? fromEmail,
  });
  
  Future<void> sendBookingConfirmationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });
  
  Future<void> sendBookingReminderEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
    required int hoursBefore,
  });
  
  Future<void> sendBookingCancellationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });
  
  Future<void> sendInstructorCancellationNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });
  
  Future<void> sendInstructorBookingCancellationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });
  
  Future<void> sendClientCancellationNotificationEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });
  
  Future<void> sendScheduleChangeEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String message,
  });
  
  Future<void> sendInstructorBookingNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  });

  Future<void> sendBookingRescheduleEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  });

  Future<void> sendInstructorRescheduleNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  });
}

/// SendGrid implementation of email service
class SendGridEmailService implements EmailService {
  final String _apiKey;
  final String _fromEmail;
  final String _fromName;
  
  SendGridEmailService({
    required String apiKey,
    required String fromEmail,
    required String fromName,
  }) : _apiKey = apiKey,
       _fromEmail = fromEmail,
       _fromName = fromName;
  
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
      AppLogger.info('📧 Sending email to: $to');
      AppLogger.info('📧 Subject: $subject');
      
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };
      
      final body = {
        'personalizations': [
          {
            'to': [
              {'email': to}
            ]
          }
        ],
        'from': {
          'email': fromEmail ?? _fromEmail,
          'name': fromName ?? _fromName,
        },
        'subject': subject,
        'content': [
          {
            'type': 'text/plain',
            'value': textContent,
          },
          {
            'type': 'text/html',
            'value': htmlContent,
          }
        ]
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info('✅ Email sent successfully');
      } else {
        AppLogger.error('❌ Email send failed with status: ${response.statusCode}');
        AppLogger.error('❌ Response body: ${response.body}');
        throw ServerException('Failed to send email: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Detailed email error: $e');
      print('❌ Error type: ${e.runtimeType}');
      AppLogger.error('❌ Error sending email: $e');
      throw ServerException('Failed to send email: $e');
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
    final subject = '🎉 Booking Confirmed - $sessionTitle';
    final textContent = _generateBookingConfirmationText(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    final htmlContent = _generateBookingConfirmationHtml(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    
    await sendEmail(
      to: clientEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
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
    final subject = '⏰ Session Reminder - $sessionTitle (in $hoursBefore hours)';
    final textContent = _generateBookingReminderText(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
      hoursBefore: hoursBefore,
    );
    final htmlContent = _generateBookingReminderHtml(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
      hoursBefore: hoursBefore,
    );
    
    await sendEmail(
      to: clientEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
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
    final subject = '❌ Session Cancelled - $sessionTitle';
    final textContent = _generateBookingCancellationText(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    final htmlContent = _generateBookingCancellationHtml(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    
    await sendEmail(
      to: clientEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
  }
  
  @override
  Future<void> sendScheduleChangeEmail({
    required String clientName,
    required String clientEmail,
    required String instructorName,
    required String message,
  }) async {
    final subject = '📅 Schedule Updated - $instructorName';
    final textContent = _generateScheduleChangeText(
      clientName: clientName,
      instructorName: instructorName,
      message: message,
    );
    final htmlContent = _generateScheduleChangeHtml(
      clientName: clientName,
      instructorName: instructorName,
      message: message,
    );
    
    await sendEmail(
      to: clientEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
  }
  
  // Email template generators
  String _generateBookingConfirmationText({
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
  
  String _generateBookingConfirmationHtml({
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
  
  String _generateBookingReminderText({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
    required int hoursBefore,
  }) {
    return '''
Hi $clientName! ⏰

This is a friendly reminder about your upcoming session.

📅 Session Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId
• Reminder: $hoursBefore hours before

Don't forget to prepare for your session!

Best regards,
The Sessionizer Team

---
This is an automated message. Please do not reply to this email.
''';
  }
  
  String _generateBookingReminderHtml({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
    required int hoursBefore,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Session Reminder</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%); color: #333; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .session-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
        .reminder-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">⏰</span> Session Reminder</h1>
        <p>Hi $clientName! Don't forget about your upcoming session.</p>
    </div>
    
    <div class="content">
        <p>This is a friendly reminder about your upcoming session:</p>
        
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
            <div class="detail-row">
                <div class="detail-label">Reminder:</div>
                <div class="detail-value"><span class="reminder-badge">$hoursBefore hours before</span></div>
            </div>
        </div>
        
        <p>Don't forget to prepare for your session!</p>
        
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
  
  String _generateBookingCancellationText({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) {
    return '''
Hi $clientName,

We're sorry to inform you that your session has been cancelled.

📅 Cancelled Session Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

We apologize for any inconvenience this may cause. If you have any questions or would like to reschedule, please contact us.

Best regards,
The Sessionizer Team

---
This is an automated message. Please do not reply to this email.
''';
  }
  
  String _generateBookingCancellationHtml({
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
    <title>Session Cancelled</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .session-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
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
        <h1><span class="emoji">❌</span> Session Cancelled</h1>
        <p>Hi $clientName, we're sorry to inform you that your session has been cancelled.</p>
    </div>
    
    <div class="content">
        <p>We apologize for any inconvenience this may cause. Here are the details of your cancelled session:</p>
        
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
            <div class="detail-row">
                <div class="detail-label">Status:</div>
                <div class="detail-value"><span class="cancelled-badge">CANCELLED</span></div>
            </div>
        </div>
        
        <p>If you have any questions or would like to reschedule, please contact us.</p>
        
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
  
  String _generateScheduleChangeText({
    required String clientName,
    required String instructorName,
    required String message,
  }) {
    return '''
Hi $clientName,

Your instructor $instructorName has updated their schedule.

📅 Schedule Update:
$message

Please check your upcoming sessions for any changes that might affect your bookings.

Best regards,
The Sessionizer Team

---
This is an automated message. Please do not reply to this email.
''';
  }
  
  String _generateScheduleChangeHtml({
    required String clientName,
    required String instructorName,
    required String message,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schedule Updated</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .message-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-left: 4px solid #4ecdc4; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">📅</span> Schedule Updated</h1>
        <p>Hi $clientName, your instructor has updated their schedule.</p>
    </div>
    
    <div class="content">
        <p>Your instructor <strong>$instructorName</strong> has made changes to their schedule:</p>
        
        <div class="message-box">
            <p>$message</p>
        </div>
        
        <p>Please check your upcoming sessions for any changes that might affect your bookings.</p>
        
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
  
  @override
  Future<void> sendInstructorBookingNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    final subject = '📅 New Booking - $sessionTitle';
    final textContent = _generateInstructorBookingNotificationText(
      instructorName: instructorName,
      clientName: clientName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    final htmlContent = _generateInstructorBookingNotificationHtml(
      instructorName: instructorName,
      clientName: clientName,
      sessionTitle: sessionTitle,
      bookingDateTime: bookingDateTime,
      bookingId: bookingId,
    );
    
    await sendEmail(
      to: instructorEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
  }
  
  String _generateInstructorBookingNotificationText({
    required String instructorName,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) {
    return '''
Hi $instructorName! 📅

You have a new booking for your session.

📅 Booking Details:
• Session: $sessionTitle
• Client: $clientName
• Date & Time: $bookingDateTime
• Booking ID: $bookingId

Please prepare for your upcoming session!

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.
''';
  }
  
  String _generateInstructorBookingNotificationHtml({
    required String instructorName,
    required String clientName,
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
    <title>New Booking Notification</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
        .new-booking-badge { background: #4CAF50; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">📅</span> New Booking!</h1>
        <p>Hi $instructorName! You have a new booking for your session.</p>
    </div>
    
    <div class="content">
        <p>Great news! Someone has booked your session. Here are the details:</p>
        
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
                <div class="detail-value"><span class="new-booking-badge">NEW BOOKING</span></div>
            </div>
        </div>
        
        <p>Please prepare for your upcoming session!</p>
        
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
  Future<void> sendInstructorCancellationNotificationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    AppLogger.info('📧 SENDGRID EMAIL SERVICE - Instructor Cancellation Notification Email:');
    AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
    AppLogger.info('📧 Client: $clientName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: instructorEmail,
      subject: '❌ Booking Cancelled - $sessionTitle',
      htmlContent: _getInstructorCancellationHtml(instructorName, clientName, sessionTitle, bookingDateTime, bookingId),
      textContent: _getInstructorCancellationText(instructorName, clientName, sessionTitle, bookingDateTime, bookingId),
    );
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
    AppLogger.info('📧 SENDGRID EMAIL SERVICE - Instructor Booking Cancellation Email:');
    AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
    AppLogger.info('📧 Client: $clientName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: instructorEmail,
      subject: '❌ Booking Cancelled by You - $sessionTitle',
      htmlContent: _getInstructorBookingCancellationHtml(instructorName, clientName, sessionTitle, bookingDateTime, bookingId),
      textContent: _getInstructorBookingCancellationText(instructorName, clientName, sessionTitle, bookingDateTime, bookingId),
    );
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
    AppLogger.info('📧 SENDGRID EMAIL SERVICE - Client Cancellation Notification Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: clientEmail,
      subject: '❌ Booking Cancelled by Instructor - $sessionTitle',
      htmlContent: _getClientCancellationNotificationHtml(clientName, instructorName, sessionTitle, bookingDateTime, bookingId),
      textContent: _getClientCancellationNotificationText(clientName, instructorName, sessionTitle, bookingDateTime, bookingId),
    );
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
    final subject = '🔄 Booking Rescheduled - $sessionTitle';
    final textContent = _generateBookingRescheduleText(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      oldBookingDateTime: oldBookingDateTime,
      newBookingDateTime: newBookingDateTime,
      bookingId: bookingId,
    );
    final htmlContent = _generateBookingRescheduleHtml(
      clientName: clientName,
      instructorName: instructorName,
      sessionTitle: sessionTitle,
      oldBookingDateTime: oldBookingDateTime,
      newBookingDateTime: newBookingDateTime,
      bookingId: bookingId,
    );
    
    await sendEmail(
      to: clientEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
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
    final subject = '🔄 Booking Rescheduled - $sessionTitle';
    final textContent = _generateInstructorRescheduleNotificationText(
      instructorName: instructorName,
      clientName: clientName,
      sessionTitle: sessionTitle,
      oldBookingDateTime: oldBookingDateTime,
      newBookingDateTime: newBookingDateTime,
      bookingId: bookingId,
    );
    final htmlContent = _generateInstructorRescheduleNotificationHtml(
      instructorName: instructorName,
      clientName: clientName,
      sessionTitle: sessionTitle,
      oldBookingDateTime: oldBookingDateTime,
      newBookingDateTime: newBookingDateTime,
      bookingId: bookingId,
    );
    
    await sendEmail(
      to: instructorEmail,
      subject: subject,
      textContent: textContent,
      htmlContent: htmlContent,
    );
  }

  String _generateBookingRescheduleText({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) {
    return '''
Hi $clientName! 🔄

Your session has been rescheduled successfully.

📅 Session Details:
• Session: $sessionTitle
• Instructor: $instructorName
• Old Date & Time: $oldBookingDateTime
• New Date & Time: $newBookingDateTime
• Booking ID: $bookingId

Please make note of the new time for your session.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.
''';
  }

  String _generateBookingRescheduleHtml({
    required String clientName,
    required String instructorName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) {
    return '''<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Booking Rescheduled</title><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }.header { background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }.content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }.booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }.detail-row { display: flex; margin: 10px 0; }.detail-label { font-weight: bold; width: 120px; color: #666; }.detail-value { flex: 1; }.footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }.emoji { font-size: 24px; }.rescheduled-badge { background: #4ecdc4; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }.time-change { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 8px; margin: 15px 0; }</style></head><body><div class="header"><h1><span class="emoji">🔄</span> Booking Rescheduled</h1><p>Hi $clientName! Your session has been rescheduled successfully.</p></div><div class="content"><p>Your session has been rescheduled. Here are the updated details:</p><div class="booking-details"><div class="detail-row"><div class="detail-label">Session:</div><div class="detail-value">$sessionTitle</div></div><div class="detail-row"><div class="detail-label">Instructor:</div><div class="detail-value">$instructorName</div></div><div class="detail-row"><div class="detail-label">Booking ID:</div><div class="detail-value">$bookingId</div></div><div class="detail-row"><div class="detail-label">Status:</div><div class="detail-value"><span class="rescheduled-badge">RESCHEDULED</span></div></div></div><div class="time-change"><h3>📅 Time Change</h3><p><strong>Old Time:</strong> $oldBookingDateTime</p><p><strong>New Time:</strong> $newBookingDateTime</p></div><p>Please make note of the new time for your session.</p><p>Best regards,<br><strong>The ARENNA Team</strong></p></div><div class="footer"><p>This is an automated message. Please do not reply to this email.</p></div></body></html>''';
  }

  String _generateInstructorRescheduleNotificationText({
    required String instructorName,
    required String clientName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) {
    return '''
Hi $instructorName! 🔄

A booking has been rescheduled by the client.

📅 Booking Details:
• Session: $sessionTitle
• Client: $clientName
• Old Date & Time: $oldBookingDateTime
• New Date & Time: $newBookingDateTime
• Booking ID: $bookingId

The client has rescheduled this booking. Please update your schedule accordingly.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.
''';
  }

  String _generateInstructorRescheduleNotificationHtml({
    required String instructorName,
    required String clientName,
    required String sessionTitle,
    required String oldBookingDateTime,
    required String newBookingDateTime,
    required String bookingId,
  }) {
    return '''<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Booking Rescheduled</title><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }.header { background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }.content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }.booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }.detail-row { display: flex; margin: 10px 0; }.detail-label { font-weight: bold; width: 120px; color: #666; }.detail-value { flex: 1; }.footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }.emoji { font-size: 24px; }.rescheduled-badge { background: #4ecdc4; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }.time-change { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 8px; margin: 15px 0; }</style></head><body><div class="header"><h1><span class="emoji">🔄</span> Booking Rescheduled</h1><p>Hi $instructorName! A booking has been rescheduled by the client.</p></div><div class="content"><p>A booking has been rescheduled by the client:</p><div class="booking-details"><div class="detail-row"><div class="detail-label">Session:</div><div class="detail-value">$sessionTitle</div></div><div class="detail-row"><div class="detail-label">Client:</div><div class="detail-value">$clientName</div></div><div class="detail-row"><div class="detail-label">Booking ID:</div><div class="detail-value">$bookingId</div></div><div class="detail-row"><div class="detail-label">Status:</div><div class="detail-value"><span class="rescheduled-badge">RESCHEDULED</span></div></div></div><div class="time-change"><h3>📅 Time Change</h3><p><strong>Old Time:</strong> $oldBookingDateTime</p><p><strong>New Time:</strong> $newBookingDateTime</p></div><p>The client has rescheduled this booking. Please update your schedule accordingly.</p><p>Best regards,<br><strong>The ARENNA Team</strong></p></div><div class="footer"><p>This is an automated message. Please do not reply to this email.</p></div></body></html>''';
  }
}
