import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SimpleSchedulableSessionForm extends StatefulWidget {
  final QueryDocumentSnapshot? schedulableSessionDoc;
  final bool isDuplicate;

  const SimpleSchedulableSessionForm({
    super.key,
    this.schedulableSessionDoc,
    this.isDuplicate = false,
  });

  @override
  State<SimpleSchedulableSessionForm> createState() => _SimpleSchedulableSessionFormState();
}

class _SimpleSchedulableSessionFormState extends State<SimpleSchedulableSessionForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSessionTypeId;
  String? _selectedLocationId;
  String? _selectedScheduleId;

  final _bufferBeforeController = TextEditingController();
  final _bufferAfterController = TextEditingController();
  final _maxDaysAheadController = TextEditingController();
  final _minHoursAheadController = TextEditingController();
  final _slotIntervalController = TextEditingController();
  final _durationOverrideController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _sessionTypes = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _populateForm();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load session types for current instructor
      final sessionTypesSnapshot = await FirebaseFirestore.instance
          .collection('session_types')
          .where('idCreatedBy', isEqualTo: user.uid)
          .get();
      _sessionTypes = sessionTypesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Load locations for current instructor
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('instructorId', isEqualTo: user.uid)
          .get();
      _locations = locationsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Load schedules for current instructor
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('instructorId', isEqualTo: user.uid)
          .get();
      _schedules = schedulesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateForm() {
    if (widget.schedulableSessionDoc != null) {
      final data = widget.schedulableSessionDoc!.data() as Map<String, dynamic>;
      _selectedSessionTypeId = data['sessionTypeId'] as String?;
      _selectedLocationId = (data['locationIds'] as List?)?.isNotEmpty == true 
          ? (data['locationIds'] as List).first as String 
          : null;
      _selectedScheduleId = data['scheduleId'] as String?;

      _bufferBeforeController.text = (data['bufferBefore'] ?? 0).toString();
      _bufferAfterController.text = (data['bufferAfter'] ?? 0).toString();
      _maxDaysAheadController.text = (data['maxDaysAhead'] ?? 7).toString();
      _minHoursAheadController.text = (data['minHoursAhead'] ?? 2).toString();
      _slotIntervalController.text = (data['slotIntervalMinutes'] ?? 60).toString();
      _durationOverrideController.text = (data['durationOverride'] ?? '').toString();
      _notesController.text = data['notes'] ?? '';
    } else {
      // Set default values
      _bufferBeforeController.text = '0';
      _bufferAfterController.text = '0';
      _maxDaysAheadController.text = '7';
      _minHoursAheadController.text = '2';
      _slotIntervalController.text = '60';
    }
  }

  @override
  void dispose() {
    _bufferBeforeController.dispose();
    _bufferAfterController.dispose();
    _maxDaysAheadController.dispose();
    _minHoursAheadController.dispose();
    _slotIntervalController.dispose();
    _durationOverrideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedSessionTypeId == null ||
        _selectedLocationId == null ||
        _selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a session type, location, and schedule.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to perform this action.'),
        ),
      );
      return;
    }

    try {
      // Get the selected items' names for the title
      final sessionType = _sessionTypes.firstWhere((st) => st['id'] == _selectedSessionTypeId);
      final location = _locations.firstWhere((loc) => loc['id'] == _selectedLocationId);
      
      final title = '${sessionType['title'] as String? ?? 'Unknown'} at ${location['name'] as String? ?? 'Unknown'}';

      final setData = {
        'title': title,
        'sessionTypeId': _selectedSessionTypeId,
        'locationIds': [_selectedLocationId], // Keep as array for compatibility
        'scheduleId': _selectedScheduleId,
        'instructorId': user.uid,
        'bufferBefore': int.tryParse(_bufferBeforeController.text) ?? 0,
        'bufferAfter': int.tryParse(_bufferAfterController.text) ?? 0,
        'maxDaysAhead': int.tryParse(_maxDaysAheadController.text) ?? 7,
        'minHoursAhead': int.tryParse(_minHoursAheadController.text) ?? 2,
        'slotIntervalMinutes': int.tryParse(_slotIntervalController.text) ?? 60,
        'durationOverride': _durationOverrideController.text.isNotEmpty 
            ? int.tryParse(_durationOverrideController.text) 
            : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'isActive': true,
        'customSettings': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      if (widget.schedulableSessionDoc != null && !widget.isDuplicate) {
        await widget.schedulableSessionDoc!.reference.update(setData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('schedulable_sessions')
            .add(setData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving template: $e'),
          backgroundColor: Colors.red,
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedulableSessionDoc != null 
            ? (widget.isDuplicate ? 'Duplicate Template' : 'Edit Template')
            : 'Create Template'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSet,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Type Selection
              _buildSectionTitle('Session Type'),
              DropdownButtonFormField<String>(
                initialValue: _selectedSessionTypeId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Session Type',
                ),
                items: _sessionTypes
                    .where((type) => type['id'] != null)
                    .map((type) {
                  return DropdownMenuItem<String>(
                    value: type['id'] as String,
                    child: Text(type['title'] as String? ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSessionTypeId = value),
                validator: (value) => value == null ? 'Please select a session type' : null,
              ),
              const SizedBox(height: 24),

              // Location Selection
              _buildSectionTitle('Location'),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocationId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Location',
                ),
                items: _locations
                    .where((location) => location['id'] != null)
                    .map((location) {
                  return DropdownMenuItem<String>(
                    value: location['id'] as String,
                    child: Text(location['name'] as String? ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedLocationId = value),
                validator: (value) => value == null ? 'Please select a location' : null,
              ),
              const SizedBox(height: 24),

              // Schedule Selection
              _buildSectionTitle('Schedule'),
              DropdownButtonFormField<String>(
                initialValue: _selectedScheduleId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Schedule',
                ),
                items: _schedules
                    .where((schedule) => schedule['id'] != null)
                    .map((schedule) {
                  return DropdownMenuItem<String>(
                    value: schedule['id'] as String,
                    child: Text(schedule['name'] as String? ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedScheduleId = value),
                validator: (value) => value == null ? 'Please select a schedule' : null,
              ),
              const SizedBox(height: 24),

              // Buffer Settings
              _buildSectionTitle('Buffer Settings'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bufferBeforeController,
                      decoration: const InputDecoration(
                        labelText: 'Buffer Before (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bufferAfterController,
                      decoration: const InputDecoration(
                        labelText: 'Buffer After (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Booking Rules
              _buildSectionTitle('Booking Rules'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxDaysAheadController,
                      decoration: const InputDecoration(
                        labelText: 'Max Days Ahead',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minHoursAheadController,
                      decoration: const InputDecoration(
                        labelText: 'Min Hours Ahead',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slot Settings
              _buildSectionTitle('Slot Settings'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _slotIntervalController,
                      decoration: const InputDecoration(
                        labelText: 'Slot Interval (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              _buildSectionTitle('Notes'),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Optional notes about this template',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}
