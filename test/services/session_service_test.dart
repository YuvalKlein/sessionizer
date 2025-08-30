import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/session_service.dart';

import 'auth_service_test.mocks.dart'; // Reusing mocks

void main() {
  late SessionService sessionService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;
  late MockQuery<Map<String, dynamic>> mockQuery;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>();
    mockQuery = MockQuery<Map<String, dynamic>>();

    when(mockFirestore.collection('sessions')).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    when(mockCollection.where(any, isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo')))
        .thenReturn(mockQuery);
    when(mockQuery.orderBy(any)).thenReturn(mockQuery);
    when(mockDocument.update(any)).thenAnswer((_) async {});

    sessionService = SessionService(mockFirestore);
  });

  group('SessionService', () {
    group('getUpcomingSessions', () {
      test('calls Firestore with correct parameters and returns a stream', () {
        fakeAsync((async) {
          final mockStream = StreamController<QuerySnapshot<Map<String, dynamic>>>().stream;
          when(mockQuery.snapshots()).thenAnswer((_) => mockStream);

          final result = sessionService.getUpcomingSessions();

          expect(result, equals(mockStream));

          final now = DateTime.now().millisecondsSinceEpoch;
          final captured = verify(mockCollection.where('startTimeEpoch',
                  isGreaterThanOrEqualTo: captureAnyNamed('isGreaterThanOrEqualTo')))
              .captured;

          expect((captured.first as int), closeTo(now, 1000));
          verify(mockQuery.orderBy('startTimeEpoch')).called(1);
        });
      });
    });

    group('joinSession', () {
      test('calls update with a FieldValue for playersIds', () async {
        const sessionId = 'test-session';
        const userId = 'test-user';

        await sessionService.joinSession(sessionId, userId);

        final captured = verify(mockDocument.update(captureAny)).captured.single as Map;
        expect(captured['playersIds'], isA<FieldValue>());
      });
    });

    group('leaveSession', () {
      test('calls update with a FieldValue for playersIds', () async {
        const sessionId = 'test-session';
        const userId = 'test-user';

        await sessionService.leaveSession(sessionId, userId);

        final captured = verify(mockDocument.update(captureAny)).captured.single as Map;
        expect(captured['playersIds'], isA<FieldValue>());
      });
    });
  });
}
