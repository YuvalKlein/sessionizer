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
      name: params.name,
      isInstructor: params.isInstructor,
    );
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final bool isInstructor;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.name,
    required this.isInstructor,
  });

  @override
  List<Object> get props => [email, password, name, isInstructor];
}
