import 'package:equatable/equatable.dart';
import 'package:myapp/features/schedule/domain/entities/schedule_entity.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleEntity> schedules;

  const ScheduleLoaded({required this.schedules});

  @override
  List<Object> get props => [schedules];
}

class ScheduleDetailLoaded extends ScheduleState {
  final ScheduleEntity schedule;

  const ScheduleDetailLoaded({required this.schedule});

  @override
  List<Object> get props => [schedule];
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError({required this.message});

  @override
  List<Object> get props => [message];
}

class ScheduleOperationSuccess extends ScheduleState {
  final String message;

  const ScheduleOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
