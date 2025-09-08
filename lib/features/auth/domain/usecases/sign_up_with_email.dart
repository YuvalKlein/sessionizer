import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';

class SignUpWithEmail implements UseCase<UserEntity, SignUpWithEmailParams> {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpWithEmailParams params) async {
    return await _repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
      phoneNumber: params.phoneNumber,
      role: params.role,
    );
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
  });

  @override
  List<Object> get props => [email, password, firstName, lastName, phoneNumber, role];
}
