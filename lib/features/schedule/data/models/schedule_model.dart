import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.instructorId,
    required super.name,
    required super.isDefault,
    required super.timezone,
    super.weeklyAvailability,
    super.specificDateAvailability,
    super.holidays,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      instructorId: data['instructorId'] ?? '',
      name: data['name'] ?? '',
      isDefault: data['isDefault'] ?? false,
      timezone: data['timezone'] ?? 'UTC',
      weeklyAvailability: data['weeklyAvailability'],
      specificDateAvailability: data['specificDateAvailability'],
      holidays: data['holidays'],
    );
  }

  factory ScheduleModel.fromEntity(ScheduleEntity entity) {
    return ScheduleModel(
      id: entity.id,
      instructorId: entity.instructorId,
      name: entity.name,
      isDefault: entity.isDefault,
      timezone: entity.timezone,
      weeklyAvailability: entity.weeklyAvailability,
      specificDateAvailability: entity.specificDateAvailability,
      holidays: entity.holidays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instructorId': instructorId,
      'name': name,
      'isDefault': isDefault,
      'timezone': timezone,
      'weeklyAvailability': weeklyAvailability,
      'specificDateAvailability': specificDateAvailability,
      'holidays': holidays,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }
}
