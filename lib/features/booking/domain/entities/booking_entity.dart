import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String clientId;
  final String instructorId;
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingEntity({
    required this.id,
    required this.clientId,
    required this.instructorId,
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        instructorId,
        sessionId,
        startTime,
        endTime,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}
