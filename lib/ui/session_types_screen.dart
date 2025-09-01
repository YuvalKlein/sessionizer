import 'package:flutter/material.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/ui/widgets/session_type_form.dart';
import 'package:provider/provider.dart';

class SessionTypesScreen extends StatefulWidget {
  const SessionTypesScreen({super.key});

  @override
  State<SessionTypesScreen> createState() => _SessionTypesScreenState();
}

class _SessionTypesScreenState extends State<SessionTypesScreen> {
  final SessionTypeService _sessionTypeService = SessionTypeService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final instructorId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Types'),
      ),
      body: StreamBuilder<List<SessionType>>(
        stream: _sessionTypeService.getSessionTypes(instructorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessionTypes = snapshot.data ?? [];
          return ListView.builder(
            itemCount: sessionTypes.length,
            itemBuilder: (context, index) {
              final sessionType = sessionTypes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    sessionType.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        '\$${sessionType.price.toStringAsFixed(2)} - ${sessionType.duration} ${sessionType.durationUnit}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.grey),
                        onPressed: () => _showSessionTypeDialog(sessionType, isDuplicating: true),
                        tooltip: 'Duplicate',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
                        onPressed: () => _showSessionTypeDialog(sessionType),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(sessionType),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSessionTypeDialog(null),
        child: const Icon(Icons.add),
        tooltip: 'Add Session Type',
      ),
    );
  }

  void _showSessionTypeDialog(SessionType? sessionType, {bool isDuplicating = false}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final instructorId = authService.currentUser!.uid;

    final SessionType? initialData =
        isDuplicating ? sessionType?.copyWith(id: null) : sessionType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(sessionType == null
              ? 'Add Session Type'
              : (isDuplicating ? 'Duplicate Session Type' : 'Edit Session Type')),
          content: SingleChildScrollView(
            child: SessionTypeForm(
              sessionType: initialData,
              onSave: (newSessionType) {
                final sessionToSave = SessionType(
                  id: newSessionType.id,
                  title: newSessionType.title,
                  details: newSessionType.details,
                  price: newSessionType.price,
                  minPlayers: newSessionType.minPlayers,
                  maxPlayers: newSessionType.maxPlayers,
                  duration: newSessionType.duration,
                  durationUnit: newSessionType.durationUnit,
                  repeatingSession: newSessionType.repeatingSession,
                  showParticipants: newSessionType.showParticipants,
                  idInstructor: instructorId,
                  idCreatedBy: sessionType?.idCreatedBy ?? instructorId,
                  createdTime: DateTime.now().millisecondsSinceEpoch, // Always new time for duplicates
                );

                if (sessionType == null || isDuplicating) {
                  _sessionTypeService.addSessionType(sessionToSave);
                } else {
                  _sessionTypeService.updateSessionType(sessionToSave);
                }

                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(SessionType sessionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session Type'),
        content: const Text('Are you sure you want to delete this session type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _sessionTypeService.deleteSessionType(sessionType.id!);
              Navigator.of(context).pop(); // Close the confirmation dialog
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
