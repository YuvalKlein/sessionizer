import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/sessions_screen.dart';
import 'package:myapp/ui/set_screen.dart';
import 'package:myapp/ui/schedule_screen.dart';
import 'package:myapp/ui/profile_screen.dart'; // Import the new profile screen

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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated. Redirecting...')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('User data not found.')));
        }

        final userData = snapshot.data!.data()!;
        final bool isInstructor = userData['isInstructor'] ?? false;

        // Dynamically build the pages and navigation items
        final List<Widget> widgetOptions = [const SessionsScreen()];
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
        
        // Add the Profile screen and navigation item, always visible
        widgetOptions.add(const ProfileScreen());
        navBarItems.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        );

        // Ensure the selected index is valid
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
                  context.go('/'); // Navigate to the login/main screen
                  AuthService().signOut();
                },
              ),
            ],
          ),
          body: Center(
            child: widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: navBarItems,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            // To ensure all items are visible and have labels when more than 3 items
            type: BottomNavigationBarType.fixed, 
          ),
        );
      },
    );
  }
}
