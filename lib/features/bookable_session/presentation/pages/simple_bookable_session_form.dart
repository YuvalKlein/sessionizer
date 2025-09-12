import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/config/firestore_collections.dart';

class SimpleBookableSessionForm extends StatefulWidget {
  final QueryDocumentSnapshot? bookableSessionDoc;
  final bool isDuplicate;

  const SimpleBookableSessionForm({
    super.key,
    this.bookableSessionDoc,
    this.isDuplicate = false,
  });

  @override
  State<SimpleBookableSessionForm> createState() => _SimpleBookableSessionFormState();
}

class _SimpleBookableSessionFormState extends State<SimpleBookableSessionForm> {
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
  
  // Cancellation Policy Override Controllers
  final _cancellationTimeController = TextEditingController();
  final _cancellationFeeController = TextEditingController();

  List<Map<String, dynamic>> _sessionTypes = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  
  // Cancellation Policy Override State
  bool _overrideCancellationPolicy = false;
  bool _hasCancellationFee = true; // Main toggle for cancellation fee
  String _selectedCancellationTimeUnit = 'hours';
  String _selectedCancellationFeeType = '%';

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
      final sessionTypesSnapshot = await FirestoreCollections.sessionTypes
          .where('idCreatedBy', isEqualTo: user.uid)
          .get();
      _sessionTypes = sessionTypesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Load locations for current instructor
      final locationsSnapshot = await FirestoreCollections.locations
          .where('instructorId', isEqualTo: user.uid)
          .get();
      _locations = locationsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Load schedules for current instructor
      final schedulesSnapshot = await FirestoreCollections.schedules
          .where('instructorId', isEqualTo: user.uid)
          .get();
      _schedules = schedulesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
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
    if (widget.bookableSessionDoc != null) {
      final data = widget.bookableSessionDoc!.data() as Map<String, dynamic>;
      _selectedSessionTypeId = data['sessionTypeIds'] != null && (data['sessionTypeIds'] as List).isNotEmpty 
          ? (data['sessionTypeIds'] as List).first as String?
          : data['sessionTypeId'] as String?; // Fallback for old data
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
      
      // Load cancellation policy override data
      _overrideCancellationPolicy = data['cancellationPolicyOverride'] ?? false;
      if (_overrideCancellationPolicy) {
        _hasCancellationFee = data['hasCancellationFeeOverride'] ?? true;
        _cancellationTimeController.text = (data['cancellationTimeBeforeOverride'] ?? 18).toString();
        _selectedCancellationTimeUnit = data['cancellationTimeUnitOverride'] ?? 'hours';
        _cancellationFeeController.text = (data['cancellationFeeAmountOverride'] ?? 100).toString();
        _selectedCancellationFeeType = data['cancellationFeeTypeOverride'] ?? '%';
      }
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
    _cancellationTimeController.dispose();
    _cancellationFeeController.dispose();
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
        'sessionTypeIds': _selectedSessionTypeId != null ? [_selectedSessionTypeId!] : [],
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
        // Cancellation Policy Override
        'cancellationPolicyOverride': _overrideCancellationPolicy,
        'hasCancellationFeeOverride': _overrideCancellationPolicy 
            ? _hasCancellationFee 
            : null,
        'cancellationTimeBeforeOverride': _overrideCancellationPolicy && _hasCancellationFee
            ? int.tryParse(_cancellationTimeController.text) 
            : null,
        'cancellationTimeUnitOverride': _overrideCancellationPolicy && _hasCancellationFee
            ? _selectedCancellationTimeUnit 
            : null,
        'cancellationFeeAmountOverride': _overrideCancellationPolicy && _hasCancellationFee
            ? int.tryParse(_cancellationFeeController.text) 
            : null,
        'cancellationFeeTypeOverride': _overrideCancellationPolicy && _hasCancellationFee
            ? _selectedCancellationFeeType 
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      if (widget.bookableSessionDoc != null && !widget.isDuplicate) {
        await widget.bookableSessionDoc!.reference.update(setData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookable session updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirestoreCollections.bookableSessions.add(setData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookable session created successfully'),
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
        title: Text(widget.bookableSessionDoc != null 
            ? (widget.isDuplicate ? 'Duplicate Bookable Session' : 'Edit Bookable Session')
            : 'Create Bookable Session'),
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
                onChanged: (value) {
                  setState(() {
                    _selectedSessionTypeId = value;
                    // If cancellation policy override is enabled, load new defaults
                    if (_overrideCancellationPolicy && value != null) {
                      _loadSessionTypeDefaults();
                    }
                  });
                },
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

              // Cancellation Policy Override
              _buildCancellationPolicySection(),
              const SizedBox(height: 24),

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

  Widget _buildCancellationPolicySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cancellation Policy'),
        Card(
          elevation: 2,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                _overrideCancellationPolicy 
                    ? 'Custom Cancellation Policy (Active)'
                    : 'Use Session Type Default',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _overrideCancellationPolicy ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
              subtitle: Text(
                _overrideCancellationPolicy
                    ? 'Click to modify cancellation policy settings'
                    : 'Click to override cancellation policy from session type',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              leading: Icon(
                _overrideCancellationPolicy ? Icons.policy : Icons.policy_outlined,
                color: _overrideCancellationPolicy ? Colors.blue[700] : Colors.grey[600],
              ),
              initiallyExpanded: _overrideCancellationPolicy,
              onExpansionChanged: (isExpanded) {
                if (isExpanded && !_overrideCancellationPolicy && _selectedSessionTypeId != null) {
                  // Load session type defaults when first expanded
                  _loadSessionTypeDefaults();
                }
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Cancellation Fee Toggle
                      SwitchListTile(
                        title: const Text('Cancellation Fee'),
                        subtitle: const Text('Enable cancellation fees for late cancellations'),
                        value: _hasCancellationFee,
                        onChanged: (value) {
                          setState(() {
                            _hasCancellationFee = value;
                            _overrideCancellationPolicy = true; // Auto-enable override when user makes changes
                          });
                        },
                      ),
                      
                      if (_hasCancellationFee) ...[
                        const SizedBox(height: 16),
                        
                        // Cancellation Time
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cancellationTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Time to Cancel',
                                  hintText: '18',
                                  border: OutlineInputBorder(),
                                  helperText: 'How long before the session',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _overrideCancellationPolicy = true; // Auto-enable override when user makes changes
                                  });
                                },
                                validator: (value) {
                                  if (_overrideCancellationPolicy && _hasCancellationFee && (value == null || value.isEmpty)) {
                                    return 'Required when cancellation fee is enabled';
                                  }
                                  final time = int.tryParse(value ?? '');
                                  if (_overrideCancellationPolicy && _hasCancellationFee && (time == null || time <= 0)) {
                                    return 'Must be positive';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCancellationTimeUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'hours', child: Text('Hours')),
                                  DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCancellationTimeUnit = value!;
                                    _overrideCancellationPolicy = true; // Auto-enable override when user makes changes
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Cancellation Fee
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cancellationFeeController,
                                decoration: const InputDecoration(
                                  labelText: 'Cancellation Fee',
                                  hintText: '100',
                                  border: OutlineInputBorder(),
                                  helperText: 'Fee for late cancellations',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _overrideCancellationPolicy = true; // Auto-enable override when user makes changes
                                  });
                                },
                                validator: (value) {
                                  if (_overrideCancellationPolicy && _hasCancellationFee && (value == null || value.isEmpty)) {
                                    return 'Required when cancellation fee is enabled';
                                  }
                                  final fee = int.tryParse(value ?? '');
                                  if (_overrideCancellationPolicy && _hasCancellationFee && (fee == null || fee < 0)) {
                                    return 'Must be 0 or more';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCancellationFeeType,
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '%', child: Text('Percentage (%)')),
                                  DropdownMenuItem(value: '\$', child: Text('Fixed Amount (\$)')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCancellationFeeType = value!;
                                    _overrideCancellationPolicy = true; // Auto-enable override when user makes changes
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These settings will override the cancellation policy from the selected session type for this bookable slot only.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSessionTypeDefaults() async {
    if (_selectedSessionTypeId == null) return;
    
    try {
      final sessionTypeDoc = await FirestoreCollections.sessionTypes
          .doc(_selectedSessionTypeId!)
          .get();
      
      if (sessionTypeDoc.exists) {
        final data = sessionTypeDoc.data() as Map<String, dynamic>;
        
        // Check if cancellation policy is in nested format or flat format
        Map<String, dynamic> cancellationPolicy = data['cancellationPolicy'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _hasCancellationFee = 
            cancellationPolicy['hasCancellationFee'] ?? 
            data['hasCancellationFee'] ?? 
            true;
            
          _cancellationTimeController.text = (
            cancellationPolicy['cancellationTimeBefore'] ?? 
            data['cancellationTimeBefore'] ?? 
            18
          ).toString();
          
          _selectedCancellationTimeUnit = 
            cancellationPolicy['cancellationTimeUnit'] ?? 
            data['cancellationTimeUnit'] ?? 
            'hours';
          
          _cancellationFeeController.text = (
            cancellationPolicy['cancellationFeeAmount'] ?? 
            data['cancellationFeeAmount'] ?? 
            100
          ).toString();
          
          _selectedCancellationFeeType = 
            cancellationPolicy['cancellationFeeType'] ?? 
            data['cancellationFeeType'] ?? 
            '%';
        });
      }
    } catch (e) {
      // Silently handle error, use current values
      print('Error loading session type defaults: $e');
    }
  }

}
