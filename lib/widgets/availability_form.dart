import 'package:flutter/material.dart';
import 'package:myapp/models/availability_model.dart';

class AvailabilityForm extends StatefulWidget {
  final Availability? availability;
  final Function(Availability) onSubmit;

  const AvailabilityForm({
    super.key,
    this.availability,
    required this.onSubmit,
  });

  @override
  _AvailabilityFormState createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<AvailabilityForm> {
  final _formKey = GlobalKey<FormState>();
  late String _dayOfWeek;
  late List<Map<String, String>> _timeSlots;

  @override
  void initState() {
    super.initState();
    _dayOfWeek = widget.availability?.dayOfWeek ?? 'Monday';
    _timeSlots = widget.availability?.timeSlots ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _dayOfWeek,
            items:
                [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ]
                    .map(
                      (day) => DropdownMenuItem(value: day, child: Text(day)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _dayOfWeek = value!),
            decoration: const InputDecoration(labelText: 'Day of Week'),
          ),
          // Add time slot management here
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onSubmit(
                  Availability(
                    id: widget.availability?.id ?? '',
                    scheduleId: '', // This should be set from the parent
                    dayOfWeek: _dayOfWeek,
                    timeSlots: _timeSlots,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
