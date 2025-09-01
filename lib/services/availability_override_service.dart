import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/availability_override.dart';

class AvailabilityOverrideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'availability_overrides';

  Stream<List<AvailabilityOverride>> getOverrides(String scheduleId) {
    return _firestore
        .collection(_collectionPath)
        .where('scheduleId', isEqualTo: scheduleId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AvailabilityOverride.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addOverride(AvailabilityOverride override) async {
    await _firestore.collection(_collectionPath).add(override.toMap());
  }

  Future<void> deleteOverride(String overrideId) async {
    await _firestore.collection(_collectionPath).doc(overrideId).delete();
  }
}
