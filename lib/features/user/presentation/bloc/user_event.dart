import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadInstructors extends UserEvent {}

class LoadUser extends UserEvent {
  final String userId;

  const LoadUser({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateUser extends UserEvent {
  final String userId;
  final Map<String, dynamic> data;

  const UpdateUser({
    required this.userId,
    required this.data,
  });

  @override
  List<Object> get props => [userId, data];
}
