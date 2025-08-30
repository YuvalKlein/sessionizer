import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<DocumentSnapshot> _templates = [];
  List<DocumentSnapshot> _locations = [];

  DocumentSnapshot? _selectedTemplate;
  DocumentSnapshot? _selectedLocation;
  DateTime? _selectedStartTime;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final templateSnapshot = await FirebaseFirestore.instance
          .collection('sessionTemplates')
          .get();
      final locationSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();

      if (!mounted) return;
      setState(() {
        _templates = templateSnapshot.docs;
        _locations = locationSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  Future<void> _selectStartTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedStartTime ?? DateTime.now()),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }

    if (_selectedTemplate == null ||
        _selectedLocation == null ||
        _selectedStartTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    try {
      final templateData = _selectedTemplate!.data() as Map<String, dynamic>;
      final sessionEntity = Map<String, dynamic>.from(
        templateData['sessionEntity'],
      );

      final duration = sessionEntity['duration'] as int;
      final durationUnit = sessionEntity['durationUnit'] as String;

      final endTime = durationUnit == 'Hours'
          ? _selectedStartTime!.add(Duration(hours: duration))
          : _selectedStartTime!.add(Duration(minutes: duration));

      // Overwrite template data with specific session details
      sessionEntity['idInstructor'] = user.uid;
      sessionEntity['startTimeEpoch'] =
          _selectedStartTime!.millisecondsSinceEpoch;
      sessionEntity['endTimeEpoch'] = endTime.millisecondsSinceEpoch;
      sessionEntity['canceled'] = false;
      sessionEntity['playersIds'] = []; // Reset for the new session
      sessionEntity['attendanceData'] = []; // Reset for the new session

      // Add location details
      final locationData = _selectedLocation!.data() as Map<String, dynamic>;
      sessionEntity['locationInfo'] = {
        'id': _selectedLocation!.id,
        'name': locationData['name'],
        'address': locationData['address'],
      };

      await FirebaseFirestore.instance
          .collection('sessions')
          .add(sessionEntity);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved successfully!')),
      );
      setState(() {
        _selectedTemplate = null;
        _selectedLocation = null;
        _selectedStartTime = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving session: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Session')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<DocumentSnapshot>(
                    value: _selectedTemplate,
                    hint: const Text('Choose a Session Template'),
                    onChanged: (v) => setState(() => _selectedTemplate = v),
                    items: _templates.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final entity = data['sessionEntity'] ?? {};
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: doc,
                        child: Text(entity['title'] ?? 'Unnamed Template'),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<DocumentSnapshot>(
                    value: _selectedLocation,
                    hint: const Text('Choose a Location'),
                    onChanged: (v) => setState(() => _selectedLocation = v),
                    items: _locations.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: doc,
                        child: Text(data['name'] ?? 'Unnamed Location'),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    title: const Text('Session Start Time'),
                    subtitle: Text(
                      _selectedStartTime == null
                          ? 'Tap to select'
                          : DateFormat.yMd().add_jm().format(
                              _selectedStartTime!,
                            ),
                    ),
                    onTap: _selectStartTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveSession,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Session'),
                  ),
                ],
              ),
            ),
    );
  }
}
