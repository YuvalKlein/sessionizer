import 'package:equatable/equatable.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<ReviewEntity> reviews;

  const ReviewLoaded({required this.reviews});

  @override
  List<Object?> get props => [reviews];
}

class ReviewCreated extends ReviewState {
  final ReviewEntity review;

  const ReviewCreated({required this.review});

  @override
  List<Object?> get props => [review];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}
