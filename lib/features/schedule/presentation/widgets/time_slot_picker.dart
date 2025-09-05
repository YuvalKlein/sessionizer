import 'package:flutter/material.dart';
import 'package:myapp/core/utils/logger.dart';

class TimeSlotPicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String label;
  final Function(TimeOfDay?) onTimeChanged;
  final bool enabled;

  const TimeSlotPicker({
    super.key,
    this.initialTime,
    required this.label,
    required this.onTimeChanged,
    this.enabled = true,
  });

  @override
  State<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<TimeSlotPicker> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  void didUpdateWidget(TimeSlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      _selectedTime = widget.initialTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('TimeSlotPicker', data: {
      'label': widget.label,
      'enabled': widget.enabled,
      'hasTime': _selectedTime != null,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled ? _selectTime : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.enabled 
                    ? (_selectedTime != null ? Colors.blue : Colors.grey.shade300)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
              color: widget.enabled 
                  ? (_selectedTime != null ? Colors.blue.shade50 : Colors.white)
                  : Colors.grey.shade100,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: widget.enabled 
                      ? (_selectedTime != null ? Colors.blue : Colors.grey)
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Select time',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.enabled 
                          ? (_selectedTime != null ? Colors.blue.shade700 : Colors.grey)
                          : Colors.grey,
                    ),
                  ),
                ),
                if (widget.enabled && _selectedTime != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedTime = null;
                      });
                      widget.onTimeChanged(null);
                    },
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
      });
      widget.onTimeChanged(selectedTime);
    }
  }
}

class TimeSlotRangePicker extends StatefulWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay? start, TimeOfDay? end) onTimeRangeChanged;
  final bool enabled;

  const TimeSlotRangePicker({
    super.key,
    this.startTime,
    this.endTime,
    required this.onTimeRangeChanged,
    this.enabled = true,
  });

  @override
  State<TimeSlotRangePicker> createState() => _TimeSlotRangePickerState();
}

class _TimeSlotRangePickerState extends State<TimeSlotRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  @override
  void didUpdateWidget(TimeSlotRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _startTime = widget.startTime;
    }
    if (widget.endTime != oldWidget.endTime) {
      _endTime = widget.endTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('TimeSlotRangePicker', data: {
      'enabled': widget.enabled,
      'hasStartTime': _startTime != null,
      'hasEndTime': _endTime != null,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimeSlotPicker(
                initialTime: _startTime,
                label: 'Start Time',
                enabled: widget.enabled,
                onTimeChanged: (time) {
                  setState(() {
                    _startTime = time;
                  });
                  widget.onTimeRangeChanged(_startTime, _endTime);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TimeSlotPicker(
                initialTime: _endTime,
                label: 'End Time',
                enabled: widget.enabled,
                onTimeChanged: (time) {
                  setState(() {
                    _endTime = time;
                  });
                  widget.onTimeRangeChanged(_startTime, _endTime);
                },
              ),
            ),
          ],
        ),
        if (_startTime != null && _endTime != null) ...[
          const SizedBox(height: 8),
          _buildDurationInfo(),
        ],
      ],
    );
  }

  Widget _buildDurationInfo() {
    final duration = _calculateDuration(_startTime!, _endTime!);
    final isValid = duration.inMinutes > 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green.shade700 : Colors.red.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isValid 
                ? 'Duration: ${duration.inHours}h ${duration.inMinutes % 60}m'
                : 'End time must be after start time',
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Duration _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endMinutes - startMinutes;
    return Duration(minutes: durationMinutes);
  }
}
