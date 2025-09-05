import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientSessionsPage extends StatefulWidget {
  const ClientSessionsPage({super.key});

  @override
  State<ClientSessionsPage> createState() => _ClientSessionsPageState();
}

class _ClientSessionsPageState extends State<ClientSessionsPage> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // First, let's try to get all schedulable sessions to see what's available
      final snapshot = await FirebaseFirestore.instance
          .collection('schedulable_sessions')
          .get();

      print('📊 Found ${snapshot.docs.length} schedulable sessions total');

      // Filter for active sessions
      var templates = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((template) => template['isActive'] == true)
          .toList();

      print('📊 Found ${templates.length} active schedulable sessions');

      // If no active templates found, show all templates for debugging
      if (templates.isEmpty && snapshot.docs.isNotEmpty) {
        print('⚠️ No active templates found, showing all templates for debugging');
        templates = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }

      // If still no templates, create a sample one for testing
      if (templates.isEmpty) {
        print('⚠️ No templates found at all, creating sample data');
        await _createSampleTemplate();
        // Reload after creating sample
        final newSnapshot = await FirebaseFirestore.instance
            .collection('schedulable_sessions')
            .get();
        templates = newSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading templates: $e');
      setState(() {
        _error = 'Failed to load session templates: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 ClientSessionsPage build called - templates: ${_templates.length}, loading: $_isLoading, error: $_error');
    return _buildSessionsContent();
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
            onPressed: () {
              print('🔙 Back button pressed');
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/client-dashboard');
              }
            },
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    final filteredTemplates = _filterSessions(_templates);
    
    if (filteredTemplates.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildSessionTemplateCard(template);
      },
    );
  }

  List<dynamic> _filterSessions(List<dynamic> templates) {
    var filteredTemplates = templates.where((template) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final title = (template['title'] ?? '').toLowerCase();
        final notes = (template['notes'] ?? '').toLowerCase();
        if (!title.contains(_searchQuery) && !notes.contains(_searchQuery)) {
          return false;
        }
      }
      
      // Only show active templates
      if (template['isActive'] != true) {
        return false;
      }
      
      // For templates, we don't filter by date since they're available for booking
      // The date filtering would be applied when showing available time slots
      return true;
    }).toList();
    
    // Sort by title
    filteredTemplates.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    
    return filteredTemplates;
  }

  Widget _buildSessionTemplateCard(dynamic template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTemplateDetails(template),
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
                          template['title'] ?? 'Session Template',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template['notes'] != null && template['notes'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            template['notes'],
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
                  _buildTemplateStatusChip(template),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${template['slotIntervalMinutes'] ?? 60} min slots',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Booking: ${template['minHoursAhead'] ?? 2}h ahead, ${template['maxDaysAhead'] ?? 7} days max',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (template['bufferBefore'] != null || template['bufferAfter'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.pause, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Buffer: ${template['bufferBefore'] ?? 0}min before, ${template['bufferAfter'] ?? 0}min after',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBookingDialog(template),
                      child: const Text('Book Session'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showTemplateDetails(template),
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

  Widget _buildTemplateStatusChip(dynamic template) {
    final isActive = template['isActive'] == true;
    if (isActive) {
      return Chip(
        label: const Text('Available', style: TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.green,
      );
    } else {
      return Chip(
        label: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.grey,
      );
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
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
                'No active session templates are available for booking.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _refreshData(),
                    child: const Text('Refresh'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await _createSampleTemplate();
                      _refreshData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Sample Data'),
                  ),
                ],
              ),
            ],
          ),
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


  void _showTemplateDetails(dynamic template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template['title'] ?? 'Session Template Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (template['notes'] != null && template['notes'].isNotEmpty) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(template['notes']),
                const SizedBox(height: 16),
              ],
              const Text(
                'Session Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Slot Duration: ${template['slotIntervalMinutes'] ?? 60} minutes'),
              const SizedBox(height: 8),
              Text('Booking Window: ${template['minHoursAhead'] ?? 2} hours ahead, max ${template['maxDaysAhead'] ?? 7} days'),
              if (template['bufferBefore'] != null || template['bufferAfter'] != null) ...[
                const SizedBox(height: 8),
                Text('Buffer Time: ${template['bufferBefore'] ?? 0}min before, ${template['bufferAfter'] ?? 0}min after'),
              ],
              if (template['durationOverride'] != null) ...[
                const SizedBox(height: 8),
                Text('Duration Override: ${template['durationOverride']} minutes'),
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
              _showBookingDialog(template);
            },
            child: const Text('Book Session'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(dynamic template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you like to book "${template['title'] ?? 'Session Template'}"?'),
            const SizedBox(height: 16),
            const Text(
              'This will open the booking calendar where you can select an available time slot.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToBookingCalendar(template);
            },
            child: const Text('Select Time'),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingCalendar(dynamic template) {
    context.go('/client/booking/${template['id']}');
  }

  void _refreshData() {
    _loadTemplates();
  }

  Future<void> _createSampleTemplate() async {
    try {
      // First, we need to create some basic data if it doesn't exist
      // Create a sample session type
      final sessionTypeRef = await FirebaseFirestore.instance
          .collection('session_types')
          .add({
        'title': 'Tennis Lesson',
        'duration': 60,
        'durationUnit': 'minutes',
        'price': 50.0,
        'minPlayers': 1,
        'maxPlayers': 4,
        'showParticipants': true,
        'createdTime': FieldValue.serverTimestamp(),
        'idCreatedBy': 'sample_instructor',
      });

      // Create a sample location
      final locationRef = await FirebaseFirestore.instance
          .collection('locations')
          .add({
        'name': 'Central Tennis Court',
        'address': '123 Main St, City',
        'description': 'Professional tennis court with all amenities',
        'createdAt': FieldValue.serverTimestamp(),
        'instructorId': 'sample_instructor',
      });

      // Create a sample schedule
      final scheduleRef = await FirebaseFirestore.instance
          .collection('schedules')
          .add({
        'name': 'Weekday Schedule',
        'timezone': 'America/New_York',
        'isDefault': true,
        'weeklyAvailability': {
          'monday': [
            {'start': '9:00 AM', 'end': '5:00 PM'}
          ],
          'tuesday': [
            {'start': '9:00 AM', 'end': '5:00 PM'}
          ],
          'wednesday': [
            {'start': '9:00 AM', 'end': '5:00 PM'}
          ],
          'thursday': [
            {'start': '9:00 AM', 'end': '5:00 PM'}
          ],
          'friday': [
            {'start': '9:00 AM', 'end': '5:00 PM'}
          ],
        },
        'specificDates': {},
        'holidays': [],
        'createdAt': FieldValue.serverTimestamp(),
        'instructorId': 'sample_instructor',
      });

      // Create a sample schedulable session template
      await FirebaseFirestore.instance
          .collection('schedulable_sessions')
          .add({
        'title': 'Tennis Lesson at Central Court',
        'sessionTypeId': sessionTypeRef.id,
        'locationIds': [locationRef.id],
        'scheduleId': scheduleRef.id,
        'instructorId': 'sample_instructor',
        'bufferBefore': 0,
        'bufferAfter': 0,
        'maxDaysAhead': 7,
        'minHoursAhead': 2,
        'slotIntervalMinutes': 60,
        'notes': 'Professional tennis lessons for all skill levels',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sample template created successfully');
    } catch (e) {
      print('❌ Error creating sample template: $e');
    }
  }
}
