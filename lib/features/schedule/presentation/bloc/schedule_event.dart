import 'package:equatable/equatable.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchedules extends ScheduleEvent {
  final String instructorId;

  const LoadSchedules({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}

class LoadScheduleById extends ScheduleEvent {
  final String scheduleId;

  const LoadScheduleById({required this.scheduleId});

  @override
  List<Object> get props => [scheduleId];
}

class CreateScheduleEvent extends ScheduleEvent {
  final ScheduleEntity schedule;

  const CreateScheduleEvent({required this.schedule});

  @override
  List<Object> get props => [schedule];
}

class UpdateSchedule extends ScheduleEvent {
  final String scheduleId;
  final Map<String, dynamic> data;

  const UpdateSchedule({
    required this.scheduleId,
    required this.data,
  });

  @override
  List<Object> get props => [scheduleId, data];
}

class DeleteSchedule extends ScheduleEvent {
  final String scheduleId;

  const DeleteSchedule({required this.scheduleId});

  @override
  List<Object> get props => [scheduleId];
}

class SetDefaultSchedule extends ScheduleEvent {
  final String instructorId;
  final String scheduleId;
  final bool isDefault;

  const SetDefaultSchedule({
    required this.instructorId,
    required this.scheduleId,
    required this.isDefault,
  });

  @override
  List<Object> get props => [instructorId, scheduleId, isDefault];
}

class UnsetAllDefaultSchedules extends ScheduleEvent {
  const UnsetAllDefaultSchedules();
}
