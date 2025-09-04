import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/schedulable_session/data/models/schedulable_session_model.dart';

abstract class SchedulableSessionRemoteDataSource {
  Stream<List<SchedulableSessionModel>> getSchedulableSessions(String instructorId);
  Future<SchedulableSessionModel> getSchedulableSession(String id);
  Future<SchedulableSessionModel> createSchedulableSession(SchedulableSessionModel schedulableSession);
  Future<SchedulableSessionModel> updateSchedulableSession(SchedulableSessionModel schedulableSession);
  Future<void> deleteSchedulableSession(String id);
}

class SchedulableSessionRemoteDataSourceImpl implements SchedulableSessionRemoteDataSource {
  final FirebaseFirestore _firestore;

  SchedulableSessionRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<SchedulableSessionModel>> getSchedulableSessions(String instructorId) {
    return _firestore
        .collection('schedulable_sessions')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => SchedulableSessionModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Filter active sessions in memory to avoid composite index requirement
          return sessions.where((session) => session.isActive).toList();
        });
  }

  @override
  Future<SchedulableSessionModel> getSchedulableSession(String id) async {
    final doc = await _firestore.collection('schedulable_sessions').doc(id).get();
    if (!doc.exists) {
      throw Exception('Schedulable session not found');
    }
    return SchedulableSessionModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<SchedulableSessionModel> createSchedulableSession(SchedulableSessionModel schedulableSession) async {
    final docRef = await _firestore.collection('schedulable_sessions').add(schedulableSession.toMap());
    final createdSession = schedulableSession.copyWith(id: docRef.id);
    await docRef.set(createdSession.toMap());
    return createdSession;
  }

  @override
  Future<SchedulableSessionModel> updateSchedulableSession(SchedulableSessionModel schedulableSession) async {
    await _firestore
        .collection('schedulable_sessions')
        .doc(schedulableSession.id)
        .update(schedulableSession.toMap());
    return schedulableSession;
  }

  @override
  Future<void> deleteSchedulableSession(String id) async {
    await _firestore.collection('schedulable_sessions').doc(id).delete();
  }
}
