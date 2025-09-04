import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:faker/faker.dart';

import 'package:myapp/ui/profile_screen.dart';

// A helper function to pump the widget with all necessary providers
Future<void> pumpProfileScreen(
  WidgetTester tester, {
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileScreen(auth: auth, firestore: firestore),
    ),
  );
}

void main() {
  // Use a late final to ensure they are initialized before tests
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser; // Corrected type from User to MockUser

  setUp(() async {
    // Initialize mock user with fake data
    mockUser = MockUser(
      uid: faker.guid.guid(), // Use a unique ID
      email: faker.internet.email(),
      displayName: faker.person.name(),
    );

    // Set up mock auth with the user signed in
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

    // Set up the fake firestore instance
    fakeFirestore = FakeFirebaseFirestore();

    // Pre-populate the fake database with the user's profile data
    await fakeFirestore.collection('users').doc(mockUser.uid).set({
      'displayName': mockUser.displayName,
      'email': mockUser.email,
      'isInstructor': false, // Initial state
      'photoURL': null,
    });
  });

  testWidgets('ProfileScreen shows user data and initial instructor status', (
    WidgetTester tester,
  ) async {
    // Pump the widget and wait for it to settle
    await pumpProfileScreen(tester, auth: mockAuth, firestore: fakeFirestore);
    await tester.pumpAndSettle();

    // Verify that the user's name and email are displayed
    expect(find.text(mockUser.displayName!), findsOneWidget);
    expect(find.text(mockUser.email!), findsOneWidget);

    // Find the SwitchListTile for instructor mode
    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );

    // Verify that the initial status is "off" (false)
    expect(
      switchTile.value,
      isFalse,
      reason: 'Instructor mode should be off initially',
    );
    expect(find.text('Enable Instructor Mode'), findsOneWidget);
  });

  testWidgets(
    'Tapping the switch updates instructor status in Firestore and UI',
    (WidgetTester tester) async {
      // Pump the widget and wait for all animations/streams
      await pumpProfileScreen(tester, auth: mockAuth, firestore: fakeFirestore);
      await tester.pumpAndSettle();

      // Tap the switch to toggle it on
      await tester.tap(find.byType(SwitchListTile));
      // Pump and settle to allow the UI to react to the state change and stream update
      await tester.pumpAndSettle();

      // 1. Verify the data was updated in the fake Firestore
      final userDoc = await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .get();
      expect(
        userDoc.data()?['isInstructor'],
        isTrue,
        reason: 'Firestore data should be updated to true',
      );

      // 2. Verify the UI reflects the change
      final updatedSwitchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(
        updatedSwitchTile.value,
        isTrue,
        reason: 'Switch tile should now be on',
      );

      // Tap the switch again to toggle it off
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // 3. Verify Firestore data is updated back to false
      final finalUserDoc = await fakeFirestore
          .collection('users')
          .doc(mockUser.uid)
          .get();
      expect(
        finalUserDoc.data()?['isInstructor'],
        isFalse,
        reason: 'Firestore data should be updated back to false',
      );

      // 4. Verify the UI is updated back to off
      final finalSwitchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(
        finalSwitchTile.value,
        isFalse,
        reason: 'Switch tile should be off again',
      );
    },
  );
}
