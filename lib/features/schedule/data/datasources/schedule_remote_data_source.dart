import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/features/schedule/data/models/schedule_model.dart';

abstract class ScheduleRemoteDataSource {
  Stream<List<ScheduleModel>> getSchedules(String instructorId);
  Future<ScheduleModel?> getSchedule(String scheduleId);
  Future<ScheduleModel> createSchedule(ScheduleModel schedule);
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> data);
  Future<void> updateScheduleEntity(ScheduleModel schedule);
  Future<void> deleteSchedule(String scheduleId);
  Future<void> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault);
  Future<void> unsetAllDefaultSchedules();
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final FirebaseFirestore _firestore;

  ScheduleRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<ScheduleModel>> getSchedules(String instructorId) {
    return _firestore
        .collection('sessionizer/schedules')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<ScheduleModel?> getSchedule(String scheduleId) async {
    try {
      final doc = await _firestore.collection('schedules').doc(scheduleId).get();
      if (doc.exists) {
        return ScheduleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to get schedule: $e');
    }
  }

  @override
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final docRef = await _firestore
          .collection('sessionizer/schedules')
          .add(schedule.toMap());
      
      final createdDoc = await docRef.get();
      return ScheduleModel.fromFirestore(createdDoc);
    } catch (e) {
      throw ServerException('Failed to create schedule: $e');
    }
  }

  @override
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update(data);
      
      final updatedDoc = await _firestore.collection('schedules').doc(scheduleId).get();
      return ScheduleModel.fromFirestore(updatedDoc);
    } catch (e) {
      throw ServerException('Failed to update schedule: $e');
    }
  }

  @override
  Future<void> updateScheduleEntity(ScheduleModel schedule) async {
    try {
      await _firestore.collection('schedules').doc(schedule.id).set(schedule.toFirestore());
    } catch (e) {
      throw ServerException('Failed to update schedule entity: $e');
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
    } catch (e) {
      throw ServerException('Failed to delete schedule: $e');
    }
  }

  @override
  Future<void> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault) async {
    try {
      if (isDefault) {
        // First, set all other schedules to not default
        final batch = _firestore.batch();
        final schedules = await _firestore
            .collection('sessionizer/schedules')
            .where('instructorId', isEqualTo: instructorId)
            .get();
        
        for (final doc in schedules.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        
        // Then set the selected schedule as default
        batch.update(
          _firestore.collection('schedules').doc(scheduleId),
          {'isDefault': true},
        );
        
        await batch.commit();
      } else {
        await _firestore.collection('schedules').doc(scheduleId).update({
          'isDefault': false,
        });
      }
    } catch (e) {
      throw ServerException('Failed to set default schedule: $e');
    }
  }

  @override
  Future<void> unsetAllDefaultSchedules() async {
    try {
      final batch = _firestore.batch();
      final schedules = await _firestore
          .collection('sessionizer/schedules')
          .where('isDefault', isEqualTo: true)
          .get();
      
      for (final doc in schedules.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to unset all default schedules: $e');
    }
  }
}
