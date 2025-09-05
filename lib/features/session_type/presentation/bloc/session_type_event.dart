import 'package:equatable/equatable.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

abstract class SessionTypeEvent extends Equatable {
  const SessionTypeEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionTypes extends SessionTypeEvent {}

class LoadSessionTypesByInstructor extends SessionTypeEvent {
  final String instructorId;

  const LoadSessionTypesByInstructor({required this.instructorId});

  @override
  List<Object> get props => [instructorId];
}

class CreateSessionTypeEvent extends SessionTypeEvent {
  final SessionTypeEntity sessionType;

  const CreateSessionTypeEvent({required this.sessionType});

  @override
  List<Object> get props => [sessionType];
}

class UpdateSessionTypeEvent extends SessionTypeEvent {
  final SessionTypeEntity sessionType;

  const UpdateSessionTypeEvent({required this.sessionType});

  @override
  List<Object> get props => [sessionType];
}

class DeleteSessionTypeEvent extends SessionTypeEvent {
  final String id;

  const DeleteSessionTypeEvent({required this.id});

  @override
  List<Object> get props => [id];
}
