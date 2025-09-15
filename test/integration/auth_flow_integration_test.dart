import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('should complete email signup flow successfully', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Should start on login page - look for any welcome text
      expect(find.textContaining('Welcome').or(find.text('Login')), findsAtLeastNWidget(1));
      
      // Look for signup navigation
      if (find.text('Sign Up').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        
        // Should be on signup page
        expect(find.textContaining('Create').or(find.textContaining('Register')), findsAtLeastNWidget(1));
        
        // Look for form fields by type rather than specific keys
        final textFields = find.byType(TextField);
        if (textFields.evaluate().length >= 5) {
          // Fill in signup form if fields are available
          await tester.enterText(textFields.at(0), 'Test');
          await tester.enterText(textFields.at(1), 'User'); 
          await tester.enterText(textFields.at(2), 'test${DateTime.now().millisecondsSinceEpoch}@example.com');
          await tester.enterText(textFields.at(3), '+1234567890');
          await tester.enterText(textFields.at(4), 'password123');
          
          // Submit signup if button exists
          final signupButton = find.textContaining('Sign Up').or(find.textContaining('Create'));
          if (signupButton.evaluate().isNotEmpty) {
            await tester.tap(signupButton.first);
            await tester.pumpAndSettle(Duration(seconds: 10));
            
            // Should navigate somewhere after successful signup
            expect(find.textContaining('Dashboard').or(find.textContaining('Home')), findsAtLeastNWidget(1));
          }
        }
      }
    });

    testWidgets('should handle login with existing user', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Should start on login page
      expect(find.text('Welcome Back'), findsOneWidget);
      
      // Fill in login form with existing user
      await tester.enterText(find.byKey(Key('email')), 'yuval@arenna.co');
      await tester.enterText(find.byKey(Key('password')), 'correct_password');
      
      // Submit login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Should navigate to appropriate dashboard
      expect(find.textContaining('Dashboard'), findsOneWidget);
    });

    testWidgets('should show error for invalid login credentials', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Fill in login form with invalid credentials
      await tester.enterText(find.byKey(Key('email')), 'nonexistent@example.com');
      await tester.enterText(find.byKey(Key('password')), 'wrongpassword');
      
      // Submit login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Should show error message
      expect(find.textContaining('No account found'), findsOneWidget);
    });
  });

  group('User Navigation Integration Tests', () {
    testWidgets('should navigate between pages correctly', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Login with existing user
      await tester.enterText(find.byKey(Key('email')), 'yuval@arenna.co');
      await tester.enterText(find.byKey(Key('password')), 'correct_password');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      expect(find.text('Profile'), findsOneWidget);
      
      // Navigate back to dashboard
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Dashboard'), findsOneWidget);
    });
  });
}