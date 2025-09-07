import 'package:flutter/material.dart';
import 'package:myapp/core/utils/logger.dart';

class ScheduleCalendar extends StatefulWidget {
  final Map<String, Map<String, dynamic>>? weeklyAvailability;
  final Function(String day, String type, TimeOfDay? time)? onTimeChanged;
  final bool readOnly;

  const ScheduleCalendar({
    super.key,
    this.weeklyAvailability,
    this.onTimeChanged,
    this.readOnly = false,
  });

  @override
  State<ScheduleCalendar> createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  final Map<String, Map<String, TimeOfDay?>> _weeklyAvailability = {
    'monday': {'startTime': null, 'endTime': null},
    'tuesday': {'startTime': null, 'endTime': null},
    'wednesday': {'startTime': null, 'endTime': null},
    'thursday': {'startTime': null, 'endTime': null},
    'friday': {'startTime': null, 'endTime': null},
    'saturday': {'startTime': null, 'endTime': null},
    'sunday': {'startTime': null, 'endTime': null},
  };

  @override
  void initState() {
    super.initState();
    _initializeAvailability();
  }

  void _initializeAvailability() {
    if (widget.weeklyAvailability != null) {
      for (final entry in widget.weeklyAvailability!.entries) {
        final day = entry.key;
        final times = entry.value;
        
        if (times['start'] != null) {
          _weeklyAvailability[day]!['start'] = _parseTimeOfDay(times['start']);
        }
        if (times['end'] != null) {
          _weeklyAvailability[day]!['end'] = _parseTimeOfDay(times['end']);
        }
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(dynamic timeString) {
    if (timeString is String) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('ScheduleCalendar', data: {'readOnly': widget.readOnly});

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        ..._weeklyAvailability.keys.map((day) => _buildDayRow(day)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Day',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Start Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'End Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          if (!widget.readOnly)
            Expanded(
              flex: 1,
              child: Text(
                'Enabled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final dayData = _weeklyAvailability[day]!;
    final isEnabled = dayData['startTime'] != null || dayData['endTime'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _getDayIcon(day),
                  size: 20,
                  color: isEnabled ? Colors.green.shade700 : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _capitalizeFirst(day),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildTimeDisplay(
              dayData['start'],
              () => _selectTime(day, 'start'),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildTimeDisplay(
              dayData['end'],
              () => _selectTime(day, 'end'),
            ),
          ),
          if (!widget.readOnly)
            Expanded(
              flex: 1,
              child: Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      // Set default times when enabling
                      dayData['start'] = const TimeOfDay(hour: 9, minute: 0);
                      dayData['end'] = const TimeOfDay(hour: 17, minute: 0);
                    } else {
                      // Clear times when disabling
                      dayData['start'] = null;
                      dayData['end'] = null;
                    }
                  });
                  widget.onTimeChanged?.call(day, 'start', dayData['start']);
                  widget.onTimeChanged?.call(day, 'end', dayData['end']);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: widget.readOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.readOnly ? Colors.transparent : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          time != null 
              ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
              : 'Not set',
          style: TextStyle(
            fontSize: 14,
            color: time != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(String day, String type) async {
    if (widget.readOnly) return;

    final currentTime = _weeklyAvailability[day]![type];
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (selectedTime != null) {
      setState(() {
        _weeklyAvailability[day]![type] = selectedTime;
      });
      widget.onTimeChanged?.call(day, type, selectedTime);
    }
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'monday':
        return Icons.calendar_today;
      case 'tuesday':
        return Icons.calendar_today;
      case 'wednesday':
        return Icons.calendar_today;
      case 'thursday':
        return Icons.calendar_today;
      case 'friday':
        return Icons.calendar_today;
      case 'saturday':
        return Icons.weekend;
      case 'sunday':
        return Icons.weekend;
      default:
        return Icons.calendar_today;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
