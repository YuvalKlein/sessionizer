import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';

abstract class UserRepository {
  Stream<List<UserProfileEntity>> getInstructors();
  Stream<UserProfileEntity?> getUser(String userId);
  Future<Either<Failure, UserProfileEntity>> getUserById(String userId);
  Future<Either<Failure, UserProfileEntity>> createUser(UserProfileEntity user);
  Future<Either<Failure, UserProfileEntity>> updateUser(String userId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteUser(String userId);
}
