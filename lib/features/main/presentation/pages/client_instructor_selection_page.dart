import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/booking/presentation/widgets/instructor_avatar.dart';
import 'package:myapp/core/config/firestore_collections.dart';

class ClientInstructorSelectionPage extends StatefulWidget {
  const ClientInstructorSelectionPage({Key? key}) : super(key: key);

  @override
  State<ClientInstructorSelectionPage> createState() => _ClientInstructorSelectionPageState();
}

class _ClientInstructorSelectionPageState extends State<ClientInstructorSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _filteredInstructors = [];

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final querySnapshot = await FirestoreQueries.getInstructors().get();
      
      final instructors = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim().isEmpty 
              ? (data['displayName'] ?? 'Unknown Instructor')
              : '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'email': data['email'] ?? '',
          'phone': data['phoneNumber'] ?? '',
          'bio': data['bio'] ?? '',
          'specialties': data['specialties'] ?? <String>[],
        };
      }).toList();

      setState(() {
        _instructors = instructors;
        _filteredInstructors = List.from(instructors);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load instructors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterInstructors(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        // If search query is empty, show all instructors
        _filteredInstructors = List.from(_instructors);
      } else {
        _filteredInstructors = _instructors.where((instructor) {
          final name = instructor['name'].toString().toLowerCase();
          final email = instructor['email'].toString().toLowerCase();
          final specialties = (instructor['specialties'] as List<dynamic>)
              .map((s) => s.toString().toLowerCase())
              .join(' ');
          
          return name.contains(_searchQuery) ||
                 email.contains(_searchQuery) ||
                 specialties.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _selectInstructor(Map<String, dynamic> instructor) {
    // Navigate to client dashboard with selected instructor
    context.go('/client-dashboard?instructorId=${instructor['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Instructor'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstructors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _instructors.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: _buildInstructorsList(),
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
          hintText: 'Search instructors...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterInstructors('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _filterInstructors,
      ),
    );
  }

  Widget _buildInstructorsList() {
    if (_filteredInstructors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No instructors found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredInstructors.length,
      itemBuilder: (context, index) => _buildInstructorCard(_filteredInstructors[index]),
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor) {
    final specialties = (instructor['specialties'] as List<dynamic>)
        .map((s) => s.toString())
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectInstructor(instructor),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              InstructorAvatar(
                instructorId: instructor['id'],
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
                      instructor['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (instructor['email'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        instructor['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (instructor['phone'].isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        instructor['phone'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (instructor['bio'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        instructor['bio'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (specialties.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: specialties.take(3).map((specialty) => Chip(
                          label: Text(
                            specialty,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[50],
                          side: BorderSide(color: Colors.blue[200]!),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
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
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No instructors available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no instructors registered in the system yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInstructors,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
