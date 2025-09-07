import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';

class ClientBookingFlowPage extends StatefulWidget {
  final String sessionId;
  final String instructorId;

  const ClientBookingFlowPage({
    super.key,
    required this.sessionId,
    required this.instructorId,
  });

  @override
  State<ClientBookingFlowPage> createState() => _ClientBookingFlowPageState();
}

class _ClientBookingFlowPageState extends State<ClientBookingFlowPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocationId;
  String? _selectedSessionTypeId;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableSlots = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _sessionTypes = [];

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
    // Load pre-selected data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreSelectedData();
    });
  }

  void _loadPreSelectedData() {
    try {
      // Get query parameters from the current route
      final uri = GoRouterState.of(context).uri;
      final timeParam = uri.queryParameters['time'];
      final dateParam = uri.queryParameters['date'];
      
      if (timeParam != null) {
        final timeParts = timeParam.split(':');
        if (timeParts.length == 2) {
          setState(() {
            _selectedTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          });
        }
      }
      
      if (dateParam != null) {
        final dateParts = dateParam.split('-');
        if (dateParts.length == 3) {
          setState(() {
            _selectedDate = DateTime(
              int.parse(dateParts[0]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[2]), // day
            );
          });
        }
      }
    } catch (e) {
      // If there's an error reading query parameters, just continue without them
      print('Error loading pre-selected data: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Load session details
      final sessionDoc = await FirebaseFirestore.instance
          .collection('bookable_sessions')
          .doc(widget.sessionId)
          .get();
      
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        
        // Load locations
        final locationIds = List<String>.from(sessionData['locationIds'] ?? []);
        for (final locationId in locationIds) {
          final locationDoc = await FirebaseFirestore.instance
              .collection('locations')
              .doc(locationId)
              .get();
          if (locationDoc.exists) {
            _locations.add({
              'id': locationId,
              'name': locationDoc.data()!['name'],
            });
          }
        }
        
        // Load session types
        final typeIds = List<String>.from(sessionData['typeIds'] ?? []);
        for (final typeId in typeIds) {
          final typeDoc = await FirebaseFirestore.instance
              .collection('session_types')
              .doc(typeId)
              .get();
          if (typeDoc.exists) {
            _sessionTypes.add({
              'id': typeId,
              'title': typeDoc.data()!['title'],
              'duration': typeDoc.data()!['duration'],
            });
          }
        }
        
        // Set defaults
        if (_locations.isNotEmpty) {
          _selectedLocationId = _locations.first['id'];
        }
        if (_sessionTypes.isNotEmpty) {
          _selectedSessionTypeId = _sessionTypes.first['id'];
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading session details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null || _selectedLocationId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load instructor's schedules for the selected date
      final schedulesQuery = await FirebaseFirestore.instance
          .collection('schedules')
          .where('instructorId', isEqualTo: widget.instructorId)
          .where('isActive', isEqualTo: true)
          .get();
      
      _availableSlots.clear();
      
      for (final scheduleDoc in schedulesQuery.docs) {
        final scheduleData = scheduleDoc.data();
        
        // Check if the selected date falls within this schedule's availability
        if (_isDateInSchedule(_selectedDate!, scheduleData)) {
          final timeSlots = _getTimeSlotsForDate(_selectedDate!, scheduleData);
          for (final slot in timeSlots) {
            _availableSlots.add({
              'time': slot,
              'scheduleId': scheduleDoc.id,
              'locationId': _selectedLocationId,
            });
          }
        }
      }
      
      // Sort slots by time
      _availableSlots.sort((a, b) => a['time'].compareTo(b['time']));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading available slots: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isDateInSchedule(DateTime date, Map<String, dynamic> scheduleData) {
    // Check if date is not a holiday
    final holidays = scheduleData['holidays'] as Map<String, dynamic>?;
    if (holidays?.containsKey(_formatDateKey(date)) == true) {
      return false;
    }
    
    // Check if date matches the schedule's day of week
    final dayOfWeek = date.weekday;
    final weeklyAvailability = scheduleData['weeklyAvailability'] as Map<String, dynamic>?;
    return weeklyAvailability?.containsKey(_getDayName(dayOfWeek)) == true;
  }

  List<TimeOfDay> _getTimeSlotsForDate(DateTime date, Map<String, dynamic> scheduleData) {
    final dayName = _getDayName(date.weekday);
    final weeklyAvailability = scheduleData['weeklyAvailability'] as Map<String, dynamic>?;
    final dayAvailability = weeklyAvailability?[dayName] as List<dynamic>?;
    
    if (dayAvailability == null) return [];
    
    final slots = <TimeOfDay>[];
    
    for (final range in dayAvailability) {
      final rangeMap = range as Map<String, dynamic>;
      final startTime = rangeMap['start'] as TimeOfDay?;
      final endTime = rangeMap['end'] as TimeOfDay?;
      
      if (startTime != null && endTime != null) {
        // Generate 30-minute slots between start and end time
        var currentTime = startTime;
        while (currentTime.hour < endTime.hour || 
               (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute)) {
          slots.add(currentTime);
          currentTime = TimeOfDay(
            hour: currentTime.hour + (currentTime.minute + 30) ~/ 60,
            minute: (currentTime.minute + 30) % 60,
          );
        }
      }
    }
    
    return slots;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _bookSession() async {
    if (_selectedDate == null || _selectedTime == null || _selectedLocationId == null || _selectedSessionTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date, time, location, and session type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userState = context.read<UserBloc>().state;
      if (userState is! UserLoaded) {
        throw Exception('User not loaded');
      }

      final startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final sessionType = _sessionTypes.firstWhere(
        (type) => type['id'] == _selectedSessionTypeId,
      );
      final duration = sessionType['duration'] as int;
      
      final endTime = startTime.add(Duration(minutes: duration));

      // Create booking
      final bookingData = {
        'clientId': userState.user.id,
        'instructorId': widget.instructorId,
        'sessionId': widget.sessionId,
        'locationId': _selectedLocationId,
        'sessionTypeId': _selectedSessionTypeId,
        'startTime': startTime,
        'endTime': endTime,
        'status': 'confirmed',
        'notes': _notesController.text.trim(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Refresh bookings
      context.read<BookingBloc>().add(LoadBookings(userId: userState.user.id!));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/client/bookings');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/sessions'),
        ),
      ),
      body: _isLoading && _availableSlots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionInfo(),
                  const SizedBox(height: 24),
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildLocationSelector(),
                  const SizedBox(height: 24),
                  _buildSessionTypeSelector(),
                  const SizedBox(height: 24),
                  _buildTimeSlotSelector(),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  _buildBookButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Session ID: ${widget.sessionId.length > 8 ? widget.sessionId.substring(0, 8) + '...' : widget.sessionId}'),
            Text('Instructor ID: ${widget.instructorId.length > 8 ? widget.instructorId.substring(0, 8) + '...' : widget.instructorId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null;
                    _availableSlots.clear();
                  });
                  _loadAvailableSlots();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select a date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _locations.map<DropdownMenuItem<String>>((location) {
                return DropdownMenuItem<String>(
                  value: location['id'] as String,
                  child: Text(location['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                  _availableSlots.clear();
                });
                if (_selectedDate != null) {
                  _loadAvailableSlots();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Session Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSessionTypeId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              items: _sessionTypes.map<DropdownMenuItem<String>>((type) {
                return DropdownMenuItem<String>(
                  value: type['id'] as String,
                  child: Text('${type['title'] as String} (${type['duration'] as int} min)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSessionTypeId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_availableSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    _selectedDate == null
                        ? 'Please select a date first'
                        : 'No available time slots for this date',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = _availableSlots[index];
                  final time = slot['time'] as TimeOfDay;
                  final isSelected = _selectedTime == time;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Any special requests or notes...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook = _selectedDate != null && 
                    _selectedTime != null && 
                    _selectedLocationId != null && 
                    _selectedSessionTypeId != null;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBook && !_isLoading ? _bookSession : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Book Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
