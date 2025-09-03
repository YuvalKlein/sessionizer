import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/availability_slot.dart';
import 'package:myapp/services/availability_service.dart';
import 'package:myapp/services/auth_service.dart';

/// Demo screen to showcase the availability calculation engine
class AvailabilityDemoScreen extends StatefulWidget {
  const AvailabilityDemoScreen({super.key});

  @override
  State<AvailabilityDemoScreen> createState() => _AvailabilityDemoScreenState();
}

class _AvailabilityDemoScreenState extends State<AvailabilityDemoScreen> {
  DateTime _selectedDate = DateTime.now();
  List<DayAvailability> _availability = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    print('=== LOADING AVAILABILITY ===');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final availabilityService = context.read<AvailabilityService>();
      final user = authService.currentUser;
      
      print('User: ${user?.uid}');
      
      if (user == null) {
        print('ERROR: User not authenticated');
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endDate = startDate.add(Duration(days: 7)); // Load week view

      print('Calling availability service...');
      final availability = await availabilityService.getAvailabilityForDateRange(
        instructorId: user.uid,
        startDate: startDate,
        endDate: endDate,
        slotDurationMinutes: 60, // 1-hour slots
      );

      print('Got ${availability.length} days of availability');
      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading availability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _loadAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Engine Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailability,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _buildAvailabilityContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text('Week starting: ${_selectedDate.toString().split(' ')[0]}'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildAvailabilityContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calculating availability...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailability,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availability.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No schedulable sessions found'),
            SizedBox(height: 8),
            Text(
              'Create schedulable sessions to see availability',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availability.length,
      itemBuilder: (context, index) {
        final dayAvailability = _availability[index];
        return _buildDayCard(dayAvailability);
      },
    );
  }

  Widget _buildDayCard(DayAvailability dayAvailability) {
    final date = dayAvailability.date;
    final dayName = _getDayName(date.weekday);
    final dateStr = '${date.month}/${date.day}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: dayAvailability.hasAvailability 
              ? Colors.green 
              : Colors.grey,
          child: Text(
            dateStr.split('/')[1],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('$dayName, $dateStr'),
        subtitle: Text(
          dayAvailability.hasAvailability
              ? '${dayAvailability.availableSlots.length} available slots'
              : 'No availability',
        ),
        children: [
          if (dayAvailability.slots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No schedulable sessions configured for this day',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...dayAvailability.slots.map((slot) => _buildSlotTile(slot)),
        ],
      ),
    );
  }

  Widget _buildSlotTile(AvailabilitySlot slot) {
    final startTime = TimeOfDay.fromDateTime(slot.startTime);
    final endTime = TimeOfDay.fromDateTime(slot.endTime);
    
    return ListTile(
      dense: true,
      leading: Icon(
        slot.isAvailable ? Icons.check_circle : Icons.cancel,
        color: slot.isAvailable ? Colors.green : Colors.red,
        size: 20,
      ),
      title: Text(
        '${startTime.format(context)} - ${endTime.format(context)}',
        style: TextStyle(
          color: slot.isAvailable ? null : Colors.grey,
          fontWeight: slot.isAvailable ? FontWeight.w500 : null,
        ),
      ),
      subtitle: slot.conflictReason != null 
          ? Text(
              slot.conflictReason!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
          : Text(
              'Duration: ${slot.duration}min (${slot.bufferBefore}min buffer + ${slot.bufferAfter}min buffer)',
              style: const TextStyle(fontSize: 12),
            ),
      trailing: slot.isAvailable 
          ? TextButton(
              onPressed: () => _showBookingDialog(slot),
              child: const Text('Book'),
            )
          : null,
    );
  }

  void _showBookingDialog(AvailabilitySlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${TimeOfDay.fromDateTime(slot.sessionStartTime).format(context)} - ${TimeOfDay.fromDateTime(slot.sessionEndTime).format(context)}'),
            Text('Duration: ${slot.duration} minutes'),
            Text('Session Type ID: ${slot.sessionTypeId}'),
            Text('Locations: ${slot.locationIds.join(', ')}'),
            const SizedBox(height: 16),
            const Text(
              'This is a demo. In a real app, this would open a booking form.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking demo completed!')),
              );
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
