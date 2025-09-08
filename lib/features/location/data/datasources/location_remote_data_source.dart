import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/location/data/models/location_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';

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
    return FirestoreCollections.locations
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocationModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
        });
  }

  @override
  Stream<List<LocationModel>> getLocationsByInstructor(String instructorId) {
    return FirestoreQueries.getLocationsByInstructor(instructorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocationModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
        });
  }

  @override
  Future<LocationModel> getLocation(String id) async {
    final doc = await FirestoreCollections.location(id).get();
    if (!doc.exists) {
      throw Exception('Location not found');
    }
    return LocationModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    final docRef = await FirestoreCollections.locations.add(location.toMap());
    final createdDoc = await docRef.get();
    return LocationModel.fromMap({...createdDoc.data() as Map<String, dynamic>, 'id': createdDoc.id});
  }

  @override
  Future<LocationModel> updateLocation(LocationModel location) async {
    if (location.id == null) {
      throw Exception('Location ID is required for update');
    }
    await FirestoreCollections.location(location.id!).update(location.toMap());
    return location;
  }

  @override
  Future<void> deleteLocation(String id) async {
    await FirestoreCollections.location(id).delete();
  }
}
