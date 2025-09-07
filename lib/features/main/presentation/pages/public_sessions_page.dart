import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_bloc.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_event.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';

class PublicSessionsPage extends StatefulWidget {
  final String instructorId;

  const PublicSessionsPage({
    Key? key,
    required this.instructorId,
  }) : super(key: key);

  @override
  State<PublicSessionsPage> createState() => _PublicSessionsPageState();
}

class _PublicSessionsPageState extends State<PublicSessionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedInstructorId;
  bool _isLoadingInstructor = true;
  String? _instructorName;
  String? _instructorEmail;
  String? _instructorPhone;

  @override
  void initState() {
    super.initState();
    _loadInstructorInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorInfo() async {
    try {
      final instructorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.instructorId)
          .get();
      
      if (instructorDoc.exists) {
        final data = instructorDoc.data()!;
        setState(() {
          _instructorName = data['name'] ?? 'Unknown Instructor';
          _instructorEmail = data['email'] ?? '';
          _instructorPhone = data['phone'] ?? '';
          _isLoadingInstructor = false;
        });
      } else {
        setState(() {
          _isLoadingInstructor = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingInstructor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_instructorName ?? 'Loading...'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructorInfo,
          ),
        ],
      ),
      body: _isLoadingInstructor
          ? const Center(child: CircularProgressIndicator())
          : _instructorName == null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildInstructorHeader(),
                    _buildSearchBar(),
                    _buildFilterChips(),
                    Expanded(
                      child: BlocProvider<BookableSessionBloc>(
                        create: (context) => sl<BookableSessionBloc>()
                          ..add(LoadBookableSessions(instructorId: widget.instructorId)),
                        child: _buildSessionsList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInstructorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InstructorAvatar(
            instructorId: widget.instructorId,
            radius: 30,
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            iconColor: Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _instructorName!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_instructorEmail != null && _instructorEmail!.isNotEmpty)
                  Text(
                    _instructorEmail!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                if (_instructorPhone != null && _instructorPhone!.isNotEmpty)
                  Text(
                    _instructorPhone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Instructor not found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The instructor link you used is invalid or the instructor no longer exists.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All Sessions'),
            selected: _selectedInstructorId == null,
            onSelected: (selected) {
              setState(() {
                _selectedInstructorId = selected ? null : widget.instructorId;
              });
            },
          ),
          FilterChip(
            label: const Text('Filter'),
            selected: false,
            onSelected: (selected) => _showFilterDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return BlocBuilder<BookableSessionBloc, BookableSessionState>(
      builder: (context, state) {
        if (state is BookableSessionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookableSessionError) {
          return _buildErrorState();
        } else if (state is BookableSessionLoaded) {
          final sessions = _filterSessions(state.sessions);
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<dynamic> _filterSessions(List<dynamic> sessions) {
    return sessions.where((session) {
      // Filter by instructor (should already be filtered by the BLoC)
      if (session.instructorId != widget.instructorId) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final searchText = '${session.instructorId} ${session.typeIds.join(' ')}'.toLowerCase();
        if (!searchText.contains(_searchQuery)) return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildSessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: InstructorAvatar(
          instructorId: session.instructorId,
          radius: 20,
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          iconColor: Colors.blue,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: _getSessionDisplayName(session),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const Text(
                  'Loading...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            InstructorName(
              instructorId: session.instructorId,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${session.durationOverride ?? 60} min',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${session.locationIds.length} loc',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(Icons.category, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${session.typeIds.length} types',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${session.futureBookingLimitInDays} days',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _showBookingDialog(session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Details', style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _showCalendarView(session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Calendar', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
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
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No sessions available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This instructor doesn\'t have any available sessions at the moment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInstructorInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_instructorName ?? 'Instructor Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_instructorEmail != null && _instructorEmail!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(_instructorEmail!),
                contentPadding: EdgeInsets.zero,
              ),
            if (_instructorPhone != null && _instructorPhone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(_instructorPhone!),
                contentPadding: EdgeInsets.zero,
              ),
          ],
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sessions'),
        content: const Text('Filter options will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: FutureBuilder<String>(
          future: _getSessionDisplayName(session),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Session Details');
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${session.durationOverride ?? 60} minutes'),
            Text('Locations: ${session.locationIds.length}'),
            Text('Session Types: ${session.typeIds.length}'),
            Text('Available for: ${session.futureBookingLimitInDays} days'),
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
              _bookSession(session);
            },
            child: const Text('Book Session'),
          ),
        ],
      ),
    );
  }

  void _showCalendarView(dynamic session) {
    context.go('/public/calendar/${session.id}/${session.instructorId}');
  }

  void _bookSession(dynamic session) {
    // For now, redirect to login or show a message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Required'),
        content: const Text(
          'To book a session, you need to create an account or log in. '
          'Would you like to go to the login page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Future<String> _getSessionDisplayName(dynamic session) async {
    try {
      // Get session type name
      String sessionTypeName = 'Session';
      if (session.typeIds.isNotEmpty) {
        final typeDoc = await FirebaseFirestore.instance
            .collection('sessionTypes')
            .doc(session.typeIds.first)
            .get();
        if (typeDoc.exists) {
          sessionTypeName = typeDoc.data()?['title'] ?? 'Session';
        }
      }

      // Get location name
      String locationName = 'Location';
      if (session.locationIds.isNotEmpty) {
        final locationDoc = await FirebaseFirestore.instance
            .collection('locations')
            .doc(session.locationIds.first)
            .get();
        if (locationDoc.exists) {
          locationName = locationDoc.data()?['name'] ?? 'Location';
        }
      }

      return '$sessionTypeName at $locationName';
    } catch (e) {
      return 'Session ${session.id.length > 8 ? session.id.substring(0, 8) + '...' : session.id}';
    }
  }
}


