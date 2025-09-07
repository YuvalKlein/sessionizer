import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';
import 'package:myapp/features/review/domain/repositories/review_repository.dart';

class GetReviewByBookingAndClient implements UseCase<ReviewEntity?, GetReviewByBookingAndClientParams> {
  final ReviewRepository _repository;

  GetReviewByBookingAndClient(this._repository);

  @override
  Future<Either<Failure, ReviewEntity?>> call(GetReviewByBookingAndClientParams params) async {
    return await _repository.getReviewByBookingAndClient(params.bookingId, params.clientId);
  }
}

class GetReviewByBookingAndClientParams {
  final String bookingId;
  final String clientId;

  GetReviewByBookingAndClientParams({
    required this.bookingId,
    required this.clientId,
  });
}
