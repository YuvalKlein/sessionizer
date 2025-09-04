import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  Future<void> createUser(String uid, String email, bool isInstructor, {String? name, String? phone, String? photoURL}) async {
    final now = DateTime.now().toIso8601String();
    await _firestore.collection(_collectionPath).doc(uid).set({
      'email': email,
      'displayName': name ?? email.split('@')[0],
      'isInstructor': isInstructor,
      'admin': false,
      'authSource': 'email',
      'createdTime': now,
      'deservesFreeTrial': true,
      'disabled': false,
      'isVerified': false,
      'phone': phone,
      'photoURL': photoURL,
      'recentAddresses': [],
      'referralsIds': [],
      'referredById': null,
      'savedAddresses': [],
      'sessionsIds': [],
      'subscriptionType': 'free',
      'uuid': uid,
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

  Future<void> updateUserProfile(String uid, {
    String? displayName,
    String? phone,
    String? photoURL,
  }) async {
    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['displayName'] = displayName;
    if (phone != null) updateData['phone'] = phone;
    if (photoURL != null) updateData['photoURL'] = photoURL;
    
    if (updateData.isNotEmpty) {
      await _firestore.collection(_collectionPath).doc(uid).update(updateData);
    }
  }

  Future<void> addRecentAddress(String uid, String address) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'recentAddresses': FieldValue.arrayUnion([address]),
    });
  }

  Future<void> addSavedAddress(String uid, String address) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'savedAddresses': FieldValue.arrayUnion([address]),
    });
  }

  Future<void> removeSavedAddress(String uid, String address) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'savedAddresses': FieldValue.arrayRemove([address]),
    });
  }

  Future<void> addSessionId(String uid, String sessionId) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'sessionsIds': FieldValue.arrayUnion([sessionId]),
    });
  }

  Future<void> removeSessionId(String uid, String sessionId) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'sessionsIds': FieldValue.arrayRemove([sessionId]),
    });
  }

  Future<void> updateSubscriptionType(String uid, String subscriptionType) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'subscriptionType': subscriptionType,
    });
  }

  Future<void> setUserVerified(String uid, bool isVerified) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'isVerified': isVerified,
    });
  }

  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'disabled': disabled,
    });
  }

  Future<void> setAdminStatus(String uid, bool isAdmin) async {
    await _firestore.collection(_collectionPath).doc(uid).update({
      'admin': isAdmin,
    });
  }
}
