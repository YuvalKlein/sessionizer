import 'package:flutter/material.dart';
import 'package:myapp/models/availability_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/availability_service.dart';
import 'package:provider/provider.dart';

class WeeklyHoursEditor extends StatefulWidget {
  const WeeklyHoursEditor({super.key});

  @override
  State<WeeklyHoursEditor> createState() => _WeeklyHoursEditorState();
}

class _WeeklyHoursEditorState extends State<WeeklyHoursEditor> {
  final Map<String, Availability?> _weeklyAvailability = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAvailability();
  }

  void _fetchAvailability() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final availabilityService = Provider.of<AvailabilityService>(
      context,
      listen: false,
    );
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      availabilityService.getAvailabilityStream(currentUser.uid).listen((
        availabilities,
      ) {
        setState(() {
          for (var day in _weeklyAvailability.keys) {
            _weeklyAvailability[day] = null;
          }
          for (var availability in availabilities) {
            _weeklyAvailability[_getDayFromInt(availability.dayOfWeek)] = availability;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly hours',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set when you are typically available for meetings',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ..._weeklyAvailability.keys.map((day) => _buildDayEditor(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEditor(String day) {
    final availability = _weeklyAvailability[day];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              day.substring(0, 1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availability == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Unavailable',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => _addTimeRange(day),
                        ),
                      ],
                    ),
                  )
                else
                  ...availability.allowedSessionTypes.map((timeSlot) {
                    final index = availability.allowedSessionTypes.indexOf(timeSlot);
                    return _buildTimeRangeRow(day, index, timeSlot);
                  }),
                if (availability != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.green),
                      onPressed: () => _addTimeRange(day),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeRow(
    String day,
    int rangeIndex,
    String timeSlot,
  ) {
    final startTime = _parseTime(timeSlot.split('-')[0]);
    final endTime = _parseTime(timeSlot.split('-')[1]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          _buildTimeButton(startTime, (newTime) {
            final newTimeSlot = '${_formatTime(newTime)}-${_formatTime(endTime)}';
            _updateTimeSlot(day, rangeIndex, newTimeSlot);
          }),
          const SizedBox(width: 8),
          const Text('-'),
          const SizedBox(width: 8),
          _buildTimeButton(endTime, (newTime) {
            final newTimeSlot = '${_formatTime(startTime)}-${_formatTime(newTime)}';
            _updateTimeSlot(day, rangeIndex, newTimeSlot);
          }),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => _removeTimeSlot(day, rangeIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(TimeOfDay time, Function(TimeOfDay) onTimeChanged) {
    return TextButton(
      onPressed: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onTimeChanged(newTime);
        }
      },
      child: Text(time.format(context)),
    );
  }

  void _addTimeRange(String day) {
    final availability = _weeklyAvailability[day];
    if (availability == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        final newAvailability = Availability(
          id: '',
          instructorId: currentUser.uid,
          type: 'weekly',
          dayOfWeek: _getIntFromDay(day),
          startTime: '09:00',
          endTime: '17:00',
          allowedSessionTypes: [],
        );
        final availabilityService = Provider.of<AvailabilityService>(
          context,
          listen: false,
        );
        availabilityService.addAvailability(newAvailability);
      }
    } else {
      final newTimeSlots = List<String>.from(
        availability.allowedSessionTypes,
      );
      newTimeSlots.add('09:00-17:00');
      final updatedAvailability = Availability(
        id: availability.id,
        instructorId: availability.instructorId,
        type: availability.type,
        dayOfWeek: availability.dayOfWeek,
        startTime: availability.startTime,
        endTime: availability.endTime,
        allowedSessionTypes: newTimeSlots,
      );
      final availabilityService = Provider.of<AvailabilityService>(
        context,
        listen: false,
      );
      availabilityService.updateAvailability(updatedAvailability);
    }
  }

  void _updateTimeSlot(
    String day,
    int rangeIndex,
    String newTimeSlot,
  ) {
    final availability = _weeklyAvailability[day];
    if (availability != null) {
      final newTimeSlots = List<String>.from(
        availability.allowedSessionTypes,
      );
      newTimeSlots[rangeIndex] = newTimeSlot;
      final updatedAvailability = Availability(
        id: availability.id,
        instructorId: availability.instructorId,
        type: availability.type,
        dayOfWeek: availability.dayOfWeek,
        startTime: availability.startTime,
        endTime: availability.endTime,
        allowedSessionTypes: newTimeSlots,
      );
      final availabilityService = Provider.of<AvailabilityService>(
        context,
        listen: false,
      );
      availabilityService.updateAvailability(updatedAvailability);
    }
  }

  void _removeTimeSlot(String day, int rangeIndex) {
    final availability = _weeklyAvailability[day];
    if (availability != null) {
      final newTimeSlots = List<String>.from(
        availability.allowedSessionTypes,
      );
      newTimeSlots.removeAt(rangeIndex);
      final updatedAvailability = Availability(
        id: availability.id,
        instructorId: availability.instructorId,
        type: availability.type,
        dayOfWeek: availability.dayOfWeek,
        startTime: availability.startTime,
        endTime: availability.endTime,
        allowedSessionTypes: newTimeSlots,
      );
      final availabilityService = Provider.of<AvailabilityService>(
        context,
        listen: false,
      );
      availabilityService.updateAvailability(updatedAvailability);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDayFromInt(int? day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  int _getIntFromDay(String day) {
    switch (day) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      default:
        return 0;
    }
  }
}
