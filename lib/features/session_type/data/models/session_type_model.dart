import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

class SessionTypeModel extends SessionTypeEntity {
  const SessionTypeModel({
    super.id,
    required super.title,
    super.notifyCancelation = false,
    required super.createdTime,
    required super.duration,
    super.durationUnit = 'minutes',
    super.details = '',
    required super.idCreatedBy,
    required super.maxPlayers,
    super.minPlayers = 1,
    super.showParticipants = true,
    super.category = '',
    required super.price,
  });

  factory SessionTypeModel.fromMap(Map<String, dynamic> map) {
    return SessionTypeModel(
      id: map['id'],
      title: map['title'] ?? '',
      notifyCancelation: map['notifyCancelation'] ?? false,
      createdTime: map['createdTime'] ?? 0,
      duration: map['duration'] ?? 0,
      durationUnit: map['durationUnit'] ?? 'minutes',
      details: map['details'] ?? '',
      idCreatedBy: map['idCreatedBy'] ?? '',
      maxPlayers: map['maxPlayers'] ?? 0,
      minPlayers: map['minPlayers'] ?? 1,
      showParticipants: map['showParticipants'] ?? false,
      category: map['category'] ?? '',
      price: map['price'] ?? 0,
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
      'title': title,
      'notifyCancelation': notifyCancelation,
      'createdTime': createdTime,
      'duration': duration,
      'durationUnit': durationUnit,
      'details': details,
      'idCreatedBy': idCreatedBy,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'showParticipants': showParticipants,
      'category': category,
      'price': price,
    };
  }

  factory SessionTypeModel.fromEntity(SessionTypeEntity entity) {
    return SessionTypeModel(
      id: entity.id,
      title: entity.title,
      notifyCancelation: entity.notifyCancelation,
      createdTime: entity.createdTime,
      duration: entity.duration,
      durationUnit: entity.durationUnit,
      details: entity.details,
      idCreatedBy: entity.idCreatedBy,
      maxPlayers: entity.maxPlayers,
      minPlayers: entity.minPlayers,
      showParticipants: entity.showParticipants,
      category: entity.category,
      price: entity.price,
    );
  }

  SessionTypeModel copyWith({
    String? id,
    String? title,
    bool? notifyCancelation,
    int? createdTime,
    int? duration,
    String? durationUnit,
    String? details,
    String? idCreatedBy,
    int? maxPlayers,
    int? minPlayers,
    bool? showParticipants,
    String? category,
    int? price,
  }) {
    return SessionTypeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notifyCancelation: notifyCancelation ?? this.notifyCancelation,
      createdTime: createdTime ?? this.createdTime,
      duration: duration ?? this.duration,
      durationUnit: durationUnit ?? this.durationUnit,
      details: details ?? this.details,
      idCreatedBy: idCreatedBy ?? this.idCreatedBy,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      showParticipants: showParticipants ?? this.showParticipants,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }
}
