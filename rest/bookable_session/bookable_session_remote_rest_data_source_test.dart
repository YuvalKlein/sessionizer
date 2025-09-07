import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/bookable_session/data/datasources/bookable_session_remote_rest_data_source.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';

import 'bookable_session_remote_rest_data_source_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  group('BookableSessionRemoteRestDataSourceImpl', () {
    late BookableSessionRemoteRestDataSourceImpl dataSource;
    late MockClient mockHttpClient;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    const baseUrl = 'https://test-api.com';
    const authToken = 'test-auth-token';

    setUp(() {
      mockHttpClient = MockClient();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      dataSource = BookableSessionRemoteRestDataSourceImpl(
        httpClient: mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
        baseUrl: baseUrl,
      );

      // Setup common mock behavior
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken()).thenAnswer((_) async => authToken);
    });

    group('getBookableSessions', () {
      test('should return bookable sessions when GET request is successful', () async {
        // Arrange
        const instructorId = 'instructor_123';
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'session_1',
              'instructorId': instructorId,
              'sessionTypeIds': ['type_1'],
              'locationIds': ['loc_1'],
              'availabilityIds': ['avail_1'],
              'breakTimeInMinutes': 15,
              'bookingLeadTimeInMinutes': 30,
              'futureBookingLimitInDays': 7,
              'durationOverride': 60,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookableSessions(instructorId).first;

        // Assert
        expect(result, isA<List<BookableSessionModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'session_1');
        expect(result.first.instructorId, instructorId);
      });

      test('should throw ServerException when GET request fails', () async {
        // Arrange
        const instructorId = 'instructor_123';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server Error"}', 500));

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions(instructorId).first,
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw UnauthorizedException when authentication fails', () async {
        // Arrange
        const instructorId = 'instructor_123';
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions(instructorId).first,
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('getAllBookableSessions', () {
      test('should return all bookable sessions when GET request is successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'session_1',
              'instructorId': 'instructor_1',
              'sessionTypeIds': ['type_1'],
              'locationIds': ['loc_1'],
              'availabilityIds': ['avail_1'],
              'breakTimeInMinutes': 15,
              'bookingLeadTimeInMinutes': 30,
              'futureBookingLimitInDays': 7,
              'durationOverride': 60,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?isActive=true'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getAllBookableSessions().first;

        // Assert
        expect(result, isA<List<BookableSessionModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'session_1');
      });
    });

    group('getBookableSession', () {
      test('should return bookable session when GET request is successful', () async {
        // Arrange
        const sessionId = 'session_123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': sessionId,
            'instructorId': 'instructor_123',
            'sessionTypeIds': ['type_1'],
            'locationIds': ['loc_1'],
            'availabilityIds': ['avail_1'],
            'breakTimeInMinutes': 15,
            'bookingLeadTimeInMinutes': 30,
            'futureBookingLimitInDays': 7,
            'durationOverride': 60,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookableSession(sessionId);

        // Assert
        expect(result, isA<BookableSessionModel>());
        expect(result.id, sessionId);
      });

      test('should throw NotFoundException when session not found', () async {
        // Arrange
        const sessionId = 'nonexistent_session';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not Found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.getBookableSession(sessionId),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('createBookableSession', () {
      test('should create bookable session when POST request is successful', () async {
        // Arrange
        final bookableSession = BookableSessionModel(
          instructorId: 'instructor_123',
          sessionTypeIds: ['type_1'],
          locationIds: ['loc_1'],
          availabilityIds: ['avail_1'],
          breakTimeInMinutes: 15,
          bookingLeadTimeInMinutes: 30,
          futureBookingLimitInDays: 7,
          durationOverride: 60,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'session_123',
            'instructorId': 'instructor_123',
            'sessionTypeIds': ['type_1'],
            'locationIds': ['loc_1'],
            'availabilityIds': ['avail_1'],
            'breakTimeInMinutes': 15,
            'bookingLeadTimeInMinutes': 30,
            'futureBookingLimitInDays': 7,
            'durationOverride': 60,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/bookable-sessions'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 201));

        // Act
        final result = await dataSource.createBookableSession(bookableSession);

        // Assert
        expect(result, isA<BookableSessionModel>());
        expect(result.id, 'session_123');
        expect(result.instructorId, 'instructor_123');
      });

      test('should throw ServerException when POST request fails', () async {
        // Arrange
        final bookableSession = BookableSessionModel(
          instructorId: 'instructor_123',
          sessionTypeIds: ['type_1'],
          locationIds: ['loc_1'],
          availabilityIds: ['avail_1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/bookable-sessions'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Server Error"}', 500));

        // Act & Assert
        expect(
          () => dataSource.createBookableSession(bookableSession),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('updateBookableSession', () {
      test('should update bookable session when PUT request is successful', () async {
        // Arrange
        final bookableSession = BookableSessionModel(
          id: 'session_123',
          instructorId: 'instructor_123',
          sessionTypeIds: ['type_1'],
          locationIds: ['loc_1'],
          availabilityIds: ['avail_1'],
          breakTimeInMinutes: 20,
          bookingLeadTimeInMinutes: 45,
          futureBookingLimitInDays: 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'session_123',
            'instructorId': 'instructor_123',
            'sessionTypeIds': ['type_1'],
            'locationIds': ['loc_1'],
            'availabilityIds': ['avail_1'],
            'breakTimeInMinutes': 20,
            'bookingLeadTimeInMinutes': 45,
            'futureBookingLimitInDays': 14,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/session_123'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.updateBookableSession(bookableSession);

        // Assert
        expect(result, isA<BookableSessionModel>());
        expect(result.id, 'session_123');
        expect(result.breakTimeInMinutes, 20);
      });

      test('should throw NotFoundException when session not found', () async {
        // Arrange
        final bookableSession = BookableSessionModel(
          id: 'nonexistent_session',
          instructorId: 'instructor_123',
          sessionTypeIds: ['type_1'],
          locationIds: ['loc_1'],
          availabilityIds: ['avail_1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/nonexistent_session'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Not Found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.updateBookableSession(bookableSession),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('deleteBookableSession', () {
      test('should delete bookable session when DELETE request is successful', () async {
        // Arrange
        const sessionId = 'session_123';
        when(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        // Act
        await dataSource.deleteBookableSession(sessionId);

        // Assert
        verify(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/$sessionId'),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should throw NotFoundException when session not found', () async {
        // Arrange
        const sessionId = 'nonexistent_session';
        when(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/bookable-sessions/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not Found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.deleteBookableSession(sessionId),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('error handling', () {
      test('should handle network timeout', () async {
        // Arrange
        const instructorId = 'instructor_123';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Connection timeout'));

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions(instructorId).first,
          throwsA(isA<ServerException>()),
        );
      });

      test('should handle JSON parsing errors', () async {
        // Arrange
        const instructorId = 'instructor_123';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('invalid json', 200));

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions(instructorId).first,
          throwsA(isA<ServerException>()),
        );
      });

      test('should handle HTTP error responses', () async {
        // Arrange
        const instructorId = 'instructor_123';
        final errorResponse = {
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Validation failed',
            'details': 'Invalid instructor ID'
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(errorResponse), 400));

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions(instructorId).first,
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('authentication', () {
      test('should include auth token in headers', () async {
        // Arrange
        const instructorId = 'instructor_123';
        final mockResponse = {
          'success': true,
          'data': [],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 0,
            'totalPages': 0,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        await dataSource.getBookableSessions(instructorId).first;

        // Assert
        verify(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
          headers: argThat(
            containsPair('Authorization', 'Bearer $authToken'),
            named: 'headers',
          ),
        )).called(1);
      });

      test('should refresh token when current token is null', () async {
        // Arrange
        when(mockUser.getIdToken()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => dataSource.getBookableSessions('instructor_123').first,
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });
  });
}
