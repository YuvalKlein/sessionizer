import 'package:equatable/equatable.dart';

class SchedulableSessionEntity extends Equatable {
  final String id;
  final String instructorId;
  final String sessionTypeId;
  final String title;
  final String description;
  final int durationMinutes;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchedulableSessionEntity({
    required this.id,
    required this.instructorId,
    required this.sessionTypeId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        id,
        instructorId,
        sessionTypeId,
        title,
        description,
        durationMinutes,
        price,
        isActive,
        createdAt,
        updatedAt,
      ];
}
