
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Lists to hold the documents from Firestore
  List<DocumentSnapshot> _templates = [];
  List<DocumentSnapshot> _times = [];
  List<DocumentSnapshot> _locations = [];

  // Variables to hold the selected dropdown value
  DocumentSnapshot? _selectedTemplate;
  DocumentSnapshot? _selectedTime;
  DocumentSnapshot? _selectedLocation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final templateSnapshot =
          await FirebaseFirestore.instance.collection('templates').get();
      final timeSnapshot =
          await FirebaseFirestore.instance.collection('times').get();
      final locationSnapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      setState(() {
        _templates = templateSnapshot.docs;
        _times = timeSnapshot.docs;
        _locations = locationSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> _saveSession() async {
    if (_selectedTemplate == null ||
        _selectedTime == null ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make a selection for all fields.')),
      );
      return;
    }

    try {
      // Get the data from the selected documents
      final templateData = _selectedTemplate!.data() as Map<String, dynamic>;
      final timeData = _selectedTime!.data() as Map<String, dynamic>;
      final locationData = _selectedLocation!.data() as Map<String, dynamic>;

      // Create a new session document with denormalized data
      await FirebaseFirestore.instance.collection('sessions').add({
        // IDs for reference if needed
        'templateId': _selectedTemplate!.id,
        'timeId': _selectedTime!.id,
        'locationId': _selectedLocation!.id,

        // Denormalized data for direct display
        'templateName': templateData['name'] ?? 'No Name',
        'minPlayers': templateData['minPlayers'] ?? 0,
        'maxPlayers': templateData['maxPlayers'] ?? 0,
        'price': templateData['price'] ?? 0.0,
        'startTime': timeData['startTime'] ?? 'N/A',
        'endTime': timeData['endTime'] ?? 'N/A',
        'locationName': locationData['name'] ?? 'No Location',
        'createdAt': FieldValue.serverTimestamp(), // To order sessions
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved successfully!')),
      );
      // Optional: Clear selections after saving
      setState(() {
        _selectedTemplate = null;
        _selectedTime = null;
        _selectedLocation = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule a Session'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Dropdown
                  Text('Template', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DocumentSnapshot>(
                    value: _selectedTemplate,
                    hint: const Text('Choose a template'),
                    onChanged: (value) {
                      setState(() {
                        _selectedTemplate = value;
                      });
                    },
                    items: _templates.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: doc,
                        child: Text(data['name'] ?? 'Unnamed Template'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Time Dropdown
                  Text('Time', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DocumentSnapshot>(
                    value: _selectedTime,
                    hint: const Text('Choose a time'),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                    items: _times.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String startTime = data['startTime'] ?? 'N/A';
                      final String endTime = data['endTime'] ?? 'N/A';
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: doc,
                        child: Text('${doc.id}: $startTime - $endTime'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Location Dropdown
                  Text('Location', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DocumentSnapshot>(
                    value: _selectedLocation,
                    hint: const Text('Choose a location'),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                    items: _locations.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<DocumentSnapshot>(
                        value: doc,
                        child: Text(data['name'] ?? 'Unnamed Location'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveSession,
                      child: const Text('Save Session'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
