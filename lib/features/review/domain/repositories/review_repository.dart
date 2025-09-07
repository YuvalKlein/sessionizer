import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, ReviewEntity>> createReview(ReviewEntity review);
  Future<Either<Failure, ReviewEntity>> updateReview(ReviewEntity review);
  Future<Either<Failure, void>> deleteReview(String reviewId);
  Future<Either<Failure, ReviewEntity>> getReviewById(String reviewId);
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByBookingId(String bookingId);
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByInstructorId(String instructorId);
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByClientId(String clientId);
  Future<Either<Failure, ReviewEntity?>> getReviewByBookingAndClient(String bookingId, String clientId);
}
