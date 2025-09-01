import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/schedule_service.dart';

class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({super.key});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedTimezone;

  // A simple list of timezones for the dropdown.
  final List<String> _timezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimezone = _timezones.first;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('New Schedule')),
      body: user == null
          ? const Center(child: Text('Please log in to add a schedule.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Schedule Name',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: const InputDecoration(labelText: 'Timezone'),
                      items: _timezones.map(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(), // This ensures we pass an Iterable of widgets
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTimezone = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _addSchedule(context, user.uid),
                      child: const Text('Add Schedule'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _addSchedule(BuildContext context, String instructorId) async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<ScheduleService>().createSchedule({
          'instructorId': instructorId,
          'name': _nameController.text,
          'timezone': _selectedTimezone!,
          'isDefault': false,
          'weeklyAvailability': {
            // Add a default empty availability
            'monday': [],
            'tuesday': [],
            'wednesday': [],
            'thursday': [],
            'friday': [],
            'saturday': [],
            'sunday': [],
          },
        });
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding schedule: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
