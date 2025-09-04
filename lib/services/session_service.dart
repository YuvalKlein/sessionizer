import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/session.dart';

class SessionService {
  final FirebaseFirestore _firestore;

  SessionService(this._firestore);

  Stream<List<Session>> getSessions(String userId, bool isInstructor) {
    return _firestore
        .collection('sessions')
        .where(isInstructor ? 'instructorId' : 'clientId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList(),
        );
  }
}
