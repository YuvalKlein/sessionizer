import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/schedule_service.dart';

class SchedulesListScreen extends StatelessWidget {
  final String instructorId;
  const SchedulesListScreen({super.key, required this.instructorId});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final scheduleService = context.watch<ScheduleService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Schedules')),
      body: StreamBuilder<QuerySnapshot>(
        stream: scheduleService.getSchedulesStream(instructorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading schedules.'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          final schedules = snapshot.data!.docs
              .map((doc) => Schedule.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return _ScheduleCard(schedule: schedules[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/instructor/schedules/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No Schedules Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to create your first availability schedule.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/instructor/schedules/${schedule.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    schedule.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (schedule.isDefault)
                    Chip(
                      label: const Text('Default'),
                      avatar: const Icon(Icons.star, size: 16),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                schedule.availableDays, // Use the new getter directly
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (schedule.availabilitySummary.isNotEmpty)
                Text(
                  schedule.availabilitySummary,
                ), // Use the new summary getter

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.green),
                    onPressed: () => _duplicateSchedule(context, schedule),
                    tooltip: 'Duplicate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, schedule),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The _getDaysSummary function is no longer needed and has been removed.

  Future<void> _duplicateSchedule(BuildContext context, Schedule schedule) async {
    try {
      await context.read<ScheduleService>().duplicateSchedule(schedule.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule duplicated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating schedule: $e')),
      );
    }
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
