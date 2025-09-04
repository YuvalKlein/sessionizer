import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';
import 'package:myapp/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:myapp/features/booking/data/models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<BookingEntity>> getBookings(String userId) {
    return _remoteDataSource.getBookings(userId);
  }

  @override
  Stream<List<BookingEntity>> getBookingsByInstructor(String instructorId) {
    return _remoteDataSource.getBookingsByInstructor(instructorId);
  }

  @override
  Stream<List<BookingEntity>> getBookingsByClient(String clientId) {
    return _remoteDataSource.getBookingsByClient(clientId);
  }

  @override
  Future<Either<Failure, BookingEntity>> getBooking(String id) async {
    try {
      final booking = await _remoteDataSource.getBooking(id);
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking(BookingEntity booking) async {
    try {
      final bookingModel = BookingModel.fromEntity(booking);
      final createdBooking = await _remoteDataSource.createBooking(bookingModel);
      return Right(createdBooking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> updateBooking(BookingEntity booking) async {
    try {
      final bookingModel = BookingModel.fromEntity(booking);
      final updatedBooking = await _remoteDataSource.updateBooking(bookingModel);
      return Right(updatedBooking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBooking(String id) async {
    try {
      await _remoteDataSource.deleteBooking(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) async {
    try {
      final cancelledBooking = await _remoteDataSource.cancelBooking(id);
      return Right(cancelledBooking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> confirmBooking(String id) async {
    try {
      final confirmedBooking = await _remoteDataSource.confirmBooking(id);
      return Right(confirmedBooking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
