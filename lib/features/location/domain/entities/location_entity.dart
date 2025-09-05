import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final String? id;
  final String instructorId;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationEntity({
    this.id,
    required this.instructorId,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        instructorId,
        name,
        description,
        address,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
