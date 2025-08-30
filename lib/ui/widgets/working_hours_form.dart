import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkingHoursForm extends StatefulWidget {
  const WorkingHoursForm({super.key});

  @override
  State<WorkingHoursForm> createState() => _WorkingHoursFormState();
}

class _WorkingHoursFormState extends State<WorkingHoursForm> {
  final Map<String, TimeOfDay> _startTimes = {
    'Sunday': const TimeOfDay(hour: 0, minute: 0),
    'Monday': const TimeOfDay(hour: 0, minute: 0),
    'Tuesday': const TimeOfDay(hour: 0, minute: 0),
    'Wednesday': const TimeOfDay(hour: 0, minute: 0),
    'Thursday': const TimeOfDay(hour: 0, minute: 0),
    'Friday': const TimeOfDay(hour: 0, minute: 0),
    'Saturday': const TimeOfDay(hour: 0, minute: 0),
  };

  final Map<String, TimeOfDay> _endTimes = {
    'Sunday': const TimeOfDay(hour: 0, minute: 0),
    'Monday': const TimeOfDay(hour: 0, minute: 0),
    'Tuesday': const TimeOfDay(hour: 0, minute: 0),
    'Wednesday': const TimeOfDay(hour: 0, minute: 0),
    'Thursday': const TimeOfDay(hour: 0, minute: 0),
    'Friday': const TimeOfDay(hour: 0, minute: 0),
    'Saturday': const TimeOfDay(hour: 0, minute: 0),
  };

  Future<void> _selectTime(BuildContext context, String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTimes[day]! : _endTimes[day]!,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[day] = picked;
        } else {
          _endTimes[day] = picked;
        }
      });
    }
  }

  Future<void> _saveHours() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      _startTimes.forEach((day, startTime) {
        final endTime = _endTimes[day]!;
        final docRef = FirebaseFirestore.instance.collection('times').doc(day);
        batch.set(docRef, {
          'startTime': '${startTime.hour}:${startTime.minute}',
          'endTime': '${endTime.hour}:${endTime.minute}',
        });
      });
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hours saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving hours: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ..._startTimes.keys.map((day) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _selectTime(context, day, true),
                        child: Text(_startTimes[day]!.format(context)),
                      ),
                      const Text('-'),
                      TextButton(
                        onPressed: () => _selectTime(context, day, false),
                        child: Text(_endTimes[day]!.format(context)),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveHours,
              child: const Text('Save Hours'),
            ),
          ],
        ),
      ),
    );
  }
}
