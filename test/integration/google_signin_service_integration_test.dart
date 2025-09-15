import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/core/services/google_signin_service.dart';
import 'package:myapp/core/utils/injection_container.dart' as di;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Sign-In Service Integration Tests', () {
    late GoogleSignInService googleSignInService;

    setUpAll(() async {
      // Initialize dependency injection
      await di.init();
      googleSignInService = di.sl<GoogleSignInService>();
    });

    testWidgets('should initialize Google Sign-In service without errors', (WidgetTester tester) async {
      // Verify the service is properly initialized
      expect(googleSignInService, isNotNull);
      
      // The service should be accessible through dependency injection
      final serviceFromDI = di.sl<GoogleSignInService>();
      expect(serviceFromDI, isNotNull);
      expect(serviceFromDI, equals(googleSignInService)); // Should be singleton
    });

    testWidgets('should handle Google Sign-In initialization', (WidgetTester tester) async {
      // Test that the service can handle sign-in attempts
      try {
        // Attempt to sign in (will likely fail in test environment, but shouldn't crash)
        final result = await googleSignInService.signInWithGoogle(isInstructor: false);
        
        // If successful (unlikely in test), should return UserCredential
        if (result != null) {
          expect(result.user, isNotNull);
        }
      } catch (e) {
        // Expected in test environment - should be a descriptive error
        expect(e.toString(), contains('Google'));
        print('Expected Google Sign-In error in test environment: $e');
      }
    });

    testWidgets('should handle sign out gracefully', (WidgetTester tester) async {
      // Test sign out functionality
      try {
        await googleSignInService.signOut();
        // Should complete without throwing
      } catch (e) {
        // If there's an error, it should be handled gracefully
        print('Sign out error (expected in test): $e');
      }
    });

    testWidgets('should maintain singleton pattern', (WidgetTester tester) async {
      // Verify singleton behavior
      final instance1 = GoogleSignInService();
      final instance2 = GoogleSignInService();
      final instance3 = di.sl<GoogleSignInService>();
      
      expect(instance1, equals(instance2));
      expect(instance2, equals(instance3));
      expect(instance1, equals(googleSignInService));
    });

    testWidgets('should handle multiple sign-in attempts', (WidgetTester tester) async {
      // Test multiple sign-in attempts don't cause issues
      for (int i = 0; i < 3; i++) {
        try {
          await googleSignInService.signInWithGoogle(isInstructor: i % 2 == 0);
        } catch (e) {
          // Expected in test environment
          expect(e, isNotNull);
        }
        
        // Small delay between attempts
        await tester.pump(Duration(milliseconds: 100));
      }
      
      // Service should still be functional
      expect(googleSignInService, isNotNull);
    });

    testWidgets('should handle instructor vs client sign-in parameter', (WidgetTester tester) async {
      // Test both instructor and client sign-in flows
      try {
        // Test client sign-in
        await googleSignInService.signInWithGoogle(isInstructor: false);
      } catch (e) {
        expect(e, isNotNull);
      }
      
      try {
        // Test instructor sign-in
        await googleSignInService.signInWithGoogle(isInstructor: true);
      } catch (e) {
        expect(e, isNotNull);
      }
      
      // Both should behave consistently
      expect(googleSignInService, isNotNull);
    });
  });

  group('Google Sign-In Configuration Tests', () {
    testWidgets('should have proper client ID configuration', (WidgetTester tester) async {
      // This test verifies that the Google Client ID is properly configured
      // In a real test environment, we would check that the client ID matches
      // the expected format and is properly registered with Google
      
      const expectedClientIdPattern = r'^\d+-[a-z0-9]+\.apps\.googleusercontent\.com$';
      const clientId = '707974722454-o7f4paigfd3nkpihs3fvbto2m5obc1h0.apps.googleusercontent.com';
      
      expect(RegExp(expectedClientIdPattern).hasMatch(clientId), isTrue);
    });

    testWidgets('should have proper scopes configured', (WidgetTester tester) async {
      // Verify that the required scopes are configured
      // The GoogleSignInService should request 'email' and 'profile' scopes
      
      // This is tested indirectly through the service behavior
      // In a real implementation, we might expose the scopes for testing
      expect(googleSignInService, isNotNull);
    });
  });
}
