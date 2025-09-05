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

class ScheduleManagementPage extends StatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  State<ScheduleManagementPage> createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('ScheduleManagementPage', data: {'action': 'initState'});
    
    // Load schedules when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSchedules();
      }
    });
  }

  void _loadSchedules() {
    if (!mounted) return;
    
    // Get the current authenticated user's ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
      context.read<ScheduleBloc>().add(LoadSchedules(instructorId: authState.user.id));
      AppLogger.blocEvent('ScheduleBloc', 'LoadSchedules', data: {'instructorId': authState.user.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('ScheduleManagementPage', data: {'action': 'build'});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Management'),
        leading: IconButton(
          onPressed: () => context.go('/instructor-dashboard'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              AppLogger.navigation('schedule-management', 'schedule-creation');
              context.go('/schedule/create');
            },
            tooltip: 'Create New Schedule',
          ),
        ],
      ),
      body: BlocListener<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reload schedules after successful operation
            _loadSchedules();
          } else if (state is ScheduleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            AppLogger.blocState('ScheduleBloc', state.runtimeType.toString());

            if (state is ScheduleLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ScheduleError) {
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
                    Text(
                      'Error: ${state.message}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadSchedules,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ScheduleLoaded) {
              return _buildScheduleList(state.schedules);
            }

            return const Center(
              child: Text('No schedules found'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleEntity> schedules) {
    if (schedules.isEmpty) {
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
            Text(
              'No schedules created yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first schedule to start managing your availability',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                AppLogger.navigation('schedule-management', 'schedule-creation');
                context.go('/schedule/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(ScheduleEntity schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: schedule.isDefault 
              ? Colors.green.shade100 
              : Colors.blue.shade100,
          child: Icon(
            schedule.isDefault ? Icons.star : Icons.schedule,
            color: schedule.isDefault 
                ? Colors.green.shade700 
                : Colors.blue.shade700,
          ),
        ),
        title: Text(
          schedule.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timezone: ${schedule.timezone}'),
            if (schedule.isDefault)
              const Text(
                'Default Schedule',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, schedule),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!schedule.isDefault)
              const PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Set as Default'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          AppLogger.navigation('schedule-management', 'schedule-edit');
          context.go('/schedule/${schedule.id}/edit');
        },
      ),
    );
  }

  void _handleMenuAction(String action, ScheduleEntity schedule) {
    switch (action) {
      case 'edit':
        AppLogger.navigation('schedule-management', 'schedule-edit');
        context.go('/schedule/${schedule.id}/edit');
        break;
      case 'set_default':
        _setAsDefault(schedule);
        break;
      case 'duplicate':
        _duplicateSchedule(schedule);
        break;
      case 'delete':
        _deleteSchedule(schedule);
        break;
    }
  }

  void _setAsDefault(ScheduleEntity schedule) {
    if (_currentUserId == null) return;
    
    // Capture the BLoC reference before showing the dialog
    final scheduleBloc = context.read<ScheduleBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set as Default Schedule'),
        content: Text('Are you sure you want to set "${schedule.name}" as your default schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              scheduleBloc.add(SetDefaultSchedule(
                instructorId: _currentUserId!,
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

  void _duplicateSchedule(ScheduleEntity schedule) {
    // TODO: Implement duplicate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate functionality coming soon!'),
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

    // Capture the BLoC reference before showing the dialog
    final scheduleBloc = context.read<ScheduleBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performDelete(schedule.id, scheduleBloc);
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

  void _performDelete(String scheduleId, ScheduleBloc scheduleBloc) {
    try {
      scheduleBloc.add(DeleteSchedule(scheduleId: scheduleId));
      AppLogger.blocEvent('ScheduleBloc', 'DeleteSchedule', data: {'scheduleId': scheduleId});
    } catch (e) {
      AppLogger.error('Failed to delete schedule', e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete schedule. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
