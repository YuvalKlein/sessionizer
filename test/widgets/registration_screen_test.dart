import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'login_screen_test.mocks.dart'; // We can reuse the same mocks

void main() {
  late MockAuthService mockAuthService;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGoRouter = MockGoRouter();
  });

  Future<void> pumpRegistrationScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuthService,
        child: MaterialApp(
          home: MockGoRouterProvider(
            goRouter: mockGoRouter,
            child: const RegistrationScreen(),
          ),
        ),
      ),
    );
  }

  group('RegistrationScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await pumpRegistrationScreen(tester);

      expect(find.text('Register'), findsNWidgets(2)); // AppBar title and button
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (WidgetTester tester) async {
      await pumpRegistrationScreen(tester);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter your display name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows validation error for mismatched passwords', (WidgetTester tester) async {
      await pumpRegistrationScreen(tester);

      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password456');
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('calls register and shows loading indicator on valid submission', (WidgetTester tester) async {
      when(mockAuthService.registerWithEmailAndPassword(any, any, any))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return null;
          });

      await pumpRegistrationScreen(tester);

      await tester.enterText(find.byKey(const Key('display_name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
    });

    testWidgets('shows snackbar on failed registration', (WidgetTester tester) async {
      when(mockAuthService.registerWithEmailAndPassword(any, any, any))
          .thenAnswer((_) async => null);

      await pumpRegistrationScreen(tester);

      await tester.enterText(find.byKey(const Key('display_name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Registration failed. Please try again.'), findsOneWidget);
    });

    testWidgets('navigates to login screen on button tap', (WidgetTester tester) async {
      await pumpRegistrationScreen(tester);

      await tester.tap(find.text('Already have an account? Login'));

      verify(mockGoRouter.go('/login')).called(1);
    });
  });
}

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
