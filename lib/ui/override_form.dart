import 'package:flutter/material.dart';

class OverrideForm extends StatefulWidget {
  final String scheduleId;
  const OverrideForm({super.key, required this.scheduleId});

  @override
  State<OverrideForm> createState() => _OverrideFormState();
}

class _OverrideFormState extends State<OverrideForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Override')),
      body: const Center(child: Text('Override Form')),
    );
  }
}
