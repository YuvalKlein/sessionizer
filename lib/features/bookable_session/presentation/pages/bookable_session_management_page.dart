import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_bloc.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_event.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_state.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_state.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';

class BookableSessionManagementPage extends StatefulWidget {
  const BookableSessionManagementPage({super.key});

  @override
  State<BookableSessionManagementPage> createState() => _BookableSessionManagementPageState();
}

class _BookableSessionManagementPageState extends State<BookableSessionManagementPage> {
  bool _isDeleting = false;
  List<SessionTypeEntity> _sessionTypes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    AppLogger.info('BookableSessionManagementPage', 'Loading data');
    
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    
    if (authState is AuthAuthenticated) {
      // Load session types with instructor filtering
      context.read<SessionTypeBloc>().add(LoadSessionTypesByInstructor(instructorId: authState.user.id));
      
      // Load bookable sessions
      context.read<BookableSessionBloc>().add(LoadBookableSessions(instructorId: authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('BookableSessionManagementPage', data: {'action': 'build'});

    return BlocListener<SessionTypeBloc, SessionTypeState>(
      listener: (context, state) {
        if (state is SessionTypeLoaded) {
          setState(() {
            _sessionTypes = state.sessionTypes;
          });
        }
      },
      child: BlocListener<BookableSessionBloc, BookableSessionState>(
        listener: (context, state) {
          if (state is BookableSessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BookableSessionLoaded && _isDeleting) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _isDeleting = false;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Bookable Slots'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            leading: IconButton(
              onPressed: () => context.go('/instructor-dashboard'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Dashboard',
            ),
            actions: [
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: BlocBuilder<BookableSessionBloc, BookableSessionState>(
            builder: (context, state) {
              if (state is BookableSessionLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is BookableSessionError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading sessions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
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
              } else if (state is BookableSessionLoaded) {
                if (state.sessions.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildSessionsList(state.sessions);
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
                  floatingActionButton: FloatingActionButton.extended(
          onPressed: _createNewSession,
          icon: const Icon(Icons.add),
          label: const Text('Create Bookable Slot'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookable Slots',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first bookable slot to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add),
            label: const Text('Create Bookable Slot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<BookableSessionEntity> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(BookableSessionEntity session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookable Slot ${session.id?.substring(0, 8) ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.sessionTypeIds.length} session types • ${session.locationIds.length} locations • ${session.availabilityIds.length} schedules',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, session),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Break: ${session.breakTimeInMinutes}min • Lead: ${session.bookingLeadTimeInMinutes}min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Booking limit: ${session.futureBookingLimitInDays} days ahead',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (session.durationOverride != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Duration override: ${session.durationOverride} minutes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip('Session Types', session.sessionTypeIds.length, Colors.blue),
                _buildInfoChip('Locations', session.locationIds.length, Colors.green),
                _buildInfoChip('Schedules', session.availabilityIds.length, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _createNewSession() {
    if (_sessionTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a session type first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.go('/bookable-sessions/create');
  }

  void _handleMenuAction(String action, BookableSessionEntity session) {
    switch (action) {
      case 'edit':
        _editSession(session);
        break;
      case 'duplicate':
        _duplicateSession(session);
        break;
      case 'delete':
        _deleteSession(session);
        break;
    }
  }

  void _editSession(BookableSessionEntity session) {
    context.go('/bookable-sessions/create', extra: {
      'session': session,
      'isEdit': true,
    });
  }

  void _duplicateSession(BookableSessionEntity session) {
    context.go('/bookable-sessions/create', extra: {
      'session': session,
      'isEdit': false,
    });
  }

  void _deleteSession(BookableSessionEntity session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete this bookable slot? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performDelete(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(BookableSessionEntity session) {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      context.read<BookableSessionBloc>().add(DeleteBookableSessionEvent(id: session.id ?? ''));
      AppLogger.blocEvent('BookableSessionBloc', 'DeleteBookableSessionEvent', data: {'sessionId': session.id});
    } catch (e) {
      AppLogger.error('Failed to delete session', e);
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
