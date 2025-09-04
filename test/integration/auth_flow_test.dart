import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main_clean.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('Complete authentication flow - signup to dashboard', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start at login page
      expect(find.text('Welcome Back'), findsOneWidget);

      // Navigate to signup page
      await tester.tap(find.text("Don't have an account? Sign Up"));
      await tester.pumpAndSettle();

      // Verify we're on signup page
      expect(find.text('Create Account'), findsOneWidget);

      // Fill out signup form
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Submit signup form
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify we're redirected to dashboard
      expect(find.text('Client Dashboard'), findsOneWidget);
    });

    testWidgets('Login flow with existing user', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start at login page
      expect(find.text('Welcome Back'), findsOneWidget);

      // Fill out login form
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Submit login form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify we're redirected to dashboard
      expect(find.text('Client Dashboard'), findsOneWidget);
    });

    testWidgets('Sign out flow', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify we're on dashboard
      expect(find.text('Client Dashboard'), findsOneWidget);

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify we're on profile page
      expect(find.text('Profile'), findsOneWidget);

      // Sign out
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Verify we're back at login page
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Navigation between screens', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Test navigation to sessions
      await tester.tap(find.text('My Sessions'));
      await tester.pumpAndSettle();
      expect(find.text('Available Sessions'), findsOneWidget);

      // Test navigation to bookings
      await tester.tap(find.text('My Bookings'));
      await tester.pumpAndSettle();
      expect(find.text('My Bookings'), findsOneWidget);

      // Test navigation back to dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Client Dashboard'), findsOneWidget);
    });

    testWidgets('Form validation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Test invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify email validation message
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });
}
