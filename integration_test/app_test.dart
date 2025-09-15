import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('app should start and show login page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      // Should show login page elements
      expect(find.text('Welcome'), findsAtLeastNWidget(1));
      expect(find.byType(TextField), findsAtLeastNWidget(1));
    });

    testWidgets('should handle navigation between login and signup', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      // Look for signup navigation
      if (find.text('Sign Up').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        
        // Should show signup page
        expect(find.text('Create'), findsAtLeastNWidget(1));
      }
    });
  });
}
