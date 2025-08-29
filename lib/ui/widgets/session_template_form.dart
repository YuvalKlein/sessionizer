import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SessionTemplateForm extends StatefulWidget {
  const SessionTemplateForm({super.key});

  @override
  State<SessionTemplateForm> createState() => _SessionTemplateFormState();
}

class _SessionTemplateFormState extends State<SessionTemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('templates').add({
          'name': _nameController.text,
          'minPlayers': int.parse(_minPlayersController.text),
          'maxPlayers': int.parse(_maxPlayersController.text),
          'price': int.parse(_priceController.text),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully!')),
        );

        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving template: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Session Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session name';
                }
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPlayersController,
                    decoration: const InputDecoration(labelText: 'Min Players'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a minimum number of players';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxPlayersController,
                    decoration: const InputDecoration(labelText: 'Max Players'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a maximum number of players';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTemplate,
              child: const Text('Save Template'),
            ),
          ],
        ),
      ),
    );
  }
}
