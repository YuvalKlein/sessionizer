import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  Future<void> createUser(String uid, String email, bool isInstructor, {String? name}) async {
    await _firestore.collection(_collectionPath).doc(uid).set({
      'email': email,
      'name': name ?? email.split('@')[0], // Use email prefix as default name
      'isInstructor': isInstructor,
      // Add other user details as needed
    });
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(uid).get();
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_collectionPath)
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? UserModel.fromFirestore(snapshot) : null,
        );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    return _firestore.collection(_collectionPath).doc(uid).update(data);
  }

  Stream<List<UserModel>> getInstructorsStream() {
    return _firestore
        .collection(_collectionPath)
        .where('isInstructor', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Add other user-related methods here
}
