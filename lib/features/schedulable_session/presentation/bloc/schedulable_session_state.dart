import 'package:equatable/equatable.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';

abstract class SchedulableSessionState extends Equatable {
  const SchedulableSessionState();

  @override
  List<Object?> get props => [];
}

class SchedulableSessionInitial extends SchedulableSessionState {}

class SchedulableSessionLoading extends SchedulableSessionState {}

class SchedulableSessionLoaded extends SchedulableSessionState {
  final List<SchedulableSessionEntity> sessions;

  const SchedulableSessionLoaded({required this.sessions});

  @override
  List<Object> get props => [sessions];
}

class SchedulableSessionError extends SchedulableSessionState {
  final String message;

  const SchedulableSessionError({required this.message});

  @override
  List<Object> get props => [message];
}
