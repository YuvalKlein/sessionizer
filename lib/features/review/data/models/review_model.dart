import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/review/domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.bookingId,
    required super.clientId,
    required super.instructorId,
    required super.sessionId,
    required super.rating,
    super.comment,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromEntity(ReviewEntity entity) {
    return ReviewModel(
      id: entity.id,
      bookingId: entity.bookingId,
      clientId: entity.clientId,
      instructorId: entity.instructorId,
      sessionId: entity.sessionId,
      rating: entity.rating,
      comment: entity.comment,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      clientId: data['clientId'] as String,
      instructorId: data['instructorId'] as String,
      sessionId: data['sessionId'] as String,
      rating: data['rating'] as int,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'clientId': clientId,
      'instructorId': instructorId,
      'sessionId': sessionId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? clientId,
    String? instructorId,
    String? sessionId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      clientId: clientId ?? this.clientId,
      instructorId: instructorId ?? this.instructorId,
      sessionId: sessionId ?? this.sessionId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
