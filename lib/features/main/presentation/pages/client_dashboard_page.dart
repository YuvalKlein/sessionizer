import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_bloc.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_event.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_state.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';
import 'package:myapp/features/booking/presentation/widgets/session_info_display.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Data will be loaded when BLoCs are created
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoaded) {
          return BlocProvider(
            create: (context) => BookingBloc(
              getBookings: sl(),
              createBooking: sl(),
              cancelBooking: sl(),
              repository: sl(),
            )..add(LoadBookingsByClient(clientId: userState.user.id)),
            child: BlocProvider(
              create: (context) => SchedulableSessionBloc(
                getSchedulableSessions: sl(),
                createSchedulableSession: sl(),
                updateSchedulableSession: sl(),
                deleteSchedulableSession: sl(),
                repository: sl(),
              )..add(LoadSchedulableSessions(instructorId: userState.user.id)),
              child: _buildDashboardContent(userState.user.displayName),
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(userName),
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
                icon: Icons.calendar_today,
                title: 'View Sessions',
                subtitle: 'Browse available sessions',
                color: Colors.green,
                onTap: () => context.go('/client/sessions'),
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
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Update your information',
                color: Colors.purple,
                onTap: () => context.go('/profile'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.help_outline,
                title: 'Help',
                subtitle: 'Get support',
                color: Colors.teal,
                onTap: () => _showHelpDialog(),
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
                  onAction: () => context.go('/client/sessions'),
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
                  // Get current user ID from UserBloc
                  final userState = context.read<UserBloc>().state;
                  if (userState is UserLoaded) {
                    context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userState.user.id));
                  }
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
              onPressed: () => context.go('/client/sessions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<SchedulableSessionBloc, SchedulableSessionState>(
          builder: (context, state) {
            if (state is SchedulableSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SchedulableSessionLoaded) {
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
            } else if (state is SchedulableSessionError) {
              return _buildErrorState(
                message: state.message,
                onRetry: () {
                  // Get current user ID from UserBloc
                  final userState = context.read<UserBloc>().state;
                  if (userState is UserLoaded) {
                    context.read<SchedulableSessionBloc>().add(LoadSchedulableSessions(instructorId: userState.user.id));
                  }
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
            Text(session.title ?? 'Session'),
            InstructorName(
              instructorId: session.instructorId,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${_formatDateTime(session.startTime)} - ${_formatDateTime(session.endTime)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
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
        title: const Text('Book Session'),
        content: Text('Would you like to book "${session.title ?? 'Session'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement booking logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking functionality coming soon!')),
              );
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Here are some common actions:\n\n'
          '• Browse available sessions\n'
          '• Book a session\n'
          '• Manage your bookings\n'
          '• Update your profile\n\n'
          'For more help, contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
