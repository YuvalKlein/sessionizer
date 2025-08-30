import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/ui/sessions_screen.dart';
import 'package:myapp/ui/set_screen.dart';
import 'package:myapp/ui/schedule_screen.dart';
import 'package:myapp/ui/profile_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userService = Provider.of<UserService>(context, listen: false);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userService.getUserStream(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text('User data not found.')),
              );
            }

            final userData = snapshot.data!.data()!;
            final bool isInstructor = userData['isInstructor'] ?? false;

            final List<Widget> widgetOptions = [
              const SessionsScreen(),
            ];
            final List<BottomNavigationBarItem> navBarItems = [
              const BottomNavigationBarItem(
                icon: Icon(Icons.sports_soccer),
                label: 'Sessions',
              ),
            ];

            if (isInstructor) {
              widgetOptions.addAll([const SetScreen(), const ScheduleScreen()]);
              navBarItems.addAll([
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Set',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Schedule',
                ),
              ]);
            }

            widgetOptions.add(const ProfileScreen());
            navBarItems.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            );

            if (_selectedIndex >= widgetOptions.length) {
              _selectedIndex = 0;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('My App'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      authService.signOut().then((_) {
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      });
                    },
                  ),
                ],
              ),
              body: Center(child: widgetOptions.elementAt(_selectedIndex)),
              bottomNavigationBar: BottomNavigationBar(
                items: navBarItems,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
              ),
            );
          },
        );
      },
    );
  }
}