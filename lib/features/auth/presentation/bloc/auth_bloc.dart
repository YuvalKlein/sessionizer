import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:myapp/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:myapp/features/auth/domain/usecases/sign_out.dart';
import 'package:myapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/core/utils/usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignUpWithEmail _signUpWithEmail;
  final SignOut _signOut;
  final AuthRepository _authRepository;

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignUpWithEmail signUpWithEmail,
    required SignOut signOut,
    required AuthRepository authRepository,
  }) : _signInWithEmail = signInWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signUpWithEmail = signUpWithEmail,
       _signOut = signOut,
       _authRepository = authRepository,
       super(AuthInitial()) {
    
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<SignOutRequested>(_onSignOutRequested);
    
    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        AppLogger.blocEvent('AuthBloc', 'AuthStateChanged', data: {'userId': user?.id ?? 'null'});
        if (user != null) {
          print('✅ AuthBloc: User found - emitting AuthAuthenticated');
          AppLogger.debug('👤 User authenticated - emitting AuthAuthenticated');
          emit(AuthAuthenticated(user));
        } else {
          AppLogger.debug('🚪 User signed out - checking current state before emitting');
          // Only emit AuthUnauthenticated if we're not already in that state
          // This prevents conflicts with manual sign-out
          if (state is! AuthUnauthenticated && state is! AuthLoading) {
            AppLogger.blocState('AuthBloc', 'AuthUnauthenticated', data: {'source': 'authStateListener'});
            emit(AuthUnauthenticated());
          } else {
            AppLogger.debug('🚪 Already in AuthUnauthenticated or AuthLoading state - skipping emission');
          }
        }
      },
      onError: (error) {
        AppLogger.error('Auth state listener error', error);
        // If there's an error in the auth state listener, emit unauthenticated
        if (state is! AuthUnauthenticated) {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _signInWithEmail(SignInWithEmailParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _signInWithGoogle(SignInWithGoogleParams(
      isInstructor: event.isInstructor,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc: Starting signup process');
    emit(AuthLoading());
    
    final result = await _signUpWithEmail(SignUpWithEmailParams(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      phoneNumber: event.phoneNumber,
      role: event.role,
    ));

    result.fold(
      (failure) {
        print('❌ AuthBloc: Signup failed - ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        print('✅ AuthBloc: Signup successful - emitting AuthAuthenticated');
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.info('🔄 Sign out requested - emitting AuthLoading');
    emit(AuthLoading());
    
    // Add a fallback timer that will force unauthenticated state after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (state is AuthLoading) {
        AppLogger.warning('⏰ Fallback timer triggered - forcing AuthUnauthenticated');
        emit(AuthUnauthenticated());
      }
    });
    
    try {
      AppLogger.info('🔄 Calling sign out use case...');
      
      // Add a timeout to prevent endless loading
      final result = await _signOut(NoParams()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('⏰ Sign out timed out after 3 seconds');
          throw Exception('Sign out timed out');
        },
      );

      result.fold(
        (failure) {
          AppLogger.error('❌ Sign out failed: ${failure.message}');
          // Even on failure, emit unauthenticated to prevent endless loading
          emit(AuthUnauthenticated());
        },
        (_) {
          AppLogger.info('✅ Sign out successful - immediately emitting AuthUnauthenticated');
          // Immediately emit AuthUnauthenticated instead of waiting for listener
          // This prevents endless loading and ensures UI updates
          emit(AuthUnauthenticated());
        },
      );
    } catch (e) {
      AppLogger.error('❌ Sign out exception: $e');
      // Even if there's an error, emit unauthenticated to prevent endless loading
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
