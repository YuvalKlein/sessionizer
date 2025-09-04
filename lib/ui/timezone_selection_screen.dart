import 'package:flutter/material.dart';

class TimezoneSelectionScreen extends StatefulWidget {
  final String initialTimezone;

  const TimezoneSelectionScreen({super.key, required this.initialTimezone});

  @override
  State<TimezoneSelectionScreen> createState() =>
      _TimezoneSelectionScreenState();
}

class _TimezoneSelectionScreenState extends State<TimezoneSelectionScreen> {
  // A simplified list of timezones. In a real app, use a comprehensive library.
  static const List<String> _timezones = [
    'UTC',
    'America/New_York', // Eastern Time
    'America/Chicago', // Central Time
    'America/Denver', // Mountain Time
    'America/Los_Angeles', // Pacific Time
    'America/Anchorage', // Alaska Time
    'America/Phoenix', // Arizona Time
    'Pacific/Honolulu', // Hawaii Time
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Asia/Tokyo',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Australia/Sydney',
    'Australia/Adelaide',
    'Australia/Perth',
  ];

  late String _selectedTimezone;
  List<String> _filteredTimezones = _timezones;

  @override
  void initState() {
    super.initState();
    _selectedTimezone = widget.initialTimezone;
  }

  void _filterTimezones(String query) {
    setState(() {
      _filteredTimezones = _timezones
          .where((tz) => tz.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Timezone')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterTimezones,
              decoration: const InputDecoration(
                labelText: 'Search Timezones',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTimezones.length,
              itemBuilder: (context, index) {
                final timezone = _filteredTimezones[index];
                return RadioListTile<String>(
                  title: Text(timezone.replaceAll('_', ' ')),
                  value: timezone,
                  groupValue: _selectedTimezone,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedTimezone = value;
                      });
                      // Pop the screen and return the selected value
                      Navigator.of(context).pop(value);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
