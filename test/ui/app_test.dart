import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/main_screen.dart';
import 'package:provider/provider.dart';

import '../test_helpers.dart';

@GenerateMocks([AuthService])
void main() {
  testWidgets('smoke test', (tester) async {
    await tester.pumpWidget(MyApp());
  });

  testWidgets('Sign out from main screen navigates to login', (tester) async {
    final authService = MockAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
        ],
        child: MyApp(),
      ),
    );

    // Go to the main screen
    await tester.pumpAndSettle();

    // Tap the sign out button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Verify that we are on the login screen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
  });
}
