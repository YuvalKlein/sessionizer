import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/services/session_service.dart';
import 'package:myapp/ui/login_screen.dart';
import 'package:myapp/ui/main_screen.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  GoogleSignIn,
  AuthService,
  UserService,
  SessionService,
  User,
  DocumentSnapshot,
  QuerySnapshot,
])
void main() {
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;
  late MockSessionService mockSessionService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();
    mockSessionService = MockSessionService();
  });

  testWidgets('Renders LoginScreen when not logged in', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.currentUser).thenReturn(null);
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          Provider<AuthService>.value(value: mockAuthService),
          Provider<UserService>.value(value: mockUserService),
          Provider<SessionService>.value(value: mockSessionService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Renders MainScreen when logged in', (WidgetTester tester) async {
    final mockUser = MockUser();
    final mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    when(mockUser.uid).thenReturn('123');
    when(mockAuthService.currentUser).thenReturn(mockUser);
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(mockUser));
    when(
      mockUserService.getUserStream('123'),
    ).thenAnswer((_) => Stream.value(mockDocumentSnapshot));
    when(
      mockDocumentSnapshot.data(),
    ).thenReturn({'displayName': 'Test User', 'isInstructor': false});
    when(mockDocumentSnapshot.exists).thenReturn(true);
    when(
      mockSessionService.getUpcomingSessions(),
    ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
    when(mockQuerySnapshot.docs).thenReturn([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          Provider<AuthService>.value(value: mockAuthService),
          Provider<UserService>.value(value: mockUserService),
          Provider<SessionService>.value(value: mockSessionService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MainScreen), findsOneWidget);
  });
}
