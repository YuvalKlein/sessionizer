import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/view_models/enhanced_booking_view_model.dart';
import 'package:myapp/services/enhanced_booking_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/models/schedulable_session.dart';

class EnhancedBookingScreen extends StatefulWidget {
  final String instructorId;

  const EnhancedBookingScreen({super.key, required this.instructorId});

  @override
  State<EnhancedBookingScreen> createState() => _EnhancedBookingScreenState();
}

class _EnhancedBookingScreenState extends State<EnhancedBookingScreen> {
  late final EnhancedBookingViewModel _viewModel;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _viewModel = EnhancedBookingViewModel(
      bookingService: EnhancedBookingService(),
      sessionTypeService: SessionTypeService(),
      locationService: LocationService(),
    );
    _selectedDay = _focusedDay.value;
    _viewModel.loadSchedulableSessions(widget.instructorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableProvider.value(
        value: _viewModel,
        child: Consumer<EnhancedBookingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && !viewModel.hasSchedulableSessions) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _viewModel.loadSchedulableSessions(widget.instructorId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!viewModel.hasSchedulableSessions) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No sessions available for booking',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This instructor hasn\'t set up any bookable sessions yet.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildSchedulableSessionSelector(viewModel),
                if (viewModel.selectedSchedulableSession != null) ...[
                  const Divider(),
                  _buildCalendar(viewModel),
                  _buildAvailableSlots(viewModel),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchedulableSessionSelector(EnhancedBookingViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Session Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...viewModel.schedulableSessions.map((session) {
            final sessionType = viewModel.getSessionTypeForSchedulableSession(session);
            final isSelected = viewModel.selectedSchedulableSession?.id == session.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isSelected ? 4 : 1,
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              child: ListTile(
                title: Text(
                  session.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sessionType != null)
                      Text('${sessionType.title} • ${sessionType.durationMinutes} min'),
                    Text('${session.slotIntervalMinutes}-min slots'),
                    if (session.bufferTimeMinutes > 0)
                      Text('${session.bufferTimeMinutes}-min buffer'),
                  ],
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () => viewModel.selectSchedulableSession(session),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendar(EnhancedBookingViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar<DateTime>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay.value,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay.value = focusedDay;
            });
            viewModel.loadAvailableSlots(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay.value = focusedDay;
        },
      ),
    );
  }

  Widget _buildAvailableSlots(EnhancedBookingViewModel viewModel) {
    if (_selectedDay == null) {
      return const Expanded(
        child: Center(
          child: Text('Select a date to see available slots'),
        ),
      );
    }

    if (viewModel.isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.availableSlots.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No available slots',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting a different date',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Available Slots - ${DateFormat.yMMMd().format(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: viewModel.availableSlots.length,
              itemBuilder: (context, index) {
                final slot = viewModel.availableSlots[index];
                return _buildSlotCard(slot, viewModel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot, EnhancedBookingViewModel viewModel) {
    final startTime = slot['startTime'] as DateTime;
    final endTime = slot['endTime'] as DateTime;
    final locationIds = slot['locationIds'] as List<String>;
    final availableLocations = viewModel.getAvailableLocationsForSession(
      viewModel.selectedSchedulableSession!,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${endTime.difference(startTime).inMinutes} minutes'),
            if (availableLocations.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Locations: ${availableLocations.map((loc) => loc['name']).join(', ')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showBookingDialog(slot, viewModel, availableLocations),
      ),
    );
  }

  Future<void> _showBookingDialog(
    Map<String, dynamic> slot,
    EnhancedBookingViewModel viewModel,
    List<Map<String, dynamic>> availableLocations,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    String? selectedLocationId;
    if (availableLocations.length == 1) {
      selectedLocationId = availableLocations.first['id'];
    }

    final bool? confirmed = await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book session on ${DateFormat.yMMMd().format(slot['startTime'])} at ${DateFormat.jm().format(slot['startTime'])}?',
              ),
              const SizedBox(height: 16),
              if (availableLocations.length > 1) ...[
                const Text('Select Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...availableLocations.map((location) => RadioListTile<String>(
                  title: Text(location['name']),
                  value: location['id'],
                  groupValue: selectedLocationId,
                  onChanged: (value) => setState(() => selectedLocationId = value),
                )),
              ] else if (availableLocations.length == 1) ...[
                Text('Location: ${availableLocations.first['name']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedLocationId != null
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedLocationId != null) {
      final success = await viewModel.bookSlot(
        slot: slot,
        clientId: currentUser.uid,
        clientName: currentUser.displayName ?? 'User',
        clientEmail: currentUser.email ?? '',
        locationId: selectedLocationId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error ?? 'Booking failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    super.dispose();
  }
}
