import 'package:flutter/material.dart';
import 'package:myapp/models/session_type.dart';

class SessionTypeForm extends StatefulWidget {
  final SessionType? sessionType;
  final Function(SessionType) onSave;

  const SessionTypeForm({super.key, this.sessionType, required this.onSave});

  @override
  State<SessionTypeForm> createState() => _SessionTypeFormState();
}

class _SessionTypeFormState extends State<SessionTypeForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _details;
  late int _price;
  late int _minPlayers;
  late int _maxPlayers;
  late int _duration;
  late String _durationUnit;
  late bool _repeatingSession;
  late bool _showParticipants;

  @override
  void initState() {
    super.initState();
    _title = widget.sessionType?.title ?? '';
    _details = widget.sessionType?.details ?? '';
    _price = widget.sessionType?.price ?? 0;
    _minPlayers = widget.sessionType?.minPlayers ?? 0;
    _maxPlayers = widget.sessionType?.maxPlayers ?? 10;
    _duration = widget.sessionType?.duration ?? 1;
    _durationUnit = widget.sessionType?.durationUnit ?? 'Hours';
    _repeatingSession = widget.sessionType?.repeatingSession ?? false;
    _showParticipants = widget.sessionType?.showParticipants ?? true;
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newSessionType = SessionType(
        id: widget.sessionType?.id,
        title: _title,
        details: _details,
        price: _price,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        duration: _duration,
        durationUnit: _durationUnit,
        repeatingSession: _repeatingSession,
        showParticipants: _showParticipants,
        // The service will fill in the rest of the required fields
        createdTime: widget.sessionType?.createdTime ?? 0,
        idCreatedBy: widget.sessionType?.idCreatedBy ?? '',
        idInstructor: widget.sessionType?.idInstructor ?? '',
      );
      widget.onSave(newSessionType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _title,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a title' : null,
            onSaved: (value) => _title = value!,
          ),
          TextFormField(
            initialValue: _details,
            decoration: const InputDecoration(labelText: 'Description'),
            onSaved: (value) => _details = value ?? '',
          ),
          TextFormField(
            initialValue: _price.toString(),
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
            onSaved: (value) => _price = int.tryParse(value!) ?? 0,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _minPlayers.toString(),
                  decoration: const InputDecoration(labelText: 'Min Players'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter min players' : null,
                  onSaved: (value) => _minPlayers = int.tryParse(value!) ?? 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _maxPlayers.toString(),
                  decoration: const InputDecoration(labelText: 'Max Players'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter max players' : null,
                  onSaved: (value) => _maxPlayers = int.tryParse(value!) ?? 0,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _duration.toString(),
                  decoration: const InputDecoration(labelText: 'Duration'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a duration' : null,
                  onSaved: (value) => _duration = int.tryParse(value!) ?? 0,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _durationUnit,
                items: <String>['Minutes', 'Hours']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _durationUnit = newValue!;
                  });
                },
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Repeat Session'),
            value: _repeatingSession,
            onChanged: (bool value) {
              setState(() {
                _repeatingSession = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Show Participants'),
            value: _showParticipants,
            onChanged: (bool value) {
              setState(() {
                _showParticipants = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveForm,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
