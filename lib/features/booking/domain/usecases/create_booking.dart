import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';

class CreateBooking implements UseCase<BookingEntity, CreateBookingParams> {
  final BookingRepository _repository;

  CreateBooking(this._repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CreateBookingParams params) async {
    return await _repository.createBooking(params.booking);
  }
}

class CreateBookingParams extends Equatable {
  final BookingEntity booking;

  const CreateBookingParams({required this.booking});

  @override
  List<Object> get props => [booking];
}
