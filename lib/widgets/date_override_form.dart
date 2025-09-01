import 'package:flutter/material.dart';
import 'package:myapp/models/availability_override.dart';

class DateOverrideForm extends StatefulWidget {
  final AvailabilityOverride? override;
  final Function(AvailabilityOverride) onSubmit;

  const DateOverrideForm({super.key, this.override, required this.onSubmit});

  State<DateOverrideForm> createState() => _DateOverrideFormState();
}

class _DateOverrideFormState extends State<DateOverrideForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  late DateTime _endDate;
  late OverrideType _type;
  late List<Map<String, String>> _timeSlots;

  @override
  void initState() {
    super.initState();
    _startDate = widget.override?.startDate ?? DateTime.now();
    _endDate = widget.override?.endDate ?? DateTime.now();
    _type = widget.override?.type ?? OverrideType.inclusion;
    _timeSlots = widget.override?.timeSlots ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Add date pickers for start and end date
          DropdownButtonFormField<OverrideType>(
            value: _type,
            items: OverrideType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _type = value!),
            decoration: const InputDecoration(labelText: 'Override Type'),
          ),
          // Add time slot management here
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onSubmit(
                  AvailabilityOverride(
                    id: widget.override?.id ?? '',
                    scheduleId: '', // This should be set from the parent
                    startDate: _startDate,
                    endDate: _endDate,
                    type: _type,
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
