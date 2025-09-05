import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';

class SchedulableSessionModel extends SchedulableSessionEntity {
  const SchedulableSessionModel({
    super.id,
    required super.instructorId,
    required super.typeIds,
    required super.locationIds,
    required super.availabilityIds,
    super.breakTimeInMinutes = 0,
    super.bookingLeadTimeInMinutes = 30,
    super.futureBookingLimitInDays = 7,
    super.durationOverride,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SchedulableSessionModel.fromMap(Map<String, dynamic> map) {
    return SchedulableSessionModel(
      id: map['id'],
      instructorId: map['instructorId'] ?? '',
      typeIds: List<String>.from(map['typeIds'] ?? []),
      locationIds: List<String>.from(map['locationIds'] ?? []),
      availabilityIds: List<String>.from(map['availabilityIds'] ?? []),
      breakTimeInMinutes: map['breakTimeInMinutes']?.toInt() ?? 0,
      bookingLeadTimeInMinutes: map['bookingLeadTimeInMinutes']?.toInt() ?? 30,
      futureBookingLimitInDays: map['futureBookingLimitInDays']?.toInt() ?? 7,
      durationOverride: map['durationOverride']?.toInt(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
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
      'instructorId': instructorId,
      'typeIds': typeIds,
      'locationIds': locationIds,
      'availabilityIds': availabilityIds,
      'breakTimeInMinutes': breakTimeInMinutes,
      'bookingLeadTimeInMinutes': bookingLeadTimeInMinutes,
      'futureBookingLimitInDays': futureBookingLimitInDays,
      'durationOverride': durationOverride,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SchedulableSessionModel.fromEntity(SchedulableSessionEntity entity) {
    return SchedulableSessionModel(
      id: entity.id,
      instructorId: entity.instructorId,
      typeIds: entity.typeIds,
      locationIds: entity.locationIds,
      availabilityIds: entity.availabilityIds,
      breakTimeInMinutes: entity.breakTimeInMinutes,
      bookingLeadTimeInMinutes: entity.bookingLeadTimeInMinutes,
      futureBookingLimitInDays: entity.futureBookingLimitInDays,
      durationOverride: entity.durationOverride,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchedulableSessionModel copyWith({
    String? id,
    String? instructorId,
    List<String>? typeIds,
    List<String>? locationIds,
    List<String>? availabilityIds,
    int? breakTimeInMinutes,
    int? bookingLeadTimeInMinutes,
    int? futureBookingLimitInDays,
    int? durationOverride,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchedulableSessionModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      typeIds: typeIds ?? this.typeIds,
      locationIds: locationIds ?? this.locationIds,
      availabilityIds: availabilityIds ?? this.availabilityIds,
      breakTimeInMinutes: breakTimeInMinutes ?? this.breakTimeInMinutes,
      bookingLeadTimeInMinutes: bookingLeadTimeInMinutes ?? this.bookingLeadTimeInMinutes,
      futureBookingLimitInDays: futureBookingLimitInDays ?? this.futureBookingLimitInDays,
      durationOverride: durationOverride ?? this.durationOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
