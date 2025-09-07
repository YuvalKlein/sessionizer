import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ClientCalendarPage extends StatefulWidget {
  final String sessionId;
  final String instructorId;

  const ClientCalendarPage({
    Key? key,
    required this.sessionId,
    required this.instructorId,
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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('=== CALENDAR DEBUG START ===');
      print('Loading schedules for instructor: ${widget.instructorId}');
      
      // First, get all bookable sessions for this instructor to find which schedules are used
      final bookableSessionsQuery = await FirebaseFirestore.instance
          .collection('bookable_sessions')
          .where('instructorId', isEqualTo: widget.instructorId)
          .get();
      
      // Extract unique schedule IDs from bookable sessions and store session data
      final usedScheduleIds = <String>{};
      final bookableSessionsData = <String, Map<String, dynamic>>{};
      for (final sessionDoc in bookableSessionsQuery.docs) {
        final sessionData = sessionDoc.data();
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
      
      // Load only the schedules that are actually used by bookable sessions
      final schedulesQuery = await FirebaseFirestore.instance
          .collection('schedules')
          .where('instructorId', isEqualTo: widget.instructorId)
          .where(FieldPath.documentId, whereIn: usedScheduleIds.toList())
          .get();
      
      print('Found ${schedulesQuery.docs.length} schedules');
      
      // Debug: Print schedule details
      for (final doc in schedulesQuery.docs) {
        final data = doc.data();
        print('Schedule ${doc.id}: isActive=${data['isActive']}, name=${data['name']}');
      }

      _availableSlots.clear();
      _scheduleData.clear();

      // Check availability for the next 3 months
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 90));

      for (int i = 0; i < 90; i++) {
        final date = startDate.add(Duration(days: i));
        final timeSlots = <TimeOfDay>[];

        for (final scheduleDoc in schedulesQuery.docs) {
          final scheduleData = scheduleDoc.data();
          
          // Debug: Print schedule data structure
          if (i == 0) { // Only print for first day to avoid spam
            print('Schedule data: $scheduleData');
            print('Weekly availability: ${scheduleData['weeklyAvailability']}');
          }
          
          if (_isDateInSchedule(date, scheduleData)) {
            // Get the slot interval from the bookable session
            final scheduleId = scheduleDoc.id;
            final bookableSessionData = bookableSessionsData[scheduleId];
            final slotIntervalMinutes = bookableSessionData?['slotIntervalMinutes'] as int? ?? 30;
            
            final slots = _getTimeSlotsForDate(date, scheduleData, slotIntervalMinutes: slotIntervalMinutes);
            if (i < 10) { // Debug: Print for first 10 days
              print('Date: $date, Day: ${_getDayName(date.weekday)}, Slots found: ${slots.length}, Interval: ${slotIntervalMinutes}min');
              if (slots.isNotEmpty) {
                print('First slot: ${slots.first}');
              }
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
          // Normalize the date to midnight for consistent key matching
          final normalizedDate = DateTime(date.year, date.month, date.day);
          _availableSlots[normalizedDate] = timeSlots;
        }
      }

      print('Total available dates: ${_availableSlots.length}');
      if (_availableSlots.isNotEmpty) {
        print('First available date: ${_availableSlots.keys.first}');
        print('Slots for first date: ${_availableSlots.values.first.length}');
      }
      print('=== CALENDAR DEBUG END ===');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('CALENDAR ERROR: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load available slots: $e';
      });
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
      print('DEBUG: No availability for $dayName');
      return [];
    }
    
    print('DEBUG: Found availability for $dayName: $dayAvailability');
    
    final slots = <TimeOfDay>[];
    
    // Handle both data structures and formats:
    // 1. Single time range: {start: "09:00", end: "17:00"} OR {startTime: "09:00", endTime: "17:00"}
    // 2. List of time ranges: [{startTime: "4:00 PM", endTime: "10:00 PM"}] OR [{start: "09:00", end: "17:00"}]
    
    if (dayAvailability is Map<String, dynamic>) {
      // Single time range format - handle both old and new formats during transition
      final startTimeStr = dayAvailability['startTime'] as String? ?? dayAvailability['start'] as String?;
      final endTimeStr = dayAvailability['endTime'] as String? ?? dayAvailability['end'] as String?;
      
          if (startTimeStr != null && endTimeStr != null) {
            final timeSlots = _generateTimeSlots(startTimeStr, endTimeStr, intervalMinutes: slotIntervalMinutes);
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
            print('DEBUG: Parsing time range: $startTimeStr - $endTimeStr');
            final timeSlots = _generateTimeSlots(startTimeStr, endTimeStr, intervalMinutes: slotIntervalMinutes);
            print('DEBUG: Generated ${timeSlots.length} slots');
            slots.addAll(timeSlots);
          }
        }
      }
    }
    
    return slots;
  }
  
  List<TimeOfDay> _generateTimeSlots(String startTimeStr, String endTimeStr, {int intervalMinutes = 30}) {
    final slots = <TimeOfDay>[];
    final startTime = _parseTimeString(startTimeStr);
    final endTime = _parseTimeString(endTimeStr);
    
    if (startTime != null && endTime != null) {
      // Generate slots with the specified interval between start and end time
      var currentTime = startTime;
      while (currentTime.hour < endTime.hour || 
             (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute)) {
        slots.add(currentTime);
        currentTime = TimeOfDay(
          hour: currentTime.hour + (currentTime.minute + intervalMinutes) ~/ 60,
          minute: (currentTime.minute + intervalMinutes) % 60,
        );
      }
    }
    
    return slots;
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

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
                                      // Navigate to booking flow with pre-selected time
                                      context.go('/client/book/${widget.sessionId}/${widget.instructorId}?time=${time.hour}:${time.minute}&date=${_selectedDay?.year}-${_selectedDay?.month}-${_selectedDay?.day}');
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
