import 'package:flutter/material.dart';
import 'package:myapp/ui/widgets/location_form.dart';
import 'package:myapp/ui/widgets/session_template_form.dart';
import 'package:myapp/ui/widgets/template_list_view.dart';
import 'package:myapp/ui/widgets/working_hours_form.dart';

class SetScreen extends StatefulWidget {
  const SetScreen({super.key});

  @override
  State<SetScreen> createState() => _SetScreenState();
}

class _SetScreenState extends State<SetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild the widget to show/hide the FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateAndCreateTemplate() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Create New Template')),
        body: const SessionTemplateForm(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Templates'),
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Hours'),
            Tab(icon: Icon(Icons.location_on), text: 'Locations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TemplateListView(),
          WorkingHoursForm(),
          LocationForm(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _navigateAndCreateTemplate,
              tooltip: 'Create New Template',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
