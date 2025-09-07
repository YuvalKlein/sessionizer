import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class CreateReviewEvent extends ReviewEvent {
  final String bookingId;
  final String clientId;
  final String instructorId;
  final String sessionId;
  final int rating;
  final String? comment;

  const CreateReviewEvent({
    required this.bookingId,
    required this.clientId,
    required this.instructorId,
    required this.sessionId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [bookingId, clientId, instructorId, sessionId, rating, comment];
}

class LoadReviewsByBookingEvent extends ReviewEvent {
  final String bookingId;

  const LoadReviewsByBookingEvent({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

class LoadReviewByBookingAndClientEvent extends ReviewEvent {
  final String bookingId;
  final String clientId;

  const LoadReviewByBookingAndClientEvent({
    required this.bookingId,
    required this.clientId,
  });

  @override
  List<Object?> get props => [bookingId, clientId];
}
