import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';
import 'package:myapp/features/booking/presentation/widgets/session_info_display.dart';

class BookingsPage extends StatelessWidget {
  final String userId;
  final bool isInstructor;

  const BookingsPage({
    super.key,
    required this.userId,
    this.isInstructor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isInstructor ? 'My Bookings' : 'My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (isInstructor) {
                context.read<BookingBloc>().add(LoadBookingsByInstructor(instructorId: userId));
              } else {
                context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userId));
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (isInstructor) {
                        context.read<BookingBloc>().add(LoadBookingsByInstructor(instructorId: userId));
                      } else {
                        context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userId));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BookingLoaded) {
            if (state.bookings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No bookings found'),
                    SizedBox(height: 8),
                    Text('Your bookings will appear here'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: InstructorAvatar(
                      instructorId: booking.instructorId,
                      radius: 24,
                      backgroundColor: _getStatusColor(booking.status),
                      iconColor: Colors.white,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SessionInfoDisplay(
                          sessionId: booking.sessionId,
                          instructorId: booking.instructorId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        InstructorName(
                          instructorId: booking.instructorId,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start: ${_formatDateTime(booking.startTime)}'),
                        Text('End: ${_formatDateTime(booking.endTime)}'),
                        Text('Status: ${booking.status.toUpperCase()}'),
                        if (booking.notes != null) Text('Notes: ${booking.notes}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'cancel') {
                          context.read<BookingBloc>().add(CancelBookingEvent(id: booking.id));
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancel'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
