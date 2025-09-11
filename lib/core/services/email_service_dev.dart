import 'package:myapp/core/services/email_service.dart';

class DevEmailService implements EmailService {
  @override
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String textContent,
    required String htmlContent,
    String? fromName,
    String? fromEmail,
  }) async {
    print('📧 [DEV] Email');
    print('To: $to');
    print('Subject: $subject');
    print('From: ${fromEmail ?? 'noreply@arenna.com'} (${fromName ?? 'ARENNA'})');
    print('Text: $textContent');
    print('HTML: $htmlContent');
    print('---');
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
    print('📧 [DEV] Booking Confirmation Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
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
    print('📧 [DEV] Booking Reminder Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('Hours Before: $hoursBefore');
    print('---');
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
    print('📧 [DEV] Booking Cancellation Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
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
    print('📧 [DEV] Instructor Cancellation Notification Email');
    print('To Instructor: $instructorEmail');
    print('Instructor: $instructorName');
    print('Client: $clientName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
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
    print('📧 [DEV] Instructor Booking Cancellation Email');
    print('To Instructor: $instructorEmail');
    print('Instructor: $instructorName');
    print('Client: $clientName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
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
    print('📧 [DEV] Client Cancellation Notification Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
  }

  @override
  Future<void> sendScheduleChangeEmail({
    required String clientEmail,
    required String clientName,
    required String instructorName,
    required String message,
  }) async {
    print('📧 [DEV] Schedule Change Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Message: $message');
    print('---');
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
    print('📧 [DEV] Instructor Booking Notification Email');
    print('To Instructor: $instructorEmail');
    print('Instructor: $instructorName');
    print('Client: $clientName');
    print('Session: $sessionTitle');
    print('Date & Time: $bookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
  }

  @override
  Future<void> sendBookingRescheduleEmail({
    required String bookingId,
    required String clientEmail,
    required String clientName,
    required String instructorName,
    required String newBookingDateTime,
    required String oldBookingDateTime,
    required String sessionTitle,
  }) async {
    print('📧 [DEV] Booking Reschedule Email');
    print('To Client: $clientEmail');
    print('Client: $clientName');
    print('Instructor: $instructorName');
    print('Session: $sessionTitle');
    print('Old Date & Time: $oldBookingDateTime');
    print('New Date & Time: $newBookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
  }

  @override
  Future<void> sendInstructorRescheduleNotificationEmail({
    required String bookingId,
    required String clientName,
    required String instructorEmail,
    required String instructorName,
    required String newBookingDateTime,
    required String oldBookingDateTime,
    required String sessionTitle,
  }) async {
    print('📧 [DEV] Instructor Reschedule Notification Email');
    print('To Instructor: $instructorEmail');
    print('Instructor: $instructorName');
    print('Client: $clientName');
    print('Session: $sessionTitle');
    print('Old Date & Time: $oldBookingDateTime');
    print('New Date & Time: $newBookingDateTime');
    print('Booking ID: $bookingId');
    print('---');
  }
}