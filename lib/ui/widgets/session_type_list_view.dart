import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/ui/widgets/session_type_form.dart';

class SessionTypeListView extends StatelessWidget {
  const SessionTypeListView({super.key});

  Future<void> _deleteType(BuildContext context, DocumentSnapshot type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session Type'),
        content: const Text(
          'Are you sure you want to delete this session type?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await type.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session type deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sessionTypes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final types = snapshot.data!.docs;

        if (types.isEmpty) {
          return const Center(
            child: Text('No session types found. Create one to get started!'),
          );
        }

        return ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final session = (type.data() as Map<String, dynamic>?) ?? {};
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(session['title'] ?? 'No Title'),
                subtitle: Text(session['category'] ?? 'No Category'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Edit Session Type'),
                              ),
                              body: SessionTypeForm(type: type),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteType(context, type),
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
}
