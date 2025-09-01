import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/user_service.dart';
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

          return ListView.builder(
            itemCount: instructors.length,
            itemBuilder: (context, index) {
              final instructor = instructors[index];
              return ListTile(
                title: Text(instructor.name),
                subtitle: Text(instructor.email),
                onTap: () => context.go('/booking/${instructor.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
