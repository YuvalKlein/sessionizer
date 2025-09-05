import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';

class GetInstructors implements UseCase<List<UserProfileEntity>, NoParams> {
  final UserRepository _repository;

  GetInstructors(this._repository);

  @override
  Future<Either<Failure, List<UserProfileEntity>>> call(NoParams params) async {
    try {
      final instructors = await _repository.getInstructors().first;
      return Right(instructors);
    } catch (e) {
      return Left(ServerFailure('Failed to load instructors: $e'));
    }
  }
}
