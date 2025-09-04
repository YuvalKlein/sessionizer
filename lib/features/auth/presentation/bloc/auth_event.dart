import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignInWithGoogleRequested extends AuthEvent {
  final bool isInstructor;

  const SignInWithGoogleRequested({
    required this.isInstructor,
  });

  @override
  List<Object> get props => [isInstructor];
}

class SignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final bool isInstructor;

  const SignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.isInstructor,
  });

  @override
  List<Object> get props => [email, password, name, isInstructor];
}

class SignOutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}
