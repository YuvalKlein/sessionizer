import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';

class InstructorBookingManagementPage extends StatefulWidget {
  const InstructorBookingManagementPage({super.key});

  @override
  State<InstructorBookingManagementPage> createState() => _InstructorBookingManagementPageState();
}

class _InstructorBookingManagementPageState extends State<InstructorBookingManagementPage> {
  String? _instructorId;
  List<BookingEntity> _bookings = [];
  List<Map<String, dynamic>> _sessionTypes = [];
  List<Map<String, dynamic>> _locations = [];
  final Map<String, Map<String, dynamic>> _clients = {}; // Store client data
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
      // Load bookings using BLoC
      context.read<BookingBloc>().add(LoadBookingsByInstructor(instructorId: _instructorId!));
      
      // Load session types and locations for display
      await _loadRelatedData();
      
      // Load client data
      await _loadClients();
      
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
      final sessionTypesSnapshot = await FirebaseFirestore.instance
          .collection('session_types')
          .get();
      _sessionTypes = sessionTypesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Load locations
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();
      _locations = locationsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error loading related data: $e');
    }
  }

  Future<void> _loadClients() async {
    try {
      // Get unique client IDs from bookings
      final Set<String> clientIds = {};
      for (final booking in _bookings) {
        clientIds.add(booking.clientId);
      }

      // Load client data
      for (final clientId in clientIds) {
        final clientDoc = await FirebaseFirestore.instance
            .collection('sessionizer')
            .doc('users')
            .collection('users')
            .doc(clientId)
            .get();
        if (clientDoc.exists) {
          _clients[clientId] = {
            'id': clientId,
            ...clientDoc.data() as Map<String, dynamic>
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
  }

  List<BookingEntity> _getFilteredBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 'upcoming':
        return _bookings.where((booking) => 
          booking.status != 'cancelled' && booking.startTime.isAfter(now)).toList();
      case 'past':
        return _bookings.where((booking) => 
          booking.status != 'cancelled' && booking.endTime.isBefore(now)).toList();
      case 'today':
        return _bookings.where((booking) {
          if (booking.status == 'cancelled') return false;
          final bookingDate = DateTime(booking.startTime.year, booking.startTime.month, booking.startTime.day);
          return bookingDate.isAtSameMomentAs(today);
        }).toList();
      case 'cancelled':
        return _bookings.where((booking) => booking.status == 'cancelled').toList();
      default: // 'all'
        return _bookings; // Show all bookings including cancelled
    }
  }

  Map<String, dynamic>? _getSessionType(String? sessionTypeId) {
    if (sessionTypeId == null) return null;
    try {
      return _sessionTypes.firstWhere((st) => st['id'] == sessionTypeId);
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

  Map<String, dynamic>? _getClient(String clientId) {
    return _clients[clientId];
  }

  String _formatDuration(Map<String, dynamic>? sessionType) {
    if (sessionType == null) return 'Unknown duration';
    
    final duration = sessionType['duration'] as int? ?? 0;
    final unit = (sessionType['durationUnit'] as String? ?? 'minutes').toLowerCase();
    
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

  Future<void> _cancelBooking(BookingEntity booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel the booking with ${_getClient(booking.clientId)?['displayName'] ?? 'Unknown Client'} on ${DateFormat.yMMMd().format(booking.startTime)} at ${DateFormat.jm().format(booking.startTime)}?',
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

    if (confirmed == true && mounted) {
      context.read<BookingBloc>().add(CancelBookingEvent(id: booking.id));
    }
  }

  Future<void> _rescheduleBooking(BookingEntity booking) async {
    // Navigate to calendar for rescheduling with reschedule query parameter
    final sessionId = booking.bookableSessionId;
    final instructorId = booking.instructorId;
    final bookingId = booking.id;
    
    print('DEBUG: Reschedule - sessionId: "$sessionId", instructorId: "$instructorId", bookingId: "$bookingId"');
    
    if (sessionId.isNotEmpty && instructorId.isNotEmpty && bookingId.isNotEmpty) {
      // Pass the booking ID as a query parameter for rescheduling
      context.go('/client/calendar/$sessionId/$instructorId?reschedule=$bookingId');
    } else {
      print('DEBUG: Missing session info - sessionId: "$sessionId", instructorId: "$instructorId", bookingId: "$bookingId"');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reschedule: Missing required information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBookForClientDialog() async {
    final TextEditingController clientEmailController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book for Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the client\'s email address:'),
            const SizedBox(height: 16),
            TextField(
              controller: clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Client Email',
                hintText: 'client@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
              final email = clientEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.of(context).pop(email);
              }
            },
            child: const Text('Find Client'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Find client by email
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('sessionizer')
            .doc('users')
            .collection('users')
            .where('email', isEqualTo: result)
            .where('isInstructor', isEqualTo: false)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final clientDoc = querySnapshot.docs.first;
          final clientId = clientDoc.id;
          final clientData = clientDoc.data();
          
          // Show session selection dialog
          _showSessionSelectionDialog(clientId, clientData['displayName'] ?? 'Client');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Client with email "$result" not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding client: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSessionSelectionDialog(String clientId, String clientName) async {
    // Load available sessions for the instructor
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookable_sessions')
          .where('instructorId', isEqualTo: _instructorId)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available sessions found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final sessions = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Session for $clientName'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  title: Text(session['title'] ?? 'Untitled Session'),
                  subtitle: Text('ID: ${session['id']}'),
                  onTap: () => Navigator.of(context).pop(session),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result != null) {
        // Navigate to calendar with client ID
        context.go('/client/calendar/${result['id']}/$_instructorId?clientId=$clientId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sessions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingLoaded) {
          setState(() {
            _bookings = state.bookings;
            _isLoading = false;
          });
          // Reload clients when bookings are updated
          _loadClients();
        } else if (state is BookingCancelled) {
          // Reload bookings after cancellation
          _loadData();
        } else if (state is BookingError) {
          setState(() {
            _error = state.message;
            _isLoading = false;
          });
        } else if (state is BookingLoading) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Bookings'),
          leading: IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/instructor-dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Dashboard',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showBookForClientDialog,
              tooltip: 'Book for Client',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    final filteredBookings = _getFilteredBookings();

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
                _buildFilterChip('upcoming', 'Upcoming', _bookings.where((b) => b.status != 'cancelled' && b.startTime.isAfter(DateTime.now())).length),
                const SizedBox(width: 8),
                _buildFilterChip('today', 'Today', _bookings.where((b) {
                  if (b.status == 'cancelled') return false;
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final bookingDate = DateTime(b.startTime.year, b.startTime.month, b.startTime.day);
                  return bookingDate.isAtSameMomentAs(today);
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('past', 'Past', _bookings.where((b) => b.status != 'cancelled' && b.endTime.isBefore(DateTime.now())).length),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled', _bookings.where((b) => b.status == 'cancelled').length),
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
                      final sessionType = _getSessionType(booking.bookableSessionId); // Using bookableSessionId as sessionTypeId for now
                      final location = _getLocation(booking.bookableSessionId); // This would need to be updated with proper locationId
                      final isUpcoming = booking.startTime.isAfter(DateTime.now());
                      final isPast = booking.endTime.isBefore(DateTime.now());
                      final isCancelled = booking.status == 'cancelled';
                      
                      // Get the client data for this booking
                      final client = _getClient(booking.clientId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isCancelled
                                ? Colors.red
                                : isUpcoming 
                                    ? Colors.blue 
                                    : isPast 
                                        ? Colors.grey 
                                        : Colors.orange,
                            child: Text(
                              client?['displayName']?.toString().substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            sessionType?['title'] ?? 'Session',
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
                              Text('Client: ${client?['displayName'] ?? 'Unknown Client'}'),
                              if (client?['email'] != null) ...[
                                const SizedBox(height: 2),
                                Text('Email: ${client?['email']}'),
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
                                      color: isCancelled
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : isUpcoming 
                                              ? Colors.blue.withValues(alpha: 0.1)
                                              : isPast 
                                                  ? Colors.grey.withValues(alpha: 0.1)
                                                  : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isCancelled
                                          ? 'Cancelled'
                                          : isUpcoming 
                                              ? 'Upcoming' 
                                              : isPast 
                                                  ? 'Completed' 
                                                  : 'In Progress',
                                      style: TextStyle(
                                        color: isCancelled
                                            ? Colors.red[700]
                                            : isUpcoming 
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
                          trailing: isUpcoming && !isCancelled
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
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
