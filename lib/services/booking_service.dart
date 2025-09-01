import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/booking.dart';

class BookingService with ChangeNotifier {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of bookings for a specific instructor
  Stream<QuerySnapshot> getBookingsStream(String instructorId) {
    return _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots();
  }

  // Stream of bookings for a specific client
  Stream<QuerySnapshot> getClientBookingsStream(String clientId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .snapshots();
  }

  // Get a list of booked slots for a specific date and instructor
  Future<List<Booking>> getBookedSlots(
    String instructorId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  // Create a new booking
  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    try {
      // Basic validation
      if (bookingData['startTime'] == null || bookingData['endTime'] == null) {
        throw 'Start and end times are required.';
      }
      // In a real app, you'd have more robust validation, including checking for conflicts.
      await _firestore.collection('bookings').add(bookingData);
      notifyListeners();
    } catch (e) {
      // In a real app, you'd have more robust error handling
      rethrow;
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      notifyListeners();
    } catch (e) {
      // In a real app, you'd have more robust error handling
      rethrow;
    }
  }
}
