import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_bloc.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_event.dart';
import 'package:myapp/features/schedulable_session/presentation/bloc/schedulable_session_state.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';

class ClientSessionsPage extends StatefulWidget {
  const ClientSessionsPage({super.key});

  @override
  State<ClientSessionsPage> createState() => _ClientSessionsPageState();
}

class _ClientSessionsPageState extends State<ClientSessionsPage> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

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
            create: (context) => SchedulableSessionBloc(
              getSchedulableSessions: sl(),
              createSchedulableSession: sl(),
              updateSchedulableSession: sl(),
              deleteSchedulableSession: sl(),
              repository: sl(),
            )..add(LoadSchedulableSessions(instructorId: userState.user.id)),
            child: BlocProvider(
              create: (context) => SessionTypeBloc(
                getSessionTypes: sl(),
                createSessionType: sl(),
                updateSessionType: sl(),
                deleteSessionType: sl(),
                repository: sl(),
              )..add(LoadSessionTypes()),
              child: _buildSessionsContent(),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildSessionsContent() {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: _buildSessionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Text(
            'Available Sessions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Sessions'),
            const SizedBox(width: 8),
            _buildFilterChip('today', 'Today'),
            const SizedBox(width: 8),
            _buildFilterChip('this_week', 'This Week'),
            const SizedBox(width: 8),
            _buildFilterChip('this_month', 'This Month'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildSessionsList() {
    return BlocBuilder<SchedulableSessionBloc, SchedulableSessionState>(
      builder: (context, state) {
        if (state is SchedulableSessionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SchedulableSessionLoaded) {
          final sessions = _filterSessions(state.sessions);
          
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionCard(session);
            },
          );
        } else if (state is SchedulableSessionError) {
          return _buildErrorState(state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<dynamic> _filterSessions(List<dynamic> sessions) {
    var filteredSessions = sessions.where((session) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final title = (session.title ?? '').toLowerCase();
        final description = (session.description ?? '').toLowerCase();
        if (!title.contains(_searchQuery) && !description.contains(_searchQuery)) {
          return false;
        }
      }
      
      // Apply date filter
      final now = DateTime.now();
      final sessionDate = session.startTime;
      
      switch (_selectedFilter) {
        case 'today':
          return sessionDate.year == now.year &&
                 sessionDate.month == now.month &&
                 sessionDate.day == now.day;
        case 'this_week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return sessionDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 sessionDate.isBefore(weekEnd.add(const Duration(days: 1)));
        case 'this_month':
          return sessionDate.year == now.year && sessionDate.month == now.month;
        default:
          return true;
      }
    }).toList();
    
    // Sort by start time
    filteredSessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return filteredSessions;
  }

  Widget _buildSessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.event_available,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title ?? 'Session',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (session.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(session),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(session.startTime),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(session.startTime, session.endTime),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (session.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.location,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showBookingDialog(session),
                      child: const Text('Book Session'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showSessionDetails(session),
                    child: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(dynamic session) {
    final now = DateTime.now();
    final sessionDate = session.startTime;
    
    if (sessionDate.isBefore(now)) {
      return Chip(
        label: const Text('Past', style: TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.grey,
      );
    } else if (sessionDate.isAfter(now.add(const Duration(days: 7)))) {
      return Chip(
        label: const Text('Future', style: TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.blue,
      );
    } else {
      return Chip(
        label: const Text('Soon', style: TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.orange,
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Sessions Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later for new sessions.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _refreshData(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Error Loading Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (sessionDate == today) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showSessionDetails(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title ?? 'Session Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session.description != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(session.description),
                const SizedBox(height: 16),
              ],
              const Text(
                'Schedule:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('${_formatDateTime(session.startTime)} - ${_formatDateTime(session.endTime)}'),
              const SizedBox(height: 8),
              Text('Duration: ${_formatDuration(session.startTime, session.endTime)}'),
              if (session.location != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(session.location),
              ],
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
              _showBookingDialog(session);
            },
            child: const Text('Book Session'),
          ),
        ],
      ),
    );
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

  void _refreshData() {
    // This will be handled by the parent widget
    context.read<SchedulableSessionBloc>().add(LoadSchedulableSessions(instructorId: 'temp'));
    context.read<SessionTypeBloc>().add(LoadSessionTypes());
  }
}
