import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/schedule.dart';
import 'package:intl/intl.dart';

class ScheduleService {
  final FirebaseFirestore _firestore;

  ScheduleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createSchedule(Map<String, dynamic> scheduleData) async {
    await _firestore.collection('schedules').add(scheduleData);
  }

  Future<Schedule?> getSchedule(String scheduleId) async {
    final doc = await _firestore.collection('schedules').doc(scheduleId).get();
    return doc.exists ? Schedule.fromFirestore(doc) : null;
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> scheduleData,
  ) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .update(scheduleData);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  Stream<QuerySnapshot> getSchedulesStream(String instructorId) {
    return _firestore
        .collection('schedules')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots();
  }

  Stream<DocumentSnapshot> getScheduleStream(String scheduleId) {
    return _firestore.collection('schedules').doc(scheduleId).snapshots();
  }

  Future<void> setDefaultSchedule(
    String instructorId,
    String newDefaultId,
    bool isSetting,
  ) async {
    final batch = _firestore.batch();
    final schedulesQuery = await _firestore
        .collection('schedules')
        .where('instructorId', isEqualTo: instructorId)
        .get();

    for (var doc in schedulesQuery.docs) {
      if (doc.id == newDefaultId) {
        batch.update(doc.reference, {'isDefault': isSetting});
      } else if (isSetting) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }

  Future<String> duplicateSchedule(String scheduleId) async {
    final originalDoc = await _firestore.collection('schedules').doc(scheduleId).get();
    if (!originalDoc.exists) {
      throw Exception('Schedule not found');
    }

    final originalData = originalDoc.data() as Map<String, dynamic>;
    final duplicatedData = Map<String, dynamic>.from(originalData);
    
    // Modify the name to indicate it's a copy
    duplicatedData['name'] = '${originalData['name']} (Copy)';
    duplicatedData['isDefault'] = false; // Copies should never be default

    final newDocRef = await _firestore.collection('schedules').add(duplicatedData);
    return newDocRef.id;
  }

  Stream<QuerySnapshot> getOverridesStream(String scheduleId) {
    return _firestore
        .collection('availability_overrides')
        .where('scheduleId', isEqualTo: scheduleId)
        .orderBy('startDate')
        .snapshots();
  }

  Future<void> createOverride(Map<String, dynamic> overrideData) async {
    await _firestore.collection('availability_overrides').add(overrideData);
  }

  Future<void> updateOverride(
    String overrideId,
    Map<String, dynamic> overrideData,
  ) async {
    await _firestore
        .collection('availability_overrides')
        .doc(overrideId)
        .update(overrideData);
  }

  Future<void> deleteOverride(String overrideId) async {
    await _firestore
        .collection('availability_overrides')
        .doc(overrideId)
        .delete();
  }

  Future<Schedule?> getDefaultSchedule(String instructorId) async {
    final querySnapshot = await _firestore
        .collection('schedules')
        .where('instructorId', isEqualTo: instructorId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return Schedule.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<List<Map<String, String>>> getAvailabilityForDay(
    Schedule schedule,
    DateTime day,
  ) async {
    // Check for overrides first
    final overrideSnapshot = await _firestore
        .collection('availability_overrides')
        .where('scheduleId', isEqualTo: schedule.id)
        .where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(day.year, day.month, day.day),
          ),
        )
        .where(
          'startDate',
          isLessThan: Timestamp.fromDate(
            DateTime(day.year, day.month, day.day).add(const Duration(days: 1)),
          ),
        )
        .get();

    if (overrideSnapshot.docs.isNotEmpty) {
      final override = overrideSnapshot.docs.first.data();
      if (override['type'] == 'exclusion') {
        return []; // No availability on this day
      }
      return List<Map<String, String>>.from(override['timeSlots']);
    }

    // Fallback to weekly availability
    final weekday = DateFormat('EEEE').format(day).toLowerCase();
    final weeklyAvailability = schedule.weeklyAvailability;
    if (weeklyAvailability != null) {
      final dayAvailability = weeklyAvailability[weekday];
      if (dayAvailability != null) {
        return List<Map<String, String>>.from(
          dayAvailability.map((e) => Map<String, String>.from(e)),
        );
      }
    }

    return [];
  }
}
