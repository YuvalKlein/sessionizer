import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';
import 'package:myapp/features/review/domain/repositories/review_repository.dart';

class GetReviewsByBooking implements UseCase<List<ReviewEntity>, String> {
  final ReviewRepository _repository;

  GetReviewsByBooking(this._repository);

  @override
  Future<Either<Failure, List<ReviewEntity>>> call(String bookingId) async {
    return await _repository.getReviewsByBookingId(bookingId);
  }
}
