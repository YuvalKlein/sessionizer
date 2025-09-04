import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class GetInstructorById implements UseCase<UserProfileEntity, String> {
  final UserRepository repository;

  GetInstructorById(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(String instructorId) async {
    return await repository.getUserById(instructorId);
  }
}
