import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'locations';

  /// Get all locations for the current instructor
  Stream<List<Map<String, dynamic>>> getLocationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('instructorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  /// Get all locations for the current instructor (one-time fetch)
  Future<List<Map<String, dynamic>>> getLocations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('instructorId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get all locations for a specific instructor (one-time fetch)
  Future<List<Map<String, dynamic>>> getLocationsForInstructor(String instructorId) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('instructorId', isEqualTo: instructorId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get a specific location by ID
  Future<Map<String, dynamic>?> getLocation(String locationId) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(locationId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new location
  Future<String?> createLocation(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final docRef = await _firestore.collection(_collectionPath).add({
        'name': name,
        'instructorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing location
  Future<bool> updateLocation(String locationId, String name) async {
    try {
      await _firestore.collection(_collectionPath).doc(locationId).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a location
  Future<bool> deleteLocation(String locationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(locationId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
