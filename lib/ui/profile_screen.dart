import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class ProfileScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  const ProfileScreen({super.key, this.auth, this.firestore});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    currentUser = _auth.currentUser;
  }

  Future<void> _updateInstructorStatus(bool isInstructor) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'isInstructor': isInstructor,
      });
    } catch (e, s) {
      developer.log(
        'Error updating instructor status',
        name: 'myapp.profile',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in.')));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Could not load user profile.'));
          }

          final userData = snapshot.data!.data()!;
          final bool isInstructor = userData['isInstructor'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                title: Text(
                  userData['displayName'] ?? 'N/A',
                  style: textTheme.headlineSmall,
                ),
                subtitle: Text(
                  userData['email'] ?? 'N/A',
                  style: textTheme.bodyMedium,
                ),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: userData['photoURL'] != null
                      ? NetworkImage(userData['photoURL'])
                      : null,
                  child: userData['photoURL'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Enable Instructor Mode'),
                subtitle: const Text('Access special features for instructors'),
                value: isInstructor,
                onChanged: _updateInstructorStatus,
                secondary: const Icon(Icons.school),
              ),
            ],
          );
        },
      ),
    );
  }
}
