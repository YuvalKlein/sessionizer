import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/session_service.dart';
import 'package:provider/provider.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<SessionService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Sessions'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: sessionService.getUpcomingSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No upcoming sessions.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return SessionCard(session: sessions[index]);
            },
          );
        },
      ),
    );
  }
}

class SessionCard extends StatefulWidget {
  final DocumentSnapshot session;

  const SessionCard({super.key, required this.session});

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  Future<void> _joinSession() async {
    final sessionService = Provider.of<SessionService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join.')),
      );
      return;
    }

    try {
      await sessionService.joinSession(widget.session.id, user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the session!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining session: $e')));
    }
  }

  Future<void> _leaveSession() async {
    final sessionService = Provider.of<SessionService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to leave.')),
      );
      return;
    }

    try {
      await sessionService.leaveSession(widget.session.id, user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the session.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error leaving session: $e')));
    }
  }

  String _formatTime(int epoch) {
    return DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(epoch));
  }

  String _formatDate(int epoch) {
    return DateFormat.yMMMd().format(
      DateTime.fromMillisecondsSinceEpoch(epoch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionData = widget.session.data() as Map<String, dynamic>;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    final textTheme = Theme.of(context).textTheme;
    final locationInfo =
        sessionData['locationInfo'] as Map<String, dynamic>? ?? {};
    final price = sessionData['price'] ?? 0;
    final playersIds = List<String>.from(sessionData['playersIds'] ?? []);
    final maxPlayers = sessionData['maxPlayers'] ?? 0;

    final bool isUserJoined = user != null && playersIds.contains(user.uid);
    final bool isSessionFull = playersIds.length >= maxPlayers;

    developer.log(
      'Building SessionCard for session: ${widget.session.id}',
      name: 'myapp.sessions',
      error: {
        'userId': user?.uid,
        'isUserJoined': isUserJoined,
        'isSessionFull': isSessionFull,
        'playersIds': playersIds,
        'maxPlayers': maxPlayers,
      }.toString(),
    );

    Widget actionButton;
    if (isUserJoined) {
      actionButton = OutlinedButton(
        onPressed: _leaveSession,
        child: const Text('Leave'),
      );
    } else if (isSessionFull) {
      actionButton = const Text(
        'Session Full',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      );
    } else {
      actionButton = ElevatedButton(
        onPressed: _joinSession,
        child: const Text('Join'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sessionData['title'] ?? 'No Title',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sessionData['details'] != null &&
                sessionData['details'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  sessionData['details'],
                  style: textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(sessionData['startTimeEpoch'] ?? 0),
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatTime(sessionData['startTimeEpoch'] ?? 0)} - ${_formatTime(sessionData['endTimeEpoch'] ?? 0)}',
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationInfo['name'] ?? 'No Location',
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${playersIds.length} / ${sessionData['maxPlayers']} players',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$$price',
                  style: textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actionButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
