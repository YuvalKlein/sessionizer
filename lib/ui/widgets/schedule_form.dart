import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/schedule.dart';

class ScheduleForm extends StatefulWidget {
  final Schedule? schedule;

  const ScheduleForm({super.key, this.schedule});

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule?.name ?? '');
    _isDefault = widget.schedule?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? 'New Schedule' : 'Edit Schedule'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Schedule Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            CheckboxListTile(
              title: const Text('Set as default'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSchedule,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // This should not happen, but as a safeguard:
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You are not logged in.')),
        );
      }
      return;
    }

    // --- CORRECT WAY TO HANDLE ASYNC OPERATIONS ---
    // Capture the Navigator and ScaffoldMessenger before the await.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final scheduleData = {
        'name': _nameController.text,
        'isDefault': _isDefault,
        'instructorId': user.uid,
      };

      final firestore = FirebaseFirestore.instance;

      if (_isDefault) {
        // If setting this as default, unset other defaults first.
        final querySnapshot = await firestore
            .collection('schedules')
            .where('instructorId', isEqualTo: user.uid)
            .where('isDefault', isEqualTo: true)
            .get();

        for (var doc in querySnapshot.docs) {
          if (widget.schedule == null || doc.id != widget.schedule!.id) {
            await doc.reference.update({'isDefault': false});
          }
        }
      }

      if (widget.schedule == null) {
        await firestore.collection('schedules').add(scheduleData);
      } else {
        await firestore
            .collection('schedules')
            .doc(widget.schedule!.id)
            .update(scheduleData);
      }

      navigator.pop(); // Use the captured navigator
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        // Use the captured messenger
        SnackBar(content: Text('Error saving schedule: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
