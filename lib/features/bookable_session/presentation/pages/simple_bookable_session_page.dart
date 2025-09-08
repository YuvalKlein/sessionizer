import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/bookable_session/presentation/pages/simple_bookable_session_form.dart';
import 'package:myapp/core/config/firestore_collections.dart';

class SimpleBookableSessionPage extends StatelessWidget {
  const SimpleBookableSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookable Slots'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/instructor-dashboard');
            }
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Refresh by rebuilding
              (context as Element).markNeedsBuild();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreQueries.getBookableSessionsByInstructor(user?.uid ?? '')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Untitled Bookable Slot';
              final sessionTypeId = data['sessionTypeId'] as String?;
              final locationIds = (data['locationIds'] as List?) ?? [];
              final scheduleId = data['scheduleId'] as String?;
              final isActive = data['isActive'] as bool? ?? true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                        ),
                                        child: const Text(
                                          'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Session Type: ${sessionTypeId?.substring(0, 8) ?? 'Unknown'} • Location: ${locationIds.isNotEmpty ? locationIds.first.toString().substring(0, 8) : 'None'} • Schedule: ${scheduleId?.substring(0, 8) ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) => _handleMenuAction(context, value, doc),
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
                      _buildInfoRow(Icons.schedule, 'Buffer: ${data['bufferBefore'] ?? 0}min before • ${data['bufferAfter'] ?? 0}min after'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.calendar_today, 'Booking: ${data['maxDaysAhead'] ?? 7} days ahead • ${data['minHoursAhead'] ?? 2} hours ahead'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.timer, 'Slot interval: ${data['slotIntervalMinutes'] ?? 60} minutes'),
                      if (data['durationOverride'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.schedule, 'Duration override: ${data['durationOverride']} minutes'),
                      ],
                      if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.note, 'Notes: ${data['notes']}'),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewSession(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Bookable Slot'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            onPressed: () => _createNewSession(context),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }


  void _createNewSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBookableSessionForm(),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, QueryDocumentSnapshot doc) {
    switch (action) {
      case 'edit':
        _editSession(context, doc);
        break;
      case 'duplicate':
        _duplicateSession(context, doc);
        break;
      case 'delete':
        _deleteSession(context, doc);
        break;
    }
  }

  void _editSession(BuildContext context, QueryDocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleBookableSessionForm(
          bookableSessionDoc: doc,
        ),
      ),
    );
  }

  void _duplicateSession(BuildContext context, QueryDocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleBookableSessionForm(
          bookableSessionDoc: doc,
          isDuplicate: true,
        ),
      ),
    );
  }

  void _deleteSession(BuildContext context, QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bookable Slot'),
        content: const Text('Are you sure you want to delete this bookable slot? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              doc.reference.delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bookable slot deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
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
}
