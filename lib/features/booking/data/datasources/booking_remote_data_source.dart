import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/booking/data/models/booking_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/notification/data/datasources/notification_remote_data_source.dart';

abstract class BookingRemoteDataSource {
  Stream<List<BookingModel>> getBookings(String userId);
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId);
  Stream<List<BookingModel>> getBookingsByClient(String clientId);
  Future<BookingModel> getBooking(String id);
  Future<BookingModel> createBooking(BookingModel booking);
  Future<BookingModel> updateBooking(BookingModel booking);
  Future<void> deleteBooking(String id);
  Future<BookingModel> cancelBooking(String id, String cancelledBy);
  Future<BookingModel> confirmBooking(String id);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore _firestore;

  BookingRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Stream<List<BookingModel>> getBookings(String userId) {
    return FirestoreCollections.bookings
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId) {
    return FirestoreCollections.bookings
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Stream<List<BookingModel>> getBookingsByClient(String clientId) {
    return FirestoreCollections.bookings
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();
          // Sort in memory to avoid composite index requirement
          bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
          return bookings;
        });
  }

  @override
  Future<BookingModel> getBooking(String id) async {
    final doc = await FirestoreCollections.booking(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    return BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    final docRef = await FirestoreCollections.bookings.add(booking.toMap());
    final createdBooking = booking.copyWith(id: docRef.id);
    await docRef.set(createdBooking.toMap());
    return createdBooking;
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    await FirestoreCollections.booking(booking.id).update(booking.toMap());
    return booking;
  }

  @override
  Future<void> deleteBooking(String id) async {
    await FirestoreCollections.booking(id).delete();
  }

  @override
  Future<BookingModel> cancelBooking(String id, String cancelledBy) async {
    final doc = await FirestoreCollections.booking(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    
    final booking = BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    final cancelledBooking = booking.copyWith(
      status: 'cancelled',
      updatedAt: DateTime.now(),
    );
    
    await FirestoreCollections.booking(id).update(cancelledBooking.toMap());
    
    // Send appropriate cancellation emails based on who cancelled
    try {
      final notificationService = sl<NotificationRemoteDataSource>();
      
      if (cancelledBy == 'client') {
        // Client cancelled - send appropriate emails
        await notificationService.sendBookingCancellation(id);
        print('📧 Client cancellation email sent for booking: $id');
        
        await notificationService.sendInstructorCancellationNotification(id);
        print('📧 Instructor cancellation notification sent for booking: $id');
      } else if (cancelledBy == 'instructor') {
        // Instructor cancelled - send different emails
        await notificationService.sendInstructorBookingCancellation(id);
        print('📧 Instructor cancellation email sent for booking: $id');
        
        await notificationService.sendClientCancellationNotification(id);
        print('📧 Client cancellation notification sent for booking: $id');
      }
    } catch (e) {
      print('❌ Error sending cancellation emails: $e');
      // Don't throw here - the booking was already cancelled successfully
    }
    
    return cancelledBooking;
  }

  @override
  Future<BookingModel> confirmBooking(String id) async {
    final doc = await FirestoreCollections.booking(id).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }
    
    final booking = BookingModel.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    final confirmedBooking = booking.copyWith(
      status: 'confirmed',
      updatedAt: DateTime.now(),
    );
    
    await FirestoreCollections.booking(id).update(confirmedBooking.toMap());
    
    return confirmedBooking;
  }
}
