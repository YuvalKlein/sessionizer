import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String bookingId;
  final String clientId;
  final String instructorId;
  final String sessionId;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewEntity({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.instructorId,
    required this.sessionId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        clientId,
        instructorId,
        sessionId,
        rating,
        comment,
        createdAt,
        updatedAt,
      ];
}
