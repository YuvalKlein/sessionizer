import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_bloc.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_event.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_state.dart';
import 'package:myapp/features/location/presentation/bloc/location_bloc.dart';
import 'package:myapp/features/location/presentation/bloc/location_event.dart';
import 'package:myapp/features/location/presentation/bloc/location_state.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_state.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';

class SchedulableSessionCreationPage extends StatefulWidget {
  final SchedulableSessionEntity? existingSession;
  final bool isEdit;

  const SchedulableSessionCreationPage({
    super.key,
    this.existingSession,
    this.isEdit = false,
  });

  @override
  State<SchedulableSessionCreationPage> createState() => _SchedulableSessionCreationPageState();
}

class _SchedulableSessionCreationPageState extends State<SchedulableSessionCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _breakTimeController = TextEditingController();
  final _bookingLeadTimeController = TextEditingController();
  final _futureBookingLimitController = TextEditingController();
  final _durationOverrideController = TextEditingController();

  List<String> _selectedTypeIds = [];
  List<String> _selectedLocationIds = [];
  List<String> _selectedAvailabilityIds = [];
  List<SessionTypeEntity> _sessionTypes = [];
  final List<Map<String, dynamic>> _locations = [];
  final List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _populateForm();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SessionTypeBloc>().add(LoadSessionTypesByInstructor(instructorId: authState.user.id));
      context.read<LocationBloc>().add(LoadLocationsByInstructor(instructorId: authState.user.id));
      context.read<ScheduleBloc>().add(LoadSchedules(instructorId: authState.user.id));
    }
  }

  void _populateForm() {
    if (widget.isEdit && widget.existingSession != null) {
      final session = widget.existingSession!;
      _breakTimeController.text = session.breakTimeInMinutes.toString();
      _bookingLeadTimeController.text = session.bookingLeadTimeInMinutes.toString();
      _futureBookingLimitController.text = session.futureBookingLimitInDays.toString();
      _durationOverrideController.text = session.durationOverride?.toString() ?? '';
      _selectedTypeIds = List.from(session.typeIds);
      _selectedLocationIds = List.from(session.locationIds);
      _selectedAvailabilityIds = List.from(session.availabilityIds);
    } else {
      _breakTimeController.text = '0';
      _bookingLeadTimeController.text = '30';
      _futureBookingLimitController.text = '7';
    }
  }

  @override
  void dispose() {
    _breakTimeController.dispose();
    _bookingLeadTimeController.dispose();
    _futureBookingLimitController.dispose();
    _durationOverrideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('SchedulableSessionCreationPage', data: {'action': 'build', 'isEdit': widget.isEdit});

    return BlocListener<SessionTypeBloc, SessionTypeState>(
      listener: (context, state) {
        if (state is SessionTypeLoaded) {
          setState(() {
            _sessionTypes = state.sessionTypes;
          });
        }
      },
      child: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationLoaded) {
            setState(() {
              _locations.clear();
              _locations.addAll(state.locations.map((location) => {
                'id': location.id,
                'name': location.name,
              }));
            });
          }
        },
        child: BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            if (state is ScheduleLoaded) {
              setState(() {
                _schedules.clear();
                _schedules.addAll(state.schedules.map((schedule) => {
                  'id': schedule.id,
                  'name': schedule.name,
                }));
              });
            }
          },
          child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? 'Edit Bookable Slot' : 'Create Bookable Slot'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.go('/schedulable-sessions'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Templates',
          ),
        ),
        body: BlocBuilder<SessionTypeBloc, SessionTypeState>(
          builder: (context, state) {
            if (state is SessionTypeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionTypesSection(),
                    const SizedBox(height: 24),
                    _buildLocationsSection(),
                    const SizedBox(height: 24),
                    _buildSchedulesSection(),
                    const SizedBox(height: 24),
                    _buildBookingRulesSection(),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveSession,
          icon: Icon(widget.isEdit ? Icons.update : Icons.add),
          label: Text(widget.isEdit ? 'Update Template' : 'Create Template'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildSessionTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select which session types this template can be used for:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_sessionTypes.isEmpty)
              const Text('No session types available. Create some first.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sessionTypes
                    .where((type) => type.id != null)
                    .map((type) {
                  final isSelected = _selectedTypeIds.contains(type.id);
                  return FilterChip(
                    label: Text(type.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypeIds.add(type.id!);
                        } else {
                          _selectedTypeIds.remove(type.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select which locations this template can be used at:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_locations.isEmpty)
              const Text('No locations available. Create some first.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _locations.map((location) {
                  final isSelected = _selectedLocationIds.contains(location['id']);
                  return FilterChip(
                    label: Text(location['name'] ?? 'Unknown'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLocationIds.add(location['id']);
                        } else {
                          _selectedLocationIds.remove(location['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select which schedules this template can use:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_schedules.isEmpty)
              const Text('No schedules available. Create some first.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _schedules.map((schedule) {
                  final isSelected = _selectedAvailabilityIds.contains(schedule['id']);
                  return FilterChip(
                    label: Text(schedule['name'] ?? 'Unknown'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAvailabilityIds.add(schedule['id']);
                        } else {
                          _selectedAvailabilityIds.remove(schedule['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingRulesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Rules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _breakTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Break Time (minutes)',
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final breakTime = int.tryParse(value);
                      if (breakTime == null || breakTime < 0) {
                        return 'Must be 0 or more';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bookingLeadTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Booking Lead Time (minutes)',
                      border: OutlineInputBorder(),
                      hintText: '30',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final leadTime = int.tryParse(value);
                      if (leadTime == null || leadTime < 0) {
                        return 'Must be 0 or more';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _futureBookingLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Future Booking Limit (days)',
                      border: OutlineInputBorder(),
                      hintText: '7',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final limit = int.tryParse(value);
                      if (limit == null || limit < 1) {
                        return 'Must be 1 or more';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationOverrideController,
                    decoration: const InputDecoration(
                      labelText: 'Duration Override (minutes)',
                      border: OutlineInputBorder(),
                      hintText: 'Optional',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final duration = int.tryParse(value);
                        if (duration == null || duration <= 0) {
                          return 'Must be positive';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSession() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTypeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one session type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAvailabilityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one schedule'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    String currentUserId = 'unknown_user';

    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    final session = SchedulableSessionEntity(
      id: widget.isEdit ? widget.existingSession!.id : null,
      instructorId: widget.isEdit ? widget.existingSession!.instructorId : currentUserId,
      typeIds: _selectedTypeIds,
      locationIds: _selectedLocationIds,
      availabilityIds: _selectedAvailabilityIds,
      breakTimeInMinutes: int.parse(_breakTimeController.text),
      bookingLeadTimeInMinutes: int.parse(_bookingLeadTimeController.text),
      futureBookingLimitInDays: int.parse(_futureBookingLimitController.text),
      durationOverride: _durationOverrideController.text.isNotEmpty 
          ? int.parse(_durationOverrideController.text) 
          : null,
      createdAt: widget.isEdit ? widget.existingSession!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.isEdit) {
      context.read<SchedulableSessionBloc>().add(UpdateSchedulableSessionEvent(schedulableSession: session));
    } else {
      context.read<SchedulableSessionBloc>().add(CreateSchedulableSessionEvent(schedulableSession: session));
    }

    AppLogger.blocEvent(
      'SchedulableSessionBloc',
      widget.isEdit ? 'UpdateSchedulableSessionEvent' : 'CreateSchedulableSessionEvent',
      data: {'sessionId': session.id, 'typeIds': session.typeIds.length},
    );

    // Navigate back to management page
    context.go('/schedulable-sessions');
  }
}