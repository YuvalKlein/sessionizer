import 'package:cloud_firestore/cloud_firestore.dart';

class Availability {
  final String id;
  final String scheduleId;
  final String dayOfWeek;
  final List<Map<String, String>> timeSlots;

  Availability({
    required this.id,
    required this.scheduleId,
    required this.dayOfWeek,
    required this.timeSlots,
  });

  factory Availability.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Availability(
      id: doc.id,
      scheduleId: data['scheduleId'],
      dayOfWeek: data['dayOfWeek'],
      timeSlots: List<Map<String, String>>.from(data['timeSlots'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'dayOfWeek': dayOfWeek,
      'timeSlots': timeSlots,
    };
  }
}
