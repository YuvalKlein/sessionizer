import 'package:equatable/equatable.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingEvent {
  final String userId;

  const LoadBookings({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadBookingsByInstructor extends BookingEvent {
  final String instructorId;

  const LoadBookingsByInstructor({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}

class LoadBookingsByClient extends BookingEvent {
  final String clientId;

  const LoadBookingsByClient({required this.clientId});

  @override
  List<Object> get props => [clientId];
}

class CreateBookingEvent extends BookingEvent {
  final BookingEntity booking;

  const CreateBookingEvent({required this.booking});

  @override
  List<Object> get props => [booking];
}

class UpdateBookingEvent extends BookingEvent {
  final BookingEntity booking;

  const UpdateBookingEvent({required this.booking});

  @override
  List<Object> get props => [booking];
}

class CancelBookingEvent extends BookingEvent {
  final String id;
  final String cancelledBy; // 'client' or 'instructor'

  const CancelBookingEvent({required this.id, required this.cancelledBy});

  @override
  List<Object> get props => [id, cancelledBy];
}

class ConfirmBookingEvent extends BookingEvent {
  final String id;

  const ConfirmBookingEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class DeleteBookingEvent extends BookingEvent {
  final String id;

  const DeleteBookingEvent({required this.id});

  @override
  List<Object> get props => [id];
}
