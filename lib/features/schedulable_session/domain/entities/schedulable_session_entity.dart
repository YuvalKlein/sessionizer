import 'package:equatable/equatable.dart';

class SchedulableSessionEntity extends Equatable {
  final String? id;
  final String instructorId;
  final List<String> typeIds; // Array of session type IDs
  final List<String> locationIds; // Array of location IDs
  final List<String> availabilityIds; // Array of schedule/availability IDs
  final int breakTimeInMinutes; // Break time between sessions
  final int bookingLeadTimeInMinutes; // Minimum advance booking time
  final int futureBookingLimitInDays; // How far in advance bookings can be made
  final int? durationOverride; // Optional duration override
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchedulableSessionEntity({
    this.id,
    required this.instructorId,
    required this.typeIds,
    required this.locationIds,
    required this.availabilityIds,
    this.breakTimeInMinutes = 0,
    this.bookingLeadTimeInMinutes = 30,
    this.futureBookingLimitInDays = 7,
    this.durationOverride,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        instructorId,
        typeIds,
        locationIds,
        availabilityIds,
        breakTimeInMinutes,
        bookingLeadTimeInMinutes,
        futureBookingLimitInDays,
        durationOverride,
        createdAt,
        updatedAt,
      ];
}
