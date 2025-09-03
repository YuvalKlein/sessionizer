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

class SchedulableSessionFormScreen extends StatefulWidget {
  final String? schedulableSessionId;

  const SchedulableSessionFormScreen({
    super.key,
    this.schedulableSessionId,
  });

  @override
  State<SchedulableSessionFormScreen> createState() => _SchedulableSessionFormScreenState();
}

class _SchedulableSessionFormScreenState extends State<SchedulableSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _durationOverrideController = TextEditingController();

  // Form data
  String? _selectedSessionTypeId;
  String? _selectedScheduleId;
  List<String> _selectedLocationIds = [];
  int _bufferBefore = 15;
  int _bufferAfter = 10;
  int _maxDaysAhead = 7;
  int _minHoursAhead = 2;
  int _slotIntervalMinutes = 60; // Default to hourly slots
  bool _isActive = true;

  // Data lists
  List<SessionType> _sessionTypes = [];
  List<Schedule> _schedules = [];
  List<String> _availableLocations = []; // TODO: Replace with actual location model

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.schedulableSessionId != null;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      if (user == null) return;

      // Load session types and schedules
      final sessionTypeService = context.read<SessionTypeService>();
      final scheduleService = context.read<ScheduleService>();

      final sessionTypesStream = sessionTypeService.getSessionTypesStream(user.uid);
      final schedulesStream = scheduleService.getSchedulesStream(user.uid);

      // Get session types
      sessionTypesStream.listen((snapshot) {
        if (mounted) {
          setState(() {
            _sessionTypes = snapshot.docs.map((doc) => SessionType.fromFirestore(doc)).toList();
          });
        }
      });

      // Get schedules
      schedulesStream.listen((snapshot) {
        if (mounted) {
          setState(() {
            _schedules = snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
          });
        }
      });

      // TODO: Load actual locations from location service
      _availableLocations = ['Location 1', 'Location 2', 'Location 3'];

      // If editing, load existing data
      if (_isEditing) {
        await _loadExistingData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExistingData() async {
    final schedulableSession = await context
        .read<SchedulableSessionService>()
        .getSchedulableSession(widget.schedulableSessionId!);

    if (schedulableSession != null && mounted) {
      setState(() {
        _selectedSessionTypeId = schedulableSession.sessionTypeId;
        _selectedScheduleId = schedulableSession.scheduleId;
        _selectedLocationIds = List.from(schedulableSession.locationIds);
        _bufferBefore = schedulableSession.bufferBefore;
        _bufferAfter = schedulableSession.bufferAfter;
        _maxDaysAhead = schedulableSession.maxDaysAhead;
        _minHoursAhead = schedulableSession.minHoursAhead;
        _slotIntervalMinutes = schedulableSession.slotIntervalMinutes;
        _isActive = schedulableSession.isActive;
        _notesController.text = schedulableSession.notes ?? '';
        _durationOverrideController.text = 
            schedulableSession.durationOverride?.toString() ?? '';
      });
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedulable Session' : 'New Schedulable Session'),
        actions: [
          TextButton(
            onPressed: _saveSchedulableSession,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSessionTypeSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildLocationsSection(),
            const SizedBox(height: 24),
            _buildBufferSection(),
            const SizedBox(height: 24),
            _buildSlotIntervalSection(),
            const SizedBox(height: 24),
            _buildBookingConstraintsSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
            const SizedBox(height: 24),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSessionTypeId,
              decoration: const InputDecoration(
                labelText: 'Select Session Type',
                border: OutlineInputBorder(),
              ),
              items: _sessionTypes.map((sessionType) {
                return DropdownMenuItem(
                  value: sessionType.id,
                  child: Text(sessionType.title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSessionTypeId = value;
                });
              },
              validator: (value) => value == null ? 'Please select a session type' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedScheduleId,
              decoration: const InputDecoration(
                labelText: 'Select Schedule',
                border: OutlineInputBorder(),
              ),
              items: _schedules.map((schedule) {
                return DropdownMenuItem(
                  value: schedule.id,
                  child: Text(schedule.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedScheduleId = value;
                });
              },
              validator: (value) => value == null ? 'Please select a schedule' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Locations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select where this session can be conducted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ..._availableLocations.map((location) {
              return CheckboxListTile(
                title: Text(location),
                value: _selectedLocationIds.contains(location),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedLocationIds.add(location);
                    } else {
                      _selectedLocationIds.remove(location);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_selectedLocationIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one location',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buffer Times',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time needed before and after each session',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Before (minutes)'),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _bufferBefore.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _bufferBefore = int.tryParse(value) ?? 15;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('After (minutes)'),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _bufferAfter.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _bufferAfter = int.tryParse(value) ?? 10;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotIntervalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot Interval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How often should booking slots be available?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _slotIntervalMinutes,
              decoration: const InputDecoration(
                labelText: 'Slot Interval',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('Every 5 minutes')),
                DropdownMenuItem(value: 10, child: Text('Every 10 minutes')),
                DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
                DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                DropdownMenuItem(value: 60, child: Text('Every hour')),
              ],
              onChanged: (value) {
                setState(() {
                  _slotIntervalMinutes = value ?? 60;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingConstraintsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Constraints',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control when clients can book sessions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Min hours ahead'),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _minHoursAhead.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minHoursAhead = int.tryParse(value) ?? 2;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max days ahead'),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _maxDaysAhead.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxDaysAhead = int.tryParse(value) ?? 7;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationOverrideController,
              decoration: const InputDecoration(
                labelText: 'Duration Override (minutes)',
                helperText: 'Leave empty to use session type duration',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Internal Notes',
                helperText: 'Private notes for your reference',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Clients can book this session when active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSchedulableSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one location')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final viewModel = context.read<SchedulableSessionViewModel>();

    final schedulableSession = SchedulableSession(
      id: _isEditing ? widget.schedulableSessionId : null,
      instructorId: user.uid,
      sessionTypeId: _selectedSessionTypeId!,
      locationIds: _selectedLocationIds,
      scheduleId: _selectedScheduleId!,
      bufferBefore: _bufferBefore,
      bufferAfter: _bufferAfter,
      maxDaysAhead: _maxDaysAhead,
      minHoursAhead: _minHoursAhead,
      durationOverride: _durationOverrideController.text.isNotEmpty
          ? int.tryParse(_durationOverrideController.text)
          : null,
      slotIntervalMinutes: _slotIntervalMinutes,
      isActive: _isActive,
      createdAt: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    bool success;
    if (_isEditing) {
      success = await viewModel.updateSchedulableSession(
        widget.schedulableSessionId!,
        schedulableSession,
      );
    } else {
      final result = await viewModel.createSchedulableSession(schedulableSession);
      success = result != null;
    }

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Schedulable session updated successfully'
                : 'Schedulable session created successfully',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.error ?? 'Failed to save')),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationOverrideController.dispose();
    super.dispose();
  }
}
