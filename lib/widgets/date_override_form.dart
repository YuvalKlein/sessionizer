import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/models/schedule.dart';

class DateOverrideForm extends StatefulWidget {
  final String scheduleId;

  const DateOverrideForm({super.key, required this.scheduleId});

  @override
  State<DateOverrideForm> createState() => _DateOverrideFormState();
}

class _DateOverrideFormState extends State<DateOverrideForm> {
  final Map<String, List<Map<String, String>>> _specificDateOverrides = {};
  DateTime? _selectedDate;
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  List<Map<String, String>> _currentTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final schedule = await context.read<ScheduleService>().getSchedule(widget.scheduleId);
      if (schedule?.specificDateAvailability != null) {
        setState(() {
          _specificDateOverrides.addAll(
            Map<String, List<Map<String, String>>>.from(
              schedule!.specificDateAvailability!.map(
                (key, value) => MapEntry(
                  key,
                  List<Map<String, String>>.from(
                    (value as List).map((item) => Map<String, String>.from(item)),
                  ),
                ),
              ),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading specific date availability: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select the date(s) you want to\nassign specific hours',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Calendar
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildCalendarHeader(),
                    const SizedBox(height: 24),
                    _buildCalendar(),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 32),
                      _buildTimeSlotSection(),
                      const SizedBox(height: 100), // Extra space for buttons
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            if (_selectedDate != null)
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveOverrides,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left, color: Colors.grey),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right, color: Color(0xFF4285F4)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        
        // Calendar grid
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    final weeks = <List<int?>>[];
    var currentWeek = <int?>[];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      currentWeek.add(null);
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <int?>[];
      }
    }

    // Add empty cells for remaining days
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    if (currentWeek.any((day) => day != null)) {
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Row(
          children: week.map((day) {
            if (day == null) {
              return const Expanded(child: SizedBox(height: 48));
            }

            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isToday = _isSameDay(date, DateTime.now());
            final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
            final hasOverride = _hasDateOverride(date);
            final isPastDate = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

            return Expanded(
              child: GestureDetector(
                onTap: isPastDate ? null : () {
                  setState(() {
                    _selectedDate = date;
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    _currentTimeSlots = List.from(_specificDateOverrides[dateKey] ?? []);
                  });
                },
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4285F4)
                        : hasOverride 
                            ? const Color(0xFF4285F4).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected || hasOverride ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected 
                                ? Colors.white
                                : isPastDate 
                                    ? Colors.grey[400]
                                    : hasOverride 
                                        ? const Color(0xFF4285F4)
                                        : Colors.black87,
                          ),
                        ),
                        if (hasOverride && !isSelected)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4285F4),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What hours are you available?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Time slots
        ..._currentTimeSlots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${slot['startTime']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('-', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${slot['endTime']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentTimeSlots.removeAt(index);
                      // Immediately save the current time slots to the overrides map
                      if (_selectedDate != null) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                        if (_currentTimeSlots.isEmpty) {
                          _specificDateOverrides.remove(dateKey);
                        } else {
                          _specificDateOverrides[dateKey] = List.from(_currentTimeSlots);
                        }
                      }
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
        
        // Add time slot button
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addTimeSlot,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add time slot'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _hasDateOverride(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _specificDateOverrides.containsKey(dateKey) &&
           (_specificDateOverrides[dateKey]?.isNotEmpty ?? false);
  }

  Future<void> _addTimeSlot() async {
    final timeSlot = await _pickTimeRange(context);
    if (timeSlot != null) {
      setState(() {
        _currentTimeSlots.add(timeSlot);
        _currentTimeSlots.sort((a, b) => a['startTime']!.compareTo(b['startTime']!));
        // Immediately save the current time slots to the overrides map
        if (_selectedDate != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          _specificDateOverrides[dateKey] = List.from(_currentTimeSlots);
        }
      });
    }
  }

  Future<Map<String, String>?> _pickTimeRange(BuildContext context) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (startTime == null) return null;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
    );
    if (endTime == null) return null;

    return {
      'startTime': startTime.format(context),
      'endTime': endTime.format(context),
    };
  }

  Future<void> _saveOverrides() async {
    // Save the current date's time slots if there's a selected date
    if (_selectedDate != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      if (_currentTimeSlots.isNotEmpty) {
        _specificDateOverrides[dateKey] = List.from(_currentTimeSlots);
      } else {
        _specificDateOverrides.remove(dateKey);
      }
    }

    try {
      // Get current schedule
      final schedule = await context.read<ScheduleService>().getSchedule(widget.scheduleId);
      if (schedule != null) {
        // Update the schedule with new specific date availability
        final updatedSchedule = Schedule(
          id: schedule.id,
          instructorId: schedule.instructorId,
          name: schedule.name,
          isDefault: schedule.isDefault,
          timezone: schedule.timezone,
          weeklyAvailability: schedule.weeklyAvailability,
          specificDateAvailability: _specificDateOverrides,
          holidays: schedule.holidays,
        );

        await context.read<ScheduleService>().updateSchedule(
          widget.scheduleId,
          updatedSchedule.toMap(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Specific dates updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dates: $e')),
        );
      }
    }
  }
}