import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionTemplateForm extends StatefulWidget {
  final DocumentSnapshot? template;

  const SessionTemplateForm({super.key, this.template});

  @override
  State<SessionTemplateForm> createState() => _SessionTemplateFormState();
}

class _SessionTemplateFormState extends State<SessionTemplateForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text input
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  String _durationUnit = 'Hours';

  // State for boolean switches
  bool _notifyCancelation = true;
  bool _repeatingSession = false;
  bool _showParticipants = true;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      final data = widget.template!.data() as Map<String, dynamic>;
      final entity = data['sessionEntity'] as Map<String, dynamic>;
      _titleController.text = entity['title'] ?? '';
      _detailsController.text = entity['details'] ?? '';
      _categoryController.text = entity['category'] ?? '';
      _priceController.text = (entity['price'] ?? 0).toString();
      _maxPlayersController.text = (entity['maxPlayers'] ?? 0).toString();
      _minPlayersController.text = (entity['minPlayers'] ?? 0).toString();
      _durationController.text = (entity['duration'] ?? 0).toString();
      _durationUnit = entity['durationUnit'] ?? 'Hours';
      _notifyCancelation = entity['notifyCancelation'] ?? true;
      _repeatingSession = entity['repeatingSession'] ?? false;
      _showParticipants = entity['showParticipants'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _maxPlayersController.dispose();
    _minPlayersController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, do not proceed.
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a template.'),
        ),
      );
      return;
    }

    try {
      final sessionData = {
        'title': _titleController.text,
        'details': _detailsController.text,
        'category': _categoryController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'maxPlayers': int.tryParse(_maxPlayersController.text) ?? 0,
        'minPlayers': int.tryParse(_minPlayersController.text) ?? 0,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'durationUnit': _durationUnit,
        'timeZoneOffsetInHours': DateTime.now().timeZoneOffset.inHours,
        'notifyCancelation': _notifyCancelation,
        'repeatingSession': _repeatingSession,
        'showParticipants': _showParticipants,
        'createdTime': DateTime.now().millisecondsSinceEpoch,
        'idCreatedBy': user.uid,
        'idInstructor': user.uid,
        'canceled': false,
        'playersIds': [],
        'attendanceData': [],
      };

      if (widget.template != null) {
        // Update existing template
        await widget.template!.reference.update({'sessionEntity': sessionData});
      } else {
        // Create new template
        await FirebaseFirestore.instance.collection('sessionTemplates').add({
          'sessionEntity': sessionData,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Template ${widget.template != null ? 'updated' : 'saved'} successfully!',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving template: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing
                  ? 'Edit Session Template'
                  : 'Create New Session Template',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a price' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Min Players',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Max Players',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter a duration'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _durationUnit,
                  items: <String>['Hours', 'Minutes']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _durationUnit = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            SwitchListTile(
              title: const Text('Notify on Cancellation'),
              value: _notifyCancelation,
              onChanged: (val) => setState(() => _notifyCancelation = val),
            ),
            SwitchListTile(
              title: const Text('Repeating Session'),
              value: _repeatingSession,
              onChanged: (val) => setState(() => _repeatingSession = val),
            ),
            SwitchListTile(
              title: const Text('Show Participants List'),
              value: _showParticipants,
              onChanged: (val) => setState(() => _showParticipants = val),
            ),
            const Divider(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTemplate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditing ? 'Update Template' : 'Save Template'),
            ),
          ],
        ),
      ),
    );
  }
}
