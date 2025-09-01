import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionTypeForm extends StatefulWidget {
  final DocumentSnapshot? type;

  const SessionTypeForm({super.key, this.type});

  @override
  State<SessionTypeForm> createState() => _SessionTypeFormState();
}

class _SessionTypeFormState extends State<SessionTypeForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text input
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  // State for boolean switches
  bool _notifyCancelation = true;
  bool _repeatingSession = false;
  bool _showParticipants = true;

  @override
  void initState() {
    super.initState();
    if (widget.type != null) {
      final data = widget.type!.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _detailsController.text = data['details'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _maxPlayersController.text = (data['maxPlayers'] ?? 0).toString();
      _minPlayersController.text = (data['minPlayers'] ?? 0).toString();
      _durationController.text = (data['durationInMinutes'] ?? 0).toString();
      _notifyCancelation = data['notifyCancelation'] ?? true;
      _repeatingSession = data['repeatingSession'] ?? false;
      _showParticipants = data['showParticipants'] ?? true;
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

  Future<void> _saveType() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, do not proceed.
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a session type.'),
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
        'durationInMinutes': int.tryParse(_durationController.text) ?? 0,
        'notifyCancelation': _notifyCancelation,
        'repeatingSession': _repeatingSession,
        'showParticipants': _showParticipants,
        'instructorId': user.uid,
      };

      if (widget.type != null) {
        // Update existing type
        await widget.type!.reference.update(sessionData);
      } else {
        // Create new type
        await FirebaseFirestore.instance
            .collection('sessionTypes')
            .add(sessionData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session type ${widget.type != null ? 'updated' : 'saved'} successfully!',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving session type: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.type != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit Session Type' : 'Create New Session Type',
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
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a duration' : null,
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
              onPressed: _saveType,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditing ? 'Update Type' : 'Save Type'),
            ),
          ],
        ),
      ),
    );
  }
}
