import 'package:cloud_firestore/cloud_firestore.dart';

enum OverrideType { inclusion, exclusion }

class AvailabilityOverride {
  final String id;
  final String scheduleId;
  final DateTime startDate;
  final DateTime endDate;
  final OverrideType type;
  final List<Map<String, String>> timeSlots;

  AvailabilityOverride({
    required this.id,
    required this.scheduleId,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.timeSlots,
  });

  factory AvailabilityOverride.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AvailabilityOverride(
      id: doc.id,
      scheduleId: data['scheduleId'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      type: OverrideType.values.firstWhere((e) => e.toString() == data['type']),
      timeSlots: List<Map<String, String>>.from(data['timeSlots'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'startDate': startDate,
      'endDate': endDate,
      'type': type.toString(),
      'timeSlots': timeSlots,
    };
  }
}
