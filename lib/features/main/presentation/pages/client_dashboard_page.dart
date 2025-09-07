import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_bloc.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_event.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_state.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';
import 'package:myapp/features/booking/presentation/widgets/session_info_display.dart';

class ClientDashboardPage extends StatefulWidget {
  final String? instructorId;
  
  const ClientDashboardPage({
    super.key,
    this.instructorId,
  });

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  String? _selectedInstructorId;
  String? _instructorName;
  bool _isLoadingInstructor = false;
  late BookingBloc _bookingBloc;
  late BookableSessionBloc _bookableSessionBloc;

  @override
  void initState() {
    super.initState();
    _selectedInstructorId = widget.instructorId;
    
    // Initialize BLoCs
    _bookingBloc = BookingBloc(
      getBookings: sl(),
      createBooking: sl(),
      cancelBooking: sl(),
      repository: sl(),
    );
    
    _bookableSessionBloc = BookableSessionBloc(
      getBookableSessions: sl(),
      getAllBookableSessions: sl(),
      createBookableSession: sl(),
      updateBookableSession: sl(),
      deleteBookableSession: sl(),
    );
    
    if (_selectedInstructorId != null) {
      _loadInstructorInfo();
      _loadData();
    } else {
      // If no instructor is selected, redirect to instructor selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/client/instructor-selection');
        }
      });
    }
  }

  void _loadData() {
    if (_selectedInstructorId != null) {
      _bookingBloc.add(LoadBookingsByInstructor(instructorId: _selectedInstructorId!));
      _bookableSessionBloc.add(LoadBookableSessions(instructorId: _selectedInstructorId!));
    }
  }

  @override
  void dispose() {
    _bookingBloc.close();
    _bookableSessionBloc.close();
    super.dispose();
  }

  Future<void> _loadInstructorInfo() async {
    if (_selectedInstructorId == null) return;
    
    setState(() {
      _isLoadingInstructor = true;
    });

    try {
      final instructorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedInstructorId!)
          .get();
      
      if (instructorDoc.exists) {
        final data = instructorDoc.data()!;
        setState(() {
          _instructorName = data['name'] ?? 'Unknown Instructor';
          _isLoadingInstructor = false;
        });
      } else {
        setState(() {
          _instructorName = 'Unknown Instructor';
          _isLoadingInstructor = false;
        });
      }
    } catch (e) {
      setState(() {
        _instructorName = 'Unknown Instructor';
        _isLoadingInstructor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoaded) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _bookingBloc),
              BlocProvider.value(value: _bookableSessionBloc),
            ],
            child: _buildDashboardContent(userState.user.displayName),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildDashboardContent(String userName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedInstructorId != null 
            ? 'Dashboard - ${_instructorName ?? 'Loading...'}'
            : 'Client Dashboard'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _selectedInstructorId != null ? [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go('/client/instructor-selection'),
            tooltip: 'Change Instructor',
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(userName),
            if (_selectedInstructorId != null) ...[
              const SizedBox(height: 16),
              _buildInstructorHeader(),
            ],
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildUpcomingBookings(),
            const SizedBox(height: 24),
            _buildAvailableSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        String? photoUrl;
        if (userState is UserLoaded) {
          photoUrl = userState.user.photoUrl;
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.blue.shade600,
                ) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to book your next session?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          InstructorAvatar(
            instructorId: _selectedInstructorId!,
            radius: 25,
            backgroundColor: Colors.green.withValues(alpha: 0.2),
            iconColor: Colors.green,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Selected Instructor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _instructorName ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_isLoadingInstructor) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, bookingState) {
        int totalBookings = 0;
        int upcomingBookings = 0;
        int completedBookings = 0;
        
        if (bookingState is BookingLoaded) {
          totalBookings = bookingState.bookings.length;
          upcomingBookings = bookingState.bookings
              .where((booking) => 
                  booking.status != 'cancelled' && 
                  booking.startTime.isAfter(DateTime.now()))
              .length;
          completedBookings = bookingState.bookings
              .where((booking) => 
                  booking.status == 'confirmed' && 
                  booking.endTime.isBefore(DateTime.now()))
              .length;
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Bookings',
                value: totalBookings.toString(),
                icon: Icons.book_online,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Upcoming',
                value: upcomingBookings.toString(),
                icon: Icons.schedule,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Completed',
                value: completedBookings.toString(),
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                title: 'Find Sessions',
                subtitle: 'Browse available sessions',
                color: Colors.green,
                onTap: () => context.go('/client/sessions?instructorId=$_selectedInstructorId'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.book_online,
                title: 'My Bookings',
                subtitle: 'Manage your bookings',
                color: Colors.orange,
                onTap: () => context.go('/client/bookings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_month,
                title: 'Calendar View',
                subtitle: 'View all sessions',
                color: Colors.blue,
                onTap: () => _showCalendarDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Update your information',
                color: Colors.purple,
                onTap: () => context.go('/client/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/client/bookings'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BookingLoaded) {
              final upcomingBookings = state.bookings
                  .where((booking) => 
                      booking.status != 'cancelled' && 
                      booking.startTime.isAfter(DateTime.now()))
                  .take(3)
                  .toList();
              
              if (upcomingBookings.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.calendar_today,
                  title: 'No Upcoming Bookings',
                  subtitle: 'Book a session to get started!',
                  actionText: 'Browse Sessions',
                  onAction: () => context.go('/client/sessions?instructorId=$_selectedInstructorId'),
                );
              }
              
              return Column(
                children: upcomingBookings.map((booking) => 
                  _buildBookingCard(booking)
                ).toList(),
              );
            } else if (state is BookingError) {
              return _buildErrorState(
                message: state.message,
                onRetry: () {
                  _loadData();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildAvailableSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/client/sessions?instructorId=$_selectedInstructorId'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<BookableSessionBloc, BookableSessionState>(
          builder: (context, state) {
            if (state is BookableSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BookableSessionLoaded) {
              final availableSessions = state.sessions.take(3).toList();
              
              if (availableSessions.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.event_available,
                  title: 'No Sessions Available',
                  subtitle: 'Check back later for new sessions',
                );
              }
              
              return Column(
                children: availableSessions.map((session) => 
                  _buildSessionCard(session)
                ).toList(),
              );
            } else if (state is BookableSessionError) {
              return _buildErrorState(
                message: state.message,
                onRetry: () {
                  _loadData();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: InstructorAvatar(
          instructorId: booking.instructorId,
          radius: 20,
          backgroundColor: _getStatusColor(booking.status).withValues(alpha: 0.2),
          iconColor: _getStatusColor(booking.status),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SessionInfoDisplay(
              sessionId: booking.sessionId,
              instructorId: booking.instructorId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            InstructorName(
              instructorId: booking.instructorId,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${_formatDateTime(booking.startTime)} - ${_formatDateTime(booking.endTime)}',
        ),
        trailing: Chip(
          label: Text(
            booking.status.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: _getStatusColor(booking.status),
        ),
      ),
    );
  }

  Widget _buildSessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: InstructorAvatar(
          instructorId: session.instructorId,
          radius: 20,
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          iconColor: Colors.blue,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _getSessionDisplayName(session),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                }
                return const Text('Loading...');
              },
            ),
            InstructorName(
              instructorId: session.instructorId,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Text('Duration: ${session.durationOverride ?? 60} min'),
        trailing: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => _showBookingDialog(session),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showBookingDialog(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This is a session template created by an instructor.'),
            const SizedBox(height: 8),
            Text('Duration: ${session.durationOverride ?? 60} minutes'),
            Text('Locations: ${session.locationIds.length} available'),
            Text('Session Types: ${session.sessionTypeIds.length} available'),
            Text('Booking Window: ${session.futureBookingLimitInDays} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/client/sessions?instructorId=$_selectedInstructorId');
            },
            child: const Text('View All Sessions'),
          ),
        ],
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar View'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a session to view its calendar:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Show available sessions for calendar view
              BlocBuilder<BookableSessionBloc, BookableSessionState>(
                builder: (context, state) {
                  if (state is BookableSessionLoaded) {
                    final sessions = state.sessions.take(5).toList(); // Show first 5 sessions
                    return Column(
                      children: sessions.map((session) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withValues(alpha: 0.2),
                            child: const Icon(Icons.calendar_month, color: Colors.green),
                          ),
                          title: FutureBuilder<String>(
                            future: _getSessionDisplayName(session),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                          subtitle: Text('Duration: ${session.durationOverride ?? 60} min'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/client/calendar/${session.id}/${session.instructorId}');
                          },
                        ),
                      )).toList(),
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/client/sessions?instructorId=$_selectedInstructorId');
            },
            child: const Text('View All Sessions'),
          ),
        ],
      ),
    );
  }


  Future<String> _getSessionDisplayName(dynamic session) async {
    try {
      // Get session type (should be exactly one)
      String sessionTypeName = 'Session';
      if (session.sessionTypeIds.isNotEmpty) {
        final typeDoc = await FirebaseFirestore.instance
            .collection('session_types')
            .doc(session.sessionTypeIds.first)
            .get();
        if (typeDoc.exists) {
          sessionTypeName = typeDoc.data()!['title'] ?? 'Session';
        }
      }

      // Get location (should be exactly one)
      String locationName = 'Unknown Location';
      if (session.locationIds.isNotEmpty) {
        final locationDoc = await FirebaseFirestore.instance
            .collection('locations')
            .doc(session.locationIds.first)
            .get();
        if (locationDoc.exists) {
          locationName = locationDoc.data()!['name'] ?? 'Unknown Location';
        }
      }

      // Create display name: "Session Type at Location"
      return '$sessionTypeName at $locationName';
    } catch (e) {
      return 'Session ${session.id != null && session.id!.length > 8 ? session.id!.substring(0, 8) + '...' : session.id ?? 'Unknown'}';
    }
  }
}


_sessiom