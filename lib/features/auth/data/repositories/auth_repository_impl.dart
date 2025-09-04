import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/data/datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges;
  }

  @override
  UserEntity? get currentUser {
    final user = _remoteDataSource.currentUser;
    return user;
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle({
    required bool isInstructor,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithGoogle(
        isInstructor: isInstructor,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isInstructor,
  }) async {
    try {
      final user = await _remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        isInstructor: isInstructor,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      print('🔄 AuthRepository: Starting sign out process');
      
      // Add timeout to prevent hanging
      await _remoteDataSource.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⏰ AuthRepository: Sign out timed out after 2 seconds');
          throw Exception('Sign out timed out');
        },
      );
      
      print('✅ AuthRepository: Sign out completed successfully');
      return const Right(null);
    } on ServerException catch (e) {
      print('❌ AuthRepository: Server error during sign out: ${e.message}');
      // Even on server error, consider it successful to prevent endless loading
      return const Right(null);
    } catch (e) {
      print('❌ AuthRepository: Unexpected error during sign out: $e');
      // Even if there's an error, we should still consider it a successful sign out
      // to prevent endless loading
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
