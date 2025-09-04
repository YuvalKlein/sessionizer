import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';
import 'package:myapp/features/booking/domain/usecases/get_bookings.dart';
import 'package:myapp/features/booking/domain/usecases/create_booking.dart';
import 'package:myapp/features/booking/domain/usecases/cancel_booking.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_state.dart';
import 'package:myapp/core/error/failures.dart';

import 'booking_bloc_test.mocks.dart';

@GenerateMocks([
  BookingRepository,
  GetBookings,
  CreateBooking,
  CancelBooking,
])
void main() {
  late BookingBloc bookingBloc;
  late MockBookingRepository mockBookingRepository;
  late MockGetBookings mockGetBookings;
  late MockCreateBooking mockCreateBooking;
  late MockCancelBooking mockCancelBooking;

  setUp(() {
    mockBookingRepository = MockBookingRepository();
    mockGetBookings = MockGetBookings();
    mockCreateBooking = MockCreateBooking();
    mockCancelBooking = MockCancelBooking();

    bookingBloc = BookingBloc(
      getBookings: mockGetBookings,
      createBooking: mockCreateBooking,
      cancelBooking: mockCancelBooking,
      repository: mockBookingRepository,
    );
  });

  tearDown(() {
    bookingBloc.close();
  });

  group('BookingBloc', () {
    test('initial state should be BookingInitial', () {
      expect(bookingBloc.state, equals(BookingInitial()));
    });

    group('LoadBookings', () {
      final bookings = [
        BookingEntity(
          id: '1',
          userId: 'user1',
          sessionId: 'session1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(hours: 1)),
          status: 'confirmed',
        ),
        BookingEntity(
          id: '2',
          userId: 'user2',
          sessionId: 'session2',
          startTime: DateTime.now().add(Duration(days: 1)),
          endTime: DateTime.now().add(Duration(days: 1, hours: 1)),
          status: 'pending',
        ),
      ];

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingLoaded] when bookings load successfully',
        build: () {
          when(mockGetBookings(any))
              .thenAnswer((_) async => Right(bookings));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [
          BookingLoading(),
          BookingLoaded(bookings: bookings),
        ],
        verify: (_) {
          verify(mockGetBookings(NoParams())).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingError] when bookings load fails',
        build: () {
          when(mockGetBookings(any))
              .thenAnswer((_) async => Left(ServerFailure()));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [
          BookingLoading(),
          BookingError(message: 'Server error'),
        ],
      );
    });

    group('LoadBookingsByInstructor', () {
      const instructorId = 'instructor123';
      final bookings = [
        BookingEntity(
          id: '1',
          userId: 'user1',
          sessionId: 'session1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(hours: 1)),
          status: 'confirmed',
        ),
      ];

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingLoaded] when instructor bookings load successfully',
        build: () {
          when(mockGetBookings(any))
              .thenAnswer((_) async => Right(bookings));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(LoadBookingsByInstructor(instructorId: instructorId)),
        expect: () => [
          BookingLoading(),
          BookingLoaded(bookings: bookings),
        ],
        verify: (_) {
          verify(mockGetBookings(GetBookingsParams(instructorId: instructorId))).called(1);
        },
      );
    });

    group('CreateBooking', () {
      const userId = 'user123';
      const sessionId = 'session123';
      final startTime = DateTime.now();
      final endTime = DateTime.now().add(Duration(hours: 1));
      final booking = BookingEntity(
        id: '1',
        userId: userId,
        sessionId: sessionId,
        startTime: startTime,
        endTime: endTime,
        status: 'pending',
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingCreated] when booking creation succeeds',
        build: () {
          when(mockCreateBooking(any))
              .thenAnswer((_) async => Right(booking));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(CreateBooking(
          userId: userId,
          sessionId: sessionId,
          startTime: startTime,
          endTime: endTime,
        )),
        expect: () => [
          BookingLoading(),
          BookingCreated(booking: booking),
        ],
        verify: (_) {
          verify(mockCreateBooking(CreateBookingParams(
            userId: userId,
            sessionId: sessionId,
            startTime: startTime,
            endTime: endTime,
          ))).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingError] when booking creation fails',
        build: () {
          when(mockCreateBooking(any))
              .thenAnswer((_) async => Left(ServerFailure()));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(CreateBooking(
          userId: userId,
          sessionId: sessionId,
          startTime: startTime,
          endTime: endTime,
        )),
        expect: () => [
          BookingLoading(),
          BookingError(message: 'Server error'),
        ],
      );
    });

    group('CancelBooking', () {
      const bookingId = 'booking123';

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingCancelled] when booking cancellation succeeds',
        build: () {
          when(mockCancelBooking(any))
              .thenAnswer((_) async => const Right(null));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(CancelBooking(bookingId: bookingId)),
        expect: () => [
          BookingLoading(),
          BookingCancelled(bookingId: bookingId),
        ],
        verify: (_) {
          verify(mockCancelBooking(CancelBookingParams(bookingId: bookingId))).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingError] when booking cancellation fails',
        build: () {
          when(mockCancelBooking(any))
              .thenAnswer((_) async => Left(ServerFailure()));
          return bookingBloc;
        },
        act: (bloc) => bloc.add(CancelBooking(bookingId: bookingId)),
        expect: () => [
          BookingLoading(),
          BookingError(message: 'Server error'),
        ],
      );
    });
  });
}
