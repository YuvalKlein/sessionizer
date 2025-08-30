import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'login_screen_test.mocks.dart';

// Annotation to generate a mock for GoRouter
@GenerateMocks([GoRouter, AuthService])
void main() {
  late MockAuthService mockAuthService;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGoRouter = MockGoRouter();
  });

  // Helper function to pump the widget with necessary providers and a mock router
  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<AuthService>.value(value: mockAuthService)],
        child: MaterialApp(
          home: MockGoRouterProvider(
            goRouter: mockGoRouter,
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await pumpLoginScreen(tester);

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('calls login and navigates on valid submission', (
      WidgetTester tester,
    ) async {
      when(mockAuthService.signInWithEmailAndPassword(any, any)).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return null;
      });

      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      verify(
        mockAuthService.signInWithEmailAndPassword(
          'test@example.com',
          'password',
        ),
      );
    });

    testWidgets('shows snackbar on failed login', (WidgetTester tester) async {
      when(
        mockAuthService.signInWithEmailAndPassword(any, any),
      ).thenThrow(Exception('Login failed'));

      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Login failed. Please check your credentials.'),
        findsOneWidget,
      );
    });

    testWidgets('navigates to register screen on button tap', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.text("Don't have an account? Register"));

      verify(mockGoRouter.go('/register')).called(1);
    });
  });
}

// A wrapper to provide the mock GoRouter to the widget tree
class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.child,
    required this.goRouter,
    super.key,
  });

  final Widget child;
  final GoRouter goRouter;

  @override
  Widget build(BuildContext context) {
    return InheritedGoRouter(goRouter: goRouter, child: child);
  }
}
