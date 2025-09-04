import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

class SessionTypeModel extends SessionTypeEntity {
  const SessionTypeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.color,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SessionTypeModel.fromMap(Map<String, dynamic> map) {
    return SessionTypeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#000000',
      isActive: map['isActive'] ?? true,
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
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SessionTypeModel.fromEntity(SessionTypeEntity entity) {
    return SessionTypeModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SessionTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
