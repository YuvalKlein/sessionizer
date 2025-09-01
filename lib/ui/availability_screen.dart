import 'package:flutter/material.dart';
import 'package:myapp/ui/widgets/weekly_hours_editor.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Default Weekly Availability')),
      body: const WeeklyHoursEditor(),
    );
  }
}
