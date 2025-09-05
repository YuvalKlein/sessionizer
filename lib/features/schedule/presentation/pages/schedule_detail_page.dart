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

class ScheduleDetailPage extends StatefulWidget {
  final String scheduleId;
  
  const ScheduleDetailPage({
    super.key,
    required this.scheduleId,
  });

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('ScheduleDetailPage', data: {'action': 'initState', 'scheduleId': widget.scheduleId});
    // Load the schedule using BLoC
    context.read<ScheduleBloc>().add(LoadScheduleById(scheduleId: widget.scheduleId));
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('ScheduleDetailPage', data: {'action': 'build', 'scheduleId': widget.scheduleId});

    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is ScheduleLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ScheduleDetailLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.schedule.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    AppLogger.navigation('schedule-detail', 'schedule-edit');
                    context.go('/schedule/${widget.scheduleId}/edit');
                  },
                  tooltip: 'Edit Schedule',
                ),
              ],
            ),
            body: _buildScheduleDetails(state.schedule),
          );
        }

        if (state is ScheduleError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Schedule Details'),
            ),
            body: _buildError(state.message),
          );
        }

        // Default case - show not found
        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule Details'),
          ),
          body: _buildNotFound(),
        );
      },
    );
  }

  Widget _buildScheduleDetails(ScheduleEntity schedule) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfo(schedule),
          const SizedBox(height: 24),
          _buildWeeklyAvailability(schedule),
          const SizedBox(height: 24),
          _buildActions(schedule),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ScheduleEntity schedule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (schedule.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', schedule.name),
            _buildInfoRow('Timezone', schedule.timezone),
            _buildInfoRow('Instructor ID', schedule.instructorId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAvailability(ScheduleEntity schedule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Availability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (schedule.weeklyAvailability == null || schedule.weeklyAvailability!.isEmpty)
              const Text(
                'No weekly availability set',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...schedule.weeklyAvailability!.entries.map((entry) {
                final day = entry.key;
                final times = entry.value;
                return _buildDayAvailability(day, times);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAvailability(String day, dynamic times) {
    // Handle both old format (Map<String, dynamic>) and new format (List<Map<String, dynamic>>)
    List<Map<String, dynamic>> timeRanges;
    
    if (times is List) {
      timeRanges = times.cast<Map<String, dynamic>>();
    } else if (times is Map<String, dynamic>) {
      // Convert old format to new format
      timeRanges = [times];
    } else {
      timeRanges = [];
    }

    final isAvailable = timeRanges.any((range) => 
      range['start'] != null && range['end'] != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _capitalizeFirst(day),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: isAvailable ? Colors.green : Colors.grey,
                size: 20,
              ),
            ],
          ),
          if (isAvailable) ...[
            const SizedBox(height: 8),
            ...timeRanges.map((range) {
              final startTime = range['start']?.toString() ?? 'Not set';
              final endTime = range['end']?.toString() ?? 'Not set';
              final hasValidTimes = startTime != 'Not set' && endTime != 'Not set';
              
              if (!hasValidTimes) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Unavailable',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(ScheduleEntity schedule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AppLogger.navigation('schedule-detail', 'schedule-edit');
                      context.go('/schedule/${schedule.id}/edit');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _duplicateSchedule(schedule);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                ),
              ],
            ),
            if (!schedule.isDefault) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _setAsDefault(schedule);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text('Set as Default'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _deleteSchedule(schedule);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Schedule not found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The schedule you\'re looking for doesn\'t exist or has been deleted.',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading schedule',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _duplicateSchedule(ScheduleEntity schedule) {
    // TODO: Implement duplicate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate functionality coming soon!'),
      ),
    );
  }

  void _setAsDefault(ScheduleEntity schedule) {
    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Default Schedule'),
        content: Text('Are you sure you want to set "${schedule.name}" as your default schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ScheduleBloc>().add(SetDefaultSchedule(
                instructorId: authState.user.id,
                scheduleId: schedule.id,
                isDefault: true,
              ));
            },
            child: const Text('Set as Default'),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(ScheduleEntity schedule) {
    if (schedule.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default schedule. Set another as default first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ScheduleBloc>().add(DeleteSchedule(scheduleId: schedule.id));
              context.pop(); // Go back to schedule list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
