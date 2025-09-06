import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_state.dart';
import 'package:myapp/features/schedule/presentation/pages/schedule_creation_page.dart';
import 'package:myapp/core/utils/logger.dart';

class ScheduleEditPage extends StatefulWidget {
  final String scheduleId;
  
  const ScheduleEditPage({
    super.key,
    required this.scheduleId,
  });

  @override
  State<ScheduleEditPage> createState() => _ScheduleEditPageState();
}

class _ScheduleEditPageState extends State<ScheduleEditPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('ScheduleEditPage', data: {'action': 'initState', 'scheduleId': widget.scheduleId});
    // Load the schedule using BLoC
    context.read<ScheduleBloc>().add(LoadScheduleById(scheduleId: widget.scheduleId));
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('ScheduleEditPage', data: {'action': 'build', 'scheduleId': widget.scheduleId});

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
          AppLogger.widgetBuild('ScheduleEditPage', data: {'action': 'schedule_loaded', 'scheduleId': widget.scheduleId, 'scheduleName': state.schedule.name});
          return ScheduleCreationPage(
            existingSchedule: state.schedule,
            isEdit: true,
          );
        }

        // Check if schedule is already in the loaded schedules
        if (state is ScheduleLoaded && state.schedules.isNotEmpty) {
          final schedule = state.schedules.firstWhere(
            (s) => s.id == widget.scheduleId,
            orElse: () => throw StateError('Schedule not found'),
          );
          AppLogger.widgetBuild('ScheduleEditPage', data: {'action': 'schedule_found_in_list', 'scheduleId': widget.scheduleId, 'scheduleName': schedule.name});
          return ScheduleCreationPage(
            existingSchedule: schedule,
            isEdit: true,
          );
        }

        if (state is ScheduleError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Schedule Edit'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: Center(
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Default case - show not found
        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule Edit'),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: const Center(
            child: Text('Schedule not found'),
          ),
        );
      },
    );
  }
}
