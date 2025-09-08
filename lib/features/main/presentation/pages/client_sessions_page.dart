import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_bloc.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_event.dart';
import 'package:myapp/features/bookable_session/presentation/bloc/bookable_session_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';

class ClientSessionsPage extends StatefulWidget {
  final String? instructorId;
  
  const ClientSessionsPage({super.key, this.instructorId});

  @override
  State<ClientSessionsPage> createState() => _ClientSessionsPageState();
}

class _ClientSessionsPageState extends State<ClientSessionsPage> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<BookableSessionBloc>();
        if (widget.instructorId != null && widget.instructorId!.isNotEmpty) {
          bloc.add(LoadBookableSessions(instructorId: widget.instructorId!));
        } else {
          bloc.add(const LoadAllBookableSessions());
        }
        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Available Sessions'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => context.go('/client-dashboard'),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () => _showFilterDialog(),
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: BlocBuilder<BookableSessionBloc, BookableSessionState>(
                builder: (context, state) {
                  if (state is BookableSessionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is BookableSessionLoaded) {
                    final sessions = _filterSessions(state.sessions);
                    return _buildSessionsList(sessions);
                  } else if (state is BookableSessionError) {
                    return _buildErrorState(state.message);
                  }
                  return const Center(child: Text('No sessions available'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search sessions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Today', 'today'),
            const SizedBox(width: 8),
            _buildFilterChip('This Week', 'week'),
            const SizedBox(width: 8),
            _buildFilterChip('This Month', 'month'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
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

  List<dynamic> _filterSessions(List<dynamic> sessions) {
    var filtered = sessions.where((session) {
      // Search filter - search by instructor ID or session type IDs
      if (_searchQuery.isNotEmpty) {
        final instructorId = (session.instructorId ?? '').toLowerCase();
        final typeIds = (session.sessionTypeIds ?? <String>[]).join(' ').toLowerCase();
        if (!instructorId.contains(_searchQuery) && !typeIds.contains(_searchQuery)) {
          return false;
        }
      }

      // For now, show all sessions since these are templates
      // In a real app, you'd filter by actual available time slots
      return true;
    }).toList();

    // Sort by creation date
    filtered.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime); // Most recent first
    });

    return filtered;
  }

  Widget _buildSessionsList(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
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
        subtitle: Row(
          children: [
            Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${session.durationOverride ?? 60} min',
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
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 20,
                child: ElevatedButton(
                  onPressed: () => _showBookingDialog(session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Details', style: TextStyle(fontSize: 8)),
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                width: 80,
                height: 20,
                child: ElevatedButton(
                  onPressed: () => _showCalendarView(session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Calendar', style: TextStyle(fontSize: 8)),
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
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new sessions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<BookableSessionBloc>().add(const LoadAllBookableSessions());
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
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
            'Error loading sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<BookableSessionBloc>().add(const LoadAllBookableSessions());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
            FutureBuilder<String>(
              future: _getSessionDisplayName(session),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Loading...');
              },
            ),
            const SizedBox(height: 8),
            Text('Instructor ID: ${session.instructorId}'),
            Text('Duration: ${session.durationOverride ?? 60} minutes'),
            Text('Locations: ${session.locationIds.length} available'),
            Text('Session Types: ${session.sessionTypeIds.length} available'),
            Text('Booking Window: ${session.futureBookingLimitInDays} days'),
            Text('Lead Time: ${session.bookingLeadTimeInMinutes} minutes'),
            if (session.breakTimeInMinutes > 0)
              Text('Break Time: ${session.breakTimeInMinutes} minutes'),
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

  void _bookSession(dynamic session) {
    context.go('/client/book/${session.id}/${session.instructorId}');
  }

  void _showCalendarView(dynamic session) {
    context.go('/client/calendar/${session.id}/${session.instructorId}');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Sessions'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Today'),
              leading: Radio<String>(
                value: 'today',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('This Week'),
              leading: Radio<String>(
                value: 'week',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('This Month'),
              leading: Radio<String>(
                value: 'month',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
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

  Future<String> _getSessionDisplayName(dynamic session) async {
    try {
      // Get session type (should be exactly one)
      String sessionTypeName = 'Session';
      if (session.sessionTypeIds.isNotEmpty) {
        final typeDoc = await FirestoreCollections.sessionType(session.sessionTypeIds.first).get();
        if (typeDoc.exists) {
          final typeData = typeDoc.data() as Map<String, dynamic>;
          sessionTypeName = typeData['title'] ?? 'Session';
        }
      }

      // Get location (should be exactly one)
      String locationName = 'Unknown Location';
      if (session.locationIds.isNotEmpty) {
        final locationDoc = await FirestoreCollections.location(session.locationIds.first).get();
        if (locationDoc.exists) {
          final locationData = locationDoc.data() as Map<String, dynamic>;
          locationName = locationData['name'] ?? 'Unknown Location';
        }
      }

      // Create display name: "Session Type at Location"
      final result = '$sessionTypeName at $locationName';
      return result;
    } catch (e) {
      return 'Session ${session.id != null && session.id!.length > 8 ? session.id!.substring(0, 8) + '...' : session.id ?? 'Unknown'}';
    }
  }
}


