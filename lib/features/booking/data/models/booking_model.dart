import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/booking/domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.clientId,
    required super.instructorId,
    required super.bookableSessionId,
    required super.startTime,
    required super.endTime,
    required super.status,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      instructorId: map['instructorId'] ?? '',
      bookableSessionId: map['bookableSessionId'] ?? map['sessionId'] ?? '', // Support both field names
      startTime: _parseDateTime(map['startTime']),
      endTime: _parseDateTime(map['endTime']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'instructorId': instructorId,
      'bookableSessionId': bookableSessionId, // Renamed from sessionId to bookableSessionId
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      clientId: entity.clientId,
      instructorId: entity.instructorId,
      bookableSessionId: entity.bookableSessionId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BookingModel copyWith({
    String? id,
    String? clientId,
    String? instructorId,
    String? bookableSessionId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      instructorId: instructorId ?? this.instructorId,
      bookableSessionId: bookableSessionId ?? this.bookableSessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
