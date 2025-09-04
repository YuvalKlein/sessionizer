import 'package:equatable/equatable.dart';

class SessionEntity extends Equatable {
  final String id;
  final String instructorId;
  final String sessionTypeId;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SessionEntity({
    required this.id,
    required this.instructorId,
    required this.sessionTypeId,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        instructorId,
        sessionTypeId,
        name,
        description,
        durationMinutes,
        price,
        isActive,
        createdAt,
        updatedAt,
      ];
}
