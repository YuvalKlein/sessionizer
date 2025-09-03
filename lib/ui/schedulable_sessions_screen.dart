import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/schedulable_session_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/view_models/schedulable_session_view_model.dart';

class SchedulableSessionsScreen extends StatelessWidget {
  const SchedulableSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to manage schedulable sessions')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedulable Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'What are schedulable sessions?',
          ),
        ],
      ),
      body: StreamBuilder<List<SchedulableSession>>(
        stream: context
            .read<SchedulableSessionService>()
            .getSchedulableSessionsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading schedulable sessions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              ),
            );
          }

          final schedulableSessions = snapshot.data ?? [];

          if (schedulableSessions.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: schedulableSessions.length,
            itemBuilder: (context, index) {
              return _SchedulableSessionCard(
                schedulableSession: schedulableSessions[index],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/instructor/schedulable-sessions/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Schedulable Session'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No Schedulable Sessions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your session types, locations, and schedules to create bookable sessions for your clients.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/instructor/schedulable-sessions/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Schedulable Session'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What are Schedulable Sessions?'),
        content: const Text(
          'Schedulable Sessions connect your session types, locations, and availability schedules together with booking rules.\n\n'
          'Each schedulable session defines:\n'
          '• Which session type can be booked\n'
          '• At which locations\n'
          '• Using which availability schedule\n'
          '• With specific buffer times and booking constraints\n\n'
          'This gives you complete control over how and when clients can book your services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SchedulableSessionCard extends StatelessWidget {
  final SchedulableSession schedulableSession;

  const _SchedulableSessionCard({required this.schedulableSession});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/instructor/schedulable-sessions/${schedulableSession.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder<SessionType?>(
                      future: context
                          .read<SessionTypeService>()
                          .getSessionType(schedulableSession.sessionTypeId),
                      builder: (context, snapshot) {
                        final sessionType = snapshot.data;
                        return Text(
                          sessionType?.title ?? 'Loading...',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!schedulableSession.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      _buildActionMenu(context),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Schedule info
              FutureBuilder<Schedule?>(
                future: context
                    .read<ScheduleService>()
                    .getSchedule(schedulableSession.scheduleId),
                builder: (context, snapshot) {
                  final schedule = snapshot.data;
                  return _buildInfoRow(
                    context,
                    Icons.schedule,
                    'Schedule',
                    schedule?.name ?? 'Loading...',
                  );
                },
              ),
              const SizedBox(height: 8),
              
              // Locations info
              _buildInfoRow(
                context,
                Icons.location_on,
                'Locations',
                '${schedulableSession.locationIds.length} location(s)',
              ),
              const SizedBox(height: 8),
              
              // Buffer times
              _buildInfoRow(
                context,
                Icons.timer,
                'Buffer',
                '${schedulableSession.bufferBefore}min before, ${schedulableSession.bufferAfter}min after',
              ),
              const SizedBox(height: 8),
              
              // Booking window
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'Booking Window',
                '${schedulableSession.minHoursAhead}h - ${schedulableSession.maxDaysAhead}d ahead',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                schedulableSession.isActive ? Icons.pause : Icons.play_arrow,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(schedulableSession.isActive ? 'Deactivate' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final viewModel = context.read<SchedulableSessionViewModel>();

    switch (action) {
      case 'edit':
        context.go('/instructor/schedulable-sessions/${schedulableSession.id}/edit');
        break;
      
      case 'duplicate':
        final success = await viewModel.duplicateSchedulableSession(schedulableSession.id!);
        if (success != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedulable session duplicated successfully')),
          );
        }
        break;
      
      case 'toggle_status':
        final success = await viewModel.toggleActiveStatus(
          schedulableSession.id!,
          !schedulableSession.isActive,
        );
        if (success && context.mounted) {
          final status = schedulableSession.isActive ? 'deactivated' : 'activated';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Schedulable session $status')),
          );
        }
        break;
      
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedulable Session'),
        content: const Text(
          'Are you sure you want to delete this schedulable session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final viewModel = context.read<SchedulableSessionViewModel>();
              final success = await viewModel.deleteSchedulableSession(schedulableSession.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedulable session deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
