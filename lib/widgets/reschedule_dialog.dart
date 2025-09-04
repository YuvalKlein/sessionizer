import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/models/booking.dart';
import 'package:myapp/services/enhanced_booking_service.dart';
import 'package:myapp/services/booking_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/models/schedulable_session.dart';

class RescheduleDialog extends StatefulWidget {
  final Booking booking;
  final String instructorId;

  const RescheduleDialog({
    super.key,
    required this.booking,
    required this.instructorId,
  });

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  final EnhancedBookingService _enhancedBookingService = EnhancedBookingService();
  final BookingService _bookingService = BookingService();
  final SessionTypeService _sessionTypeService = SessionTypeService();
  final LocationService _locationService = LocationService();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _availableSlots = [];
  Map<String, dynamic>? _selectedSlot;
  SessionType? _sessionType;
  Map<String, dynamic>? _location;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.booking.startTime;
    _focusedDay = widget.booking.startTime;
    _loadRelatedData();
  }

  Future<void> _loadRelatedData() async {
    try {
      // Load session type
      if (widget.booking.sessionTypeId != null) {
        _sessionType = await _sessionTypeService.getSessionType(widget.booking.sessionTypeId!);
      }

      // Load location
      if (widget.booking.locationId != null) {
        _location = await _locationService.getLocation(widget.booking.locationId!);
      }

      // Load available slots for the selected date
      await _loadAvailableSlots();
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_sessionType == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get schedulable sessions for the instructor
      final schedulableSessions = await _enhancedBookingService.getSchedulableSessions(widget.instructorId);
      
      // Find a matching schedulable session for this session type and location
      SchedulableSession? matchingSession;
      for (final session in schedulableSessions) {
        if (session.sessionTypeId == widget.booking.sessionTypeId) {
          if (widget.booking.locationId == null || session.locationIds.contains(widget.booking.locationId)) {
            matchingSession = session;
            break;
          }
        }
      }

      if (matchingSession == null) {
        setState(() {
          _error = 'No matching schedulable session found';
          _isLoading = false;
        });
        return;
      }

      final slots = await _enhancedBookingService.getAvailableSlots(
        schedulableSessionId: matchingSession.id!,
        date: _selectedDate,
      );
      
      setState(() {
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available slots: $e';
        _isLoading = false;
      });
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
      return '$duration min';
    }
  }

  Future<void> _confirmReschedule() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a new time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reschedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reschedule booking to:'),
            const SizedBox(height: 8),
            Text(
              '${DateFormat.yMMMd().format(_selectedDate)} at ${DateFormat.jm().format(_selectedSlot!['startTime'])}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Duration: ${_formatDuration(_sessionType!)}'),
            if (_location != null) ...[
              const SizedBox(height: 4),
              Text('Location: ${_location!['name']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.rescheduleBooking(
          widget.booking.id!,
          _selectedSlot!['startTime'],
          _selectedSlot!['endTime'],
        );
        
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rescheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reschedule booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.schedule, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Reschedule Booking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: 16),

            // Current booking info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Booking',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.yMMMd().format(widget.booking.startTime)} at ${DateFormat.jm().format(widget.booking.startTime)}',
                  ),
                  if (_sessionType != null) ...[
                    const SizedBox(height: 2),
                    Text('Duration: ${_formatDuration(_sessionType!)}'),
                  ],
                  if (_location != null) ...[
                    const SizedBox(height: 2),
                    Text('Location: ${_location!['name']}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            Expanded(
              child: Row(
                children: [
                  // Calendar
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select New Date',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TableCalendar<Map<String, dynamic>>(
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 90)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDate = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedSlot = null;
                              });
                              _loadAvailableSlots();
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                final isToday = isSameDay(day, DateTime.now());
                                final isSelected = isSameDay(day, _selectedDate);
                                final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                                
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : isToday
                                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                                            : isPast
                                                ? Colors.grey.withOpacity(0.3)
                                                : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isSelected || isToday
                                            ? Colors.white
                                            : isPast
                                                ? Colors.grey
                                                : null,
                                        fontWeight: isSelected || isToday ? FontWeight.bold : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Available slots
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Times',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildSlotsList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedSlot != null ? _confirmReschedule : null,
                  child: const Text('Reschedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadAvailableSlots,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No available slots',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting a different date',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final isSelected = _selectedSlot == slot;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            title: Text(
              DateFormat.jm().format(slot['startTime']),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: Text(
              'Duration: ${_formatDuration(_sessionType!)}',
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedSlot = slot;
              });
            },
            trailing: isSelected ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            ) : null,
          ),
        );
      },
    );
  }
}
