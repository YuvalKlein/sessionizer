import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:myapp/features/user/data/datasources/user_remote_data_source.dart';
import 'package:myapp/features/user/data/models/user_profile_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<UserProfileEntity>> getInstructors() {
    return _remoteDataSource.getInstructors();
  }

  @override
  Stream<UserProfileEntity?> getUser(String userId) {
    return _remoteDataSource.getUser(userId);
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getUserById(String userId) async {
    try {
      final user = await _remoteDataSource.getUserById(userId);
      if (user != null) {
        return Right(user);
      } else {
        return const Left(ServerFailure('User not found'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> createUser(UserProfileEntity user) async {
    try {
      final userModel = await _remoteDataSource.createUser(
        UserProfileModel.fromEntity(user),
      );
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final user = await _remoteDataSource.updateUser(userId, data);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _remoteDataSource.deleteUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
