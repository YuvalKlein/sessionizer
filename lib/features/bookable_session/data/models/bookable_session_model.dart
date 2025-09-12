import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';

class BookableSessionModel extends BookableSessionEntity {
  const BookableSessionModel({
    super.id,
    required super.instructorId,
    required super.sessionTypeIds,
    required super.locationIds,
    required super.availabilityIds,
    super.breakTimeInMinutes = 0,
    super.bookingLeadTimeInMinutes = 30,
    super.futureBookingLimitInDays = 7,
    super.durationOverride,
    super.cancellationPolicyOverride,
    super.hasCancellationFeeOverride,
    super.cancellationTimeBeforeOverride,
    super.cancellationTimeUnitOverride,
    super.cancellationFeeAmountOverride,
    super.cancellationFeeTypeOverride,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BookableSessionModel.fromMap(Map<String, dynamic> map) {
    return BookableSessionModel(
      id: map['id'],
      instructorId: map['instructorId'] ?? '',
      sessionTypeIds: List<String>.from(map['sessionTypeIds'] ?? []),
      locationIds: List<String>.from(map['locationIds'] ?? []),
      availabilityIds: List<String>.from(map['scheduleIds'] ?? map['availabilityIds'] ?? []),
      breakTimeInMinutes: map['breakTimeInMinutes']?.toInt() ?? 0,
      bookingLeadTimeInMinutes: map['bookingLeadTimeInMinutes']?.toInt() ?? 30,
      futureBookingLimitInDays: map['futureBookingLimitInDays']?.toInt() ?? 7,
      durationOverride: map['durationOverride']?.toInt(),
      cancellationPolicyOverride: map['cancellationPolicyOverride'],
      hasCancellationFeeOverride: map['hasCancellationFeeOverride'],
      cancellationTimeBeforeOverride: map['cancellationTimeBeforeOverride']?.toInt(),
      cancellationTimeUnitOverride: map['cancellationTimeUnitOverride'],
      cancellationFeeAmountOverride: map['cancellationFeeAmountOverride']?.toInt(),
      cancellationFeeTypeOverride: map['cancellationFeeTypeOverride'],
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
      'sessionTypeIds': sessionTypeIds,
      'locationIds': locationIds,
      'availabilityIds': availabilityIds,
      'breakTimeInMinutes': breakTimeInMinutes,
      'bookingLeadTimeInMinutes': bookingLeadTimeInMinutes,
      'futureBookingLimitInDays': futureBookingLimitInDays,
      'durationOverride': durationOverride,
      'cancellationPolicyOverride': cancellationPolicyOverride,
      'hasCancellationFeeOverride': hasCancellationFeeOverride,
      'cancellationTimeBeforeOverride': cancellationTimeBeforeOverride,
      'cancellationTimeUnitOverride': cancellationTimeUnitOverride,
      'cancellationFeeAmountOverride': cancellationFeeAmountOverride,
      'cancellationFeeTypeOverride': cancellationFeeTypeOverride,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BookableSessionModel.fromEntity(BookableSessionEntity entity) {
    return BookableSessionModel(
      id: entity.id,
      instructorId: entity.instructorId,
      sessionTypeIds: entity.sessionTypeIds,
      locationIds: entity.locationIds,
      availabilityIds: entity.availabilityIds,
      breakTimeInMinutes: entity.breakTimeInMinutes,
      bookingLeadTimeInMinutes: entity.bookingLeadTimeInMinutes,
      futureBookingLimitInDays: entity.futureBookingLimitInDays,
      durationOverride: entity.durationOverride,
      cancellationPolicyOverride: entity.cancellationPolicyOverride,
      hasCancellationFeeOverride: entity.hasCancellationFeeOverride,
      cancellationTimeBeforeOverride: entity.cancellationTimeBeforeOverride,
      cancellationTimeUnitOverride: entity.cancellationTimeUnitOverride,
      cancellationFeeAmountOverride: entity.cancellationFeeAmountOverride,
      cancellationFeeTypeOverride: entity.cancellationFeeTypeOverride,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BookableSessionModel copyWith({
    String? id,
    String? instructorId,
    List<String>? sessionTypeIds,
    List<String>? locationIds,
    List<String>? availabilityIds,
    int? breakTimeInMinutes,
    int? bookingLeadTimeInMinutes,
    int? futureBookingLimitInDays,
    int? durationOverride,
    bool? cancellationPolicyOverride,
    bool? hasCancellationFeeOverride,
    int? cancellationTimeBeforeOverride,
    String? cancellationTimeUnitOverride,
    int? cancellationFeeAmountOverride,
    String? cancellationFeeTypeOverride,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookableSessionModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      sessionTypeIds: sessionTypeIds ?? this.sessionTypeIds,
      locationIds: locationIds ?? this.locationIds,
      availabilityIds: availabilityIds ?? this.availabilityIds,
      breakTimeInMinutes: breakTimeInMinutes ?? this.breakTimeInMinutes,
      bookingLeadTimeInMinutes: bookingLeadTimeInMinutes ?? this.bookingLeadTimeInMinutes,
      futureBookingLimitInDays: futureBookingLimitInDays ?? this.futureBookingLimitInDays,
      durationOverride: durationOverride ?? this.durationOverride,
      cancellationPolicyOverride: cancellationPolicyOverride ?? this.cancellationPolicyOverride,
      hasCancellationFeeOverride: hasCancellationFeeOverride ?? this.hasCancellationFeeOverride,
      cancellationTimeBeforeOverride: cancellationTimeBeforeOverride ?? this.cancellationTimeBeforeOverride,
      cancellationTimeUnitOverride: cancellationTimeUnitOverride ?? this.cancellationTimeUnitOverride,
      cancellationFeeAmountOverride: cancellationFeeAmountOverride ?? this.cancellationFeeAmountOverride,
      cancellationFeeTypeOverride: cancellationFeeTypeOverride ?? this.cancellationFeeTypeOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
