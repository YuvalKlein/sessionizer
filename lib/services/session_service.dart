import 'package:cloud_firestore/cloud_firestore.dart';

class SessionService {
  final FirebaseFirestore _firestore;

  SessionService(this._firestore);

  Stream<QuerySnapshot> getUpcomingSessions() {
    return _firestore
        .collection('sessions')
        .where('startTimeEpoch', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
        .orderBy('startTimeEpoch')
        .snapshots();
  }

  Future<void> joinSession(String sessionId, String userId) {
    return _firestore.collection('sessions').doc(sessionId).update({
      'playersIds': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> leaveSession(String sessionId, String userId) {
    return _firestore.collection('sessions').doc(sessionId).update({
      'playersIds': FieldValue.arrayRemove([userId])
    });
  }
}
