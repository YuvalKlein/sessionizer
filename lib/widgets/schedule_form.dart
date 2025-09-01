import 'package:flutter/material.dart';
import 'package:myapp/models/schedule.dart';

class ScheduleForm extends StatefulWidget {
  final Schedule? schedule;
  final Function(Schedule) onSubmit;

  const ScheduleForm({super.key, this.schedule, required this.onSubmit});

  @override
  _ScheduleFormState createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late bool _isDefault;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    _name = widget.schedule?.name ?? '';
    _isDefault = widget.schedule?.isDefault ?? false;
    _timezone = widget.schedule?.timezone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: _name,
            decoration: const InputDecoration(labelText: 'Schedule Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
            onSaved: (value) => _name = value!,
          ),
          SwitchListTile(
            title: const Text('Default Schedule'),
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
          ),
          TextFormField(
            initialValue: _timezone,
            decoration: const InputDecoration(labelText: 'Timezone'),
            onSaved: (value) => _timezone = value!,
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onSubmit(
                  Schedule(
                    id: widget.schedule?.id ?? '',
                    instructorId:
                        '', // This should be set based on the logged in user
                    name: _name,
                    isDefault: _isDefault,
                    timezone: _timezone,
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
