import 'package:equatable/equatable.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<BookingEntity> bookings;

  const BookingLoaded({required this.bookings});

  @override
  List<Object> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object> get props => [message];
}

class BookingCreated extends BookingState {
  final BookingEntity booking;

  const BookingCreated({required this.booking});

  @override
  List<Object> get props => [booking];
}

class BookingUpdated extends BookingState {
  final BookingEntity booking;

  const BookingUpdated({required this.booking});

  @override
  List<Object> get props => [booking];
}

class BookingCancelled extends BookingState {
  final String bookingId;

  const BookingCancelled({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingConfirmed extends BookingState {
  final String bookingId;

  const BookingConfirmed({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
