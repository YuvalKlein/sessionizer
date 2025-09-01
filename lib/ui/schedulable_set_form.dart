import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SchedulableSetForm extends StatefulWidget {
  final DocumentSnapshot? schedulableSessionDoc;

  const SchedulableSetForm({super.key, this.schedulableSessionDoc});

  @override
  State<SchedulableSetForm> createState() => _SchedulableSetFormState();
}

class _SchedulableSetFormState extends State<SchedulableSetForm> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _selectedTypeIds = [];
  final List<String> _selectedLocationIds = [];
  final List<String> _selectedAvailabilityIds = [];

  final _breakTimeController = TextEditingController();
  final _bookingLeadTimeController = TextEditingController();
  final _futureBookingLimitController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.schedulableSessionDoc != null) {
      final data = widget.schedulableSessionDoc!.data() as Map<String, dynamic>;
      _selectedTypeIds.addAll(List<String>.from(data['typeIds'] ?? []));
      _selectedLocationIds.addAll(List<String>.from(data['locationIds'] ?? []));
      _selectedAvailabilityIds.addAll(
        List<String>.from(data['availabilityIds'] ?? []),
      );

      _breakTimeController.text = (data['breakTimeInMinutes'] ?? '').toString();
      _bookingLeadTimeController.text = (data['bookingLeadTimeInMinutes'] ?? '')
          .toString();
      _futureBookingLimitController.text =
          (data['futureBookingLimitInDays'] ?? '').toString();
      _durationController.text = (data['durationOverride'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _breakTimeController.dispose();
    _bookingLeadTimeController.dispose();
    _futureBookingLimitController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedTypeIds.isEmpty ||
        _selectedLocationIds.isEmpty ||
        _selectedAvailabilityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please make selections for session types, locations, and availability.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to perform this action.'),
        ),
      );
      return;
    }

    try {
      final setData = {
        'typeIds': _selectedTypeIds,
        'locationIds': _selectedLocationIds,
        'availabilityIds': _selectedAvailabilityIds,
        'breakTimeInMinutes': int.tryParse(_breakTimeController.text) ?? 0,
        'bookingLeadTimeInMinutes':
            int.tryParse(_bookingLeadTimeController.text) ?? 30,
        'futureBookingLimitInDays':
            int.tryParse(_futureBookingLimitController.text) ?? 7,
        'durationOverride': int.tryParse(_durationController.text),
        'instructorId': user.uid,
        'createdTimestamp': FieldValue.serverTimestamp(),
      };

      if (widget.schedulableSessionDoc != null) {
        await widget.schedulableSessionDoc!.reference.update(setData);
      } else {
        await FirebaseFirestore.instance
            .collection('schedulableSessions')
            .add(setData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configuration ${widget.schedulableSessionDoc != null ? 'updated' : 'saved'} successfully!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving configuration: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isEditing = widget.schedulableSessionDoc != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Schedulable Set' : 'Create Schedulable Set',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSet),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMultiSelectSection(
                title: 'Session Types',
                stream: FirebaseFirestore.instance
                    .collection('sessionTypes')
                    .where('instructorId', isEqualTo: user?.uid)
                    .snapshots(),
                selectedIds: _selectedTypeIds,
                displayField: 'title',
              ),
              _buildMultiSelectSection(
                title: 'Locations',
                stream: FirebaseFirestore.instance
                    .collection('locations')
                    .where('instructorId', isEqualTo: user?.uid)
                    .snapshots(),
                selectedIds: _selectedLocationIds,
                displayField: 'name',
              ),
              _buildMultiSelectSection(
                title: 'Availability Slots',
                stream: FirebaseFirestore.instance
                    .collection('availabilities')
                    .where('instructorId', isEqualTo: user?.uid)
                    .snapshots(),
                selectedIds: _selectedAvailabilityIds,
                displayField: 'dayOfWeek',
                displayBuilder: (doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final day = data['dayOfWeek'];
                  final start = data['startTime'];
                  final end = data['endTime'];
                  return 'Day: $day, $start - $end';
                },
              ),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEditing ? 'Update Configuration' : 'Save Configuration',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required Stream<QuerySnapshot> stream,
    required List<String> selectedIds,
    required String displayField,
    String Function(DocumentSnapshot doc)? displayBuilder,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Error loading data.');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Text(
                    'No items found. Please create some first.',
                  );

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final display = displayBuilder != null
                        ? displayBuilder(doc)
                        : data[displayField];

                    return CheckboxListTile(
                      title: Text(display),
                      value: selectedIds.contains(doc.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedIds.add(doc.id);
                          } else {
                            selectedIds.remove(doc.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breakTimeController,
              decoration: const InputDecoration(
                labelText: 'Break Time (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingLeadTimeController,
              decoration: const InputDecoration(
                labelText: 'Booking Lead Time (minutes)',
                helperText: 'How long before a session can users book?',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _futureBookingLimitController,
              decoration: const InputDecoration(
                labelText: 'Future Booking Limit (days)',
                helperText: 'How far in the future can users book?',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration Override (minutes)',
                helperText: 'Optional: Overrides the session type duration.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }
}
