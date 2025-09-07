import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/location/data/models/location_model.dart';

abstract class LocationRemoteDataSource {
  Stream<List<LocationModel>> getLocations();
  Stream<List<LocationModel>> getLocationsByInstructor(String instructorId);
  Future<LocationModel> getLocation(String id);
  Future<LocationModel> createLocation(LocationModel location);
  Future<LocationModel> updateLocation(LocationModel location);
  Future<void> deleteLocation(String id);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final FirebaseFirestore _firestore;

  LocationRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<LocationModel>> getLocations() {
    return _firestore
        .collection('sessionizer')
        .doc('locations')
        .collection('locations')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocationModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  @override
  Stream<List<LocationModel>> getLocationsByInstructor(String instructorId) {
    return _firestore
        .collection('sessionizer')
        .doc('locations')
        .collection('locations')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocationModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  @override
  Future<LocationModel> getLocation(String id) async {
    final doc = await _firestore.collection('locations').doc(id).get();
    if (!doc.exists) {
      throw Exception('Location not found');
    }
    return LocationModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    final docRef = await _firestore.collection('locations').add(location.toMap());
    final createdDoc = await docRef.get();
    return LocationModel.fromMap({...createdDoc.data()!, 'id': createdDoc.id});
  }

  @override
  Future<LocationModel> updateLocation(LocationModel location) async {
    await _firestore.collection('locations').doc(location.id).update(location.toMap());
    return location;
  }

  @override
  Future<void> deleteLocation(String id) async {
    await _firestore.collection('locations').doc(id).delete();
  }
}
