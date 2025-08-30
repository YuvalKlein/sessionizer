import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/ui/main_screen.dart';
import 'package:myapp/ui/post_list_screen.dart';
import 'package:myapp/ui/sessions_screen.dart';
import 'package:myapp/ui/profile_screen.dart';
import 'package:myapp/ui/set_screen.dart';
import 'package:myapp/ui/schedule_screen.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'main_screen_test.mocks.dart';

@GenerateMocks([UserService, AuthService])
void main() {
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();
    mockUser = MockUser(uid: '123');
    fakeFirestore = FakeFirebaseFirestore();
  });

  Future<void> pumpMainScreen(WidgetTester tester, {bool isInstructor = false}) async {
    when(mockAuthService.currentUser).thenReturn(mockUser);

    final userDoc = fakeFirestore.collection('users').doc(mockUser.uid);
    await userDoc.set({'isInstructor': isInstructor});

    when(mockUserService.getUserStream(mockUser.uid)).thenAnswer((_) => userDoc.snapshots());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: mockAuthService),
          Provider<UserService>.value(value: mockUserService),
        ],
        child: const MaterialApp(
          home: MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MainScreen', () {
    testWidgets('shows standard tabs for regular user', (WidgetTester tester) async {
      await pumpMainScreen(tester, isInstructor: false);

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Set'), findsNothing);
      expect(find.text('Schedule'), findsNothing);
    });

    testWidgets('shows all tabs for instructor user', (WidgetTester tester) async {
      await pumpMainScreen(tester, isInstructor: true);

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('tapping tabs changes the screen', (WidgetTester tester) async {
      await pumpMainScreen(tester, isInstructor: true);

      // Starts on SessionsScreen
      expect(find.byType(SessionsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.article));
      await tester.pumpAndSettle();
      expect(find.byType(PostListScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SetScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('logout button calls signOut', (WidgetTester tester) async {
      await pumpMainScreen(tester);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      verify(mockAuthService.signOut()).called(1);
    });
  });
}
