import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userService = Provider.of<UserService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: userService.getUserStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isInstructor = snapshot.hasData && snapshot.data!.isInstructor;
        final title = isInstructor ? 'Instructor Dashboard' : 'Client Dashboard';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authService.signOut(),
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            items: isInstructor ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ] : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'My Sessions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _calculateSelectedIndex(context, isInstructor),
            onTap: (index) => _onItemTapped(index, context, isInstructor),
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context, bool isInstructor) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/profile')) {
      return isInstructor ? 1 : 2;
    } else if (location.startsWith('/client/bookings')) {
      return 1;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isInstructor) {
    if (isInstructor) {
      switch (index) {
        case 0:
          context.go('/instructor');
          break;
        case 1:
          context.go('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/client');
          break;
        case 1:
          context.go('/client/bookings');
          break;
        case 2:
          context.go('/profile');
          break;
      }
    }
  }
}
