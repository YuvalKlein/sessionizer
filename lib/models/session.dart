import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String id;
  final String instructorId;
  final String clientId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Session({
    required this.id,
    required this.instructorId,
    required this.clientId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Session.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      instructorId: data['instructorId'],
      clientId: data['clientId'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instructorId': instructorId,
      'clientId': clientId,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }
}
