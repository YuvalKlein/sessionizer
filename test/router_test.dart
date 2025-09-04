import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/router.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/services/session_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/main_screen.dart';
import 'package:myapp/ui/registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'router_test.mocks.dart';

@GenerateMocks([
  AuthService,
  UserService,
  SessionService,
  User,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;
  late MockSessionService mockSessionService;
  late AppRouter appRouter;
  late MockUser mockUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();
    mockSessionService = MockSessionService();
    appRouter = AppRouter(mockAuthService);
    mockUser = MockUser();
    when(mockUser.uid).thenReturn('123');
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: mockAuthService),
        Provider<UserService>.value(value: mockUserService),
        Provider<SessionService>.value(value: mockSessionService),
      ],
      child: MaterialApp.router(routerConfig: appRouter.router),
    );
  }

  void stubUserIsLoggedIn(bool isInstructor) {
    when(mockAuthService.currentUser).thenReturn(mockUser);
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(mockUser));

    when(mockUserService.getUserStream(any)).thenAnswer((_) => Stream.value(
        UserModel(id: '123', email: 'test@test.com', name: 'test')));
    when(mockSessionService.getSessions(any, any))
        .thenAnswer((_) => Stream.value([]));
  }

  void stubUserIsLoggedOut() {
    when(mockAuthService.currentUser).thenReturn(null);
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));
  }

  testWidgets('redirects to login when not logged in', (
    WidgetTester tester,
  ) async {
    stubUserIsLoggedOut();

    await tester.pumpWidget(createTestableWidget(const SizedBox()));

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('redirects to main screen when logged in', (
    WidgetTester tester,
  ) async {
    stubUserIsLoggedIn(false);

    await tester.pumpWidget(createTestableWidget(const SizedBox()));

    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets('navigates to registration from login', (
    WidgetTester tester,
  ) async {
    stubUserIsLoggedOut();

    await tester.pumpWidget(createTestableWidget(const SizedBox()));

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    final BuildContext context = tester.element(find.byType(LoginScreen));
    GoRouter.of(context).push('/register');
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });
}
