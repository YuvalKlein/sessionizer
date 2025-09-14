import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/services/email_service.dart';
import 'package:myapp/core/services/cancellation_policy_service.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart';
import 'package:myapp/core/services/google_calendar_service.dart';

class BookingConfirmationModal extends StatefulWidget {
  final String sessionId;
  final String instructorId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> locationData;
  final Map<String, dynamic> sessionTypeData;
  final String? rescheduleBookingId; // For reschedule mode
  final String? clientId; // Optional client ID for instructor bookings
  final VoidCallback onBookingSuccess;

  const BookingConfirmationModal({
    Key? key,
    required this.sessionId,
    required this.instructorId,
    required this.selectedDate,
    required this.selectedTime,
    required this.sessionData,
    required this.locationData,
    required this.sessionTypeData,
    this.rescheduleBookingId, // Optional for reschedule
    this.clientId, // Optional client ID
    required this.onBookingSuccess,
  }) : super(key: key);

  @override
  State<BookingConfirmationModal> createState() => _BookingConfirmationModalState();
}

class _BookingConfirmationModalState extends State<BookingConfirmationModal> {
  final _notesController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Create a Google Calendar event for the booking
  Future<void> _createGoogleCalendarEvent(String bookingId, Map<String, dynamic> bookingData) async {
    try {
      print('🗓️ Creating Google Calendar event for booking: $bookingId');

      final calendarService = GoogleCalendarService.instance;
      
      // Get user data for email addresses
      final userState = context.read<UserBloc>().state;
      if (userState is! UserLoaded) {
        print('⚠️ User not loaded - skipping calendar event creation');
        return;
      }

      // Get instructor data
      final instructorDoc = await FirestoreCollections.user(widget.instructorId).get();
      if (!instructorDoc.exists) {
        print('⚠️ Instructor not found - skipping calendar event creation');
        return;
      }
      final instructorData = instructorDoc.data() as Map<String, dynamic>;

      // Prepare event details
      final sessionTitle = widget.sessionData['title'] ?? 'Session';
      final sessionType = widget.sessionTypeData['name'] ?? 'Session';
      final locationName = widget.locationData['name'] ?? 'Location';
      final locationAddress = widget.locationData['address'] ?? '';
      
      final startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedTime.hour,
        widget.selectedTime.minute,
      );
      
      final duration = widget.sessionTypeData['duration'] ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));

      final title = '$sessionType - $sessionTitle';
      final description = '''
Session Details:
• Type: $sessionType
• Duration: ${duration}min
• Location: $locationName
• Notes: ${_notesController.text.isEmpty ? 'No additional notes' : _notesController.text}

Booking ID: $bookingId
''';

      final location = locationAddress.isEmpty ? locationName : '$locationName, $locationAddress';
      final clientEmail = userState.user.email;
      final instructorEmail = instructorData['email'] ?? '';

      // Create the calendar event
      final eventId = await calendarService.createBookingEvent(
        bookingId: bookingId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        clientEmail: clientEmail,
        instructorEmail: instructorEmail,
      );

      if (eventId != null) {
        print('✅ Google Calendar event created: $eventId');
      }
    } catch (e) {
      print('❌ Error creating Google Calendar event: $e');
      // Don't throw - calendar integration shouldn't break the booking process
    }
  }

  Future<void> _confirmBooking() async {
    // Show cancellation policy agreement modal first
    final agreed = await _showCancellationPolicyAgreementModal();
    if (!agreed) {
      return; // User didn't agree, don't proceed with booking
    }

    setState(() => _isBooking = true);

    try {
      final userState = context.read<UserBloc>().state;
      if (userState is! UserLoaded) {
        throw Exception('User not loaded');
      }

      final startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.selectedTime.hour,
        widget.selectedTime.minute,
      );

      final duration = widget.sessionTypeData['duration'] as int;
      final endTime = startTime.add(Duration(minutes: duration));

      final bookingData = {
        'clientId': widget.clientId ?? userState.user.id, // Use provided clientId or current user
        'instructorId': widget.instructorId,
        'bookableSessionId': widget.sessionId,
        'locationId': widget.locationData['id'],
        'sessionTypeId': widget.sessionTypeData['id'],
        'startTime': startTime,
        'endTime': endTime,
        'status': 'confirmed',
        'notes': _notesController.text.trim(),
        'updatedAt': DateTime.now(),
      };

      if (widget.rescheduleBookingId != null) {
        // Reschedule mode - update existing booking (only time-related fields)
        final rescheduleData = {
          'bookableSessionId': widget.sessionId,
          'locationId': widget.locationData['id'],
          'sessionTypeId': widget.sessionTypeData['id'],
          'startTime': startTime,
          'endTime': endTime,
          'status': 'confirmed',
          'notes': _notesController.text.trim(),
          'updatedAt': DateTime.now(),
        };
        
        // Get the old booking data for email comparison
        final oldBookingDoc = await FirestoreCollections.booking(widget.rescheduleBookingId!).get();
        final oldBookingData = oldBookingDoc.data() as Map<String, dynamic>?;
        final oldStartTime = oldBookingData?['startTime'] as Timestamp?;
        final oldEndTime = oldBookingData?['endTime'] as Timestamp?;
        
        await FirestoreCollections.booking(widget.rescheduleBookingId!).update(rescheduleData);

        // Send reschedule emails
        try {
          print('📧 Sending reschedule emails for booking: ${widget.rescheduleBookingId}');
          
          // Get booking details for emails
          final bookingDoc = await FirestoreCollections.booking(widget.rescheduleBookingId!).get();
          final bookingData = bookingDoc.data() as Map<String, dynamic>?;
          
          if (bookingData != null) {
            final clientId = bookingData['clientId'] as String?;
            final instructorId = bookingData['instructorId'] as String?;
            final bookableSessionId = bookingData['bookableSessionId'] as String?;
            
            if (clientId != null && instructorId != null && bookableSessionId != null) {
              // Get client details
              final clientDoc = await FirestoreCollections.user(clientId).get();
              final clientData = clientDoc.data() as Map<String, dynamic>?;
              final clientName = clientData?['name'] as String? ?? 'Client';
              final clientEmail = clientData?['email'] as String? ?? 'client@example.com';
              
              // Get instructor details
              final instructorDoc = await FirestoreCollections.user(instructorId).get();
              final instructorData = instructorDoc.data() as Map<String, dynamic>?;
              final instructorName = instructorData?['name'] as String? ?? 'Instructor';
              final instructorEmail = instructorData?['email'] as String? ?? 'instructor@example.com';
              
              // Get session details
              final sessionDoc = await FirestoreCollections.bookableSession(bookableSessionId).get();
              final sessionData = sessionDoc.data() as Map<String, dynamic>?;
              final sessionTitle = sessionData?['title'] as String? ?? 'Session';
              
              // Format old and new times
              final oldStartDateTime = oldStartTime?.toDate() ?? DateTime.now();
              final oldEndDateTime = oldEndTime?.toDate() ?? DateTime.now();
              final oldBookingDateTime = '${oldStartDateTime.day}/${oldStartDateTime.month}/${oldStartDateTime.year} at ${oldStartDateTime.hour}:${oldStartDateTime.minute.toString().padLeft(2, '0')} - ${oldEndDateTime.hour}:${oldEndDateTime.minute.toString().padLeft(2, '0')}';
              
              final newBookingDateTime = '${startTime.day}/${startTime.month}/${startTime.year} at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
              
              // Send reschedule emails
              final emailService = sl<EmailService>();
              
              // Send client reschedule email
              await emailService.sendBookingRescheduleEmail(
                clientName: clientName,
                clientEmail: clientEmail,
                instructorName: instructorName,
                sessionTitle: sessionTitle,
                oldBookingDateTime: oldBookingDateTime,
                newBookingDateTime: newBookingDateTime,
                bookingId: widget.rescheduleBookingId!,
              );
              
              // Send instructor reschedule notification email
              await emailService.sendInstructorRescheduleNotificationEmail(
                instructorName: instructorName,
                instructorEmail: instructorEmail,
                clientName: clientName,
                sessionTitle: sessionTitle,
                oldBookingDateTime: oldBookingDateTime,
                newBookingDateTime: newBookingDateTime,
                bookingId: widget.rescheduleBookingId!,
              );
              
              print('✅ Reschedule emails sent successfully');
            }
          }
        } catch (e) {
          print('❌ Error sending reschedule emails: $e');
          // Don't fail the reschedule if email fails
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rescheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // New booking mode - create new booking
        print('📝 Creating new booking...');
        bookingData['createdAt'] = DateTime.now();
        
        final docRef = await FirestoreCollections.bookings.add(bookingData);
        print('📝 Booking created with ID: ${docRef.id}');

        // Create Google Calendar event
        await _createGoogleCalendarEvent(docRef.id, bookingData);

        // Send email notification
        try {
          print('📧 Attempting to send booking confirmation email for booking: ${docRef.id}');
          final sendBookingConfirmation = sl<SendBookingConfirmation>();
          await sendBookingConfirmation(docRef.id);
          print('✅ Booking confirmation email sent successfully');
        } catch (e) {
          // Log error but don't fail the booking process
          print('❌ Error sending booking confirmation email: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Close modal and call success callback
      Navigator.of(context).pop();
      
      // Redirect to My Bookings for both new bookings and reschedules
      // Use a post-frame callback to ensure the modal is fully closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/client/bookings');
        }
      });
      
      widget.onBookingSuccess();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (fixed)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Session Details Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Session Type
                    _buildDetailRow(
                      Icons.fitness_center,
                      'Session Type',
                      widget.sessionTypeData['title'] ?? 'Unknown',
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      widget.locationData['name'] ?? 'Unknown',
                    ),
                    const SizedBox(height: 8),
                    
                    // Date
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(widget.selectedDate),
                    ),
                    const SizedBox(height: 8),
                    
                    // Time
                    _buildDetailRow(
                      Icons.access_time,
                      'Time',
                      _formatTime(widget.selectedTime),
                    ),
                    const SizedBox(height: 8),
                    
                    // Duration
                    _buildDetailRow(
                      Icons.timer,
                      'Duration',
                      '${widget.sessionTypeData['duration'] ?? 60} minutes',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancellation Policy Section
            _buildCancellationPolicySection(),
            const SizedBox(height: 16),

            // Notes Section
            Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any special requests or notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons (fixed at bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBooking ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isBooking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Confirm Booking'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showCancellationPolicyAgreementModal() async {
    final hasCancellationFee = widget.sessionTypeData['hasCancellationFee'] as bool? ?? true;
    
    // If no cancellation fee, no need to show agreement modal
    if (!hasCancellationFee) {
      return true;
    }

    // Check if user has already agreed to this session type's cancellation policy
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      final sessionTypeId = widget.sessionTypeData['id'] as String?;
      if (sessionTypeId != null) {
        final hasAgreed = await CancellationPolicyService.hasAgreed(sessionTypeId, userState.user.id);
        if (hasAgreed) {
          return true; // User has already agreed, no need to show modal
        }
      }
    }

    bool dontShowAgain = false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancellation Policy Agreement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'By confirming this booking, you agree to the cancellation policy:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              // Show policy details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: _buildCancellationPolicyContent(),
              ),
              
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Don\'t show this again for this session type'),
                subtitle: const Text('I understand the cancellation policy'),
                value: dontShowAgain,
                onChanged: (value) {
                  setDialogState(() {
                    dontShowAgain = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dontShowAgain) {
                  _saveCancellationPolicyAgreement();
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('I Agree'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Widget _buildCancellationPolicyContent() {
    final cancellationTimeBefore = widget.sessionTypeData['cancellationTimeBefore'] as int? ?? 18;
    final cancellationTimeUnit = widget.sessionTypeData['cancellationTimeUnit'] as String? ?? 'hours';
    final cancellationFeeAmount = widget.sessionTypeData['cancellationFeeAmount'] as int? ?? 100;
    final cancellationFeeType = widget.sessionTypeData['cancellationFeeType'] as String? ?? '%';
    
    // Calculate actual fee amount
    final sessionPrice = widget.sessionTypeData['price'] as int? ?? 100;
    final actualFeeAmount = cancellationFeeType == '%' 
        ? (cancellationFeeAmount * sessionPrice / 100).round()
        : cancellationFeeAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• Cancel or reschedule ${cancellationTimeBefore} ${cancellationTimeUnit} before the session to avoid fees',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '• Late cancellations will incur a fee of \$${actualFeeAmount}',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      ],
    );
  }

  void _saveCancellationPolicyAgreement() async {
    // Save agreement to local storage
    final userState = context.read<UserBloc>().state;
    final sessionTypeId = widget.sessionTypeData['id'] as String?;
    
    if (userState is UserLoaded && sessionTypeId != null) {
      await CancellationPolicyService.saveAgreement(sessionTypeId, userState.user.id);
      print('Cancellation policy agreement saved for session type: $sessionTypeId');
    }
  }

  Widget _buildCancellationPolicySection() {
    // Get cancellation policy from sessionTypeData
    final hasCancellationFee = widget.sessionTypeData['hasCancellationFee'] as bool? ?? true;
    final cancellationTimeBefore = widget.sessionTypeData['cancellationTimeBefore'] as int? ?? 18;
    final cancellationTimeUnit = widget.sessionTypeData['cancellationTimeUnit'] as String? ?? 'hours';
    final cancellationFeeAmount = widget.sessionTypeData['cancellationFeeAmount'] as int? ?? 100;
    final cancellationFeeType = widget.sessionTypeData['cancellationFeeType'] as String? ?? '%';
    
    // Calculate actual fee amount
    final sessionPrice = widget.sessionTypeData['price'] as int? ?? 100;
    final actualFeeAmount = cancellationFeeType == '%' 
        ? (cancellationFeeAmount * sessionPrice / 100).round()
        : cancellationFeeAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cancellation Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (!hasCancellationFee) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No cancellation fees - you can cancel or reschedule anytime.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[600], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Cancellation fees may apply for late cancellations',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Cancel or reschedule ${cancellationTimeBefore} ${cancellationTimeUnit} before the session to avoid fees',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Late cancellations will incur a fee of \$${actualFeeAmount}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
