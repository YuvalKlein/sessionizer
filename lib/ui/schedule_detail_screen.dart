import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/models/availability_override.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/widgets/date_override_form.dart';
import 'package:intl/intl.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final String scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();

    return StreamBuilder<DocumentSnapshot>(
      stream: scheduleService.getScheduleStream(scheduleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Error loading schedule.')),
          );
        }

        final schedule = Schedule.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text(schedule.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.go('/instructor/schedules/${schedule.id}/edit'),
                tooltip: 'Edit Schedule',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, schedule),
                tooltip: 'Delete Schedule',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _CoreDetailsCard(schedule: schedule),
              const SizedBox(height: 16),
              _WeeklyHoursCard(schedule: schedule),
              const SizedBox(height: 16),
              _DateOverridesCard(schedule: schedule),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Schedule schedule) async {
    if (schedule.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the default schedule.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<ScheduleService>().deleteSchedule(schedule.id);
        context.pop(); // Go back after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting schedule: $e')));
      }
    }
  }
}

class _CoreDetailsCard extends StatelessWidget {
  final Schedule schedule;
  const _CoreDetailsCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Core Details', style: theme.textTheme.titleLarge),
            const Divider(height: 20),
            SwitchListTile(
              title: const Text('Default Schedule'),
              subtitle: const Text('This is your main schedule'),
              value: schedule.isDefault,
              onChanged: (isDefault) => _toggleDefault(context, isDefault),
              secondary: const Icon(Icons.star),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Timezone'),
              subtitle: Text(schedule.timezone),
              onTap: () =>
                  context.go('/instructor/schedules/${schedule.id}/timezone'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDefault(BuildContext context, bool isDefault) async {
    final scheduleService = context.read<ScheduleService>();
    try {
      await scheduleService.setDefaultSchedule(
        schedule.instructorId,
        schedule.id,
        isDefault,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default schedule updated.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating default: $e')));
    }
  }
}

class _WeeklyHoursCard extends StatelessWidget {
  final Schedule schedule;
  const _WeeklyHoursCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Hours', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () =>
                      context.go('/instructor/schedules/${schedule.id}/hours'),
                ),
              ],
            ),
            const Divider(height: 20),
            for (var day in [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ])
              _buildDayRow(theme, day, schedule.availableDays.contains(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(ThemeData theme, String day, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(day, style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: Text(
              isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(color: isAvailable ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateOverridesCard extends StatelessWidget {
  final Schedule schedule;
  const _DateOverridesCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleService = context.watch<ScheduleService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date Overrides', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddOverrideDialog(context, schedule.id),
                ),
              ],
            ),
            const Divider(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: scheduleService.getOverridesStream(schedule.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No overrides defined.'));
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final override = AvailabilityOverride.fromFirestore(doc);
                    return _buildOverrideTile(context, theme, override);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverrideTile(
    BuildContext context,
    ThemeData theme,
    AvailabilityOverride override,
  ) {
    final isExclusion = override.type == OverrideType.exclusion;
    String dateRange = DateFormat.yMMMd().format(override.startDate);
    if (override.startDate != override.endDate) {
      dateRange += ' - ${DateFormat.yMMMd().format(override.endDate)}';
    }

    return ListTile(
      title: Text(dateRange),
      subtitle: Text(
        isExclusion
            ? 'Unavailable'
            : 'Available: ${override.timeSlots.map((s) => '${s["startTime"]}-${s["endTime"]}').join(', ')}',
        style: TextStyle(color: isExclusion ? Colors.red : Colors.green),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                _showEditOverrideDialog(context, schedule.id, override),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteOverride(context, override.id),
          ),
        ],
      ),
    );
  }

  void _showAddOverrideDialog(BuildContext context, String scheduleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Override'),
        content: DateOverrideForm(
          onSubmit: (newOverride) {
            final scheduleService = context.read<ScheduleService>();
            final overrideWithId = AvailabilityOverride(
              id: '',
              scheduleId: scheduleId,
              startDate: newOverride.startDate,
              endDate: newOverride.endDate,
              type: newOverride.type,
              timeSlots: newOverride.timeSlots,
            );
            scheduleService.createOverride(overrideWithId.toMap());
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _showEditOverrideDialog(
    BuildContext context,
    String scheduleId,
    AvailabilityOverride override,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Override'),
        content: DateOverrideForm(
          override: override,
          onSubmit: (updatedOverride) {
            final scheduleService = context.read<ScheduleService>();
            scheduleService.updateOverride(
                override.id, updatedOverride.toMap());
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  Future<void> _deleteOverride(BuildContext context, String overrideId) async {
    try {
      await context.read<ScheduleService>().deleteOverride(overrideId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Override deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting override: $e')));
    }
  }
}
