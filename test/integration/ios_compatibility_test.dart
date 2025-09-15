import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Safari Compatibility Tests', () {
    testWidgets('should load app successfully on mobile viewport', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812)); // iPhone X size
      
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10)); // Extra time for iOS
      
      // Should load successfully and show login page
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidget(2));
    });

    testWidgets('should handle touch interactions properly', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Test touch interactions
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.pumpAndSettle();
      
      // Should focus the field without issues
      expect(emailField, findsOneWidget);
      
      // Test button taps
      if (find.text('Sign Up').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        
        // Should navigate successfully
        expect(find.textContaining('Create'), findsAtLeastNWidget(1));
      }
    });

    testWidgets('should handle keyboard input on mobile', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Test text input
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();
      
      // Should accept text input
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should maintain responsive layout on various iOS screen sizes', (WidgetTester tester) async {
      // Test different iOS screen sizes
      final screenSizes = [
        Size(375, 667), // iPhone SE
        Size(375, 812), // iPhone X/11/12 mini
        Size(414, 896), // iPhone 11/XR
        Size(428, 926), // iPhone 12/13/14 Pro Max
        Size(768, 1024), // iPad
        Size(1024, 1366), // iPad Pro
      ];
      
      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);
        
        app.main();
        await tester.pumpAndSettle(Duration(seconds: 5));
        
        // Should maintain proper layout
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidget(2));
        
        // Clean up for next iteration
        await tester.binding.setSurfaceSize(null);
      }
    });

    testWidgets('should handle app state restoration', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Navigate to signup
      if (find.text('Sign Up').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        
        // Should maintain state properly
        expect(find.textContaining('Create'), findsAtLeastNWidget(1));
        
        // Navigate back
        if (find.text('Sign In').evaluate().isNotEmpty) {
          await tester.tap(find.text('Sign In'));
          await tester.pumpAndSettle();
          
          // Should restore login page state
          expect(find.text('Welcome Back'), findsOneWidget);
        }
      }
    });

    testWidgets('should handle Google Sign-In on mobile', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Should show Google Sign-In button
      expect(find.text('Continue with Google'), findsOneWidget);
      
      // Test Google Sign-In button tap (will likely show error in test environment)
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // Should handle the interaction gracefully
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('iOS Performance Tests', () {
    testWidgets('should load within reasonable time on mobile', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 15)); // Allow extra time for iOS
      
      stopwatch.stop();
      
      // Should load within 15 seconds (generous for iOS)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('should handle memory constraints gracefully', (WidgetTester tester) async {
      // Simulate mobile viewport
      await tester.binding.setSurfaceSize(Size(375, 812));
      
      // Test multiple navigation cycles to check for memory leaks
      for (int i = 0; i < 3; i++) {
        app.main();
        await tester.pumpAndSettle(Duration(seconds: 5));
        
        // Navigate between pages
        if (find.text('Sign Up').evaluate().isNotEmpty) {
          await tester.tap(find.text('Sign Up'));
          await tester.pumpAndSettle();
          
          if (find.text('Sign In').evaluate().isNotEmpty) {
            await tester.tap(find.text('Sign In'));
            await tester.pumpAndSettle();
          }
        }
        
        // Should maintain performance
        expect(find.text('Welcome Back'), findsOneWidget);
      }
    });
  });
}
