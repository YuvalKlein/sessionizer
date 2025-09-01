import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import User
import 'package:myapp/view_models/booking_view_model.dart';
import 'package:myapp/services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final String instructorId;

  const BookingScreen({super.key, required this.instructorId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final BookingViewModel _viewModel;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _viewModel = BookingViewModel(
      scheduleService: context.read(),
      bookingService: context.read(),
    );
    _selectedDay = _focusedDay.value;
    _viewModel.loadScheduleAndInitialAvailability(
      widget.instructorId,
      _selectedDay!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Book an Appointment')),
      body: ListenableProvider.value(
        value: _viewModel,
        child: Consumer<BookingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!viewModel.isScheduleAvailable) {
              return const Center(
                child: Text('This instructor has no availability.'),
              );
            }
            return Column(
              children: [
                _buildCalendar(viewModel),
                _buildAvailableSlots(viewModel, currentUser),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendar(BookingViewModel viewModel) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _focusedDay,
      builder: (context, focusedDay, child) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay.value = focusedDay;
                  viewModel.loadAvailabilityForDay(selectedDay);
                });
              }
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableSlots(BookingViewModel viewModel, User? currentUser) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Available Slots for ${DateFormat.yMMMd().format(_selectedDay!)}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: viewModel.availableSlots.isEmpty
                    ? const Center(child: Text('No slots available.'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: viewModel.availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot = viewModel.availableSlots[index];
                          return ElevatedButton(
                            onPressed: () =>
                                _confirmBooking(context, slot, currentUser),
                            child: Text(DateFormat.jm().format(slot)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
    BuildContext context,
    DateTime slot,
    User? currentUser,
  ) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    final bool? confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Book a 30-minute session on ${DateFormat.yMMMd().format(slot)} at ${DateFormat.jm().format(slot)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Book'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _viewModel.bookSlot(
        slot: slot,
        clientId: currentUser.uid,
        clientName: currentUser.displayName ?? '',
        clientEmail: currentUser.email ?? '',
        instructorId: widget.instructorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    super.dispose();
  }
}
