import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart';

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

  Future<void> _confirmBooking() async {
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
        
        await FirestoreCollections.booking(widget.rescheduleBookingId!).update(rescheduleData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rescheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // New booking mode - create new booking
        bookingData['createdAt'] = DateTime.now();
        
<<<<<<< HEAD
        await FirestoreCollections.bookings.add(bookingData);
=======
        final docRef = await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);
>>>>>>> notification

        // Send email notification
        try {
          final sendBookingConfirmation = sl<SendBookingConfirmation>();
          await sendBookingConfirmation(docRef.id);
        } catch (e) {
          // Log error but don't fail the booking process
          print('Error sending booking confirmation email: $e');
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Action Buttons
            Row(
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
