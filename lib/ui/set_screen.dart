import 'package:flutter/material.dart';
import 'package:myapp/ui/widgets/location_form.dart';
import 'package:myapp/ui/widgets/session_template_form.dart';
import 'package:myapp/ui/widgets/working_hours_form.dart';

class SetScreen extends StatelessWidget {
  const SetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Templates'),
              Tab(text: 'Hours'),
              Tab(text: 'Locations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SessionTemplateForm(),
            WorkingHoursForm(),
            LocationForm(),
          ],
        ),
      ),
    );
  }
}
