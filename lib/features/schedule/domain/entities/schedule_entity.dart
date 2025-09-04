import 'package:equatable/equatable.dart';

class ScheduleEntity extends Equatable {
  final String id;
  final String instructorId;
  final String name;
  final bool isDefault;
  final String timezone;
  final Map<String, dynamic>? weeklyAvailability;
  final Map<String, dynamic>? specificDateAvailability;
  final Map<String, dynamic>? holidays;

  const ScheduleEntity({
    required this.id,
    required this.instructorId,
    required this.name,
    required this.isDefault,
    required this.timezone,
    this.weeklyAvailability,
    this.specificDateAvailability,
    this.holidays,
  });

  @override
  List<Object?> get props => [
        id,
        instructorId,
        name,
        isDefault,
        timezone,
        weeklyAvailability,
        specificDateAvailability,
        holidays,
      ];
}
