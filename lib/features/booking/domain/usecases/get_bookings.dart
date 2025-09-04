import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';

class GetBookings implements UseCase<List<BookingEntity>, GetBookingsParams> {
  final BookingRepository _repository;

  GetBookings(this._repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(GetBookingsParams params) async {
    try {
      final bookings = await _repository.getBookings(params.userId).first;
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure('Failed to load bookings: $e'));
    }
  }
}

class GetBookingsParams extends Equatable {
  final String userId;

  const GetBookingsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
