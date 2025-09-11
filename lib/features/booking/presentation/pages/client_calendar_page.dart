import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/booking/presentation/widgets/booking_confirmation_modal.dart';
import 'package:myapp/core/config/firestore_collections.dart';

class ClientCalendarPage extends StatefulWidget {
  final String sessionId;
  final String instructorId;
  final String? rescheduleBookingId; // For reschedule mode
  final String? clientId; // Optional client ID for instructor bookings

  const ClientCalendarPage({
    Key? key,
    required this.sessionId,
    required this.instructorId,
    this.rescheduleBookingId,
    this.clientId,
  }) : super(key: key);

  @override
  State<ClientCalendarPage> createState() => _ClientCalendarPageState();
}

class _ClientCalendarPageState extends State<ClientCalendarPage> {
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String _errorMessage = '';

  // Available dates and their time slots
  final Map<DateTime, List<TimeOfDay>> _availableSlots = {};
  final Map<DateTime, List<Map<String, dynamic>>> _scheduleData = {};
  
  // Session details for booking confirmation
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _locationData;
  Map<String, dynamic>? _sessionTypeData;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]); // Start with empty events
    _loadSessionDetails();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    try {
      print('🔍 Loading session details for sessionId: ${widget.sessionId}');
      print('🔍 Using collection path: sessionizer/bookable_sessions/bookable_sessions/${widget.sessionId}');
      
      // Load session details
      final sessionDoc = await FirestoreCollections.bookableSession(widget.sessionId).get();
      
      if (sessionDoc.exists) {
        print('✅ Session document found');
        _sessionData = sessionDoc.data() as Map<String, dynamic>;
        print('📊 Session data keys: ${_sessionData!.keys.toList()}');
        
        // Load location (first one)
        final locationIds = List<String>.from(_sessionData!['locationIds'] ?? []);
        print('🔍 Location IDs: $locationIds');
        if (locationIds.isNotEmpty) {
          print('🔍 Loading location: ${locationIds.first}');
          final locationDoc = await FirestoreCollections.location(locationIds.first).get();
          if (locationDoc.exists) {
            print('✅ Location document found');
            final locationData = locationDoc.data() as Map<String, dynamic>;
            _locationData = {
              'id': locationIds.first,
              'name': locationData['name'],
            };
          } else {
            print('❌ Location document not found');
          }
        }
        
        // Load session type (first one)
        final typeIds = List<String>.from(_sessionData!['sessionTypeIds'] ?? []);
        print('🔍 Session type IDs: $typeIds');
        if (typeIds.isNotEmpty) {
          print('🔍 Loading session type: ${typeIds.first}');
          final typeDoc = await FirestoreCollections.sessionType(typeIds.first).get();
          if (typeDoc.exists) {
            print('✅ Session type document found');
            final typeData = typeDoc.data() as Map<String, dynamic>;
            _sessionTypeData = {
              'id': typeIds.first,
              'title': typeData['title'],
              'duration': typeData['duration'],
            };
          } else {
            print('❌ Session type document not found');
          }
        }
      } else {
        print('❌ Session document not found');
      }
    } catch (e) {
      print('❌ Error loading session details: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Debug logging reduced for performance
      print('Loading schedules for instructor: ${widget.instructorId}');
      
      // First, get all bookable sessions for this instructor to find which schedules are used
      final bookableSessionsQuery = await FirestoreQueries.getBookableSessionsByInstructor(widget.instructorId).get();
      
      // Extract unique schedule IDs from bookable sessions and store session data
      final usedScheduleIds = <String>{};
      final bookableSessionsData = <String, Map<String, dynamic>>{};
      for (final sessionDoc in bookableSessionsQuery.docs) {
        final sessionData = sessionDoc.data() as Map<String, dynamic>;
        final scheduleId = sessionData['scheduleId'] as String?;
        if (scheduleId != null) {
          usedScheduleIds.add(scheduleId);
          bookableSessionsData[scheduleId] = sessionData;
        }
      }
      
      print('Used schedule IDs: $usedScheduleIds');
      
      if (usedScheduleIds.isEmpty) {
        print('No bookable sessions found for this instructor');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load existing bookings for this instructor to avoid double booking
      final existingBookings = await FirestoreCollections.bookings
          .where('instructorId', isEqualTo: widget.instructorId)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();
      
      print('Found ${existingBookings.docs.length} existing bookings');
      
      // Create a map of booked times for quick lookup
      final bookedTimes = <String, Set<String>>{};
      for (final bookingDoc in existingBookings.docs) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final startTime = (bookingData['startTime'] as Timestamp).toDate();
        final endTime = (bookingData['endTime'] as Timestamp).toDate();
        
        // Create date key
        final dateKey = '${startTime.year}-${startTime.month}-${startTime.day}';
        
        // Debug: Log each booking
        print('DEBUG: Processing booking - Date: $dateKey, Start: $startTime, End: $endTime');
        
        // Create time range key
        final startTimeKey = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final endTimeKey = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
        
        if (!bookedTimes.containsKey(dateKey)) {
          bookedTimes[dateKey] = <String>{};
        }
        
        // Get the slot interval from the bookable session data
        final sessionId = bookingData['sessionId'] as String? ?? bookingData['bookableSessionId'] as String?;
        int slotIntervalMinutes = 60; // Default to 60 minutes
        
        if (sessionId != null) {
          // Find the bookable session to get its slot interval
          for (final scheduleId in bookableSessionsData.keys) {
            final sessionData = bookableSessionsData[scheduleId];
            if (sessionData != null && sessionData['id'] == sessionId) {
              slotIntervalMinutes = sessionData['slotIntervalMinutes'] as int? ?? 60;
              break;
            }
          }
        }
        
        // Add all time slots in the booking range
        var currentTime = startTime;
        while (currentTime.isBefore(endTime)) {
          final timeKey = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
          bookedTimes[dateKey]!.add(timeKey);
          currentTime = currentTime.add(Duration(minutes: slotIntervalMinutes));
        }
      }
      
      // Debug: Log final booked times map
      print('DEBUG: Final booked times map: $bookedTimes');
      
      // Load only the schedules that are actually used by bookable sessions
      final schedulesQuery = await FirestoreCollections.schedules
          .where('instructorId', isEqualTo: widget.instructorId)
          .where(FieldPath.documentId, whereIn: usedScheduleIds.toList())
          .get();
      
      print('Found ${schedulesQuery.docs.length} schedules');

      _availableSlots.clear();
      _scheduleData.clear();

      // Check availability for the next maxDaysAhead days
      final startDate = DateTime.now();
      final maxDaysAhead = _sessionData?['maxDaysAhead'] ?? 7;
      final endDate = DateTime.now().add(Duration(days: maxDaysAhead));

      for (int i = 0; i < maxDaysAhead; i++) {
        final date = startDate.add(Duration(days: i));
        final timeSlots = <TimeOfDay>[];

        for (final scheduleDoc in schedulesQuery.docs) {
          final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
          
          // Debug: Print schedule data structure (reduced)
          if (i == 0) { // Only print for first day to avoid spam
            print('Schedule data: ${scheduleData['name']} - ${scheduleData['weeklyAvailability']?.keys.length ?? 0} days available');
          }
          
          if (_isDateInSchedule(date, scheduleData)) {
            // Get the slot interval from the bookable session
            final scheduleId = scheduleDoc.id;
            final bookableSessionData = bookableSessionsData[scheduleId];
            final slotIntervalMinutes = bookableSessionData?['slotIntervalMinutes'] as int? ?? 30;
            
            final slots = _getTimeSlotsForDate(date, scheduleData, slotIntervalMinutes: slotIntervalMinutes);
            // Reduced debug logging
            if (i < 3) { // Debug: Print for first 3 days only
              print('Date: $date, Day: ${_getDayName(date.weekday)}, Slots found: ${slots.length}, Interval: ${slotIntervalMinutes}min');
            }
            timeSlots.addAll(slots);
            
            // Normalize the date to midnight for consistent key matching
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (!_scheduleData.containsKey(normalizedDate)) {
              _scheduleData[normalizedDate] = [];
            }
            _scheduleData[normalizedDate]!.add({
              'scheduleId': scheduleDoc.id,
              'data': scheduleData,
            });
          }
        }

        if (timeSlots.isNotEmpty) {
          // Filter out booked times
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final bookedTimesForDate = bookedTimes[dateKey] ?? <String>{};
          
          
          final availableTimeSlots = timeSlots.where((slot) {
            final timeKey = '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
            final isAvailable = !bookedTimesForDate.contains(timeKey);
            
            
            return isAvailable;
          }).toList();
          
          
          if (availableTimeSlots.isNotEmpty) {
            // Normalize the date to midnight for consistent key matching
            final normalizedDate = DateTime(date.year, date.month, date.day);
            _availableSlots[normalizedDate] = availableTimeSlots;
          }
        }
      }

      print('Total available dates: ${_availableSlots.length}');
      if (_availableSlots.isNotEmpty) {
        print('First available date: ${_availableSlots.keys.first}');
        print('Slots for first date: ${_availableSlots.values.first.length}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Refresh the selected day's events after loading is complete
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    } catch (e) {
      print('CALENDAR ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load available slots: $e';
        });
      }
    }
  }

  bool _isDateInSchedule(DateTime date, Map<String, dynamic> scheduleData) {
    // Check if date is not a holiday
    final holidays = scheduleData['holidays'] as Map<String, dynamic>?;
    if (holidays?.containsKey(_formatDateKey(date)) == true) {
      return false;
    }
    
    // Check if date matches the schedule's day of week
    final dayOfWeek = date.weekday;
    final weeklyAvailability = scheduleData['weeklyAvailability'] as Map<String, dynamic>?;
    return weeklyAvailability?.containsKey(_getDayName(dayOfWeek)) == true;
  }

  List<TimeOfDay> _getTimeSlotsForDate(DateTime date, Map<String, dynamic> scheduleData, {int slotIntervalMinutes = 30}) {
    final dayName = _getDayName(date.weekday);
    final weeklyAvailability = scheduleData['weeklyAvailability'] as Map<String, dynamic>?;
    final dayAvailability = weeklyAvailability?[dayName];
    
    if (dayAvailability == null) {
      return [];
    }
    
    final slots = <TimeOfDay>[];
    
    // Handle both data structures and formats:
    // 1. Single time range: {start: "09:00", end: "17:00"} OR {startTime: "09:00", endTime: "17:00"}
    // 2. List of time ranges: [{startTime: "4:00 PM", endTime: "10:00 PM"}] OR [{start: "09:00", end: "17:00"}]
    
    if (dayAvailability is Map<String, dynamic>) {
      // Single time range format - handle both old and new formats during transition
      final startTimeStr = dayAvailability['startTime'] as String? ?? dayAvailability['start'] as String?;
      final endTimeStr = dayAvailability['endTime'] as String? ?? dayAvailability['end'] as String?;
      
          if (startTimeStr != null && endTimeStr != null) {
            final timeSlots = _generateTimeSlots(startTimeStr, endTimeStr, intervalMinutes: slotIntervalMinutes, forDate: date);
            slots.addAll(timeSlots);
          }
    } else if (dayAvailability is List<dynamic>) {
      // List of time ranges format
      for (final range in dayAvailability) {
        if (range is Map<String, dynamic>) {
          // Handle both old and new formats during transition
          final startTimeStr = range['startTime'] as String? ?? range['start'] as String?;
          final endTimeStr = range['endTime'] as String? ?? range['end'] as String?;
          
          if (startTimeStr != null && endTimeStr != null) {
            final timeSlots = _generateTimeSlots(startTimeStr, endTimeStr, intervalMinutes: slotIntervalMinutes, forDate: date);
            slots.addAll(timeSlots);
          }
        }
      }
    }
    
    return slots;
  }
  
  List<TimeOfDay> _generateTimeSlots(String startTimeStr, String endTimeStr, {int intervalMinutes = 30, DateTime? forDate}) {
    final slots = <TimeOfDay>[];
    final startTime = _parseTimeString(startTimeStr);
    final endTime = _parseTimeString(endTimeStr);
    
    if (startTime != null && endTime != null) {
      // Get current time for filtering past slots
      final now = DateTime.now();
      final isToday = forDate != null && 
          now.year == forDate.year && 
          now.month == forDate.month && 
          now.day == forDate.day;
      
      // Generate slots with the specified interval between start and end time
      var currentTime = startTime;
      while (currentTime.hour < endTime.hour || 
             (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute)) {
        
        // Only add slots that are in the future (for today) or all slots (for future days)
        if (!isToday || _isTimeInFuture(currentTime, now)) {
          slots.add(currentTime);
        }
        
        currentTime = TimeOfDay(
          hour: currentTime.hour + (currentTime.minute + intervalMinutes) ~/ 60,
          minute: (currentTime.minute + intervalMinutes) % 60,
        );
      }
    }
    
    return slots;
  }
  
  bool _isTimeInFuture(TimeOfDay timeSlot, DateTime now) {
    final slotDateTime = DateTime(now.year, now.month, now.day, timeSlot.hour, timeSlot.minute);
    return slotDateTime.isAfter(now);
  }
  
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle 12-hour format like "4:00 PM"
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final period = parts[1].toUpperCase();
          
          final timeSplit = timePart.split(':');
          if (timeSplit.length == 2) {
            var hour = int.parse(timeSplit[0]);
            final minute = int.parse(timeSplit[1]);
            
            // Convert to 24-hour format
            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }
            
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      } else {
        // Handle 24-hour format like "09:00"
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      print('Error parsing time string "$timeStr": $e');
    }
    return null;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final slots = _availableSlots[normalizedDay] ?? [];
    
    return slots.map((slot) => {
      'time': slot,
      'sessionId': widget.sessionId,
      'instructorId': widget.instructorId,
    }).toList();
  }

  bool _isDayAvailable(DateTime day) {
    // Check if the day has any available time slots
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final hasSlots = _availableSlots.containsKey(normalizedDay) && _availableSlots[normalizedDay]!.isNotEmpty;
    
    
    // Debug logging for first few days
    if (day.day <= 10) {
      print('DEBUG: Day ${day.day}/${day.month}/${day.year} - Available: $hasSlots, Slots: ${_availableSlots[normalizedDay]?.length ?? 0}');
    }
    
    return hasSlots;
  }

  void _showBookingConfirmation(TimeOfDay time) {
    if (_sessionData == null || _locationData == null || _sessionTypeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session details not loaded yet. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BookingConfirmationModal(
        sessionId: widget.sessionId,
        instructorId: widget.instructorId,
        selectedDate: _selectedDay!,
        selectedTime: time,
        sessionData: _sessionData!,
        locationData: _locationData!,
        sessionTypeData: _sessionTypeData!,
        rescheduleBookingId: widget.rescheduleBookingId, // Pass reschedule ID
        clientId: widget.clientId, // Pass client ID for instructor bookings
        onBookingSuccess: () async {
          // Only refresh calendar for new bookings, not reschedules
          if (widget.rescheduleBookingId == null) {
            print('DEBUG: Booking successful, refreshing calendar...');
            if (mounted) {
              await _loadAvailableSlots();
              // Also refresh the selected day events
              if (mounted) {
                try {
                  _selectedEvents.value = _getEventsForDay(_selectedDay!);
                } catch (e) {
                  print('DEBUG: Could not update selected events: $e');
                }
              }
              print('DEBUG: Calendar refresh completed');
            }
          } else {
            print('DEBUG: Reschedule successful, no calendar refresh needed');
          }
        },
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      // Always update the events for the selected day
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Booking Times'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/sessions?instructorId=${widget.instructorId}'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAvailableSlots,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Calendar
                    TableCalendar<Map<String, dynamic>>(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      enabledDayPredicate: _isDayAvailable,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        markersMaxCount: 3,
                        markerDecoration: BoxDecoration(
                          color: Colors.blue[400],
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue[200],
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        disabledTextStyle: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onDaySelected: _onDaySelected,
                      onFormatChanged: _onFormatChanged,
                      onPageChanged: _onPageChanged,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                    ),
                    const SizedBox(height: 8.0),
                    // Selected day events
                    Expanded(
                      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _selectedEvents,
                        builder: (context, value, _) {
                          if (value.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No available slots for ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: value.length,
                            itemBuilder: (context, index) {
                              final event = value[index];
                              final time = event['time'] as TimeOfDay;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Icon(
                                      Icons.access_time,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Available time slot',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      // Show booking confirmation modal
                                      _showBookingConfirmation(time);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Book'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
