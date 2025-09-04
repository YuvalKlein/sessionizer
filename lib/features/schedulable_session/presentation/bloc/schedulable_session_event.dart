import 'package:equatable/equatable.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';

abstract class SchedulableSessionEvent extends Equatable {
  const SchedulableSessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchedulableSessions extends SchedulableSessionEvent {
  final String instructorId;

  const LoadSchedulableSessions({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}

class CreateSchedulableSessionEvent extends SchedulableSessionEvent {
  final SchedulableSessionEntity schedulableSession;

  const CreateSchedulableSessionEvent({required this.schedulableSession});

  @override
  List<Object> get props => [schedulableSession];
}

class UpdateSchedulableSessionEvent extends SchedulableSessionEvent {
  final SchedulableSessionEntity schedulableSession;

  const UpdateSchedulableSessionEvent({required this.schedulableSession});

  @override
  List<Object> get props => [schedulableSession];
}

class DeleteSchedulableSessionEvent extends SchedulableSessionEvent {
  final String id;

  const DeleteSchedulableSessionEvent({required this.id});

  @override
  List<Object> get props => [id];
}
