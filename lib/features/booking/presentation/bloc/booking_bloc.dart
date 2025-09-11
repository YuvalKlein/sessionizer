import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';
import 'package:myapp/features/booking/domain/usecases/get_bookings.dart';
import 'package:myapp/features/booking/domain/usecases/create_booking.dart';
import 'package:myapp/features/booking/domain/usecases/cancel_booking.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/features/notification/domain/usecases/send_booking_confirmation.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetBookings _getBookings;
  final CreateBooking _createBooking;
  final CancelBooking _cancelBooking;
  final BookingRepository _repository;
  final SendBookingConfirmation _sendBookingConfirmation;

  BookingBloc({
    required GetBookings getBookings,
    required CreateBooking createBooking,
    required CancelBooking cancelBooking,
    required BookingRepository repository,
    required SendBookingConfirmation sendBookingConfirmation,
  })  : _getBookings = getBookings,
        _createBooking = createBooking,
        _cancelBooking = cancelBooking,
        _repository = repository,
        _sendBookingConfirmation = sendBookingConfirmation,
        super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<LoadBookingsByInstructor>(_onLoadBookingsByInstructor);
    on<LoadBookingsByClient>(_onLoadBookingsByClient);
    on<CreateBookingEvent>(_onCreateBooking);
    on<CancelBookingEvent>(_onCancelBooking);
  }

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    final result = await _getBookings(GetBookingsParams(userId: event.userId));

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (bookings) => emit(BookingLoaded(bookings: bookings)),
    );
  }

  Future<void> _onLoadBookingsByInstructor(
    LoadBookingsByInstructor event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    try {
      final bookings = await _repository.getBookingsByInstructor(event.instructorId).first;
      emit(BookingLoaded(bookings: bookings));
    } catch (e) {
      emit(BookingError(message: 'Failed to load instructor bookings: $e'));
    }
  }

  Future<void> _onLoadBookingsByClient(
    LoadBookingsByClient event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    try {
      final bookings = await _repository.getBookingsByClient(event.clientId).first;
      emit(BookingLoaded(bookings: bookings));
    } catch (e) {
      emit(BookingError(message: 'Failed to load client bookings: $e'));
    }
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    final result = await _createBooking(CreateBookingParams(booking: event.booking));

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) async {
        // Send email notification after successful booking creation
        try {
          print('📧 Attempting to send booking confirmation email for booking: ${booking.id}');
          print('📧 Booking details: ${booking.toString()}');
          await _sendBookingConfirmation(booking.id);
          print('✅ Booking confirmation email sent successfully');
        } catch (e) {
          // Log error but don't fail the booking process
          print('❌ Error sending booking confirmation email: $e');
          print('❌ Error details: ${e.toString()}');
        }
        
        emit(BookingCreated(booking: booking));
      },
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    final result = await _cancelBooking(CancelBookingParams(id: event.id, cancelledBy: event.cancelledBy));

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (_) => emit(BookingCancelled(bookingId: event.id)),
    );
  }
}
