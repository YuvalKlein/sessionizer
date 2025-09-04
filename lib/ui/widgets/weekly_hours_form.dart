import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/schedule_service.dart';

class WeeklyHoursForm extends StatefulWidget {
  final String scheduleId;

  const WeeklyHoursForm({super.key, required this.scheduleId});

  @override
  State<WeeklyHoursForm> createState() => _WeeklyHoursFormState();
}

class _WeeklyHoursFormState extends State<WeeklyHoursForm> {
  final _days = const [
    'Sunday',
    'Monday', 
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  
  final _dayLabels = const [
    'S',
    'M',
    'T', 
    'W',
    'T',
    'F',
    'S',
  ];
  
  final ValueNotifier<Map<String, List<Map<String, String>>>>
  _weeklyAvailability = ValueNotifier({});
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final schedule = await context.read<ScheduleService>().getSchedule(
        widget.scheduleId,
      );
      if (schedule != null && schedule.weeklyAvailability != null) {
        final initialData = <String, List<Map<String, String>>>{
          for (var day in _days)
            day: List<Map<String, String>>.from(
              schedule.weeklyAvailability![day.toLowerCase()]?.map(
                    (e) => Map<String, String>.from(e),
                  ) ??
                  [],
            ),
        };
        _weeklyAvailability.value = initialData;
      } else {
        // Initialize with empty data for all days
        _weeklyAvailability.value = {
          for (var day in _days) day: <Map<String, String>>[]
        };
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Hours'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Weekly hours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set when you are typically available for meetings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ValueListenableBuilder<Map<String, List<Map<String, String>>>>(
                      valueListenable: _weeklyAvailability,
                      builder: (context, availability, child) {
                        return ListView.builder(
                          itemCount: _days.length,
                          itemBuilder: (context, index) {
                            return _buildDaySection(_days[index], _dayLabels[index], availability);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDaySection(String day, String dayLabel, Map<String, List<Map<String, String>>> availability) {
    final timeSlots = availability[day] ?? [];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          // Day header with first time slot or "Unavailable"
          if (timeSlots.isEmpty)
            _buildDayRow(day, dayLabel, null, 0, isUnavailable: true)
          else
            ...timeSlots.asMap().entries.map((entry) {
              return _buildDayRow(day, dayLabel, entry.value, entry.key);
            }),
        ],
      ),
    );
  }

  Widget _buildDayRow(String day, String dayLabel, Map<String, String>? timeSlot, int index, {bool isUnavailable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // Day label (only show for first slot of each day)
          SizedBox(
            width: 24,
            child: index == 0 ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isUnavailable ? Colors.grey[300] : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    color: isUnavailable ? Colors.grey[600] : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ) : null,
          ),
          const SizedBox(width: 16),
          
          // Time range or "Unavailable"
          if (isUnavailable)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      '${timeSlot!['startTime']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('-', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '${timeSlot['endTime']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Action buttons
          if (!isUnavailable) ...[
            // Delete button
            InkWell(
              onTap: () => _removeSlot(day, index),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ),
          ],
          
          // Add button (always show)
          InkWell(
            onTap: () => _addSlot(day),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, size: 20, color: Colors.grey),
            ),
          ),
          
          // Copy button (only show if there are time slots)
          if (!isUnavailable && index == 0 && (_weeklyAvailability.value[day]?.isNotEmpty ?? false))
            InkWell(
              onTap: () => _showCopyDialog(day),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.copy, size: 20, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showCopyDialog(String sourceDay) {
    final sourceDaySlots = _weeklyAvailability.value[sourceDay] ?? [];
    if (sourceDaySlots.isEmpty) return;

    final selectedDays = <String, bool>{
      for (var day in _days) day: day == sourceDay
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Copy times to...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _days.map((day) {
              return CheckboxListTile(
                title: Text(day),
                value: selectedDays[day],
                onChanged: day == sourceDay ? null : (value) {
                  setDialogState(() {
                    selectedDays[day] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.trailing,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _copyTimesToDays(sourceDay, selectedDays);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTimesToDays(String sourceDay, Map<String, bool> selectedDays) {
    final sourceDaySlots = _weeklyAvailability.value[sourceDay] ?? [];
    final currentAvailability = Map.of(_weeklyAvailability.value);

    for (var entry in selectedDays.entries) {
      if (entry.value && entry.key != sourceDay) {
        currentAvailability[entry.key] = List.from(sourceDaySlots);
      }
    }

    _weeklyAvailability.value = currentAvailability;
  }

  void _updateSlots(String day, Function(List<Map<String, String>>) updateFn) {
    final currentAvailability = Map.of(_weeklyAvailability.value);
    final daySlots = List.of(
      currentAvailability[day] ?? <Map<String, String>>[],
    );
    updateFn(daySlots);
    daySlots.sort((a, b) => a['startTime']!.compareTo(b['startTime']!));
    currentAvailability[day] = daySlots;
    _weeklyAvailability.value = currentAvailability;
  }

  void _addSlot(String day) async {
    final newSlot = await _pickTimeRange(context);
    if (newSlot != null) {
      _updateSlots(day, (slots) => slots.add(newSlot));
    }
  }

  void _removeSlot(String day, int index) {
    _updateSlots(day, (slots) => slots.removeAt(index));
  }

  Future<Map<String, String>?> _pickTimeRange(
    BuildContext context, {
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
  }) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: initialStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null) return null;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime:
          initialEndTime ?? startTime.replacing(hour: startTime.hour + 1),
    );
    if (endTime == null) return null;

    return {
      'startTime': startTime.format(context),
      'endTime': endTime.format(context),
    };
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);
    final scheduleData = _weeklyAvailability.value.map(
      (key, value) => MapEntry(key.toLowerCase(), value),
    );

    try {
      await context.read<ScheduleService>().updateSchedule(widget.scheduleId, {
        'weeklyAvailability': scheduleData,
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly hours updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating hours: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _weeklyAvailability.dispose();
    super.dispose();
  }
}