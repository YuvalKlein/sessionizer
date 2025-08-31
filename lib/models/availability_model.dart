
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents an availability rule set by an instructor.
class Availability {
  final String id;
  final String instructorId;

  // Type can be 'weekly' for recurring availability or 'date' for a specific date override.
  final String type;

  // For weekly availability, 1 = Monday, 7 = Sunday.
  final int? dayOfWeek;

  // For a specific date override.
  final DateTime? date;

  // Start and end time for the availability slot, format "HH:mm".
  final String startTime;
  final String endTime;

  // List of session template IDs allowed in this slot.
  final List<String> allowedSessionTemplates;

  // Optional break time between sessions in minutes.
  final int breakTime;

  // Optional custom duration to override the template's default duration.
  final int? customDuration;

  // How many days into the future users can book.
  final int daysInFuture;

  // How long before the session they can book it, in minutes.
  final int bookingLeadTime;

  Availability({
    required this.id,
    required this.instructorId,
    required this.type,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.allowedSessionTemplates,
    this.breakTime = 0,
    this.customDuration,
    this.daysInFuture = 7,
    this.bookingLeadTime = 0,
  }) {
    // Ensure that the correct fields are provided for the given type.
    if (type == 'weekly' && dayOfWeek == null) {
      throw ArgumentError("dayOfWeek is required for type 'weekly'");
    }
    if (type == 'date' && date == null) {
      throw ArgumentError("date is required for type 'date'");
    }
  }

  factory Availability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Availability(
      id: doc.id,
      instructorId: data['instructorId'] ?? '',
      type: data['type'] ?? 'weekly',
      dayOfWeek: data['dayOfWeek'],
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      startTime: data['startTime'] ?? '00:00',
      endTime: data['endTime'] ?? '00:00',
      allowedSessionTemplates:
          List<String>.from(data['allowedSessionTemplates'] ?? []),
      breakTime: data['breakTime'] ?? 0,
      customDuration: data['customDuration'],
      daysInFuture: data['daysInFuture'] ?? 7,
      bookingLeadTime: data['bookingLeadTime'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'instructorId': instructorId,
      'type': type,
      'dayOfWeek': dayOfWeek,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'startTime': startTime,
      'endTime': endTime,
      'allowedSessionTemplates': allowedSessionTemplates,
      'breakTime': breakTime,
      'customDuration': customDuration,
      'daysInFuture': daysInFuture,
      'bookingLeadTime': bookingLeadTime,
    };
  }
}
