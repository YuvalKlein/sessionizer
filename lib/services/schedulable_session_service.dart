import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/schedulable_session.dart';

class SchedulableSessionService {
  final FirebaseFirestore _firestore;

  SchedulableSessionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new schedulable session
  Future<String> createSchedulableSession(SchedulableSession schedulableSession) async {
    final docRef = await _firestore
        .collection('schedulable_sessions')
        .add(schedulableSession.toFirestore());
    return docRef.id;
  }

  /// Get a specific schedulable session by ID
  Future<SchedulableSession?> getSchedulableSession(String id) async {
    final doc = await _firestore
        .collection('schedulable_sessions')
        .doc(id)
        .get();
    
    return doc.exists ? SchedulableSession.fromFirestore(doc) : null;
  }

  /// Update an existing schedulable session
  Future<void> updateSchedulableSession(String id, SchedulableSession schedulableSession) async {
    await _firestore
        .collection('schedulable_sessions')
        .doc(id)
        .update(schedulableSession.toFirestore());
  }

  /// Delete a schedulable session
  Future<void> deleteSchedulableSession(String id) async {
    await _firestore
        .collection('schedulable_sessions')
        .doc(id)
        .delete();
  }

  /// Get all schedulable sessions for an instructor
  Stream<List<SchedulableSession>> getSchedulableSessionsStream(String instructorId) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchedulableSession.fromFirestore(doc))
            .toList());
  }

  /// Get all schedulable sessions for an instructor (one-time fetch)
  Future<List<SchedulableSession>> getSchedulableSessionsForInstructor(String instructorId) async {
    final snapshot = await _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .get();
    
    return snapshot.docs
        .map((doc) => SchedulableSession.fromFirestore(doc))
        .toList();
  }

  /// Get active schedulable sessions for an instructor
  Stream<List<SchedulableSession>> getActiveSchedulableSessionsStream(String instructorId) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchedulableSession.fromFirestore(doc))
            .toList());
  }

  /// Get schedulable sessions by session type
  Stream<List<SchedulableSession>> getSchedulableSessionsByTypeStream(
    String instructorId,
    String sessionTypeId,
  ) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .where('sessionTypeId', isEqualTo: sessionTypeId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchedulableSession.fromFirestore(doc))
            .toList());
  }

  /// Get schedulable sessions by location
  Stream<List<SchedulableSession>> getSchedulableSessionsByLocationStream(
    String instructorId,
    String locationId,
  ) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .where('locationIds', arrayContains: locationId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchedulableSession.fromFirestore(doc))
            .toList());
  }

  /// Get schedulable sessions by schedule
  Stream<List<SchedulableSession>> getSchedulableSessionsByScheduleStream(
    String instructorId,
    String scheduleId,
  ) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .where('scheduleId', isEqualTo: scheduleId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchedulableSession.fromFirestore(doc))
            .toList());
  }

  /// Toggle active status of a schedulable session
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _firestore
        .collection('schedulable_sessions')
        .doc(id)
        .update({
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Duplicate a schedulable session
  Future<String> duplicateSchedulableSession(String id) async {
    final original = await getSchedulableSession(id);
    if (original == null) {
      throw Exception('Schedulable session not found');
    }

    final duplicate = original.copyWith(
      id: null, // Will get new ID
      createdAt: DateTime.now(),
      updatedAt: null,
      isActive: false, // Start as inactive
    );

    return await createSchedulableSession(duplicate);
  }

  /// Get count of schedulable sessions by instructor
  Future<int> getSchedulableSessionsCount(String instructorId) async {
    final snapshot = await _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .get();
    
    return snapshot.docs.length;
  }

  /// Get count of active schedulable sessions by instructor
  Future<int> getActiveSchedulableSessionsCount(String instructorId) async {
    final snapshot = await _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .where('isActive', isEqualTo: true)
        .get();
    
    return snapshot.docs.length;
  }

  /// Batch update multiple schedulable sessions
  Future<void> batchUpdateSchedulableSessions(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {
    final batch = _firestore.batch();
    
    for (final id in ids) {
      final docRef = _firestore.collection('schedulable_sessions').doc(id);
      batch.update(docRef, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  /// Delete multiple schedulable sessions
  Future<void> batchDeleteSchedulableSessions(List<String> ids) async {
    final batch = _firestore.batch();
    
    for (final id in ids) {
      final docRef = _firestore.collection('schedulable_sessions').doc(id);
      batch.delete(docRef);
    }
    
    await batch.commit();
  }
}
