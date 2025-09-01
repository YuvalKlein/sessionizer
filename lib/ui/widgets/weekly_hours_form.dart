import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/schedule_service.dart';

class WeeklyHoursForm extends StatefulWidget {
  final String scheduleId;

  const WeeklyHoursForm({super.key, required this.scheduleId});

  @override
  State<WeeklyHoursForm> createState() => _WeeklyHoursFormState();
}

class _WeeklyHoursFormState extends State<WeeklyHoursForm>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final ValueNotifier<Map<String, List<Map<String, String>>>>
  _weeklyAvailability = ValueNotifier({});
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
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
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Weekly Hours'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _days.map((day) => _buildDayEditor(day)).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
      ),
    );
  }

  Widget _buildDayEditor(String day) {
    return ValueListenableBuilder<Map<String, List<Map<String, String>>>>(
      valueListenable: _weeklyAvailability,
      builder: (context, availability, child) {
        final slots = availability[day] ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...slots.asMap().entries.map((entry) {
              final index = entry.key;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${slots[index]['startTime']} - ${slots[index]['endTime']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeSlot(day, index),
                  ),
                  onTap: () => _editSlot(day, index),
                ),
              );
            }),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Time Slot'),
              onPressed: () => _addSlot(day),
            ),
          ],
        );
      },
    );
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

  void _editSlot(String day, int index) async {
    final currentSlot = _weeklyAvailability.value[day]![index];
    final editedSlot = await _pickTimeRange(
      context,
      initialStartTime: _parseTime(currentSlot['startTime']!),
      initialEndTime: _parseTime(currentSlot['endTime']!),
    );
    if (editedSlot != null) {
      _updateSlots(day, (slots) => slots[index] = editedSlot);
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

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ').first);
    return TimeOfDay(hour: hour, minute: minute);
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly hours updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating hours: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weeklyAvailability.dispose();
    super.dispose();
  }
}
