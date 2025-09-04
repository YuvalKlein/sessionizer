import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/auth/presentation/pages/login_page.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';

import 'login_page_test.mocks.dart';

@GenerateMocks([AuthBloc])
void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (context) => mockAuthBloc,
          child: const LoginPage(),
        ),
      );
    }

    testWidgets('should display login form elements', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
    });

    testWidgets('should show loading indicator when state is AuthLoading', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when state is AuthError', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthError(message: 'Invalid credentials'));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should call sign in with email when form is submitted', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      when(mockAuthBloc.add(any)).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      verify(mockAuthBloc.add(any)).called(1);
    });

    testWidgets('should call Google sign in when Google button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      when(mockAuthBloc.add(any)).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Assert
      verify(mockAuthBloc.add(any)).called(1);
    });

    testWidgets('should navigate to signup page when sign up link is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pump();

      // Assert
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
