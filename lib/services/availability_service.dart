import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/availability_model.dart';

class AvailabilityService {
  final CollectionReference _availabilityCollection = FirebaseFirestore.instance.collection('availability');

  // Create a new availability rule in Firestore
  Future<void> createAvailability(Availability availability) async {
    try {
      await _availabilityCollection.add(availability.toFirestore());
    } catch (e) {
      // It's good practice to handle potential errors
      print('Error creating availability: $e');
      rethrow; // Rethrow the error to be handled by the UI layer
    }
  }

  // Stream of availability rules for a specific instructor
  Stream<List<Availability>> getAvailabilityForInstructor(String instructorId) {
    return _availabilityCollection
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Availability.fromFirestore(doc)).toList();
    });
  }

  // Update an existing availability rule
  Future<void> updateAvailability(Availability availability) async {
    try {
      await _availabilityCollection.doc(availability.id).update(availability.toFirestore());
    } catch (e) {
      print('Error updating availability: $e');
      rethrow;
    }
  }

  // Delete an availability rule
  Future<void> deleteAvailability(String availabilityId) async {
    try {
      await _availabilityCollection.doc(availabilityId).delete();
    } catch (e) {
      print('Error deleting availability: $e');
      rethrow;
    }
  }
}
