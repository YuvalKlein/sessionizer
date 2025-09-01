import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // Import the collection package

class Schedule {
  final String id;
  final String instructorId;
  final String name;
  final bool isDefault;
  final String timezone;
  final Map<String, dynamic>? weeklyAvailability;

  Schedule({
    required this.id,
    required this.instructorId,
    required this.name,
    required this.isDefault,
    required this.timezone,
    this.weeklyAvailability,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      instructorId: data['instructorId'],
      name: data['name'],
      isDefault: data['isDefault'] ?? false,
      timezone: data['timezone'] ?? '',
      weeklyAvailability: data['weeklyAvailability'] as Map<String, dynamic>?,
    );
  }

  // Smarter getter for available days summary
  String get availableDays {
    if (weeklyAvailability == null) return 'No availability set';
    final availableDaysList = weeklyAvailability!.entries
        .where((day) => (day.value as List).isNotEmpty)
        .map((day) => day.key[0].toUpperCase() + day.key.substring(1))
        .toList();

    if (availableDaysList.length == 7) return 'Every day';
    if (availableDaysList.length == 5 &&
        {
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        }.every(availableDaysList.contains))
      return 'Weekdays';
    if (availableDaysList.isEmpty) return 'No availability set';

    return availableDaysList.join(', ');
  }

  // New getter for the time range summary
  String get availabilitySummary {
    if (weeklyAvailability == null) return '';

    final allSlots = weeklyAvailability!.values
        .expand((daySlots) => daySlots as List)
        .map((slot) => slot as Map<String, dynamic>)
        .toList();

    if (allSlots.isEmpty) return '';

    final startTime = allSlots.map((s) => s['startTime'] as String).min;
    final endTime = allSlots.map((s) => s['endTime'] as String).max;

    return 'Available from $startTime to $endTime';
  }

  Map<String, dynamic> toMap() {
    return {
      'instructorId': instructorId,
      'name': name,
      'isDefault': isDefault,
      'timezone': timezone,
      'weeklyAvailability': weeklyAvailability,
    };
  }
}
