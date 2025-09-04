import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<UserEntity, SignInWithEmailParams> {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) async {
    return await _repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
