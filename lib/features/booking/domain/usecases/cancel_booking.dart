import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/booking/domain/repositories/booking_repository.dart';

class CancelBooking implements UseCase<void, CancelBookingParams> {
  final BookingRepository _repository;

  CancelBooking(this._repository);

  @override
  Future<Either<Failure, void>> call(CancelBookingParams params) async {
    return await _repository.cancelBooking(params.id, params.cancelledBy);
  }
}

class CancelBookingParams extends Equatable {
  final String id;
  final String cancelledBy; // 'client' or 'instructor'

  const CancelBookingParams({required this.id, required this.cancelledBy});

  @override
  List<Object> get props => [id, cancelledBy];
}
