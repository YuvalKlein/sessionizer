import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Stream<List<BookingEntity>> getBookings(String userId);
  Stream<List<BookingEntity>> getBookingsByInstructor(String instructorId);
  Stream<List<BookingEntity>> getBookingsByClient(String clientId);
  ResultFuture<BookingEntity> getBooking(String id);
  ResultFuture<BookingEntity> createBooking(BookingEntity booking);
  ResultFuture<BookingEntity> updateBooking(BookingEntity booking);
  ResultVoid deleteBooking(String id);
  ResultFuture<BookingEntity> cancelBooking(String id);
  ResultFuture<BookingEntity> confirmBooking(String id);
}
