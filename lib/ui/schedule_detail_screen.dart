import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/ui/widgets/weekly_hours_form.dart';
import 'package:myapp/widgets/date_override_form.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  Schedule? _schedule;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await context.read<ScheduleService>().getSchedule(widget.scheduleId);
      if (schedule != null) {
        setState(() {
          _schedule = schedule;
          _nameController.text = schedule.name;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Details')),
        body: const Center(child: Text('Schedule not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Settings'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNameAndDefaultSection(),
          const SizedBox(height: 24),
          _buildAvailabilitySection(),
        ],
      ),
    );
  }

  Widget _buildNameAndDefaultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SwitchListTile(
                    title: const Text('Default'),
                    subtitle: const Text('Use for new bookings'),
                    value: _schedule!.isDefault,
                    onChanged: (value) {
                      setState(() {
                        _schedule = Schedule(
                          id: _schedule!.id,
                          instructorId: _schedule!.instructorId,
                          name: _schedule!.name,
                          isDefault: value,
                          timezone: _schedule!.timezone,
                          weeklyAvailability: _schedule!.weeklyAvailability,
                          specificDateAvailability: _schedule!.specificDateAvailability,
                          holidays: _schedule!.holidays,
                        );
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _AvailabilityOption(
              icon: Icons.schedule,
              title: 'Weekly Hours',
              subtitle: 'Set your regular weekly availability',
              onTap: () => _showWeeklyHours(),
            ),
            const Divider(),
            _AvailabilityOption(
              icon: Icons.calendar_today,
              title: 'Specific Dates',
              subtitle: 'Override availability for specific dates',
              onTap: () => _showSpecificDates(),
            ),
            const Divider(),
            _AvailabilityOption(
              icon: Icons.beach_access,
              title: 'Holidays',
              subtitle: 'Mark periods when you are unavailable',
              onTap: () => _showHolidays(),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeeklyHours() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: WeeklyHoursForm(scheduleId: widget.scheduleId),
      ),
    );
  }

  void _showSpecificDates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: DateOverrideForm(scheduleId: widget.scheduleId),
      ),
    );
  }

  void _showHolidays() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: HolidaysForm(scheduleId: widget.scheduleId),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule name cannot be empty')),
      );
      return;
    }

    try {
      final updatedSchedule = Schedule(
        id: _schedule!.id,
        instructorId: _schedule!.instructorId,
        name: _nameController.text.trim(),
        isDefault: _schedule!.isDefault,
        timezone: _schedule!.timezone,
        weeklyAvailability: _schedule!.weeklyAvailability,
        specificDateAvailability: _schedule!.specificDateAvailability,
        holidays: _schedule!.holidays,
      );

      if (_schedule!.isDefault) {
        await context.read<ScheduleService>().setDefaultSchedule(
          _schedule!.instructorId,
          _schedule!.id,
          true,
        );
      }

      await context.read<ScheduleService>().updateSchedule(
        _schedule!.id,
        updatedSchedule.toMap(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule updated successfully')),
      );

      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating schedule: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class _AvailabilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvailabilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class HolidaysForm extends StatefulWidget {
  final String scheduleId;

  const HolidaysForm({super.key, required this.scheduleId});

  @override
  State<HolidaysForm> createState() => _HolidaysFormState();
}

class _HolidaysFormState extends State<HolidaysForm> {
  final List<Map<String, String>> _holidays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays'),
        actions: [
          TextButton(
            onPressed: _saveHolidays,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _holidays.length,
                itemBuilder: (context, index) {
                  final holiday = _holidays[index];
                  return Card(
                    child: ListTile(
                      title: Text(holiday['name'] ?? ''),
                      subtitle: Text(
                        '${holiday['startDate']} - ${holiday['endDate']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _holidays.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addHoliday,
              icon: const Icon(Icons.add),
              label: const Text('Add Holiday'),
            ),
          ],
        ),
      ),
    );
  }

  void _addHoliday() {
    // This would open a dialog to add a new holiday period
    // For now, adding a placeholder
    setState(() {
      _holidays.add({
        'name': 'Holiday ${_holidays.length + 1}',
        'startDate': DateTime.now().toString().split(' ')[0],
        'endDate': DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0],
      });
    });
  }

  void _saveHolidays() {
    // Implementation to save holidays to the schedule
    Navigator.of(context).pop();
  }
}