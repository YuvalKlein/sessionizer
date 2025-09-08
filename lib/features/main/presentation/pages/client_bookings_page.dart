import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/review/presentation/bloc/review_bloc.dart';
import 'package:myapp/features/review/presentation/widgets/review_dialog.dart';

class ClientBookingsPage extends StatefulWidget {
  const ClientBookingsPage({super.key});

  @override
  State<ClientBookingsPage> createState() => _ClientBookingsPageState();
}

class _ClientBookingsPageState extends State<ClientBookingsPage> with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFilter = _getFilterFromTab(_tabController.index);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getFilterFromTab(int index) {
    switch (index) {
      case 0: return 'upcoming';
      case 1: return 'past';
      case 2: return 'cancelled';
      default: return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoaded) {
          // Load bookings when the page is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userState.user.id));
          });
          return _buildContent();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildContent() {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingCancelled) {
          // Reload bookings after cancellation
          final userState = context.read<UserBloc>().state;
          if (userState is UserLoaded) {
            context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userState.user.id));
          }
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
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
          IconButton(
            onPressed: () => _refreshBookings(),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList('upcoming'),
                _buildBookingsList('past'),
                _buildBookingsList('cancelled'),
              ],
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
          hintText: 'Search bookings...',
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

  Widget _buildBookingsList(String filter) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state is BookingLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookingLoaded) {
          final bookings = _filterBookings(state.bookings, filter);
          return _buildBookingsContent(bookings, filter);
        } else if (state is BookingError) {
          return _buildErrorState(state.message);
        }
        return const Center(child: Text('No bookings found'));
      },
    );
  }

  List<dynamic> _filterBookings(List<dynamic> bookings, String filter) {
    final now = DateTime.now();
    
    var filtered = bookings.where((booking) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final notes = (booking.notes ?? '').toLowerCase();
        final sessionId = (booking.bookableSessionId ?? '').toLowerCase();
        if (!notes.contains(_searchQuery) && 
            !sessionId.contains(_searchQuery)) {
          return false;
        }
      }

      // Status and time filter
      switch (filter) {
        case 'upcoming':
          return booking.status != 'cancelled' && booking.startTime.isAfter(now);
        case 'past':
          return booking.status == 'confirmed' && booking.endTime.isBefore(now);
        case 'cancelled':
          return booking.status == 'cancelled';
        default:
          return true;
      }
    }).toList();

    // Sort by start time
    filtered.sort((a, b) {
      if (filter == 'past') {
        return b.startTime.compareTo(a.startTime); // Most recent first
      } else {
        return a.startTime.compareTo(b.startTime); // Earliest first
      }
    });

    return filtered;
  }

  Widget _buildBookingsContent(List<dynamic> bookings, String filter) {
    if (bookings.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final isUpcoming = booking.startTime.isAfter(DateTime.now()) && booking.status != 'cancelled';
    final isPast = booking.endTime.isBefore(DateTime.now()) && booking.status == 'confirmed';
    final isCancelled = booking.status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: InstructorAvatar(
          instructorId: booking.instructorId,
          radius: 25,
          backgroundColor: _getStatusColor(booking.status).withValues(alpha: 0.2),
          iconColor: _getStatusColor(booking.status),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _getSessionName(booking.bookableSessionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Loading...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );
                }
                return Text(
                  snapshot.data ?? 'Session',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            InstructorName(
              instructorId: booking.instructorId,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(booking.startTime),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Chip(
                  label: Text(
                    booking.status.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(booking.status),
                ),
              ],
            ),
            if (booking.notes != null && booking.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.notes,
                      style: TextStyle(color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Start Time', _formatDateTime(booking.startTime)),
                _buildDetailRow('End Time', _formatDateTime(booking.endTime)),
                _buildDetailRow('Duration', _calculateDuration(booking.startTime, booking.endTime)),
                _buildDetailRow('Session ID', booking.bookableSessionId),
                _buildDetailRow('Status', booking.status.toUpperCase()),
                if (booking.notes != null && booking.notes.isNotEmpty)
                  _buildDetailRow('Notes', booking.notes),
                _buildDetailRow('Created', _formatDateTime(booking.createdAt)),
                const SizedBox(height: 16),
                if (isUpcoming) _buildActionButtons(booking),
                if (isPast) _buildPastActions(booking),
                if (isCancelled) _buildCancelledActions(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic booking) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRescheduleDialog(booking),
            icon: const Icon(Icons.schedule),
            label: const Text('Reschedule'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCancelDialog(booking),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastActions(dynamic booking) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showReviewDialog(booking),
            icon: const Icon(Icons.star),
            label: const Text('Leave Review'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showBookingDetails(booking),
            icon: const Icon(Icons.info),
            label: const Text('Details'),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledActions(dynamic booking) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showBookingDetails(booking),
            icon: const Icon(Icons.info),
            label: const Text('View Details'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _bookSimilarSession(booking),
            icon: const Icon(Icons.add),
            label: const Text('Book Similar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;
    
    switch (filter) {
      case 'upcoming':
        title = 'No Upcoming Bookings';
        subtitle = 'You don\'t have any upcoming sessions booked';
        icon = Icons.schedule;
        break;
      case 'past':
        title = 'No Past Bookings';
        subtitle = 'Your completed sessions will appear here';
        icon = Icons.history;
        break;
      case 'cancelled':
        title = 'No Cancelled Bookings';
        subtitle = 'Your cancelled sessions will appear here';
        icon = Icons.cancel;
        break;
      default:
        title = 'No Bookings';
        subtitle = 'Your bookings will appear here';
        icon = Icons.calendar_today;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (filter == 'upcoming') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/client/sessions'),
              child: const Text('Browse Sessions'),
            ),
          ],
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
            'Error loading bookings',
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
            onPressed: _refreshBookings,
            child: const Text('Retry'),
          ),
        ],
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

  Future<String> _getSessionName(String sessionId) async {
    try {
      // First try to get from bookable_sessions
      final bookableSessionDoc = await FirestoreCollections.bookableSession(sessionId).get();
      
      if (bookableSessionDoc.exists) {
        final sessionData = bookableSessionDoc.data() as Map<String, dynamic>;
        final title = sessionData['title'] as String?;
        if (title != null && title.isNotEmpty) {
          return title;
        }
      }
      
      // If not found in bookable_sessions, try to get session type name
      final bookingDoc = await FirestoreCollections.bookings
          .where('bookableSessionId', isEqualTo: sessionId)
          .limit(1)
          .get();
      
      if (bookingDoc.docs.isNotEmpty) {
        final bookingData = bookingDoc.docs.first.data() as Map<String, dynamic>;
        final sessionTypeId = bookingData['sessionTypeId'] as String?;
        
        if (sessionTypeId != null) {
          final sessionTypeDoc = await FirestoreCollections.sessionType(sessionTypeId).get();
          
          if (sessionTypeDoc.exists) {
            final sessionTypeData = sessionTypeDoc.data() as Map<String, dynamic>;
            final title = sessionTypeData['title'] as String?;
            if (title != null && title.isNotEmpty) {
              return title;
            }
          }
        }
      }
      
      return 'Session';
    } catch (e) {
      print('Error getting session name: $e');
      return 'Session';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (sessionDate == today) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _refreshBookings() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      context.read<BookingBloc>().add(LoadBookingsByClient(clientId: userState.user.id));
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Bookings'),
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
              title: const Text('Upcoming'),
              leading: Radio<String>(
                value: 'upcoming',
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
              title: const Text('Past'),
              leading: Radio<String>(
                value: 'past',
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
              title: const Text('Cancelled'),
              leading: Radio<String>(
                value: 'cancelled',
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

  void _showRescheduleDialog(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Booking'),
        content: const Text('Select a new time for your booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to calendar page for reschedule
              try {
                if (booking.bookableSessionId.isEmpty || booking.instructorId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to reschedule: Session information not available'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                context.go('/client/calendar/${booking.bookableSessionId}/${booking.instructorId}?reschedule=${booking.id}');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unable to reschedule: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Choose New Time'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(dynamic booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              try {
                // Use the correct context that has access to BookingBloc
                final bookingBloc = context.read<BookingBloc>();
                bookingBloc.add(CancelBookingEvent(id: booking.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
              } catch (e) {
                print('Error cancelling booking: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling booking: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(dynamic booking) {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) return;

    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => sl<ReviewBloc>(),
        child: ReviewDialog(
          bookingId: booking.id,
          clientId: userState.user.id,
          instructorId: booking.instructorId,
          sessionId: booking.bookableSessionId,
        ),
      ),
    ).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showBookingDetails(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Session: ${booking.bookableSessionId.length > 8 ? booking.bookableSessionId.substring(0, 8) + '...' : booking.bookableSessionId}'),
              const SizedBox(height: 8),
              Text('Start: ${_formatDateTime(booking.startTime)}'),
              Text('End: ${_formatDateTime(booking.endTime)}'),
              Text('Duration: ${_calculateDuration(booking.startTime, booking.endTime)}'),
              Text('Status: ${booking.status.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Created: ${_formatDateTime(booking.createdAt)}'),
              if (booking.updatedAt != null)
                Text('Last Updated: ${_formatDateTime(booking.updatedAt!)}'),
              if (booking.notes != null && booking.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: ${booking.notes}'),
              ],
            ],
          ),
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

  void _bookSimilarSession(dynamic booking) {
    context.go('/client/sessions');
  }
}
