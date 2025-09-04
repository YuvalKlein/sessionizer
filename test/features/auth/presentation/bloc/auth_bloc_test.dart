import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:myapp/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_out.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/core/error/failures.dart';
import 'package:myapp/core/utils/usecase.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  SignInWithEmail,
  SignInWithGoogle,
  SignUpWithEmail,
  SignOut,
])
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockSignInWithEmail mockSignInWithEmail;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignUpWithEmail mockSignUpWithEmail;
  late MockSignOut mockSignOut;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSignInWithEmail = MockSignInWithEmail();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignUpWithEmail = MockSignUpWithEmail();
    mockSignOut = MockSignOut();

    // Mock the authStateChanges stream
    when(mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.value(null));

    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      signInWithEmail: mockSignInWithEmail,
      signInWithGoogle: mockSignInWithGoogle,
      signUpWithEmail: mockSignUpWithEmail,
      signOut: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('SignInWithEmailRequested', () {
      const email = 'test@example.com';
      const password = 'password123';
      final userEntity = UserEntity(
        id: '1',
        email: email,
        displayName: 'Test User',
        isInstructor: false,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
        build: () {
          when(mockSignInWithEmail(any))
              .thenAnswer((_) async => Right(userEntity));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailRequested(
          email: email,
          password: password,
        )),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(userEntity),
        ],
        verify: (_) {
          verify(mockSignInWithEmail(SignInWithEmailParams(
            email: email,
            password: password,
          ))).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in fails',
        build: () {
          when(mockSignInWithEmail(any))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailRequested(
          email: email,
          password: password,
        )),
        expect: () => [
          AuthLoading(),
          AuthError('Server error'),
        ],
      );
    });

    group('SignInWithGoogleRequested', () {
      final userEntity = UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Google sign in succeeds',
        build: () {
          when(mockSignInWithGoogle(any))
              .thenAnswer((_) async => Right(userEntity));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithGoogleRequested(isInstructor: false)),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(userEntity),
        ],
        verify: (_) {
          verify(mockSignInWithGoogle(SignInWithGoogleParams(isInstructor: false))).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when Google sign in fails',
        build: () {
          when(mockSignInWithGoogle(any))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInWithGoogleRequested(isInstructor: false)),
        expect: () => [
          AuthLoading(),
          AuthError('Server error'),
        ],
      );
    });

    group('SignUpWithEmailRequested', () {
      const email = 'test@example.com';
      const password = 'password123';
      final userEntity = UserEntity(
        id: '1',
        email: email,
        displayName: 'Test User',
        isInstructor: false,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when sign up succeeds',
        build: () {
          when(mockSignUpWithEmail(any))
              .thenAnswer((_) async => Right(userEntity));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignUpWithEmailRequested(
          email: email,
          password: password,
          name: 'Test User',
          isInstructor: false,
        )),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(userEntity),
        ],
        verify: (_) {
          verify(mockSignUpWithEmail(SignUpWithEmailParams(
            email: email,
            password: password,
            name: 'Test User',
            isInstructor: false,
          ))).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign up fails',
        build: () {
          when(mockSignUpWithEmail(any))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignUpWithEmailRequested(
          email: email,
          password: password,
          name: 'Test User',
          isInstructor: false,
        )),
        expect: () => [
          AuthLoading(),
          AuthError('Server error'),
        ],
      );
    });

    group('SignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when sign out succeeds',
        build: () {
          when(mockSignOut(any))
              .thenAnswer((_) async => const Right(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          AuthLoading(),
          AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(mockSignOut(NoParams())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign out fails',
        build: () {
          when(mockSignOut(any))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          AuthLoading(),
          AuthError('Server error'),
        ],
      );
    });

    group('AuthCheckRequested', () {
      final userEntity = UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(userEntity);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          AuthLoading(),
          AuthAuthenticated(userEntity),
        ],
        verify: (_) {
          verify(mockAuthRepository.currentUser).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when user is not authenticated',
        build: () {
          when(mockAuthRepository.currentUser).thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          AuthLoading(),
          AuthUnauthenticated(),
        ],
      );
    });
  });
}
