import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/utils/logger.dart';

/// Web-compatible email service that uses a simple HTTP endpoint
/// This bypasses CORS issues by using a different approach
class WebEmailService implements EmailService {
  WebEmailService() {
    print('🚀 WebEmailService constructor called - this should appear in console');
    AppLogger.info('🚀 WebEmailService initialized');
  }
  
  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String textContent,
    required String htmlContent,
    String? fromName,
    String? fromEmail,
  }) async {
    // For now, just log the email content
    // In production, you would implement a backend endpoint
    print('📧 WEB EMAIL SERVICE - Email would be sent:');
    print('📧 To: $to');
    print('📧 Subject: $subject');
    print('📧 From: ${fromEmail ?? 'noreply@arenna.link'}');
    print('📧 From Name: ${fromName ?? 'ARENNA'}');
    print('📧 HTML Content Length: ${htmlContent.length} characters');
    print('📧 Text Content Length: ${textContent.length} characters');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Email would be sent:');
    AppLogger.info('📧 To: $to');
    AppLogger.info('📧 Subject: $subject');
    AppLogger.info('📧 From: ${fromEmail ?? 'noreply@arenna.link'}');
    AppLogger.info('📧 From Name: ${fromName ?? 'ARENNA'}');
    AppLogger.info('📧 HTML Content Length: ${htmlContent.length} characters');
    AppLogger.info('📧 Text Content Length: ${textContent.length} characters');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('✅ WEB EMAIL SERVICE - Email "sent" successfully');
    AppLogger.info('✅ WEB EMAIL SERVICE - Email "sent" successfully');
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
    print('📧 WEB EMAIL SERVICE - Booking Confirmation Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Booking Confirmation Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: clientEmail,
      subject: 'Booking Confirmed! 🎉',
      htmlContent: _getBookingConfirmationHtml(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
      textContent: _getBookingConfirmationText(
        clientName, instructorName, sessionTitle, bookingDateTime, bookingId
      ),
    );
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
    print('📧 WEB EMAIL SERVICE - Instructor Notification Email:');
    print('📧 Instructor: $instructorName ($instructorEmail)');
    print('📧 Client: $clientName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Instructor Notification Email:');
    AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
    AppLogger.info('📧 Client: $clientName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: instructorEmail,
      subject: 'New Booking Received! 📅',
      htmlContent: _getInstructorNotificationHtml(
        instructorName, clientName, sessionTitle, bookingDateTime, bookingId
      ),
      textContent: _getInstructorNotificationText(
        instructorName, clientName, sessionTitle, bookingDateTime, bookingId
      ),
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
    print('📧 WEB EMAIL SERVICE - Booking Cancellation Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Booking Cancellation Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
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
    print('📧 WEB EMAIL SERVICE - Booking Reminder Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Date/Time: $bookingDateTime');
    print('📧 Booking ID: $bookingId');
    print('📧 Hours Before: $hoursBefore');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Booking Reminder Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Date/Time: $bookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    AppLogger.info('📧 Hours Before: $hoursBefore');
    
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
    print('📧 WEB EMAIL SERVICE - Schedule Change Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Message: $message');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Schedule Change Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Message: $message');
    
    await sendEmail(
      to: clientEmail,
      subject: 'Schedule Change Notification',
      htmlContent: _getScheduleChangeHtml(clientName, instructorName, message),
      textContent: _getScheduleChangeText(clientName, instructorName, message),
    );
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
    AppLogger.info('📧 WEB EMAIL SERVICE - Instructor Cancellation Notification Email:');
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

  @override
  Future<void> sendInstructorBookingCancellationEmail({
    required String instructorName,
    required String instructorEmail,
    required String clientName,
    required String sessionTitle,
    required String bookingDateTime,
    required String bookingId,
  }) async {
    AppLogger.info('📧 WEB EMAIL SERVICE - Instructor Booking Cancellation Email:');
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
    AppLogger.info('📧 WEB EMAIL SERVICE - Client Cancellation Notification Email:');
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

  // HTML Templates (simplified for web)
  String _getBookingConfirmationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #8B5CF6; text-align: center; margin-bottom: 30px;">🎉 Booking Confirmed!</h2><p>Hi <strong>$clientName</strong>,</p><p>Your session has been successfully booked!</p><div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;"><p><strong>Instructor:</strong> $instructorName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Date & Time:</strong> $bookingDateTime</p><p><strong>Booking ID:</strong> $bookingId</p></div><p>We look forward to seeing you!</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getInstructorNotificationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #10B981; text-align: center; margin-bottom: 30px;">📅 New Booking Received!</h2><p>Hi <strong>$instructorName</strong>,</p><p>You have received a new booking!</p><div style="background: #f0fdf4; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #10B981;"><p><strong>Client:</strong> $clientName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Date & Time:</strong> $bookingDateTime</p><p><strong>Booking ID:</strong> $bookingId</p></div><p>Please prepare for your session!</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getBookingCancellationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #EF4444; text-align: center; margin-bottom: 30px;">❌ Booking Cancelled</h2><p>Hi <strong>$clientName</strong>,</p><p>Your session has been cancelled.</p><div style="background: #fef2f2; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #EF4444;"><p><strong>Instructor:</strong> $instructorName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Date & Time:</strong> $bookingDateTime</p><p><strong>Booking ID:</strong> $bookingId</p></div><p>If you have any questions, please contact us.</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getBookingReminderHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #F59E0B; text-align: center; margin-bottom: 30px;">⏰ Session Reminder</h2><p>Hi <strong>$clientName</strong>,</p><p>This is a reminder about your upcoming session!</p><div style="background: #fffbeb; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #F59E0B;"><p><strong>Instructor:</strong> $instructorName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Date & Time:</strong> $bookingDateTime</p><p><strong>Booking ID:</strong> $bookingId</p></div><p>We look forward to seeing you tomorrow!</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getScheduleChangeHtml(
    String clientName, String instructorName, String message
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #F59E0B; text-align: center; margin-bottom: 30px;">📅 Schedule Change</h2><p>Hi <strong>$clientName</strong>,</p><p>There has been a change to your schedule.</p><div style="background: #fffbeb; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #F59E0B;"><p><strong>Instructor:</strong> $instructorName</p><p><strong>Message:</strong> $message</p></div><p>Please check your updated schedule.</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getInstructorCancellationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Booking Cancelled</title><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; } .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; } .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; } .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); } .detail-row { display: flex; margin: 10px 0; } .detail-label { font-weight: bold; width: 120px; color: #666; } .detail-value { flex: 1; } .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; } .emoji { font-size: 24px; } .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }</style></head><body><div class="header"><h1><span class="emoji">❌</span> Booking Cancelled</h1><p>Hi $instructorName! A client has cancelled their booking.</p></div><div class="content"><p>A booking has been cancelled by the client:</p><div class="booking-details"><div class="detail-row"><div class="detail-label">Session:</div><div class="detail-value">$sessionTitle</div></div><div class="detail-row"><div class="detail-label">Client:</div><div class="detail-value">$clientName</div></div><div class="detail-row"><div class="detail-label">Date & Time:</div><div class="detail-value">$bookingDateTime</div></div><div class="detail-row"><div class="detail-label">Booking ID:</div><div class="detail-value">$bookingId</div></div><div class="detail-row"><div class="detail-label">Status:</div><div class="detail-value"><span class="cancelled-badge">Cancelled by Client</span></div></div></div><p>The client has cancelled this booking. You may want to check your schedule for any available slots.</p><p>Best regards,<br><strong>The ARENNA Team</strong></p></div><div class="footer"><p>This is an automated message. Please do not reply to this email.</p></div></body></html>';
  }

  String _getInstructorBookingCancellationHtml(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Booking Cancelled by You</title><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; } .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; } .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; } .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); } .detail-row { display: flex; margin: 10px 0; } .detail-label { font-weight: bold; width: 120px; color: #666; } .detail-value { flex: 1; } .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; } .emoji { font-size: 24px; } .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }</style></head><body><div class="header"><h1><span class="emoji">❌</span> Booking Cancelled by You</h1><p>Hi $instructorName! You have cancelled a booking.</p></div><div class="content"><p>You have cancelled the following booking:</p><div class="booking-details"><div class="detail-row"><div class="detail-label">Session:</div><div class="detail-value">$sessionTitle</div></div><div class="detail-row"><div class="detail-label">Client:</div><div class="detail-value">$clientName</div></div><div class="detail-row"><div class="detail-label">Date & Time:</div><div class="detail-value">$bookingDateTime</div></div><div class="detail-row"><div class="detail-label">Booking ID:</div><div class="detail-value">$bookingId</div></div><div class="detail-row"><div class="detail-label">Status:</div><div class="detail-value"><span class="cancelled-badge">Cancelled by You</span></div></div></div><p>The client has been notified of the cancellation.</p><p>Best regards,<br><strong>The ARENNA Team</strong></p></div><div class="footer"><p>This is an automated message. Please do not reply to this email.</p></div></body></html>';
  }

  String _getClientCancellationNotificationHtml(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Booking Cancelled by Instructor</title><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; } .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; } .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; } .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); } .detail-row { display: flex; margin: 10px 0; } .detail-label { font-weight: bold; width: 120px; color: #666; } .detail-value { flex: 1; } .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; } .emoji { font-size: 24px; } .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }</style></head><body><div class="header"><h1><span class="emoji">❌</span> Booking Cancelled by Instructor</h1><p>Hi $clientName! Your booking has been cancelled.</p></div><div class="content"><p>Your booking has been cancelled by the instructor:</p><div class="booking-details"><div class="detail-row"><div class="detail-label">Session:</div><div class="detail-value">$sessionTitle</div></div><div class="detail-row"><div class="detail-label">Instructor:</div><div class="detail-value">$instructorName</div></div><div class="detail-row"><div class="detail-label">Date & Time:</div><div class="detail-value">$bookingDateTime</div></div><div class="detail-row"><div class="detail-label">Booking ID:</div><div class="detail-value">$bookingId</div></div><div class="detail-row"><div class="detail-label">Status:</div><div class="detail-value"><span class="cancelled-badge">Cancelled by Instructor</span></div></div></div><p>We apologize for any inconvenience this may cause.</p><p>Best regards,<br><strong>The ARENNA Team</strong></p></div><div class="footer"><p>This is an automated message. Please do not reply to this email.</p></div></body></html>';
  }

  // Text Templates (simplified for web)
  String _getBookingConfirmationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Booking Confirmed! 🎉\n\nHi $clientName,\n\nYour session has been successfully booked!\n\nDetails:\n- Instructor: $instructorName\n- Session: $sessionTitle\n- Date & Time: $bookingDateTime\n- Booking ID: $bookingId\n\nWe look forward to seeing you!\n\nARENNA Team';
  }

  String _getInstructorNotificationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'New Booking Received! 📅\n\nHi $instructorName,\n\nYou have received a new booking!\n\nDetails:\n- Client: $clientName\n- Session: $sessionTitle\n- Date & Time: $bookingDateTime\n- Booking ID: $bookingId\n\nPlease prepare for your session!\n\nARENNA Team';
  }

  String _getBookingCancellationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Booking Cancelled ❌\n\nHi $clientName,\n\nYour session has been cancelled.\n\nDetails:\n- Instructor: $instructorName\n- Session: $sessionTitle\n- Date & Time: $bookingDateTime\n- Booking ID: $bookingId\n\nIf you have any questions, please contact us.\n\nARENNA Team';
  }

  String _getBookingReminderText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Session Reminder ⏰\n\nHi $clientName,\n\nThis is a reminder about your upcoming session!\n\nDetails:\n- Instructor: $instructorName\n- Session: $sessionTitle\n- Date & Time: $bookingDateTime\n- Booking ID: $bookingId\n\nWe look forward to seeing you tomorrow!\n\nARENNA Team';
  }

  String _getScheduleChangeText(
    String clientName, String instructorName, String message
  ) {
    return 'Schedule Change 📅\n\nHi $clientName,\n\nThere has been a change to your schedule.\n\nDetails:\n- Instructor: $instructorName\n- Message: $message\n\nPlease check your updated schedule.\n\nARENNA Team';
  }

  String _getInstructorCancellationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Hi $instructorName,\n\nA booking has been cancelled by the client.\n\n📅 Booking Details:\n• Session: $sessionTitle\n• Client: $clientName\n• Date & Time: $bookingDateTime\n• Booking ID: $bookingId\n\nThe client has cancelled this booking. You may want to check your schedule for any available slots.\n\nBest regards,\nThe ARENNA Team\n\n---\nThis is an automated message. Please do not reply to this email.';
  }

  String _getInstructorBookingCancellationText(
    String instructorName, String clientName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Hi $instructorName,\n\nYou have cancelled a booking.\n\n📅 Booking Details:\n• Session: $sessionTitle\n• Client: $clientName\n• Date & Time: $bookingDateTime\n• Booking ID: $bookingId\n\nYou have cancelled this booking. The client has been notified.\n\nBest regards,\nThe ARENNA Team\n\n---\nThis is an automated message. Please do not reply to this email.';
  }

  String _getClientCancellationNotificationText(
    String clientName, String instructorName, String sessionTitle, 
    String bookingDateTime, String bookingId
  ) {
    return 'Hi $clientName,\n\nYour booking has been cancelled by the instructor.\n\n📅 Booking Details:\n• Session: $sessionTitle\n• Instructor: $instructorName\n• Date & Time: $bookingDateTime\n• Booking ID: $bookingId\n\nThe instructor has cancelled this booking. We apologize for any inconvenience this may cause.\n\nBest regards,\nThe ARENNA Team\n\n---\nThis is an automated message. Please do not reply to this email.';
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
    print('📧 WEB EMAIL SERVICE - Booking Reschedule Email:');
    print('📧 Client: $clientName ($clientEmail)');
    print('📧 Instructor: $instructorName');
    print('📧 Session: $sessionTitle');
    print('📧 Old Date/Time: $oldBookingDateTime');
    print('📧 New Date/Time: $newBookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Booking Reschedule Email:');
    AppLogger.info('📧 Client: $clientName ($clientEmail)');
    AppLogger.info('📧 Instructor: $instructorName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Old Date/Time: $oldBookingDateTime');
    AppLogger.info('📧 New Date/Time: $newBookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: clientEmail,
      subject: '🔄 Booking Rescheduled - $sessionTitle',
      htmlContent: _getBookingRescheduleHtml(
        clientName, instructorName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId
      ),
      textContent: _getBookingRescheduleText(
        clientName, instructorName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId
      ),
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
    print('📧 WEB EMAIL SERVICE - Instructor Reschedule Notification Email:');
    print('📧 Instructor: $instructorName ($instructorEmail)');
    print('📧 Client: $clientName');
    print('📧 Session: $sessionTitle');
    print('📧 Old Date/Time: $oldBookingDateTime');
    print('📧 New Date/Time: $newBookingDateTime');
    print('📧 Booking ID: $bookingId');
    
    AppLogger.info('📧 WEB EMAIL SERVICE - Instructor Reschedule Notification Email:');
    AppLogger.info('📧 Instructor: $instructorName ($instructorEmail)');
    AppLogger.info('📧 Client: $clientName');
    AppLogger.info('📧 Session: $sessionTitle');
    AppLogger.info('📧 Old Date/Time: $oldBookingDateTime');
    AppLogger.info('📧 New Date/Time: $newBookingDateTime');
    AppLogger.info('📧 Booking ID: $bookingId');
    
    await sendEmail(
      to: instructorEmail,
      subject: '🔄 Booking Rescheduled - $sessionTitle',
      htmlContent: _getInstructorRescheduleNotificationHtml(
        instructorName, clientName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId
      ),
      textContent: _getInstructorRescheduleNotificationText(
        instructorName, clientName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId
      ),
    );
  }

  String _getBookingRescheduleHtml(
    String clientName, String instructorName, String sessionTitle,
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #4ecdc4; text-align: center; margin-bottom: 30px;">🔄 Booking Rescheduled</h2><p>Hi <strong>$clientName</strong>,</p><p>Your session has been rescheduled successfully!</p><div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;"><p><strong>Instructor:</strong> $instructorName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Booking ID:</strong> $bookingId</p></div><div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 8px; margin: 15px 0;"><h3 style="margin-top: 0; color: #856404;">📅 Time Change</h3><p><strong>Old Time:</strong> $oldBookingDateTime</p><p><strong>New Time:</strong> $newBookingDateTime</p></div><p>Please make note of the new time for your session.</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getBookingRescheduleText(
    String clientName, String instructorName, String sessionTitle,
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return 'Booking Rescheduled! 🔄\n\nHi $clientName,\n\nYour session has been rescheduled successfully!\n\nDetails:\n- Instructor: $instructorName\n- Session: $sessionTitle\n- Booking ID: $bookingId\n\nTime Change:\n- Old Time: $oldBookingDateTime\n- New Time: $newBookingDateTime\n\nPlease make note of the new time for your session.\n\nARENNA Team';
  }

  String _getInstructorRescheduleNotificationHtml(
    String instructorName, String clientName, String sessionTitle,
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return '<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;"><div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><h2 style="color: #4ecdc4; text-align: center; margin-bottom: 30px;">🔄 Booking Rescheduled</h2><p>Hi <strong>$instructorName</strong>,</p><p>A booking has been rescheduled by the client.</p><div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;"><p><strong>Client:</strong> $clientName</p><p><strong>Session:</strong> $sessionTitle</p><p><strong>Booking ID:</strong> $bookingId</p></div><div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 8px; margin: 15px 0;"><h3 style="margin-top: 0; color: #856404;">📅 Time Change</h3><p><strong>Old Time:</strong> $oldBookingDateTime</p><p><strong>New Time:</strong> $newBookingDateTime</p></div><p>The client has rescheduled this booking. Please update your schedule accordingly.</p><p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p></div></body></html>';
  }

  String _getInstructorRescheduleNotificationText(
    String instructorName, String clientName, String sessionTitle,
    String oldBookingDateTime, String newBookingDateTime, String bookingId
  ) {
    return 'Booking Rescheduled! 🔄\n\nHi $instructorName,\n\nA booking has been rescheduled by the client.\n\nDetails:\n- Client: $clientName\n- Session: $sessionTitle\n- Booking ID: $bookingId\n\nTime Change:\n- Old Time: $oldBookingDateTime\n- New Time: $newBookingDateTime\n\nThe client has rescheduled this booking. Please update your schedule accordingly.\n\nARENNA Team';
  }
}