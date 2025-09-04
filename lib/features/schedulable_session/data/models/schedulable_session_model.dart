import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';

class SchedulableSessionModel extends SchedulableSessionEntity {
  const SchedulableSessionModel({
    required super.id,
    required super.instructorId,
    required super.sessionTypeId,
    required super.title,
    required super.description,
    required super.durationMinutes,
    required super.price,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SchedulableSessionModel.fromMap(Map<String, dynamic> map) {
    return SchedulableSessionModel(
      id: map['id'] ?? '',
      instructorId: map['instructorId'] ?? '',
      sessionTypeId: map['sessionTypeId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
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
      'instructorId': instructorId,
      'sessionTypeId': sessionTypeId,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SchedulableSessionModel.fromEntity(SchedulableSessionEntity entity) {
    return SchedulableSessionModel(
      id: entity.id,
      instructorId: entity.instructorId,
      sessionTypeId: entity.sessionTypeId,
      title: entity.title,
      description: entity.description,
      durationMinutes: entity.durationMinutes,
      price: entity.price,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchedulableSessionModel copyWith({
    String? id,
    String? instructorId,
    String? sessionTypeId,
    String? title,
    String? description,
    int? durationMinutes,
    double? price,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchedulableSessionModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      sessionTypeId: sessionTypeId ?? this.sessionTypeId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
