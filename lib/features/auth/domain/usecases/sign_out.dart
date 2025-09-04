import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  SignOut(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.signOut();
  }
}
