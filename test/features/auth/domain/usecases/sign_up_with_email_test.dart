import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/domain/usecases/sign_up_with_email.dart';

import 'sign_up_with_email_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignUpWithEmail useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignUpWithEmail(mockAuthRepository);
  });

  group('SignUpWithEmail', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testFirstName = 'John';
    const testLastName = 'Doe';
    const testPhoneNumber = '+1234567890';
    const testRole = 'client';
    
    final testUser = UserEntity(
      id: 'user-123',
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      phoneNumber: testPhoneNumber,
      role: testRole,
      isInstructor: false,
      displayName: '$testFirstName $testLastName',
    );

    test('should return UserEntity when sign up is successful', () async {
      // Arrange
      when(mockAuthRepository.signUpWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      )).thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase(SignUpWithEmailParams(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      ));

      // Assert
      expect(result, Right(testUser));
      verify(mockAuthRepository.signUpWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      ));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return AuthFailure when email already exists', () async {
      // Arrange
      const failure = AuthFailure('An account with this email already exists');
      when(mockAuthRepository.signUpWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignUpWithEmailParams(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      ));

      // Assert
      expect(result, Left(failure));
    });

    test('should return AuthFailure when password is too weak', () async {
      // Arrange
      const failure = AuthFailure('Password is too weak');
      when(mockAuthRepository.signUpWithEmailAndPassword(
        email: testEmail,
        password: '123', // Weak password
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(SignUpWithEmailParams(
        email: testEmail,
        password: '123',
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: testRole,
      ));

      // Assert
      expect(result, Left(failure));
    });

    test('should handle instructor role correctly', () async {
      // Arrange
      final instructorUser = UserEntity(
        id: 'instructor-123',
        email: testEmail,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: 'instructor',
        isInstructor: true,
        displayName: '$testFirstName $testLastName',
      );

      when(mockAuthRepository.signUpWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: 'instructor',
      )).thenAnswer((_) async => Right(instructorUser));

      // Act
      final result = await useCase(SignUpWithEmailParams(
        email: testEmail,
        password: testPassword,
        firstName: testFirstName,
        lastName: testLastName,
        phoneNumber: testPhoneNumber,
        role: 'instructor',
      ));

      // Assert
      expect(result, Right(instructorUser));
      final userResult = result.getOrElse(() => throw Exception());
      expect(userResult.isInstructor, isTrue);
    });
  });

  group('SignUpWithEmailParams', () {
    test('should be equal when all properties are the same', () {
      // Arrange
      const params1 = SignUpWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        role: 'client',
      );
      const params2 = SignUpWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        role: 'client',
      );

      // Assert
      expect(params1, equals(params2));
    });

    test('should not be equal when properties are different', () {
      // Arrange
      const params1 = SignUpWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        role: 'client',
      );
      const params2 = SignUpWithEmailParams(
        email: 'different@example.com',
        password: 'password123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        role: 'client',
      );

      // Assert
      expect(params1, isNot(equals(params2)));
    });

    test('should include all properties in props for equality', () {
      // Arrange
      const params = SignUpWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        role: 'client',
      );

      // Assert
      expect(params.props, [
        'test@example.com',
        'password123',
        'John',
        'Doe',
        '+1234567890',
        'client',
      ]);
    });
  });
}
