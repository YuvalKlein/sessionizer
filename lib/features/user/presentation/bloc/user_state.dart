import 'package:equatable/equatable.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class InstructorsLoaded extends UserState {
  final List<UserProfileEntity> instructors;

  const InstructorsLoaded({required this.instructors});

  @override
  List<Object> get props => [instructors];
}

class UserLoaded extends UserState {
  final UserProfileEntity user;

  const UserLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object> get props => [message];
}

class UserOperationSuccess extends UserState {
  final String message;

  const UserOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
