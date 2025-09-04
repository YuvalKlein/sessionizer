import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/session_type/data/models/session_type_model.dart';

abstract class SessionTypeRemoteDataSource {
  Stream<List<SessionTypeModel>> getSessionTypes();
  Future<SessionTypeModel> getSessionType(String id);
  Future<SessionTypeModel> createSessionType(SessionTypeModel sessionType);
  Future<SessionTypeModel> updateSessionType(SessionTypeModel sessionType);
  Future<void> deleteSessionType(String id);
}

class SessionTypeRemoteDataSourceImpl implements SessionTypeRemoteDataSource {
  final FirebaseFirestore _firestore;

  SessionTypeRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<SessionTypeModel>> getSessionTypes() {
    return _firestore
        .collection('session_types')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionTypeModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<SessionTypeModel> getSessionType(String id) async {
    final doc = await _firestore.collection('session_types').doc(id).get();
    if (!doc.exists) {
      throw Exception('Session type not found');
    }
    return SessionTypeModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<SessionTypeModel> createSessionType(SessionTypeModel sessionType) async {
    final docRef = await _firestore.collection('session_types').add(sessionType.toMap());
    final createdSessionType = sessionType.copyWith(id: docRef.id);
    await docRef.set(createdSessionType.toMap());
    return createdSessionType;
  }

  @override
  Future<SessionTypeModel> updateSessionType(SessionTypeModel sessionType) async {
    await _firestore
        .collection('session_types')
        .doc(sessionType.id)
        .update(sessionType.toMap());
    return sessionType;
  }

  @override
  Future<void> deleteSessionType(String id) async {
    await _firestore.collection('session_types').doc(id).delete();
  }
}
