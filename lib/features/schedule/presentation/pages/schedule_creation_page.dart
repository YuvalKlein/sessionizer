import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_state.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/core/utils/logger.dart';

class ScheduleCreationPage extends StatefulWidget {
  final ScheduleEntity? existingSchedule;
  final bool isEdit;
  
  const ScheduleCreationPage({
    super.key,
    this.existingSchedule,
    this.isEdit = false,
  });

  @override
  State<ScheduleCreationPage> createState() => _ScheduleCreationPageState();
}

class _ScheduleCreationPageState extends State<ScheduleCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'America/New_York');
  bool _isDefault = false;
  bool _isLoading = false;

  // Weekly availability - 7 days, each with multiple time ranges
  final Map<String, List<Map<String, TimeOfDay?>>> _weeklyAvailability = {
    'monday': [{'start': null, 'end': null}],
    'tuesday': [{'start': null, 'end': null}],
    'wednesday': [{'start': null, 'end': null}],
    'thursday': [{'start': null, 'end': null}],
    'friday': [{'start': null, 'end': null}],
    'saturday': [{'start': null, 'end': null}],
    'sunday': [{'start': null, 'end': null}],
  };

  // Specific date availability - overrides for specific dates
  final Map<String, Map<String, dynamic>> _specificDateAvailability = {};

  // Holidays - dates when instructor is unavailable
  final Map<String, String> _holidays = {}; // date -> reason

  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('ScheduleCreationPage', data: {'action': 'initState', 'isEdit': widget.isEdit});
    _setDefaultTimes();
    if (widget.isEdit && widget.existingSchedule != null) {
      _populateForm();
    }
  }

  void _setDefaultTimes() {
    // Set default times for Monday to Friday (9 AM - 5 PM)
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    for (final day in weekdays) {
      _weeklyAvailability[day]![0]['start'] = const TimeOfDay(hour: 9, minute: 0);
      _weeklyAvailability[day]![0]['end'] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  void _populateForm() {
    if (widget.existingSchedule == null) return;
    
    final schedule = widget.existingSchedule!;
    _nameController.text = schedule.name;
    _timezoneController.text = schedule.timezone;
    _isDefault = schedule.isDefault;
    
    // Populate weekly availability
    if (schedule.weeklyAvailability != null) {
      for (final entry in schedule.weeklyAvailability!.entries) {
        final day = entry.key;
        final dayRanges = entry.value;
        
        if (dayRanges.isNotEmpty) {
          _weeklyAvailability[day] = dayRanges.map((range) => {
            'start': _parseTimeOfDay(range['start']),
            'end': _parseTimeOfDay(range['end']),
          }).toList();
        }
      }
    }
    
    // Populate specific date availability
    if (schedule.specificDateAvailability != null) {
      for (final entry in schedule.specificDateAvailability!.entries) {
        final date = entry.key;
        final dayData = entry.value;
        
        if (dayData['unavailable'] == true) {
          _specificDateAvailability[date] = {'unavailable': true};
        } else if (dayData['start'] != null && dayData['end'] != null) {
          _specificDateAvailability[date] = {
            'start': _parseTimeOfDay(dayData['start']),
            'end': _parseTimeOfDay(dayData['end']),
          };
        }
      }
    }
    
    // Populate holidays
    if (schedule.holidays != null) {
      _holidays.addAll(schedule.holidays!);
    }
  }

  TimeOfDay? _parseTimeOfDay(dynamic timeString) {
    if (timeString == null || timeString is! String) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Invalid time format
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('ScheduleCreationPage', data: {'action': 'build'});

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Schedule' : 'Create Schedule'),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/schedule');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: BlocListener<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
            // Redirect to schedules list instead of just popping
            context.go('/schedule');
          } else if (state is ScheduleError) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state is ScheduleLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildWeeklyAvailabilitySection(),
                const SizedBox(height: 24),
                _buildSpecificDateAvailabilitySection(),
                const SizedBox(height: 24),
                _buildHolidaysSection(),
                const SizedBox(height: 24),
                _buildDefaultScheduleSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Schedule Name',
                hintText: 'e.g., Regular Schedule, Holiday Schedule',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a schedule name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timezoneController,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                hintText: 'e.g., UTC, America/New_York',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a timezone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Weekly hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Set when you are typically available for meetings',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ..._weeklyAvailability.keys.map((day) => _buildDayAvailability(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAvailability(String day) {
    final dayRanges = _weeklyAvailability[day]!;
    final dayLetter = _getDayLetter(day);
    final dayName = _capitalizeFirst(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Day letter icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    dayLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Day name
              Expanded(
                flex: 2,
                child: Text(
                  dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              // Time ranges
              Expanded(
                flex: 4,
                child: Column(
                  children: dayRanges.asMap().entries.map((entry) {
                    final index = entry.key;
                    final range = entry.value;
                    final isEnabled = range['start'] != null && range['end'] != null;
                    final isFirstSlot = index == 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          // Time range display (clickable for editing)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editTimeRange(day, index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                  color: isEnabled ? Colors.white : Colors.grey[50],
                                ),
                                child: isEnabled
                                    ? Text(
                                        '${_formatTimeOfDay(range['start']!)} - ${_formatTimeOfDay(range['end']!)}',
                                        style: const TextStyle(fontSize: 14),
                                      )
                                    : const Text(
                                        'Click to set times',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action icons in order: X, +, duplicate
                          IconButton(
                            onPressed: () => _removeTimeRange(day, index),
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            onPressed: () => _addTimeRange(day),
                            icon: const Icon(Icons.add, size: 16),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          // Duplicate icon only on the first time slot
                          if (isFirstSlot)
                            IconButton(
                              onPressed: () => _showDuplicateDialog(day),
                              icon: const Icon(Icons.copy, size: 16),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                              tooltip: 'Duplicate all times for this day',
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDefaultScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set this as your default schedule. Only one schedule can be default at a time.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as default schedule'),
              subtitle: const Text('This will be used for new bookings'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDateAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Specific Date Availability',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addSpecificDate,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Specific Date',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Override your regular schedule for specific dates (e.g., holidays, special events).',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (_specificDateAvailability.isEmpty)
              const Center(
                child: Text(
                  'No specific dates added yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._specificDateAvailability.entries.map((entry) => 
                _buildSpecificDateCard(entry.key, entry.value)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificDateCard(String date, Map<String, dynamic> dayData) {
    final isUnavailable = dayData['unavailable'] == true;
    final startTime = dayData['start'] as TimeOfDay?;
    final endTime = dayData['end'] as TimeOfDay?;
    final isEnabled = startTime != null && endTime != null;
    
    String timeString;
    Color timeColor;
    
    if (isUnavailable) {
      timeString = 'Unavailable';
      timeColor = Colors.red[600]!;
    } else if (isEnabled) {
      timeString = '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';
      timeColor = Colors.grey[600]!;
    } else {
      timeString = 'No times set';
      timeColor = Colors.grey[400]!;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              timeString,
              style: TextStyle(
                color: timeColor,
                fontSize: 14,
                fontWeight: isUnavailable ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeSpecificDate(date),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remove Date',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Holidays & Unavailable Dates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addHoliday,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Holiday',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Mark dates when you are completely unavailable (holidays, personal time, etc.).',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (_holidays.isEmpty)
              const Center(
                child: Text(
                  'No holidays added yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._holidays.entries.map((entry) => _buildHolidayCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayCard(String date, String reason) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.event_busy, color: Colors.red),
        title: Text(_formatDate(date)),
        subtitle: Text(reason),
        trailing: IconButton(
          onPressed: () => _removeHoliday(date),
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Remove Holiday',
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSchedule,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Schedule...'),
                ],
              )
            : Text(
                widget.isEdit ? 'Update Schedule' : 'Create Schedule',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  String _getDayLetter(String day) {
    switch (day.toLowerCase()) {
      case 'sunday': return 'S';
      case 'monday': return 'M';
      case 'tuesday': return 'T';
      case 'wednesday': return 'W';
      case 'thursday': return 'T';
      case 'friday': return 'F';
      case 'saturday': return 'S';
      default: return day[0].toUpperCase();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute$period';
  }

  void _addTimeRange(String day) {
    setState(() {
      final dayRanges = _weeklyAvailability[day]!;
      
      // Find the latest end time from existing ranges
      TimeOfDay? latestEndTime;
      for (final range in dayRanges) {
        if (range['end'] != null) {
          final endTime = range['end'] as TimeOfDay;
          if (latestEndTime == null || endTime.hour > latestEndTime.hour || 
              (endTime.hour == latestEndTime.hour && endTime.minute > latestEndTime.minute)) {
            latestEndTime = endTime;
          }
        }
      }
      
      // Calculate new start time (1 hour after latest end time, or 9 AM if no existing times)
      TimeOfDay newStartTime;
      if (latestEndTime != null) {
        final newHour = latestEndTime.hour + 1;
        newStartTime = TimeOfDay(hour: newHour > 23 ? 23 : newHour, minute: latestEndTime.minute);
      } else {
        newStartTime = const TimeOfDay(hour: 9, minute: 0);
      }
      
      // Calculate new end time (1 hour after start time)
      final newEndTime = TimeOfDay(
        hour: (newStartTime.hour + 1) > 23 ? 23 : (newStartTime.hour + 1),
        minute: newStartTime.minute,
      );
      
      // Add the new time range with calculated times
      dayRanges.add({
        'start': newStartTime,
        'end': newEndTime,
      });
    });
  }

  void _removeTimeRange(String day, int index) {
    setState(() {
      _weeklyAvailability[day]!.removeAt(index);
      // If no time ranges left, add an empty one
      if (_weeklyAvailability[day]!.isEmpty) {
        _weeklyAvailability[day]!.add({'start': null, 'end': null});
      }
    });
  }

  void _editTimeRange(String day, int index) async {
    final range = _weeklyAvailability[day]![index];
    
    // Show start time picker
    final startTime = await showTimePicker(
      context: context,
      initialTime: range['start'] ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (startTime != null && mounted) {
      // Show end time picker
      final endTime = await showTimePicker(
        context: context,
        initialTime: range['end'] ?? const TimeOfDay(hour: 17, minute: 0),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );
      
      if (endTime != null) {
        // Check for overlaps with other time ranges on the same day
        if (_hasTimeOverlap(day, index, startTime, endTime)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Time ranges cannot overlap on the same day'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() {
          range['start'] = startTime;
          range['end'] = endTime;
        });
      }
    }
  }

  bool _hasTimeOverlap(String day, int currentIndex, TimeOfDay startTime, TimeOfDay endTime) {
    final dayRanges = _weeklyAvailability[day]!;
    
    for (int i = 0; i < dayRanges.length; i++) {
      if (i == currentIndex) continue; // Skip the current range being edited
      
      final range = dayRanges[i];
      final existingStart = range['start'];
      final existingEnd = range['end'];
      
      if (existingStart != null && existingEnd != null) {
        // Check if the new time range overlaps with this existing range
        if (_timeRangesOverlap(startTime, endTime, existingStart, existingEnd)) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _timeRangesOverlap(TimeOfDay start1, TimeOfDay end1, TimeOfDay start2, TimeOfDay end2) {
    // Convert to minutes for easier comparison
    final start1Minutes = start1.hour * 60 + start1.minute;
    final end1Minutes = end1.hour * 60 + end1.minute;
    final start2Minutes = start2.hour * 60 + start2.minute;
    final end2Minutes = end2.hour * 60 + end2.minute;
    
    // Two ranges overlap if one starts before the other ends
    return start1Minutes < end2Minutes && start2Minutes < end1Minutes;
  }

  void _showDuplicateDialog(String sourceDay) {
    final selectedDays = <String>{sourceDay};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('COPY TIMES TO...'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Fixed height to prevent overflow
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _weeklyAvailability.keys.map((day) {
                  final isSourceDay = day == sourceDay;
                  return CheckboxListTile(
                    title: Text(_capitalizeFirst(day)),
                    value: selectedDays.contains(day),
                    onChanged: isSourceDay ? null : (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                    enabled: !isSourceDay,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _duplicateDayTimes(sourceDay, selectedDays.toList());
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateDayTimes(String sourceDay, List<String> targetDays) {
    final sourceRanges = List<Map<String, TimeOfDay?>>.from(_weeklyAvailability[sourceDay]!);
    
    setState(() {
      for (final targetDay in targetDays) {
        if (targetDay != sourceDay) {
          // Clear existing time ranges for target day
          _weeklyAvailability[targetDay]!.clear();
          // Copy all time ranges from source day
          for (final range in sourceRanges) {
            _weeklyAvailability[targetDay]!.add({
              'start': range['start'],
              'end': range['end'],
            });
          }
        }
      }
    });
  }


  void _addSpecificDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final dateString = _dateToString(date);
      final dayOfWeek = _getDayOfWeek(date.weekday);
      
      // Get weekly hours for this day of the week
      final weeklyHours = _weeklyAvailability[dayOfWeek] ?? [];
      final prePopulatedTimes = <Map<String, TimeOfDay?>>[];
      
      // Pre-populate with weekly hours if available
      for (final range in weeklyHours) {
        if (range['start'] != null && range['end'] != null) {
          prePopulatedTimes.add({
            'start': range['start'],
            'end': range['end'],
          });
        }
      }
      
      // If no weekly hours, add one empty slot
      if (prePopulatedTimes.isEmpty) {
        prePopulatedTimes.add({'start': null, 'end': null});
      }
      
      // Show dialog with date picker and time slots combined
      _showSpecificDateDialog(dateString, prePopulatedTimes);
    }
  }

  void _removeSpecificDate(String date) {
    setState(() {
      // Instead of removing, mark as unavailable
      _specificDateAvailability[date] = {
        'start': null,
        'end': null,
        'unavailable': true,
      };
    });
  }

  String _getDayOfWeek(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  void _showSpecificDateDialog(String dateString, List<Map<String, TimeOfDay?>> initialTimes) {
    final times = List<Map<String, TimeOfDay?>>.from(initialTimes);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Specific Hours'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(dateString),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What hours are you available?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Time slots (using same widgets as weekly hours)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: times.asMap().entries.map((entry) {
                        final index = entry.key;
                        final timeRange = entry.value;
                        final isEnabled = timeRange['start'] != null && timeRange['end'] != null;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Time range display (clickable for editing)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _editSpecificDateTimeRange(times, index, setDialogState),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                      color: isEnabled ? Colors.white : Colors.grey[50],
                                    ),
                                    child: isEnabled
                                        ? Text(
                                            '${_formatTimeOfDay(timeRange['start']!)} - ${_formatTimeOfDay(timeRange['end']!)}',
                                            style: const TextStyle(fontSize: 14),
                                          )
                                        : const Text(
                                            'Click to set times',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action icons - only show + on first row
                              if (index == 0)
                                IconButton(
                                  onPressed: () => _addSpecificDateTimeRange(times, setDialogState),
                                  icon: const Icon(Icons.add, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              IconButton(
                                onPressed: () => _removeSpecificDateTimeRange(times, index, setDialogState),
                                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save the times to specific date availability
                setState(() {
                  _specificDateAvailability[dateString] = times.isNotEmpty 
                      ? times.first 
                      : {'start': null, 'end': null};
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _editSpecificDateTimeRange(List<Map<String, TimeOfDay?>> times, int index, StateSetter setDialogState) async {
    final timeRange = times[index];
    final startTime = await showTimePicker(
      context: context,
      initialTime: timeRange['start'] ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime != null && mounted) {
      final endTime = await showTimePicker(
        context: context,
        initialTime: timeRange['end'] ?? const TimeOfDay(hour: 17, minute: 0),
      );
      if (endTime != null) {
        setDialogState(() {
          timeRange['start'] = startTime;
          timeRange['end'] = endTime;
        });
      }
    }
  }

  void _addSpecificDateTimeRange(List<Map<String, TimeOfDay?>> times, StateSetter setDialogState) {
    setDialogState(() {
      // Find the latest end time to add one hour later
      TimeOfDay? latestEndTime;
      for (final range in times) {
        if (range['end'] != null) {
          final endTime = range['end'] as TimeOfDay;
          if (latestEndTime == null || endTime.hour > latestEndTime.hour || 
              (endTime.hour == latestEndTime.hour && endTime.minute > latestEndTime.minute)) {
            latestEndTime = endTime;
          }
        }
      }
      
      TimeOfDay newStartTime;
      if (latestEndTime != null) {
        final newHour = latestEndTime.hour + 1;
        newStartTime = TimeOfDay(hour: newHour > 23 ? 23 : newHour, minute: latestEndTime.minute);
      } else {
        newStartTime = const TimeOfDay(hour: 9, minute: 0);
      }
      
      final newEndTime = TimeOfDay(
        hour: (newStartTime.hour + 1) > 23 ? 23 : (newStartTime.hour + 1),
        minute: newStartTime.minute,
      );
      
      times.add({
        'start': newStartTime,
        'end': newEndTime,
      });
    });
  }

  void _removeSpecificDateTimeRange(List<Map<String, TimeOfDay?>> times, int index, StateSetter setDialogState) {
    setDialogState(() {
      times.removeAt(index);
      if (times.isEmpty) {
        times.add({'start': null, 'end': null});
      }
    });
  }


  void _addHoliday() async {
    // Show dialog to choose between single date or date range
    final isRange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holiday'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose holiday type:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Single Date'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    
    if (isRange == null) return;
    
    if (isRange) {
      // Date range selection
      final startDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      
      if (startDate != null && mounted) {
        final endDate = await showDatePicker(
          context: context,
          initialDate: startDate,
          firstDate: startDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        if (endDate != null && mounted) {
          final reason = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Add Holiday Range'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('From: ${_formatDate(_dateToString(startDate))}'),
                    Text('To: ${_formatDate(_dateToString(endDate))}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                        hintText: 'e.g., Christmas Break, Vacation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                    child: const Text('Add Range'),
                  ),
                ],
              );
            },
          );
          
          if (reason != null) {
            setState(() {
              // Add all dates in the range
              final days = endDate.difference(startDate).inDays + 1;
              for (int i = 0; i < days; i++) {
                final date = startDate.add(Duration(days: i));
                final dateString = _dateToString(date);
                _holidays[dateString] = reason.isEmpty ? 'Holiday' : reason;
              }
            });
          }
        }
      }
    } else {
      // Single date selection
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      
      if (date != null && mounted) {
        final dateString = _dateToString(date);
        
        final reason = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Add Holiday'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Date: ${_formatDate(dateString)}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'e.g., Christmas, Personal Day',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
        
        if (reason != null) {
          setState(() {
            _holidays[dateString] = reason.isEmpty ? 'Holiday' : reason;
          });
        }
      }
    }
  }

  void _removeHoliday(String date) {
    setState(() {
      _holidays.remove(date);
    });
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(String dateString) {
    final parts = dateString.split('-');
    if (parts.length == 3) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      return '${date.day}/${date.month}/${date.year}';
    }
    return dateString;
  }

  void _saveSchedule() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Prepare weekly availability data
    final weeklyAvailability = <String, List<Map<String, String>>>{};
    for (final entry in _weeklyAvailability.entries) {
      final day = entry.key;
      final dayRanges = entry.value;
      
      final validRanges = <Map<String, String>>[];
      for (final range in dayRanges) {
        if (range['start'] != null && range['end'] != null) {
          validRanges.add({
            'start': '${range['start']!.hour.toString().padLeft(2, '0')}:${range['start']!.minute.toString().padLeft(2, '0')}',
            'end': '${range['end']!.hour.toString().padLeft(2, '0')}:${range['end']!.minute.toString().padLeft(2, '0')}',
          });
        }
      }
      
      if (validRanges.isNotEmpty) {
        weeklyAvailability[day] = validRanges;
      }
    }

    // Prepare specific date availability data
    final specificDateAvailability = <String, Map<String, dynamic>>{};
    for (final entry in _specificDateAvailability.entries) {
      final date = entry.key;
      final dayData = entry.value;
      
      if (dayData['unavailable'] == true) {
        // Mark as unavailable
        specificDateAvailability[date] = {'unavailable': true};
      } else if (dayData['start'] != null && dayData['end'] != null) {
        // Mark as available with specific times
        specificDateAvailability[date] = {
          'start': '${dayData['start']!.hour.toString().padLeft(2, '0')}:${dayData['start']!.minute.toString().padLeft(2, '0')}',
          'end': '${dayData['end']!.hour.toString().padLeft(2, '0')}:${dayData['end']!.minute.toString().padLeft(2, '0')}',
        };
      }
    }

    // Prepare holidays data
    final holidays = <String, String>{};
    for (final entry in _holidays.entries) {
      holidays[entry.key] = entry.value;
    }

    // Create or update schedule entity
    final schedule = ScheduleEntity(
      id: widget.isEdit && widget.existingSchedule != null 
          ? widget.existingSchedule!.id 
          : '', // Will be generated by the backend for new schedules
      instructorId: authState.user.id,
      name: _nameController.text.trim(),
      isDefault: _isDefault,
      timezone: _timezoneController.text.trim(),
      weeklyAvailability: weeklyAvailability.isNotEmpty ? weeklyAvailability : null,
      specificDateAvailability: specificDateAvailability.isNotEmpty ? specificDateAvailability : null,
      holidays: holidays.isNotEmpty ? holidays : null,
    );

    // Create or update schedule
    if (widget.isEdit && widget.existingSchedule != null) {
      context.read<ScheduleBloc>().add(UpdateScheduleEvent(schedule: schedule));
      AppLogger.blocEvent('ScheduleBloc', 'UpdateScheduleEvent', data: {'scheduleName': schedule.name});
    } else {
      context.read<ScheduleBloc>().add(CreateScheduleEvent(schedule: schedule));
      AppLogger.blocEvent('ScheduleBloc', 'CreateScheduleEvent', data: {'scheduleName': schedule.name});
    }
    
    // If this schedule is set as default, unset all other schedules as default
    if (_isDefault) {
      context.read<ScheduleBloc>().add(UnsetAllDefaultSchedules());
      AppLogger.blocEvent('ScheduleBloc', 'UnsetAllDefaultSchedules', data: {'reason': 'Default schedule ${widget.isEdit ? 'updated' : 'created'}'});
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
