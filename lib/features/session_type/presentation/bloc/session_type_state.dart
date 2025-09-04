import 'package:equatable/equatable.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

abstract class SessionTypeState extends Equatable {
  const SessionTypeState();

  @override
  List<Object?> get props => [];
}

class SessionTypeInitial extends SessionTypeState {}

class SessionTypeLoading extends SessionTypeState {}

class SessionTypeLoaded extends SessionTypeState {
  final List<SessionTypeEntity> sessionTypes;

  const SessionTypeLoaded({required this.sessionTypes});

  @override
  List<Object> get props => [sessionTypes];
}

class SessionTypeError extends SessionTypeState {
  final String message;

  const SessionTypeError({required this.message});

  @override
  List<Object> get props => [message];
}
