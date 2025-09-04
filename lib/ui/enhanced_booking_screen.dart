import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/view_models/enhanced_booking_view_model.dart';
import 'package:myapp/services/enhanced_booking_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/models/session_type.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.loadSchedulableSessions(widget.instructorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildSchedulableSessionSelector(viewModel),
                  if (viewModel.selectedSchedulableSession != null) ...[
                    const Divider(),
                    _buildCalendar(viewModel),
                    _buildAvailableSlots(viewModel),
                  ],
                ],
              ),
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
              child: Opacity(
                opacity: session.isActive ? 1.0 : 0.6,
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
                      Text('${sessionType.title} • ${_formatDuration(sessionType)}'),
                    Text('${session.slotIntervalMinutes}-min slots'),
                    if (session.bufferBefore > 0 || session.bufferAfter > 0)
                      Text('${session.bufferBefore + session.bufferAfter}-min buffer'),
                    Row(
                      children: [
                        Icon(
                          session.isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: session.isActive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: session.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: session.isActive ? () => viewModel.selectSchedulableSession(session) : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendar(EnhancedBookingViewModel viewModel) {
    final now = DateTime.now();
    final schedulableSession = viewModel.selectedSchedulableSession;
    
    // Calculate the last bookable day based on schedulable session constraints
    final lastBookableDay = now.add(Duration(days: schedulableSession?.maxDaysAhead ?? 7));
    
    // Ensure focusedDay is within bounds
    final currentFocusedDay = _focusedDay.value;
    final validFocusedDay = currentFocusedDay.isBefore(now) 
        ? now 
        : currentFocusedDay.isAfter(lastBookableDay) 
            ? lastBookableDay 
            : currentFocusedDay;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar<DateTime>(
        firstDay: now,
        lastDay: lastBookableDay,
        focusedDay: validFocusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          // Disable past days and days beyond max booking window
          disabledTextStyle: TextStyle(color: Colors.grey[400]),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        enabledDayPredicate: (day) {
          // Only enable days that are:
          // 1. Today or in the future
          // 2. Within the max booking window
          final isTodayOrFuture = day.isAfter(now.subtract(const Duration(days: 1)));
          final isWithinMaxDays = day.isBefore(lastBookableDay.add(const Duration(days: 1)));
          
          return isTodayOrFuture && isWithinMaxDays;
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
          // Ensure focusedDay stays within bounds
          final validFocusedDay = focusedDay.isBefore(now) 
              ? now 
              : focusedDay.isAfter(lastBookableDay) 
                  ? lastBookableDay 
                  : focusedDay;
          _focusedDay.value = validFocusedDay;
        },
        // Custom day builder to show availability status
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, viewModel, now, lastBookableDay);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, viewModel, now, lastBookableDay, isSelected: true);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, viewModel, now, lastBookableDay, isToday: true);
          },
          disabledBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, viewModel, now, lastBookableDay, isDisabled: true);
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, EnhancedBookingViewModel viewModel, DateTime now, DateTime lastBookableDay, {bool isSelected = false, bool isToday = false, bool isDisabled = false}) {
    final isPast = day.isBefore(now.subtract(const Duration(days: 1)));
    final isFuture = day.isAfter(lastBookableDay);
    final isClickable = !isPast && !isFuture;
    
    return FutureBuilder<bool>(
      future: isClickable ? viewModel.hasAvailabilityForDay(day) : Future.value(false),
      builder: (context, snapshot) {
        final hasAvailability = snapshot.data ?? false;
        final isActuallyClickable = isClickable && hasAvailability;
        
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected 
                ? Theme.of(context).primaryColor
                : isToday 
                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isActuallyClickable ? () {
                // Ensure the focused day stays within bounds
                final validFocusedDay = day.isBefore(now) 
                    ? now 
                    : day.isAfter(lastBookableDay) 
                        ? lastBookableDay 
                        : day;
                setState(() {
                  _selectedDay = day;
                  _focusedDay.value = validFocusedDay;
                });
                viewModel.loadAvailableSlots(day);
              } : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActuallyClickable 
                      ? null 
                      : Colors.grey.withOpacity(0.3),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white
                          : isActuallyClickable 
                              ? Colors.black
                              : Colors.grey[400],
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableSlots(EnhancedBookingViewModel viewModel) {
    if (_selectedDay == null) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Select a date to see available slots'),
        ),
      );
    }

    if (viewModel.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.availableSlots.isEmpty) {
      return SizedBox(
        height: 200,
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

    return Column(
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
        ...viewModel.availableSlots.map((slot) => _buildSlotCard(slot, viewModel)),
        const SizedBox(height: 16), // Add some bottom padding
      ],
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
      selectedLocationId = availableLocations.first['id'] as String;
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
              onPressed: (selectedLocationId != null || availableLocations.length == 1)
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedLocationId != null) {
      try {
        final success = await viewModel.bookSlot(
          slot: slot,
          clientId: currentUser.uid,
          clientName: currentUser.displayName ?? 'User',
          clientEmail: currentUser.email ?? '',
          locationId: selectedLocationId!,
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDuration(SessionType sessionType) {
    final duration = sessionType.duration;
    final unit = sessionType.durationUnit.toLowerCase();
    
    if (unit == 'hours' || unit == 'hour') {
      if (duration == 1) {
        return '1 hour';
      } else {
        return '$duration hours';
      }
    } else if (unit == 'minutes' || unit == 'minute' || unit == 'min') {
      if (duration >= 60) {
        final hours = duration ~/ 60;
        final minutes = duration % 60;
        if (minutes == 0) {
          return hours == 1 ? '1 hour' : '$hours hours';
        } else {
          return '${hours}h ${minutes}m';
        }
      } else {
        return '$duration min';
      }
    } else {
      // Default to minutes if unit is unknown
      return '$duration min';
    }
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
