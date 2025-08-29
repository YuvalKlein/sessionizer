
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Order sessions by when they were created, newest first.
        stream: FirebaseFirestore.instance.collection('sessions').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No sessions yet'));
          }

          // We have data, so let's display it.
          final sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              // Pass the entire session document to the card
              return SessionCard(sessionData: sessions[index].data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionCard({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
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
              sessionData['templateName'] ?? 'No Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${sessionData['startTime']} - ${sessionData['endTime']}', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(sessionData['locationName'] ?? 'No Location', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${sessionData['minPlayers']} - ${sessionData['maxPlayers']} players', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Price: \$${sessionData['price']?.toStringAsFixed(2) ?? '0.00'}',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
