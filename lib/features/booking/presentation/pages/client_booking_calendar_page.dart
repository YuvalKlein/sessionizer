import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart';

class ClientBookingCalendarPage extends StatefulWidget {
  final Map<String, dynamic> template;

  const ClientBookingCalendarPage({
    super.key,
    required this.template,
  });

  @override
  State<ClientBookingCalendarPage> createState() => _ClientBookingCalendarPageState();
}

class _ClientBookingCalendarPageState extends State<ClientBookingCalendarPage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _schedule;
  Map<String, dynamic>? _sessionType;
  Map<String, dynamic>? _location;
  List<Map<String, dynamic>> _existingBookings = [];

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load schedule data
      if (widget.template['scheduleId'] != null) {
        final scheduleDoc = await FirestoreCollections.schedule(widget.template['scheduleId']).get();
        if (scheduleDoc.exists) {
          _schedule = {'id': scheduleDoc.id, ...scheduleDoc.data() as Map<String, dynamic>};
        }
      }

      // Load session type data
      if (widget.template['sessionTypeId'] != null) {
        final sessionTypeDoc = await FirestoreCollections.sessionType(widget.template['sessionTypeId']).get();
        if (sessionTypeDoc.exists) {
          _sessionType = {'id': sessionTypeDoc.id, ...sessionTypeDoc.data() as Map<String, dynamic>};
        }
      }

      // Load location data
      if (widget.template['locationIds'] != null && 
          (widget.template['locationIds'] as List).isNotEmpty) {
        final locationId = (widget.template['locationIds'] as List).first;
        final locationDoc = await FirestoreCollections.location(locationId).get();
        if (locationDoc.exists) {
          _location = {'id': locationDoc.id, ...locationDoc.data() as Map<String, dynamic>};
        }
      }

      // Load existing bookings for the instructor
      if (widget.template['instructorId'] != null) {
        final bookingsSnapshot = await FirestoreCollections.bookings
            .where('instructorId', isEqualTo: widget.template['instructorId'])
            .get();
        
        _existingBookings = bookingsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      }

      // Calculate available slots for the selected date
      await _calculateAvailableSlots();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load template data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAvailableSlots() async {
    if (_schedule == null) {
      setState(() {
        _availableSlots = [];
        _error = 'Schedule not found';
      });
      return;
    }

    final availableSlots = <Map<String, dynamic>>[];
    final slotInterval = widget.template['slotIntervalMinutes'] ?? 60;
    final bufferBefore = widget.template['bufferBefore'] ?? 0;
    final bufferAfter = widget.template['bufferAfter'] ?? 0;
    final minHoursAhead = widget.template['minHoursAhead'] ?? 2;
    final maxDaysAhead = widget.template['maxDaysAhead'] ?? 7;

    // Check if the selected date is within booking window
    final now = DateTime.now();
    final minDate = now.add(Duration(hours: minHoursAhead));
    final maxDate = now.add(Duration(days: maxDaysAhead));
    
    if (_selectedDate.isBefore(minDate) || _selectedDate.isAfter(maxDate)) {
      setState(() {
        _availableSlots = [];
        _error = 'Selected date is outside booking window';
      });
      return;
    }

    // Get available time ranges for the selected date
    final availableRanges = _getAvailableTimeRanges(_selectedDate);
    
    // Generate time slots within available ranges
    for (final range in availableRanges) {
      final startTime = range['start'] as DateTime;
      final endTime = range['end'] as DateTime;
      
      DateTime current = startTime;
      while (current.add(Duration(minutes: slotInterval)).isBefore(endTime) || 
             current.add(Duration(minutes: slotInterval)).isAtSameMomentAs(endTime)) {
        
        final slotStart = current;
        final slotEnd = current.add(Duration(minutes: slotInterval));
        
        // Check if this slot conflicts with existing bookings
        if (!_isSlotBooked(slotStart, slotEnd, bufferBefore, bufferAfter)) {
          availableSlots.add({
            'start': slotStart,
            'end': slotEnd,
            'formatted': _formatTimeSlot(slotStart, slotEnd),
          });
        }
        
        current = current.add(Duration(minutes: slotInterval));
      }
    }

    setState(() {
      _availableSlots = availableSlots;
      _error = availableSlots.isEmpty ? 'No available slots for this date' : null;
    });
  }

  List<Map<String, dynamic>> _getAvailableTimeRanges(DateTime date) {
    if (_schedule == null) return [];

    final weekday = _getWeekdayName(date.weekday);
    final ranges = <Map<String, dynamic>>[];

    // Check if it's a holiday
    if (_isHoliday(date)) {
      return ranges; // No availability on holidays
    }

    // Check specific dates first
    final specificDates = _schedule!['specificDates'] as Map<String, dynamic>? ?? {};
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    if (specificDates.containsKey(dateKey)) {
      final specificDate = specificDates[dateKey] as Map<String, dynamic>;
      
      if (specificDate['isUnavailable'] == true) {
        return ranges; // No availability
      }
      
      // Use specific date times
      final times = specificDate['times'] as List<dynamic>? ?? [];
      for (final time in times) {
        final timeMap = time as Map<String, dynamic>;
        final startTime = _parseTime(date, timeMap['start'] as String);
        final endTime = _parseTime(date, timeMap['end'] as String);
        ranges.add({'start': startTime, 'end': endTime});
      }
    } else {
      // Use weekly availability
      final weeklyAvailability = _schedule!['weeklyAvailability'] as Map<String, dynamic>? ?? {};
      final dayAvailability = weeklyAvailability[weekday] as List<dynamic>? ?? [];
      
      for (final time in dayAvailability) {
        final timeMap = time as Map<String, dynamic>;
        final startTime = _parseTime(date, timeMap['start'] as String);
        final endTime = _parseTime(date, timeMap['end'] as String);
        ranges.add({'start': startTime, 'end': endTime});
      }
    }

    return ranges;
  }

  bool _isHoliday(DateTime date) {
    if (_schedule == null) return false;
    
    final holidays = _schedule!['holidays'] as List<dynamic>? ?? [];
    
    for (final holiday in holidays) {
      final holidayMap = holiday as Map<String, dynamic>;
      final startDate = (holidayMap['startDate'] as Timestamp).toDate();
      final endDate = (holidayMap['endDate'] as Timestamp).toDate();
      
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    return false;
  }

  bool _isSlotBooked(DateTime slotStart, DateTime slotEnd, int bufferBefore, int bufferAfter) {
    final effectiveStart = slotStart.subtract(Duration(minutes: bufferBefore));
    final effectiveEnd = slotEnd.add(Duration(minutes: bufferAfter));
    
    for (final booking in _existingBookings) {
      final bookingStart = (booking['startTime'] as Timestamp).toDate();
      final bookingEnd = (booking['endTime'] as Timestamp).toDate();
      
      // Check for overlap
      if (effectiveStart.isBefore(bookingEnd) && effectiveEnd.isAfter(bookingStart)) {
        return true;
      }
    }
    
    return false;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return weekdays[weekday - 1];
  }

  DateTime _parseTime(DateTime date, String timeStr) {
    final time = DateFormat('h:mm a').parse(timeStr);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTimeSlot(DateTime start, DateTime end) {
    final startStr = DateFormat('h:mm a').format(start);
    final endStr = DateFormat('h:mm a').format(end);
    return '$startStr - $endStr';
  }

  Future<void> _bookSlot(Map<String, dynamic> slot) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book a session')),
        );
        return;
      }

      // Create booking
      final bookingData = {
        'instructorId': widget.template['instructorId'],
        'clientId': user.uid,
        'clientName': user.displayName ?? 'Unknown',
        'clientEmail': user.email ?? '',
        'scheduleId': widget.template['scheduleId'],
        'bookableSessionId': widget.template['id'],
        'sessionTypeId': widget.template['sessionTypeId'],
        'locationId': (widget.template['locationIds'] as List).first,
        'startTime': slot['start'],
        'endTime': slot['end'],
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirestoreCollections.bookings.add(bookingData);

      // Send email notification
      try {
        print('📧 Attempting to send booking confirmation email for booking: ${docRef.id}');
        final sendBookingConfirmation = sl<SendBookingConfirmation>();
        await sendBookingConfirmation(docRef.id);
        print('✅ Booking confirmation email sent successfully');
      } catch (e) {
        // Log error but don't fail the booking process
        print('❌ Error sending booking confirmation email: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh available slots
        await _calculateAvailableSlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template['title'] ?? 'Book Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplateData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildTemplateInfo(),
          Expanded(
            child: _buildAvailableSlots(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today),
          const SizedBox(width: 8),
          Text(
            'Select Date: ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectDate,
            child: const Text('Change Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sessionType != null) ...[
            Text(
              'Session Type: ${_sessionType!['title'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
          ],
          if (_location != null) ...[
            Text('Location: ${_location!['name'] ?? 'Unknown'}'),
            const SizedBox(height: 4),
          ],
          Text('Duration: ${widget.template['slotIntervalMinutes'] ?? 60} minutes'),
          const SizedBox(height: 4),
          Text('Buffer: ${widget.template['bufferBefore'] ?? 0}min before, ${widget.template['bufferAfter'] ?? 0}min after'),
        ],
      ),
    );
  }

  Widget _buildAvailableSlots() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTemplateData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No available slots for this date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different date',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Colors.blue),
            title: Text(
              slot['formatted'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('EEEE, MMMM d').format(_selectedDate),
            ),
            trailing: ElevatedButton(
              onPressed: () => _showBookingConfirmation(slot),
              child: const Text('Book'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minDate = now.add(Duration(hours: widget.template['minHoursAhead'] ?? 2));
    final maxDate = now.add(Duration(days: widget.template['maxDaysAhead'] ?? 7));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    
    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });
      await _calculateAvailableSlots();
    }
  }

  Future<void> _showBookingConfirmation(Map<String, dynamic> slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session: ${widget.template['title'] ?? 'Session'}'),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}'),
            const SizedBox(height: 8),
            Text('Time: ${slot['formatted']}'),
            const SizedBox(height: 8),
            Text('Duration: ${widget.template['slotIntervalMinutes'] ?? 60} minutes'),
            if (_location != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${_location!['name']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookSlot(slot);
    }
  }
}
