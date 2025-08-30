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
      Provider<AuthService>.value(
        value: mockAuthService,
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

      expect(find.text('Login'), findsNWidgets(2)); // AppBar title and button
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (WidgetTester tester) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Re-render the widget after state change

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('calls login and shows loading indicator on valid submission', (WidgetTester tester) async {
      when(mockAuthService.signInWithEmailAndPassword(any, any))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100)); 
            return null;
          });

      await pumpLoginScreen(tester);

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password');
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Show loading indicator

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Let the future complete
    });

    testWidgets('shows snackbar on failed login', (WidgetTester tester) async {
       when(mockAuthService.signInWithEmailAndPassword('test@example.com', 'wrongpassword'))
          .thenAnswer((_) async => null);

      await pumpLoginScreen(tester);
      
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Complete login future

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Login failed. Please check your credentials.'), findsOneWidget);
    });

    testWidgets('navigates to register screen on button tap', (WidgetTester tester) async {
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
    return InheritedGoRouter(
      goRouter: goRouter,
      child: child,
    );
  }
}