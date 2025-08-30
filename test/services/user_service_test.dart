import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/user_service.dart';

import 'auth_service_test.mocks.dart'; // Reusing mocks

void main() {
  late UserService userService;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;

  setUp(() {
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference<Map<String, dynamic>>();
    mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();

    when(
      mockFirebaseFirestore.collection('users'),
    ).thenReturn(mockCollectionReference);
    when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);

    userService = UserService(mockFirebaseFirestore);
  });

  group('UserService', () {
    test(
      'getUserStream calls Firestore with correct UID and returns stream',
      () {
        const uid = 'test_uid';
        final mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockStream = Stream.value(mockSnapshot);

        when(mockDocumentReference.snapshots()).thenAnswer((_) => mockStream);

        // Act
        final result = userService.getUserStream(uid);

        // Assert
        expect(result, equals(mockStream));

        // Verify the interactions with the mocks
        verify(mockFirebaseFirestore.collection('users')).called(1);
        verify(mockCollectionReference.doc(uid)).called(1);
        verify(mockDocumentReference.snapshots()).called(1);
      },
    );
  });
}
