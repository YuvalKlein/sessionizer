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
    super.hasCancellationFee = true,
    super.cancellationTimeBefore = 18,
    super.cancellationTimeUnit = 'hours',
    super.cancellationFeeAmount = 100,
    super.cancellationFeeType = '%',
  });

  factory SessionTypeModel.fromMap(Map<String, dynamic> map) {
    // Handle both old format (separate fields) and new format (cancellationPolicy map)
    Map<String, dynamic> cancellationPolicy = map['cancellationPolicy'] as Map<String, dynamic>? ?? {};
    
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
      // Support both formats: new format (cancellationPolicy map) and old format (separate fields)
      hasCancellationFee: cancellationPolicy['hasCancellationFee'] ?? map['hasCancellationFee'] ?? true,
      cancellationTimeBefore: cancellationPolicy['cancellationTimeBefore'] ?? map['cancellationTimeBefore'] ?? 18,
      cancellationTimeUnit: cancellationPolicy['cancellationTimeUnit'] ?? map['cancellationTimeUnit'] ?? 'hours',
      cancellationFeeAmount: cancellationPolicy['cancellationFeeAmount'] ?? map['cancellationFeeAmount'] ?? 100,
      cancellationFeeType: cancellationPolicy['cancellationFeeType'] ?? map['cancellationFeeType'] ?? '%',
    );
  }


  Map<String, dynamic> toMap() {
    print('🔧 SessionTypeModel.toMap(): Creating map with cancellation policy:');
    print('  hasCancellationFee: $hasCancellationFee');
    print('  cancellationTimeBefore: $cancellationTimeBefore');
    print('  cancellationTimeUnit: $cancellationTimeUnit');
    print('  cancellationFeeAmount: $cancellationFeeAmount');
    print('  cancellationFeeType: $cancellationFeeType');
    
    final map = {
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
      'cancellationPolicy': {
        'hasCancellationFee': hasCancellationFee,
        'cancellationTimeBefore': cancellationTimeBefore,
        'cancellationTimeUnit': cancellationTimeUnit,
        'cancellationFeeAmount': cancellationFeeAmount,
        'cancellationFeeType': cancellationFeeType,
      },
    };
    
    print('🔧 SessionTypeModel.toMap(): Final map: $map');
    return map;
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
      hasCancellationFee: entity.hasCancellationFee,
      cancellationTimeBefore: entity.cancellationTimeBefore,
      cancellationTimeUnit: entity.cancellationTimeUnit,
      cancellationFeeAmount: entity.cancellationFeeAmount,
      cancellationFeeType: entity.cancellationFeeType,
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
    bool? hasCancellationFee,
    int? cancellationTimeBefore,
    String? cancellationTimeUnit,
    int? cancellationFeeAmount,
    String? cancellationFeeType,
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
      hasCancellationFee: hasCancellationFee ?? this.hasCancellationFee,
      cancellationTimeBefore: cancellationTimeBefore ?? this.cancellationTimeBefore,
      cancellationTimeUnit: cancellationTimeUnit ?? this.cancellationTimeUnit,
      cancellationFeeAmount: cancellationFeeAmount ?? this.cancellationFeeAmount,
      cancellationFeeType: cancellationFeeType ?? this.cancellationFeeType,
    );
  }
}
