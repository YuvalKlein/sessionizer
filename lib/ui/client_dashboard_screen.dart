import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/widgets/user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<List<UserModel>>(
        stream: userService.getInstructorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final instructors = snapshot.data ?? [];

          // Debug: Print instructor data
          debugPrint('Instructors loaded: ${instructors.length}');
          for (final instructor in instructors) {
            debugPrint('Instructor: ${instructor.displayName} (${instructor.email}) - isInstructor: ${instructor.isInstructor}');
          }

          if (instructors.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No instructors available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please check back later or contact support.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: instructors.length,
            itemBuilder: (context, index) {
              final instructor = instructors[index];
              return ListTile(
                leading: UserAvatar(
                  user: instructor,
                  size: 48,
                  showBorder: true,
                  borderColor: Theme.of(context).primaryColor,
                ),
                title: Text(instructor.displayName.isNotEmpty ? instructor.displayName : instructor.email),
                subtitle: Text('Click to book a session'),
                onTap: () => context.go('/booking/${instructor.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
