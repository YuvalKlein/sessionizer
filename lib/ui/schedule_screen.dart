
import 'package:flutter/material.dart';
import 'package:myapp/models/availability_model.dart';
import 'package:myapp/services/availability_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/ui/widgets/availability_form.dart';

// This is the new screen where instructors will manage their availability.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AvailabilityService _availabilityService;
  late String _instructorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _availabilityService = AvailabilityService();
    final authService = Provider.of<AuthService>(context, listen: false);
    _instructorId = authService.currentUser!.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly Recurring'),
            Tab(text: 'Date Overrides'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyRecurringView(),
          _buildDateOverridesView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAvailabilityForm(),
        child: const Icon(Icons.add),
        tooltip: 'Add Availability',
      ),
    );
  }

  void _showAvailabilityForm({Availability? availability}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AvailabilityForm(availability: availability),
      ),
    );
  }

  Widget _buildWeeklyRecurringView() {
    return StreamBuilder<List<Availability>>(
      stream: _availabilityService.getAvailabilityForInstructor(_instructorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final allAvailability = snapshot.data ?? [];
        final weeklyAvailability = allAvailability.where((a) => a.type == 'weekly').toList();

        if (weeklyAvailability.isEmpty) {
          return const Center(child: Text('No weekly recurring availability set. Tap + to add one.'));
        }

        return ListView.builder(
          itemCount: 7,
          itemBuilder: (context, index) {
            final dayOfWeek = index + 1;
            final dayAvailability = weeklyAvailability.where((a) => a.dayOfWeek == dayOfWeek).toList();

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(_getDayOfWeekName(dayOfWeek)),
                children: dayAvailability.map((availability) {
                  return ListTile(
                    title: Text('${availability.startTime} - ${availability.endTime}'),
                    subtitle: Text('Break: ${availability.breakTime} mins'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAvailabilityForm(availability: availability),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _availabilityService.deleteAvailability(availability.id);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateOverridesView() {
    return StreamBuilder<List<Availability>>(
      stream: _availabilityService.getAvailabilityForInstructor(_instructorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final allAvailability = snapshot.data ?? [];
        final dateOverrides = allAvailability.where((a) => a.type == 'date').toList();

        if (dateOverrides.isEmpty) {
          return const Center(child: Text('No date overrides set. Tap + to add one.'));
        }

        return ListView.builder(
          itemCount: dateOverrides.length,
          itemBuilder: (context, index) {
            final availability = dateOverrides[index];
            final date = DateFormat.yMMMd().format(availability.date!);

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text('$date: ${availability.startTime} - ${availability.endTime}'),
                subtitle: Text('Break: ${availability.breakTime} mins'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAvailabilityForm(availability: availability),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _availabilityService.deleteAvailability(availability.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
