import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_email.dart';

import 'sign_in_with_email_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInWithEmail useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignInWithEmail(mockAuthRepository);
  });

  group('SignInWithEmail', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    
    final testUser = UserEntity(
      id: 'user-123',
      email: testEmail,
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '+1234567890',
      role: 'client',
      isInstructor: false,
      displayName: 'John Doe',
    );

    test('should return UserEntity when sign in is successful', () async {
      // Arrange
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase(SignInWithEmailParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result, Right(testUser));
      verify(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      ));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return AuthFailure when sign in fails', () async {
      // Arrange
      const failure = AuthFailure('Invalid credentials');
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignInWithEmailParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result, Left(failure));
      verify(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      ));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return ServerFailure when unexpected error occurs', () async {
      // Arrange
      const failure = ServerFailure('Network error');
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignInWithEmailParams(
        email: testEmail,
        password: testPassword,
      ));

      // Assert
      expect(result, Left(failure));
    });

    test('should handle empty email', () async {
      // Arrange
      const failure = AuthFailure('Invalid email');
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: '',
        password: testPassword,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignInWithEmailParams(
        email: '',
        password: testPassword,
      ));

      // Assert
      expect(result, Left(failure));
    });

    test('should handle empty password', () async {
      // Arrange
      const failure = AuthFailure('Invalid password');
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: testEmail,
        password: '',
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignInWithEmailParams(
        email: testEmail,
        password: '',
      ));

      // Assert
      expect(result, Left(failure));
    });
  });

  group('SignInWithEmailParams', () {
    test('should be equal when all properties are the same', () {
      // Arrange
      const params1 = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
      );
      const params2 = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(params1, equals(params2));
    });

    test('should not be equal when properties are different', () {
      // Arrange
      const params1 = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
      );
      const params2 = SignInWithEmailParams(
        email: 'different@example.com',
        password: 'password123',
      );

      // Assert
      expect(params1, isNot(equals(params2)));
    });
  });
}
