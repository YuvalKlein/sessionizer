import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/features/user/data/models/user_profile_model.dart';

abstract class UserRemoteDataSource {
  Stream<List<UserProfileModel>> getInstructors();
  Stream<UserProfileModel?> getUser(String userId);
  Future<UserProfileModel?> getUserById(String userId);
  Future<UserProfileModel> createUser(UserProfileModel user);
  Future<UserProfileModel> updateUser(String userId, Map<String, dynamic> data);
  Future<void> deleteUser(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<UserProfileModel>> getInstructors() {
    return _firestore
        .collection('users')
        .where('isInstructor', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfileModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<UserProfileModel?> getUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      return null;
    });
  }

  @override
  Future<UserProfileModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to get user: $e');
    }
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      return user;
    } catch (e) {
      throw ServerException('Failed to create user: $e');
    }
  }

  @override
  Future<UserProfileModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      
      final updatedDoc = await _firestore.collection('users').doc(userId).get();
      return UserProfileModel.fromFirestore(updatedDoc);
    } catch (e) {
      throw ServerException('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw ServerException('Failed to delete user: $e');
    }
  }
}
