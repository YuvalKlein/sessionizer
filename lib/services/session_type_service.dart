import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/session_type.dart';

class SessionTypeService {
  final CollectionReference _sessionTypesCollection =
      FirebaseFirestore.instance.collection('sessionTypes');

  Stream<List<SessionType>> getSessionTypes(String instructorId) {
    return _sessionTypesCollection
        .where('idInstructor', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SessionType.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addSessionType(SessionType sessionType) {
    return _sessionTypesCollection.add(sessionType.toFirestore());
  }

  Future<void> updateSessionType(SessionType sessionType) {
    return _sessionTypesCollection
        .doc(sessionType.id)
        .update(sessionType.toFirestore());
  }

  Future<void> deleteSessionType(String id) {
    return _sessionTypesCollection.doc(id).delete();
  }
}
