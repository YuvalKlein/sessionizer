import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/booking/data/models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Stream<List<BookingModel>> getBookings(String userId);
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId);
  Stream<List<BookingModel>> getBookingsByClient(String clientId);
  Future<BookingModel> getBooking(String id);
  Future<BookingModel> createBooking(BookingModel booking);
  Future<BookingModel> updateBooking(BookingModel booking);
  Future<void> deleteBooking(String id);
  Future<BookingModel> cancelBooking(String id);
  Future<BookingModel> confirmBooking(String id);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore _firestore;

  BookingRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<BookingModel>> getBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId) {
    return _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Stream<List<BookingModel>> getBookingsByClient(String clientId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Future<BookingModel> getBooking(String id) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    return BookingModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    final docRef = await _firestore.collection('bookings').add(booking.toMap());
    final createdBooking = booking.copyWith(id: docRef.id);
    await docRef.set(createdBooking.toMap());
    return createdBooking;
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    await _firestore
        .collection('bookings')
        .doc(booking.id)
        .update(booking.toMap());
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    await _firestore.collection('bookings').doc(id).delete();
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    
    final booking = BookingModel.fromMap({...doc.data()!, 'id': doc.id});
    final cancelledBooking = booking.copyWith(
      status: 'cancelled',
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection('bookings')
        .doc(id)
        .update(cancelledBooking.toMap());
    
    return cancelledBooking;
  }

  @override
  Future<BookingModel> confirmBooking(String id) async {
    final doc = await _firestore.collection('bookings').doc(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    
    final booking = BookingModel.fromMap({...doc.data()!, 'id': doc.id});
    final confirmedBooking = booking.copyWith(
      status: 'confirmed',
      updatedAt: DateTime.now(),
    );
    
    await _firestore
        .collection('bookings')
        .doc(id)
        .update(confirmedBooking.toMap());
    
    return confirmedBooking;
  }
}
