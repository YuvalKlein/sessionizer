
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/availability_model.dart';
import 'package:myapp/models/session_template_model.dart';
import 'package:myapp/services/availability_service.dart';
import 'package:myapp/services/session_template_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';

class AvailabilityForm extends StatefulWidget {
  final Availability? availability; // Optional availability to edit

  const AvailabilityForm({Key? key, this.availability}) : super(key: key);

  @override
  _AvailabilityFormState createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<AvailabilityForm> {
  final _formKey = GlobalKey<FormState>();
  late AvailabilityService _availabilityService;
  late SessionTemplateService _sessionTemplateService;
  late String _instructorId;

  String _type = 'weekly';
  int? _dayOfWeek;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _breakTime = 0;
  int? _customDuration;
  int _daysInFuture = 7;
  int _bookingLeadTime = 0;
  List<String> _selectedTemplates = [];

  @override
  void initState() {
    super.initState();
    _availabilityService = AvailabilityService();
    _sessionTemplateService = SessionTemplateService();
    final authService = Provider.of<AuthService>(context, listen: false);
    _instructorId = authService.currentUser!.uid;

    if (widget.availability != null) {
      final availability = widget.availability!;
      _type = availability.type;
      _dayOfWeek = availability.dayOfWeek;
      _date = availability.date;
      _startTime = TimeOfDay(hour: int.parse(availability.startTime.split(':')[0]), minute: int.parse(availability.startTime.split(':')[1]));
      _endTime = TimeOfDay(hour: int.parse(availability.endTime.split(':')[0]), minute: int.parse(availability.endTime.split(':')[1]));
      _breakTime = availability.breakTime;
      _customDuration = availability.customDuration;
      _daysInFuture = availability.daysInFuture;
      _bookingLeadTime = availability.bookingLeadTime;
      _selectedTemplates = availability.allowedSessionTemplates;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildTypeSelector(),
            if (_type == 'weekly') _buildDayOfWeekSelector(),
            if (_type == 'date') _buildDateSelector(),
            _buildTimePickers(),
            _buildNumericField(initialValue: _breakTime.toString(), label: 'Break Time (minutes)', onSaved: (value) => _breakTime = int.parse(value!)),
            _buildNumericField(initialValue: _customDuration?.toString(), label: 'Custom Duration (minutes)', onSaved: (value) => _customDuration = value!.isNotEmpty ? int.parse(value) : null),
            _buildNumericField(initialValue: _daysInFuture.toString(), label: 'Days in Future', onSaved: (value) => _daysInFuture = int.parse(value!)),
            _buildNumericField(initialValue: _bookingLeadTime.toString(), label: 'Booking Lead Time (minutes)', onSaved: (value) => _bookingLeadTime = int.parse(value!)),
            _buildTemplateSelector(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Save Availability'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _type,
      decoration: const InputDecoration(labelText: 'Availability Type'),
      items: const [
        DropdownMenuItem(value: 'weekly', child: Text('Weekly Recurring')),
        DropdownMenuItem(value: 'date', child: Text('Specific Date')),
      ],
      onChanged: (value) {
        setState(() {
          _type = value!;
        });
      },
    );
  }

  Widget _buildDayOfWeekSelector() {
    return DropdownButtonFormField<int>(
      value: _dayOfWeek,
      decoration: const InputDecoration(labelText: 'Day of Week'),
      items: List.generate(7, (index) {
        return DropdownMenuItem(value: index + 1, child: Text(_getDayOfWeekName(index + 1)));
      }),
      onChanged: (value) {
        setState(() {
          _dayOfWeek = value;
        });
      },
      validator: (value) => _type == 'weekly' && value == null ? 'Please select a day' : null,
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      title: Text(_date == null ? 'Select Date' : DateFormat.yMMMd().format(_date!)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          setState(() {
            _date = pickedDate;
          });
        }
      },
    );
  }

  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: Text(_startTime == null ? 'Start Time' : _startTime!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final pickedTime = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
              if (pickedTime != null) {
                setState(() {
                  _startTime = pickedTime;
                });
              }
            },
          ),
        ),
        Expanded(
          child: ListTile(
            title: Text(_endTime == null ? 'End Time' : _endTime!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final pickedTime = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
              if (pickedTime != null) {
                setState(() {
                  _endTime = pickedTime;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNumericField({String? initialValue, required String label, required FormFieldSetter<String> onSaved}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a value';
        if (int.tryParse(value) == null) return 'Please enter a valid number';
        return null;
      },
    );
  }

  Widget _buildTemplateSelector() {
    return StreamBuilder<List<SessionTemplate>>(
      stream: _sessionTemplateService.getSessionTemplatesForInstructor(_instructorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final templates = snapshot.data!;
        return DropdownButtonFormField<List<String>>(
          decoration: const InputDecoration(labelText: 'Allowed Session Templates'),
          isExpanded: true,
          value: _selectedTemplates,
          items: templates.map((template) {
            return DropdownMenuItem(
              value: [template.id],
              child: Text(template.title),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTemplates = value!;
            });
          },
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newAvailability = Availability(
        id: widget.availability?.id ?? '', // Keep existing id if editing
        instructorId: _instructorId,
        type: _type,
        dayOfWeek: _dayOfWeek,
        date: _date,
        startTime: '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        breakTime: _breakTime,
        customDuration: _customDuration,
        daysInFuture: _daysInFuture,
        bookingLeadTime: _bookingLeadTime,
        allowedSessionTemplates: _selectedTemplates,
      );

      if (widget.availability == null) {
        _availabilityService.createAvailability(newAvailability);
      } else {
        _availabilityService.updateAvailability(newAvailability);
      }

      Navigator.of(context).pop();
    }
  }

  String _getDayOfWeekName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}
