import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/booking_service.dart';
import 'package:myapp/models/booking.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/widgets/reschedule_dialog.dart';

class InstructorBookingManagementScreen extends StatefulWidget {
  const InstructorBookingManagementScreen({super.key});

  @override
  State<InstructorBookingManagementScreen> createState() => _InstructorBookingManagementScreenState();
}

class _InstructorBookingManagementScreenState extends State<InstructorBookingManagementScreen> {
  final BookingService _bookingService = BookingService();
  final SessionTypeService _sessionTypeService = SessionTypeService();
  final LocationService _locationService = LocationService();
  
  String? _instructorId;
  List<Booking> _bookings = [];
  List<SessionType> _sessionTypes = [];
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, upcoming, past, today

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    _instructorId = user.uid;
    
    try {
      // Load bookings
      final bookingsSnapshot = await _bookingService.getBookingsStream(_instructorId!).first;
      _bookings = bookingsSnapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
      
      // Sort bookings by start time (upcoming first)
      _bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // Load session types and locations for display
      await _loadRelatedData();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelatedData() async {
    try {
      // Load session types
      final sessionTypeIds = _bookings
          .map((b) => b.sessionTypeId)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      _sessionTypes = [];
      for (final sessionTypeId in sessionTypeIds) {
        final sessionType = await _sessionTypeService.getSessionType(sessionTypeId!);
        if (sessionType != null) {
          _sessionTypes.add(sessionType);
        }
      }

      // Load locations
      final locationIds = _bookings
          .map((b) => b.locationId)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      _locations = [];
      for (final locationId in locationIds) {
        final location = await _locationService.getLocation(locationId!);
        if (location != null) {
          _locations.add(location);
        }
      }
    } catch (e) {
      debugPrint('Error loading related data: $e');
    }
  }

  List<Booking> _getFilteredBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    switch (_selectedFilter) {
      case 'upcoming':
        return _bookings.where((booking) => booking.startTime.isAfter(now)).toList();
      case 'past':
        return _bookings.where((booking) => booking.endTime.isBefore(now)).toList();
      case 'today':
        return _bookings.where((booking) {
          final bookingDate = DateTime(booking.startTime.year, booking.startTime.month, booking.startTime.day);
          return bookingDate.isAtSameMomentAs(today);
        }).toList();
      default:
        return _bookings;
    }
  }

  SessionType? _getSessionType(String? sessionTypeId) {
    if (sessionTypeId == null) return null;
    try {
      return _sessionTypes.firstWhere((st) => st.id == sessionTypeId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _getLocation(String? locationId) {
    if (locationId == null) return null;
    try {
      return _locations.firstWhere((loc) => loc['id'] == locationId);
    } catch (e) {
      return null;
    }
  }

  String _formatDuration(SessionType sessionType) {
    final duration = sessionType.duration;
    final unit = sessionType.durationUnit.toLowerCase();
    
    if (unit == 'hours' || unit == 'hour') {
      if (duration == 1) {
        return '1 hour';
      } else {
        return '$duration hours';
      }
    } else if (unit == 'minutes' || unit == 'minute' || unit == 'min') {
      if (duration >= 60) {
        final hours = duration ~/ 60;
        final minutes = duration % 60;
        if (minutes == 0) {
          return hours == 1 ? '1 hour' : '$hours hours';
        } else {
          return '${hours}h ${minutes}m';
        }
      } else {
        return '$duration min';
      }
    } else {
      return '$duration min';
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel the booking with ${booking.clientName} on ${DateFormat.yMMMd().format(booking.startTime)} at ${DateFormat.jm().format(booking.startTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.cancelBooking(booking.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleBooking(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RescheduleDialog(
        booking: booking,
        instructorId: booking.instructorId,
      ),
    );

    if (result == true && mounted) {
      _loadData(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _getFilteredBookings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(filteredBookings),
    );
  }

  Widget _buildBody(List<Booking> filteredBookings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', _bookings.length),
                const SizedBox(width: 8),
                _buildFilterChip('upcoming', 'Upcoming', _bookings.where((b) => b.startTime.isAfter(DateTime.now())).length),
                const SizedBox(width: 8),
                _buildFilterChip('today', 'Today', _bookings.where((b) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final bookingDate = DateTime(b.startTime.year, b.startTime.month, b.startTime.day);
                  return bookingDate.isAtSameMomentAs(today);
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('past', 'Past', _bookings.where((b) => b.endTime.isBefore(DateTime.now())).length),
              ],
            ),
          ),
        ),
        
        // Bookings list
        Expanded(
          child: filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bookings will appear here when clients book sessions.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final sessionType = _getSessionType(booking.sessionTypeId);
                      final location = _getLocation(booking.locationId);
                      final isUpcoming = booking.startTime.isAfter(DateTime.now());
                      final isPast = booking.endTime.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isUpcoming 
                                ? Colors.blue 
                                : isPast 
                                    ? Colors.grey 
                                    : Colors.orange,
                            child: Icon(
                              isUpcoming 
                                  ? Icons.schedule 
                                  : isPast 
                                      ? Icons.check 
                                      : Icons.access_time,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            sessionType?.title ?? 'Session',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat.yMMMd().format(booking.startTime)} at ${DateFormat.jm().format(booking.startTime)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text('Client: ${booking.clientName}'),
                              if (booking.clientEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Email: ${booking.clientEmail}'),
                              ],
                              if (sessionType != null) ...[
                                const SizedBox(height: 2),
                                Text('Duration: ${_formatDuration(sessionType)}'),
                              ],
                              if (location != null) ...[
                                const SizedBox(height: 2),
                                Text('Location: ${location['name']}'),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isUpcoming 
                                          ? Colors.blue.withOpacity(0.1)
                                          : isPast 
                                              ? Colors.grey.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isUpcoming 
                                          ? 'Upcoming' 
                                          : isPast 
                                              ? 'Completed' 
                                              : 'In Progress',
                                      style: TextStyle(
                                        color: isUpcoming 
                                            ? Colors.blue[700]
                                            : isPast 
                                                ? Colors.grey[700]
                                                : Colors.orange[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isUpcoming
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'reschedule') {
                                      _rescheduleBooking(booking);
                                    } else if (value == 'cancel') {
                                      _cancelBooking(booking);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'reschedule',
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Reschedule'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'cancel',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Cancel'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
