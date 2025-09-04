import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/features/main/presentation/pages/main_screen_clean.dart';
import 'package:myapp/features/auth/domain/entities/user_entity.dart';

import 'main_screen_clean_test.mocks.dart';

@GenerateMocks([AuthBloc, UserBloc])
void main() {
  group('MainScreenClean Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockUserBloc mockUserBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockUserBloc = MockUserBloc();
    });

    Widget createWidgetUnderTest({required Widget child}) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => mockAuthBloc,
            ),
            BlocProvider<UserBloc>(
              create: (context) => mockUserBloc,
            ),
          ],
          child: MainScreenClean(child: child),
        ),
      );
    }

    testWidgets('should show loading indicator when auth state is AuthLoading', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show loading indicator when user state is UserLoading', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      )));
      when(mockUserBloc.state).thenReturn(UserLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show client dashboard for non-instructor user', (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      when(mockUserBloc.state).thenReturn(UserLoaded(user: user));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.text('Client Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show instructor dashboard for instructor user', (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '1',
        email: 'instructor@example.com',
        displayName: 'Instructor User',
        isInstructor: true,
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      when(mockUserBloc.state).thenReturn(UserLoaded(user: user));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.text('Instructor Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      // Instructor should not have calendar icon
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('should show error screen when auth state is AuthError', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthError(message: 'Authentication failed'));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.text('Error: Authentication failed'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });

    testWidgets('should show error screen when user state is UserError', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      )));
      when(mockUserBloc.state).thenReturn(UserError(message: 'User not found'));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Assert
      expect(find.text('Error: User not found'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });

    testWidgets('should call sign out when logout button is tapped', (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      when(mockUserBloc.state).thenReturn(UserLoaded(user: user));
      when(mockAuthBloc.add(any)).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest(child: Container()));

      // Act
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      // Assert
      verify(mockAuthBloc.add(any)).called(1);
    });

    testWidgets('should display child widget when user is loaded', (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
      when(mockUserBloc.state).thenReturn(UserLoaded(user: user));

      const testChild = Text('Test Child Widget');

      // Act
      await tester.pumpWidget(createWidgetUnderTest(child: testChild));

      // Assert
      expect(find.text('Test Child Widget'), findsOneWidget);
    });
  });
}
