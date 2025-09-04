import 'package:dartz/dartz.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/typedef.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  
  ResultFuture<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  ResultFuture<UserEntity> signInWithGoogle({
    required bool isInstructor,
  });
  
  ResultFuture<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isInstructor,
  });
  
  ResultVoid signOut();
  
  ResultFuture<void> deleteAccount();
}
