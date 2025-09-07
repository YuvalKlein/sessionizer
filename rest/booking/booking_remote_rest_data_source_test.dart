import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/booking/data/models/booking_model.dart';
import 'booking_remote_rest_data_source.dart';

import 'booking_remote_rest_data_source_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  group('BookingRemoteRestDataSourceImpl', () {
    late BookingRemoteRestDataSourceImpl dataSource;
    late MockClient mockHttpClient;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    const baseUrl = 'https://test-api.com';
    const authToken = 'test-auth-token';

    setUp(() {
      mockHttpClient = MockClient();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      dataSource = BookingRemoteRestDataSourceImpl(
        httpClient: mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
        baseUrl: baseUrl,
      );

      // Setup common mock behavior
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken()).thenAnswer((_) async => authToken);
    });

    group('getBooking', () {
      test('should return booking when GET request is successful', () async {
        // Arrange
        const bookingId = 'booking_123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': bookingId,
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-01T10:00:00Z',
            'endTime': '2024-01-01T11:00:00Z',
            'status': 'confirmed',
            'notes': 'First session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBooking(bookingId);

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, bookingId);
        expect(result.clientId, 'client_456');
        expect(result.instructorId, 'instructor_789');
        expect(result.status, 'confirmed');
      });

      test('should throw ServerException when booking not found', () async {
        // Arrange
        const bookingId = 'nonexistent_booking';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.getBooking(bookingId),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createBooking', () {
      test('should create booking when POST request is successful', () async {
        // Arrange
        final booking = BookingModel(
          clientId: 'client_456',
          instructorId: 'instructor_789',
          bookableSessionId: 'session_123',
          startTime: DateTime.parse('2024-01-01T10:00:00Z'),
          endTime: DateTime.parse('2024-01-01T11:00:00Z'),
          status: 'pending',
          notes: 'First session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'booking_123',
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-01T10:00:00Z',
            'endTime': '2024-01-01T11:00:00Z',
            'status': 'pending',
            'notes': 'First session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/bookings'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 201));

        // Act
        final result = await dataSource.createBooking(booking);

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, 'booking_123');
        expect(result.clientId, 'client_456');
        expect(result.status, 'pending');
      });

      test('should throw ServerException when validation fails', () async {
        // Arrange
        final booking = BookingModel(
          clientId: '',
          instructorId: 'instructor_789',
          bookableSessionId: 'session_123',
          startTime: DateTime.parse('2024-01-01T10:00:00Z'),
          endTime: DateTime.parse('2024-01-01T11:00:00Z'),
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/bookings'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Validation failed"}', 400));

        // Act & Assert
        expect(
          () => dataSource.createBooking(booking),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('updateBooking', () {
      test('should update booking when PUT request is successful', () async {
        // Arrange
        final booking = BookingModel(
          id: 'booking_123',
          clientId: 'client_456',
          instructorId: 'instructor_789',
          bookableSessionId: 'session_123',
          startTime: DateTime.parse('2024-01-01T10:00:00Z'),
          endTime: DateTime.parse('2024-01-01T11:00:00Z'),
          status: 'confirmed',
          notes: 'Updated session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'booking_123',
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-01T10:00:00Z',
            'endTime': '2024-01-01T11:00:00Z',
            'status': 'confirmed',
            'notes': 'Updated session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookings/booking_123'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.updateBooking(booking);

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, 'booking_123');
        expect(result.notes, 'Updated session');
      });
    });

    group('deleteBooking', () {
      test('should delete booking when DELETE request is successful', () async {
        // Arrange
        const bookingId = 'booking_123';
        when(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        // Act
        await dataSource.deleteBooking(bookingId);

        // Assert
        verify(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId'),
          headers: anyNamed('headers'),
        )).called(1);
      });
    });

    group('cancelBooking', () {
      test('should cancel booking when PUT request is successful', () async {
        // Arrange
        const bookingId = 'booking_123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': bookingId,
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-01T10:00:00Z',
            'endTime': '2024-01-01T11:00:00Z',
            'status': 'cancelled',
            'notes': 'First session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId/cancel'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.cancelBooking(bookingId);

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, bookingId);
        expect(result.status, 'cancelled');
      });

      test('should throw ServerException when booking cannot be cancelled', () async {
        // Arrange
        const bookingId = 'booking_123';
        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId/cancel'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Cannot cancel booking"}', 409));

        // Act & Assert
        expect(
          () => dataSource.cancelBooking(bookingId),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('confirmBooking', () {
      test('should confirm booking when PUT request is successful', () async {
        // Arrange
        const bookingId = 'booking_123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': bookingId,
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-01T10:00:00Z',
            'endTime': '2024-01-01T11:00:00Z',
            'status': 'confirmed',
            'notes': 'First session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId/confirm'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.confirmBooking(bookingId);

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, bookingId);
        expect(result.status, 'confirmed');
      });
    });

    group('searchBookings', () {
      test('should return search results when request is successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'booking_123',
              'clientId': 'client_456',
              'instructorId': 'instructor_789',
              'bookableSessionId': 'session_123',
              'startTime': '2024-01-01T10:00:00Z',
              'endTime': '2024-01-01T11:00:00Z',
              'status': 'confirmed',
              'notes': 'Yoga session',
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/search'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.searchBookings(
          query: 'yoga',
          instructorId: 'instructor_789',
          page: 1,
          limit: 20,
        );

        // Assert
        expect(result, isA<List<BookingModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'booking_123');
        expect(result.first.notes, 'Yoga session');
      });
    });

    group('getBookingsByDateRange', () {
      test('should return bookings in date range when request is successful', () async {
        // Arrange
        final startDate = DateTime.parse('2024-01-01T00:00:00Z');
        final endDate = DateTime.parse('2024-01-31T23:59:59Z');
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'booking_123',
              'clientId': 'client_456',
              'instructorId': 'instructor_789',
              'bookableSessionId': 'session_123',
              'startTime': '2024-01-15T10:00:00Z',
              'endTime': '2024-01-15T11:00:00Z',
              'status': 'confirmed',
              'notes': 'Mid-month session',
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/date-range'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookingsByDateRange(
          startDate: startDate,
          endDate: endDate,
          instructorId: 'instructor_789',
        );

        // Assert
        expect(result, isA<List<BookingModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'booking_123');
      });
    });

    group('getBookingStats', () {
      test('should return booking stats when request is successful', () async {
        // Arrange
        const userId = 'user_123';
        final mockResponse = {
          'success': true,
          'data': {
            'totalBookings': 25,
            'confirmedBookings': 20,
            'pendingBookings': 3,
            'cancelledBookings': 2,
            'thisMonth': 8,
            'lastMonth': 12,
            'thisYear': 25,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/stats/$userId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookingStats(userId);

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result['totalBookings'], 25);
        expect(result['confirmedBookings'], 20);
        expect(result['pendingBookings'], 3);
        expect(result['cancelledBookings'], 2);
      });
    });

    group('rescheduleBooking', () {
      test('should reschedule booking when request is successful', () async {
        // Arrange
        const bookingId = 'booking_123';
        final newStartTime = DateTime.parse('2024-01-02T10:00:00Z');
        final newEndTime = DateTime.parse('2024-01-02T11:00:00Z');
        final mockResponse = {
          'success': true,
          'data': {
            'id': bookingId,
            'clientId': 'client_456',
            'instructorId': 'instructor_789',
            'bookableSessionId': 'session_123',
            'startTime': '2024-01-02T10:00:00Z',
            'endTime': '2024-01-02T11:00:00Z',
            'status': 'confirmed',
            'notes': 'Rescheduled session',
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/bookings/$bookingId/reschedule'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.rescheduleBooking(
          bookingId: bookingId,
          newStartTime: newStartTime,
          newEndTime: newEndTime,
          reason: 'Schedule conflict',
        );

        // Assert
        expect(result, isA<BookingModel>());
        expect(result.id, bookingId);
        expect(result.startTime, newStartTime);
        expect(result.endTime, newEndTime);
      });
    });

    group('getBookingAvailability', () {
      test('should return availability when request is successful', () async {
        // Arrange
        final startDate = DateTime.parse('2024-01-01T00:00:00Z');
        final endDate = DateTime.parse('2024-01-07T23:59:59Z');
        final mockResponse = {
          'success': true,
          'data': [
            {
              'date': '2024-01-01',
              'availableSlots': [
                {'startTime': '09:00', 'endTime': '10:00'},
                {'startTime': '14:00', 'endTime': '15:00'},
              ]
            },
            {
              'date': '2024-01-02',
              'availableSlots': [
                {'startTime': '10:00', 'endTime': '11:00'},
                {'startTime': '15:00', 'endTime': '16:00'},
              ]
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/availability'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookingAvailability(
          instructorId: 'instructor_789',
          startDate: startDate,
          endDate: endDate,
          sessionTypeId: 'type_1',
        );

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result.first['date'], '2024-01-01');
        expect(result.first['availableSlots'], isA<List>());
      });
    });

    group('getBookingHistory', () {
      test('should return booking history when request is successful', () async {
        // Arrange
        const userId = 'user_123';
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'booking_123',
              'clientId': 'client_456',
              'instructorId': 'instructor_789',
              'bookableSessionId': 'session_123',
              'startTime': '2024-01-01T10:00:00Z',
              'endTime': '2024-01-01T11:00:00Z',
              'status': 'completed',
              'notes': 'Completed session',
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings/history/$userId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookingHistory(
          userId: userId,
          status: 'completed',
          page: 1,
          limit: 20,
        );

        // Assert
        expect(result, isA<List<BookingModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'booking_123');
        expect(result.first.status, 'completed');
      });
    });

    group('stream methods', () {
      test('should return stream of bookings for getBookings', () async {
        // Arrange
        const userId = 'user_123';
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'booking_123',
              'clientId': userId,
              'instructorId': 'instructor_789',
              'bookableSessionId': 'session_123',
              'startTime': '2024-01-01T10:00:00Z',
              'endTime': '2024-01-01T11:00:00Z',
              'status': 'confirmed',
              'notes': 'First session',
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/bookings'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getBookings(userId).first;

        // Assert
        expect(result, isA<List<BookingModel>>());
        expect(result.length, 1);
        expect(result.first.clientId, userId);
      });
    });
  });
}
