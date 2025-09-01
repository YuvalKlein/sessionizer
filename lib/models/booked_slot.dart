import 'package:cloud_firestore/cloud_firestore.dart';

class BookedSlot {
  final String id;
  final String instructorId;
  final String clientId;
  final DateTime startTime;
  final DateTime endTime;

  BookedSlot({
    required this.id,
    required this.instructorId,
    required this.clientId,
    required this.startTime,
    required this.endTime,
  });

  factory BookedSlot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookedSlot(
      id: doc.id,
      instructorId: data['instructorId'],
      clientId: data['clientId'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instructorId': instructorId,
      'clientId': clientId,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
