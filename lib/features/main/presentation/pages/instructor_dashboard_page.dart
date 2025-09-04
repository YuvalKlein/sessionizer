import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_bloc.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_event.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_state.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<InstructorDashboardPage> createState() => _InstructorDashboardPageState();
}

class _InstructorDashboardPageState extends State<InstructorDashboardPage> {
  BookingBloc? _bookingBloc;
  SchedulableSessionBloc? _schedulableSessionBloc;
  SessionTypeBloc? _sessionTypeBloc;
  String? _currentUserId;
  int _buildCount = 0;
  DateTime? _lastBuildTime;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('InstructorDashboardPage', data: {'action': 'initState'});
    
    // Load data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppLogger.debug('📱 PostFrameCallback executed - loading data');
        _loadData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLogger.widgetBuild('InstructorDashboardPage', data: {'action': 'didChangeDependencies'});
  }

  @override
  void dispose() {
    AppLogger.widgetBuild('InstructorDashboardPage', data: {'action': 'dispose'});
    _bookingBloc?.close();
    _schedulableSessionBloc?.close();
    _sessionTypeBloc?.close();
    super.dispose();
  }

  void _loadData() {
    if (!mounted) {
      AppLogger.warning('🚫 Widget not mounted - skipping _loadData');
      return;
    }
    
    AppLogger.debug('🔄 _loadData called');
    // Get the current authenticated user's ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    AppLogger.blocState('AuthBloc', authState.runtimeType.toString());
    
    if (authState is AuthAuthenticated && _currentUserId != authState.user.id) {
      AppLogger.debug('👤 Loading user data for ID: ${authState.user.id}');
      _currentUserId = authState.user.id;
      context.read<UserBloc>().add(LoadUser(userId: authState.user.id));
      AppLogger.blocEvent('UserBloc', 'LoadUser', data: {'userId': authState.user.id});
    } else if (authState is! AuthAuthenticated) {
      AppLogger.warning('❌ User not authenticated in _loadData');
    } else {
      AppLogger.debug('✅ User already loaded: $_currentUserId');
    }
  }

  void _initializeBlocs(String userId) {
    if (!mounted) {
      AppLogger.warning('🚫 Widget not mounted - skipping BLoC initialization');
      return;
    }
    
    AppLogger.debug('🔧 Initializing BLoCs for userId: $userId');
    
    // Only create BLoCs if they don't exist or if the user ID changed
    if (_bookingBloc == null || _currentUserId != userId) {
      AppLogger.debug('📊 Creating/Updating BookingBloc');
      _bookingBloc?.close();
      _bookingBloc = BookingBloc(
        getBookings: sl(),
        createBooking: sl(),
        cancelBooking: sl(),
        repository: sl(),
      )..add(LoadBookingsByInstructor(instructorId: userId));
      AppLogger.blocEvent('BookingBloc', 'LoadBookingsByInstructor', data: {'instructorId': userId});
    }

    if (_schedulableSessionBloc == null || _currentUserId != userId) {
      AppLogger.debug('📅 Creating/Updating SchedulableSessionBloc');
      _schedulableSessionBloc?.close();
      _schedulableSessionBloc = SchedulableSessionBloc(
        getSchedulableSessions: sl(),
        createSchedulableSession: sl(),
        updateSchedulableSession: sl(),
        deleteSchedulableSession: sl(),
        repository: sl(),
      )..add(LoadSchedulableSessions(instructorId: userId));
      AppLogger.blocEvent('SchedulableSessionBloc', 'LoadSchedulableSessions', data: {'instructorId': userId});
    }

    if (_sessionTypeBloc == null) {
      AppLogger.debug('🏷️ Creating SessionTypeBloc');
      _sessionTypeBloc = SessionTypeBloc(
        getSessionTypes: sl(),
        createSessionType: sl(),
        updateSessionType: sl(),
        deleteSessionType: sl(),
        repository: sl(),
      )..add(LoadSessionTypes());
      AppLogger.blocEvent('SessionTypeBloc', 'LoadSessionTypes');
    }
    
    _currentUserId = userId;
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      AppLogger.warning('🚫 Widget not mounted - returning empty container');
      return const SizedBox.shrink();
    }
    
    _buildCount++;
    final now = DateTime.now();
    
    // Detect rapid rebuilds (potential flashing)
    if (_lastBuildTime != null) {
      final timeSinceLastBuild = now.difference(_lastBuildTime!);
      if (timeSinceLastBuild.inMilliseconds < 100) {
        AppLogger.flashing('InstructorDashboardPage', 'Rapid rebuild detected', data: {
          'buildCount': _buildCount,
          'timeSinceLastBuild': timeSinceLastBuild.inMilliseconds,
          'authState': context.read<AuthBloc>().state.runtimeType.toString(),
        });
        
        // If we're getting rapid rebuilds, return the previous state to prevent flashing
        if (_isInitialized) {
          AppLogger.debug('🔄 Preventing rapid rebuild - returning stable state');
          return _buildStableState();
        }
      }
    }
    
    _lastBuildTime = now;
    AppLogger.widgetBuild('InstructorDashboardPage', data: {
      'buildCount': _buildCount,
      'authState': context.read<AuthBloc>().state.runtimeType.toString(),
    });

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        AppLogger.blocState('AuthBloc', authState.runtimeType.toString());
        
        if (authState is! AuthAuthenticated) {
          AppLogger.warning('❌ User not authenticated - showing error screen');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: User not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      AppLogger.navigation('instructor-dashboard', 'login');
                      context.go('/login');
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            AppLogger.blocState('UserBloc', userState.runtimeType.toString());
            
            if (userState is UserLoaded) {
              AppLogger.debug('✅ User loaded - initializing BLoCs and building dashboard');
              // Initialize BLoCs only once
              _initializeBlocs(userState.user.id);
              _isInitialized = true;
              
              return MultiBlocProvider(
                providers: [
                  BlocProvider<BookingBloc>.value(value: _bookingBloc!),
                  BlocProvider<SchedulableSessionBloc>.value(value: _schedulableSessionBloc!),
                  BlocProvider<SessionTypeBloc>.value(value: _sessionTypeBloc!),
                ],
                child: _buildDashboardContent(userState.user.displayName),
              );
            }

            AppLogger.debug('⏳ User not loaded yet - showing loading state');
            // Show a stable loading state to prevent flashing
            return Scaffold(
              backgroundColor: Colors.grey.shade50,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading instructor data...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildDashboardContent(String instructorName) {
    AppLogger.widgetBuild('DashboardContent', data: {'instructorName': instructorName});
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(instructorName),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildUpcomingSessions(),
            const SizedBox(height: 24),
            _buildMySessions(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String instructorName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.school,
              size: 40,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $instructorName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your sessions and bookings',
                  style: TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Bookings',
            value: '12',
            icon: Icons.book_online,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'This Month',
            value: '8',
            icon: Icons.calendar_month,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Earnings',
            value: '\$1,240',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  Widget _buildUpcomingSessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Sessions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all bookings
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BookingLoaded) {
                  final upcomingBookings = state.bookings
                      .where((booking) => booking.startTime.isAfter(DateTime.now()))
                      .take(3)
                      .toList();

                  if (upcomingBookings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No upcoming sessions'),
                      ),
                    );
                  }

                  return Column(
                    children: upcomingBookings.map((booking) => _buildBookingCard(booking)).toList(),
                  );
                } else if (state is BookingError) {
                  return Center(
                    child: Column(
                      children: [
                        Text('Error: ${state.message}'),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(booking.status).withValues(alpha: 0.2),
          child: Icon(
            Icons.person,
            color: _getStatusColor(booking.status),
          ),
        ),
        title: Text('Client Session'),
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

  Widget _buildMySessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Session Types',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to manage sessions
                  },
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<SchedulableSessionBloc, SchedulableSessionState>(
              builder: (context, state) {
                if (state is SchedulableSessionLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SchedulableSessionLoaded) {
                  final sessions = state.sessions.take(3).toList();

                  if (sessions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No sessions created yet'),
                      ),
                    );
                  }

                  return Column(
                    children: sessions.map((session) => _buildSessionCard(session)).toList(),
                  );
                } else if (state is SchedulableSessionError) {
                  return Center(
                    child: Column(
                      children: [
                        Text('Error: ${state.message}'),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          child: const Icon(Icons.fitness_center, color: Colors.blue),
        ),
        title: Text(session.title ?? 'Session'),
        subtitle: Text(
          '${session.durationMinutes} min • \$${session.price.toStringAsFixed(2)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // TODO: Edit session
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Create Session',
                    icon: Icons.add,
                    color: Colors.green,
                    onTap: () {
                      // TODO: Navigate to create session
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: 'View Bookings',
                    icon: Icons.book_online,
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Navigate to bookings
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Schedule',
                    icon: Icons.schedule,
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navigate to schedule
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: 'Analytics',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigate to analytics
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
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
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStableState() {
    // Return a stable loading state to prevent flashing during rapid rebuilds
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading instructor data...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
