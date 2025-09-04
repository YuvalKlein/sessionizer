import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<UserEntity, SignInWithGoogleParams> {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithGoogleParams params) async {
    return await _repository.signInWithGoogle(
      isInstructor: params.isInstructor,
    );
  }
}

class SignInWithGoogleParams extends Equatable {
  final bool isInstructor;

  const SignInWithGoogleParams({
    required this.isInstructor,
  });

  @override
  List<Object> get props => [isInstructor];
}
