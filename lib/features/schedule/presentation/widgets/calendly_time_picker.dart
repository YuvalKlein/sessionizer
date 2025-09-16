import 'package:flutter/material.dart';
import 'package:myapp/core/utils/logger.dart';

class CalendlyTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String label;
  final Function(TimeOfDay?) onTimeChanged;
  final bool enabled;
  final List<TimeOfDay> unavailableTimes;

  const CalendlyTimePicker({
    super.key,
    this.initialTime,
    required this.label,
    required this.onTimeChanged,
    this.enabled = true,
    this.unavailableTimes = const [],
  });

  @override
  State<CalendlyTimePicker> createState() => _CalendlyTimePickerState();
}

class _CalendlyTimePickerState extends State<CalendlyTimePicker> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  void didUpdateWidget(CalendlyTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      _selectedTime = widget.initialTime;
    }
  }

  List<TimeOfDay> _generateTimeSlots() {
    final times = <TimeOfDay>[];
    
    // Generate 15-minute intervals from 6:00 AM to 11:00 PM
    for (int hour = 6; hour <= 23; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final time = TimeOfDay(hour: hour, minute: minute);
        times.add(time);
      }
    }
    
    return times;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  bool _isTimeUnavailable(TimeOfDay time) {
    return widget.unavailableTimes.any((unavailable) => 
        unavailable.hour == time.hour && unavailable.minute == time.minute);
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('CalendlyTimePicker', data: {
      'label': widget.label,
      'enabled': widget.enabled,
      'hasTime': _selectedTime != null,
    });

    return DropdownButtonFormField<TimeOfDay>(
      value: _selectedTime,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.enabled 
                ? (_selectedTime != null ? Colors.blue : Colors.grey.shade300)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.enabled 
                ? (_selectedTime != null ? Colors.blue : Colors.grey.shade300)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.enabled ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        fillColor: widget.enabled 
            ? (_selectedTime != null ? Colors.blue.shade50 : Colors.white)
            : Colors.grey.shade100,
        filled: true,
      ),
      hint: Text(
        'Select time',
        style: TextStyle(
          fontSize: 14,
          color: widget.enabled ? Colors.grey : Colors.grey.shade400,
        ),
      ),
      items: widget.enabled ? _generateTimeSlots().where((time) {
        // Filter out unavailable times completely
        return !_isTimeUnavailable(time);
      }).map((time) {
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(
            _formatTimeOfDay(time),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      }).toList() : null,
      onChanged: widget.enabled ? (TimeOfDay? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedTime = newValue;
          });
          widget.onTimeChanged(newValue);
        }
      } : null,
      isDense: true,
      isExpanded: true,
      menuMaxHeight: 200,
    );
  }
}

class CalendlyTimeRangePicker extends StatefulWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay? start, TimeOfDay? end) onTimeRangeChanged;
  final bool enabled;
  final List<TimeOfDay> unavailableStartTimes;
  final List<TimeOfDay> unavailableEndTimes;

  const CalendlyTimeRangePicker({
    super.key,
    this.startTime,
    this.endTime,
    required this.onTimeRangeChanged,
    this.enabled = true,
    this.unavailableStartTimes = const [],
    this.unavailableEndTimes = const [],
  });

  @override
  State<CalendlyTimeRangePicker> createState() => _CalendlyTimeRangePickerState();
}

class _CalendlyTimeRangePickerState extends State<CalendlyTimeRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  @override
  void didUpdateWidget(CalendlyTimeRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _startTime = widget.startTime;
    }
    if (widget.endTime != oldWidget.endTime) {
      _endTime = widget.endTime;
    }
  }

  List<TimeOfDay> _getUnavailableEndTimes() {
    final unavailable = List<TimeOfDay>.from(widget.unavailableEndTimes);
    
    // If start time is selected, make all times before or equal to start time unavailable
    if (_startTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      
      for (int hour = 6; hour <= 23; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          final timeMinutes = hour * 60 + minute;
          if (timeMinutes <= startMinutes) {
            unavailable.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }
    }
    
    return unavailable;
  }

  List<TimeOfDay> _getUnavailableStartTimes() {
    final unavailable = List<TimeOfDay>.from(widget.unavailableStartTimes);
    
    // If end time is selected, make all times after or equal to end time unavailable
    if (_endTime != null) {
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      
      for (int hour = 6; hour <= 23; hour++) {
        for (int minute = 0; minute < 60; minute += 15) {
          final timeMinutes = hour * 60 + minute;
          if (timeMinutes >= endMinutes) {
            unavailable.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }
    }
    
    return unavailable;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('CalendlyTimeRangePicker', data: {
      'enabled': widget.enabled,
      'hasStartTime': _startTime != null,
      'hasEndTime': _endTime != null,
    });

    return Row(
      children: [
        Expanded(
          child: CalendlyTimePicker(
            initialTime: _startTime,
            label: 'Start Time',
            enabled: widget.enabled,
            unavailableTimes: _getUnavailableStartTimes(),
            onTimeChanged: (time) {
              setState(() {
                _startTime = time;
                // Clear end time if it's now invalid
                if (_endTime != null && time != null) {
                  final startMinutes = time.hour * 60 + time.minute;
                  final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
                  if (endMinutes <= startMinutes) {
                    _endTime = null;
                  }
                }
              });
              widget.onTimeRangeChanged(_startTime, _endTime);
            },
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          '-',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CalendlyTimePicker(
            initialTime: _endTime,
            label: 'End Time',
            enabled: widget.enabled,
            unavailableTimes: _getUnavailableEndTimes(),
            onTimeChanged: (time) {
              setState(() {
                _endTime = time;
              });
              widget.onTimeRangeChanged(_startTime, _endTime);
            },
          ),
        ),
      ],
    );
  }
}
