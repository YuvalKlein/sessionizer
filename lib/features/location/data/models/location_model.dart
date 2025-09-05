import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    super.id,
    required super.instructorId,
    required super.name,
    super.description,
    super.address,
    super.latitude,
    super.longitude,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      instructorId: map['instructorId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
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
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      id: entity.id,
      instructorId: entity.instructorId,
      name: entity.name,
      description: entity.description,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LocationModel copyWith({
    String? id,
    String? instructorId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
