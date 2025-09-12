import 'package:equatable/equatable.dart';

class BookableSessionEntity extends Equatable {
  final String? id;
  final String instructorId;
  final List<String> sessionTypeIds; // Array of session type IDs
  final List<String> locationIds; // Array of location IDs
  final List<String> availabilityIds; // Array of schedule/availability IDs
  final int breakTimeInMinutes; // Break time between sessions
  final int bookingLeadTimeInMinutes; // Minimum advance booking time
  final int futureBookingLimitInDays; // How far in advance bookings can be made
  final int? durationOverride; // Optional duration override
  
  // Cancellation Policy Override
  final bool? cancellationPolicyOverride; // null = use sessionType default, true = override enabled, false = override disabled
  final bool? hasCancellationFeeOverride; // Override whether cancellation fee is enabled
  final int? cancellationTimeBeforeOverride; // Override cancellation time
  final String? cancellationTimeUnitOverride; // Override cancellation time unit
  final int? cancellationFeeAmountOverride; // Override cancellation fee amount
  final String? cancellationFeeTypeOverride; // Override cancellation fee type
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookableSessionEntity({
    this.id,
    required this.instructorId,
    required this.sessionTypeIds,
    required this.locationIds,
    required this.availabilityIds,
    this.breakTimeInMinutes = 0,
    this.bookingLeadTimeInMinutes = 30,
    this.futureBookingLimitInDays = 7,
    this.durationOverride,
    this.cancellationPolicyOverride,
    this.hasCancellationFeeOverride,
    this.cancellationTimeBeforeOverride,
    this.cancellationTimeUnitOverride,
    this.cancellationFeeAmountOverride,
    this.cancellationFeeTypeOverride,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        instructorId,
        sessionTypeIds,
        locationIds,
        availabilityIds,
        breakTimeInMinutes,
        bookingLeadTimeInMinutes,
        futureBookingLimitInDays,
        durationOverride,
        cancellationPolicyOverride,
        hasCancellationFeeOverride,
        cancellationTimeBeforeOverride,
        cancellationTimeUnitOverride,
        cancellationFeeAmountOverride,
        cancellationFeeTypeOverride,
        createdAt,
        updatedAt,
      ];
}
