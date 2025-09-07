import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';
import 'package:myapp/features/review/domain/repositories/review_repository.dart';
import 'package:myapp/features/review/data/models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, ReviewEntity>> createReview(ReviewEntity review) async {
    try {
      final reviewModel = ReviewModel.fromEntity(review);
      final docRef = await _firestore.collection('reviews').add(reviewModel.toFirestore());
      
      final createdReview = reviewModel.copyWith(id: docRef.id);
      return Right(createdReview);
    } catch (e) {
      return Left(ServerFailure('Failed to create review: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> updateReview(ReviewEntity review) async {
    try {
      final reviewModel = ReviewModel.fromEntity(review);
      await _firestore.collection('reviews').doc(review.id).update(reviewModel.toFirestore());
      return Right(review);
    } catch (e) {
      return Left(ServerFailure('Failed to update review: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete review: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore.collection('reviews').doc(reviewId).get();
      if (doc.exists) {
        final review = ReviewModel.fromFirestore(doc);
        return Right(review);
      } else {
        return Left(ServerFailure('Review not found'));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get review: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByBookingId(String bookingId) async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final reviews = query.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
      
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure('Failed to get reviews by booking: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByInstructorId(String instructorId) async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final reviews = query.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
      
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure('Failed to get reviews by instructor: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviewsByClientId(String clientId) async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final reviews = query.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
      
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure('Failed to get reviews by client: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity?>> getReviewByBookingAndClient(String bookingId, String clientId) async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final review = ReviewModel.fromFirestore(query.docs.first);
        return Right(review);
      } else {
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to get review by booking and client: $e'));
    }
  }
}
