import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';
import 'package:myapp/features/review/domain/repositories/review_repository.dart';

class CreateReview implements UseCase<ReviewEntity, CreateReviewParams> {
  final ReviewRepository _repository;

  CreateReview(this._repository);

  @override
  Future<Either<Failure, ReviewEntity>> call(CreateReviewParams params) async {
    final review = ReviewEntity(
      id: '', // Will be set by the repository
      bookingId: params.bookingId,
      clientId: params.clientId,
      instructorId: params.instructorId,
      sessionId: params.sessionId,
      rating: params.rating,
      comment: params.comment,
      createdAt: DateTime.now(),
    );

    return await _repository.createReview(review);
  }
}

class CreateReviewParams {
  final String bookingId;
  final String clientId;
  final String instructorId;
  final String sessionId;
  final int rating;
  final String? comment;

  CreateReviewParams({
    required this.bookingId,
    required this.clientId,
    required this.instructorId,
    required this.sessionId,
    required this.rating,
    this.comment,
  });
}
