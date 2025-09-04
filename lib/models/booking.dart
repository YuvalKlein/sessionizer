import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String instructorId;
  final String? instructorName;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String scheduleId;
  final String schedulableSessionId; // New field for schedulable session
  final String sessionTypeId; // New field for session type
  final String locationId; // New field for location
  final DateTime startTime;
  final DateTime endTime;

  Booking({
    required this.id,
    required this.instructorId,
    this.instructorName,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.scheduleId,
    required this.schedulableSessionId,
    required this.sessionTypeId,
    required this.locationId,
    required this.startTime,
    required this.endTime,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'],
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      schedulableSessionId: data['schedulableSessionId'] ?? '',
      sessionTypeId: data['sessionTypeId'] ?? '',
      locationId: data['locationId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instructorId': instructorId,
      'instructorName': instructorName,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'scheduleId': scheduleId,
      'schedulableSessionId': schedulableSessionId,
      'sessionTypeId': sessionTypeId,
      'locationId': locationId,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
