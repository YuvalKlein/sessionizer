import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class PublicCalendarPage extends StatefulWidget {
  final String sessionId;
  final String instructorId;

  const PublicCalendarPage({
    Key? key,
    required this.sessionId,
    required this.instructorId,
  }) : super(key: key);

  @override
  State<PublicCalendarPage> createState() => _PublicCalendarPageState();
}

class _PublicCalendarPageState extends State<PublicCalendarPage> {
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _instructorName;

  // Available dates and their time slots
  final Map<DateTime, List<TimeOfDay>> _availableSlots = {};
  final Map<DateTime, List<Map<String, dynamic>>> _scheduleData = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadInstructorInfo();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorInfo() async {
    try {
      final instructorDoc = await FirebaseFirestore.instance
          .collection('sessionizer')
          .doc('users')
          .collection('users')
          .doc(widget.instructorId)
          .get();
      
      if (instructorDoc.exists) {
        final data = instructorDoc.data()!;
        setState(() {
          _instructorName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim().isEmpty 
              ? (data['displayName'] ?? 'Unknown Instructor')
              : '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load instructor's schedules
      final schedulesQuery = await FirebaseFirestore.instance
          .collection('schedules')
          .where('instructorId', isEqualTo: widget.instructorId)
          .where('isActive', isEqualTo: true)
          .get();

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
          
          if (_isDateInSchedule(date, scheduleData)) {
            final slots = _getTimeSlotsForDate(date, scheduleData);
            timeSlots.addAll(slots);
            
            if (!_scheduleData.containsKey(date)) {
              _scheduleData[date] = [];
            }
            _scheduleData[date]!.add({
              'scheduleId': scheduleDoc.id,
              'data': scheduleData,
            });
          }
        }

        if (timeSlots.isNotEmpty) {
          _availableSlots[date] = timeSlots;
        }
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available slots: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
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

  List<TimeOfDay> _getTimeSlotsForDate(DateTime date, Map<String, dynamic> scheduleData) {
    final dayName = _getDayName(date.weekday);
    final weeklyAvailability = scheduleData['weeklyAvailability'] as Map<String, dynamic>?;
    final dayAvailability = weeklyAvailability?[dayName] as List<dynamic>?;
    
    if (dayAvailability == null) return [];
    
    final slots = <TimeOfDay>[];
    
    for (final range in dayAvailability) {
      final rangeMap = range as Map<String, dynamic>;
      
      // Parse start and end times from Firestore data
      final startTimeMap = rangeMap['start'] as Map<String, dynamic>?;
      final endTimeMap = rangeMap['end'] as Map<String, dynamic>?;
      
      if (startTimeMap != null && endTimeMap != null) {
        final startTime = TimeOfDay(
          hour: startTimeMap['hour'] as int? ?? 0,
          minute: startTimeMap['minute'] as int? ?? 0,
        );
        final endTime = TimeOfDay(
          hour: endTimeMap['hour'] as int? ?? 0,
          minute: endTimeMap['minute'] as int? ?? 0,
        );
        
        // Generate 30-minute slots between start and end time
        var currentTime = startTime;
        while (currentTime.hour < endTime.hour || 
               (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute)) {
          slots.add(currentTime);
          currentTime = TimeOfDay(
            hour: currentTime.hour + (currentTime.minute + 30) ~/ 60,
            minute: (currentTime.minute + 30) % 60,
          );
        }
      }
    }
    
    return slots;
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
        title: Text('${_instructorName ?? 'Instructor'}\'s Calendar'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/public/sessions/${widget.instructorId}'),
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
                                      // Show login dialog for booking
                                      _showBookingDialog(time);
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

  void _showBookingDialog(TimeOfDay time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Required'),
        content: Text(
          'To book this time slot (${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}), '
          'you need to create an account or log in. Would you like to go to the login page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
