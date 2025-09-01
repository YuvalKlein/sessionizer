import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/availability_model.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'availability';

  Stream<List<Availability>> getAvailabilityStream(String instructorId) {
    return _firestore
        .collection(_collectionPath)
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Availability.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addAvailability(Availability availability) {
    return _firestore.collection(_collectionPath).add(availability.toMap());
  }

  Future<void> updateAvailability(Availability availability) {
    return _firestore
        .collection(_collectionPath)
        .doc(availability.id)
        .update(availability.toMap());
  }

  Future<void> deleteAvailability(String availabilityId) {
    return _firestore.collection(_collectionPath).doc(availabilityId).delete();
  }
}
