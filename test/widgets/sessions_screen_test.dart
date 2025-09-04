import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:faker/faker.dart';

import 'package:myapp/services/session_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/ui/sessions_screen.dart';

import 'sessions_screen_test.mocks.dart';

@GenerateMocks([
  SessionService,
  AuthService,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  late MockSessionService mockSessionService;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQueryDocumentSnapshot mockQueryDocumentSnapshot;

  setUp(() {
    mockSessionService = MockSessionService();
    mockAuthService = MockAuthService();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    mockUser = MockUser(
      uid: faker.guid.guid(),
      email: faker.internet.email(),
      displayName: faker.person.name(),
    );
    when(mockAuthService.currentUser).thenReturn(mockUser);
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(mockUser));
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: mockAuthService),
        Provider<SessionService>.value(value: mockSessionService),
      ],
      child: const MaterialApp(home: SessionsScreen()),
    );
  }

  testWidgets('SessionsScreen shows list of sessions from the service', (
    WidgetTester tester,
  ) async {
    // 1. Arrange
    final sessionData = {
      'title': faker.lorem.words(3).join(' '),
      'details': faker.lorem.sentence(),
      'startTimeEpoch': DateTime.now().millisecondsSinceEpoch,
      'endTimeEpoch': DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'locationInfo': {'name': faker.address.city()},
      'price': 15,
      'playersIds': <String>[],
      'maxPlayers': 12,
    };

    // Mock the Firestore data structure
    when(mockQueryDocumentSnapshot.data()).thenReturn(sessionData);
    when(mockQueryDocumentSnapshot.id).thenReturn(faker.guid.guid());
    when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

    // Stub the service to return the mocked snapshot
    when(
      mockSessionService.getUpcomingSessions(),
    ).thenAnswer((_) => Stream.value(mockQuerySnapshot));

    // 2. Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Wait for the stream to emit and the UI to rebuild
    await tester.pumpAndSettle();

    // 3. Assert
    expect(
      find.text('Upcoming Sessions'),
      findsOneWidget,
    ); // Check AppBar title
    expect(
      find.text(sessionData['title'] as String),
      findsOneWidget,
    ); // Check session title
    expect(
      find.textContaining(
        (sessionData['locationInfo'] as Map<String, dynamic>)['name'],
      ),
      findsOneWidget,
    );
    expect(
      find.byType(SessionCard),
      findsOneWidget,
    ); // Check that a card is rendered
  });
}
