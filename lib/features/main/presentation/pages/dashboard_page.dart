import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                ],
              ),
            );
          }
          
          if (state is UserLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text('Welcome, ${state.user.displayName}!'),
                  const SizedBox(height: 8),
                  Text('Email: ${state.user.email}'),
                  const SizedBox(height: 8),
                  Text('Role: ${state.user.isInstructor ? 'Instructor' : 'Client'}'),
                ],
              ),
            );
          }
          
          return const Center(
            child: Text('No user data available'),
          );
        },
      ),
    );
  }
}
