import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/location/data/models/location_model.dart';
import 'location_remote_rest_data_source.dart';

import 'location_remote_rest_data_source_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
void main() {
  group('LocationRemoteRestDataSourceImpl', () {
    late LocationRemoteRestDataSourceImpl dataSource;
    late MockClient mockHttpClient;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;

    const baseUrl = 'https://test-api.com';
    const authToken = 'test-auth-token';

    setUp(() {
      mockHttpClient = MockClient();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      
      dataSource = LocationRemoteRestDataSourceImpl(
        httpClient: mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
        baseUrl: baseUrl,
      );

      // Setup common mock behavior
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken()).thenAnswer((_) async => authToken);
    });

    group('getLocation', () {
      test('should return location when GET request is successful', () async {
        // Arrange
        const locationId = 'location_123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': locationId,
            'instructorId': 'instructor_456',
            'name': 'Downtown Yoga Studio',
            'address': '123 Main St',
            'city': 'New York',
            'state': 'NY',
            'country': 'USA',
            'postalCode': '10001',
            'latitude': 40.7589,
            'longitude': -73.9851,
            'phone': '+1-555-0123',
            'email': 'downtown@yoga.com',
            'description': 'A peaceful yoga studio',
            'amenities': ['Mats', 'Props', 'Parking'],
            'isActive': true,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/$locationId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocation(locationId);

        // Assert
        expect(result, isA<LocationModel>());
        expect(result.id, locationId);
        expect(result.name, 'Downtown Yoga Studio');
        expect(result.city, 'New York');
        expect(result.isActive, true);
      });

      test('should throw ServerException when location not found', () async {
        // Arrange
        const locationId = 'nonexistent_location';
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/$locationId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.getLocation(locationId),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('createLocation', () {
      test('should create location when POST request is successful', () async {
        // Arrange
        final location = LocationModel(
          instructorId: 'instructor_456',
          name: 'New Yoga Studio',
          address: '456 Oak Ave',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          postalCode: '90210',
          latitude: 34.0522,
          longitude: -118.2437,
          phone: '+1-555-0456',
          email: 'newstudio@yoga.com',
          description: 'A modern yoga studio',
          amenities: ['Mats', 'Props', 'Parking'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'location_456',
            'instructorId': 'instructor_456',
            'name': 'New Yoga Studio',
            'address': '456 Oak Ave',
            'city': 'Los Angeles',
            'state': 'CA',
            'country': 'USA',
            'postalCode': '90210',
            'latitude': 34.0522,
            'longitude': -118.2437,
            'phone': '+1-555-0456',
            'email': 'newstudio@yoga.com',
            'description': 'A modern yoga studio',
            'amenities': ['Mats', 'Props', 'Parking'],
            'isActive': true,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/locations'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 201));

        // Act
        final result = await dataSource.createLocation(location);

        // Assert
        expect(result, isA<LocationModel>());
        expect(result.id, 'location_456');
        expect(result.name, 'New Yoga Studio');
        expect(result.city, 'Los Angeles');
      });

      test('should throw ServerException when validation fails', () async {
        // Arrange
        final location = LocationModel(
          instructorId: '',
          name: '',
          address: '456 Oak Ave',
          city: 'Los Angeles',
          state: 'CA',
          country: 'USA',
          postalCode: '90210',
          latitude: 34.0522,
          longitude: -118.2437,
          phone: '+1-555-0456',
          email: 'newstudio@yoga.com',
          description: 'A modern yoga studio',
          amenities: ['Mats', 'Props', 'Parking'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/locations'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Validation failed"}', 400));

        // Act & Assert
        expect(
          () => dataSource.createLocation(location),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('updateLocation', () {
      test('should update location when PUT request is successful', () async {
        // Arrange
        final location = LocationModel(
          id: 'location_123',
          instructorId: 'instructor_456',
          name: 'Updated Yoga Studio',
          address: '123 Main St',
          city: 'New York',
          state: 'NY',
          country: 'USA',
          postalCode: '10001',
          latitude: 40.7589,
          longitude: -73.9851,
          phone: '+1-555-0123',
          email: 'updated@yoga.com',
          description: 'An updated peaceful yoga studio',
          amenities: ['Mats', 'Props', 'Parking', 'WiFi'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'id': 'location_123',
            'instructorId': 'instructor_456',
            'name': 'Updated Yoga Studio',
            'address': '123 Main St',
            'city': 'New York',
            'state': 'NY',
            'country': 'USA',
            'postalCode': '10001',
            'latitude': 40.7589,
            'longitude': -73.9851,
            'phone': '+1-555-0123',
            'email': 'updated@yoga.com',
            'description': 'An updated peaceful yoga studio',
            'amenities': ['Mats', 'Props', 'Parking', 'WiFi'],
            'isActive': true,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/locations/location_123'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.updateLocation(location);

        // Assert
        expect(result, isA<LocationModel>());
        expect(result.id, 'location_123');
        expect(result.name, 'Updated Yoga Studio');
        expect(result.amenities, contains('WiFi'));
      });
    });

    group('deleteLocation', () {
      test('should delete location when DELETE request is successful', () async {
        // Arrange
        const locationId = 'location_123';
        when(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/locations/$locationId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        // Act
        await dataSource.deleteLocation(locationId);

        // Assert
        verify(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/locations/$locationId'),
          headers: anyNamed('headers'),
        )).called(1);
      });
    });

    group('searchLocations', () {
      test('should return search results when request is successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'location_123',
              'instructorId': 'instructor_456',
              'name': 'Downtown Yoga Studio',
              'address': '123 Main St',
              'city': 'New York',
              'state': 'NY',
              'country': 'USA',
              'postalCode': '10001',
              'latitude': 40.7589,
              'longitude': -73.9851,
              'phone': '+1-555-0123',
              'email': 'downtown@yoga.com',
              'description': 'A peaceful yoga studio',
              'amenities': ['Mats', 'Props', 'Parking'],
              'isActive': true,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/search'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.searchLocations(
          query: 'yoga studio',
          city: 'New York',
          page: 1,
          limit: 20,
        );

        // Assert
        expect(result, isA<List<LocationModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'location_123');
        expect(result.first.name, 'Downtown Yoga Studio');
      });
    });

    group('getLocationsNearby', () {
      test('should return nearby locations when request is successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'location_123',
              'instructorId': 'instructor_456',
              'name': 'Nearby Yoga Studio',
              'address': '123 Main St',
              'city': 'New York',
              'state': 'NY',
              'country': 'USA',
              'postalCode': '10001',
              'latitude': 40.7589,
              'longitude': -73.9851,
              'phone': '+1-555-0123',
              'email': 'nearby@yoga.com',
              'description': 'A nearby yoga studio',
              'amenities': ['Mats', 'Props'],
              'isActive': true,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/nearby'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocationsNearby(
          latitude: 40.7589,
          longitude: -73.9851,
          radius: 10.0,
        );

        // Assert
        expect(result, isA<List<LocationModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'location_123');
        expect(result.first.name, 'Nearby Yoga Studio');
      });
    });

    group('getLocationStats', () {
      test('should return location stats when request is successful', () async {
        // Arrange
        const instructorId = 'instructor_456';
        final mockResponse = {
          'success': true,
          'data': {
            'totalLocations': 5,
            'activeLocations': 4,
            'inactiveLocations': 1,
            'totalBookings': 150,
            'averageBookingsPerLocation': 30,
            'mostPopularLocation': 'Downtown Yoga Studio',
            'locationsByCity': {
              'New York': 2,
              'Los Angeles': 2,
              'Chicago': 1,
            }
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/stats/$instructorId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocationStats(instructorId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['totalLocations'], 5);
        expect(result['activeLocations'], 4);
        expect(result['inactiveLocations'], 1);
        expect(result['totalBookings'], 150);
        expect(result['averageBookingsPerLocation'], 30);
        expect(result['mostPopularLocation'], 'Downtown Yoga Studio');
      });
    });

    group('getLocationByCoordinates', () {
      test('should return location when found by coordinates', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'location_123',
            'instructorId': 'instructor_456',
            'name': 'Exact Location Studio',
            'address': '123 Main St',
            'city': 'New York',
            'state': 'NY',
            'country': 'USA',
            'postalCode': '10001',
            'latitude': 40.7589,
            'longitude': -73.9851,
            'phone': '+1-555-0123',
            'email': 'exact@yoga.com',
            'description': 'A studio at exact coordinates',
            'amenities': ['Mats', 'Props'],
            'isActive': true,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/coordinates'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocationByCoordinates(
          latitude: 40.7589,
          longitude: -73.9851,
        );

        // Assert
        expect(result, isA<LocationModel>());
        expect(result?.id, 'location_123');
        expect(result?.name, 'Exact Location Studio');
      });

      test('should return null when no location found by coordinates', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/coordinates'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        // Act
        final result = await dataSource.getLocationByCoordinates(
          latitude: 40.7589,
          longitude: -73.9851,
        );

        // Assert
        expect(result, null);
      });
    });

    group('getLocationsByCity', () {
      test('should return locations in city when request is successful', () async {
        // Arrange
        const city = 'New York';
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'location_123',
              'instructorId': 'instructor_456',
              'name': 'NYC Yoga Studio',
              'address': '123 Main St',
              'city': 'New York',
              'state': 'NY',
              'country': 'USA',
              'postalCode': '10001',
              'latitude': 40.7589,
              'longitude': -73.9851,
              'phone': '+1-555-0123',
              'email': 'nyc@yoga.com',
              'description': 'A NYC yoga studio',
              'amenities': ['Mats', 'Props'],
              'isActive': true,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations/city/$city'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocationsByCity(city);

        // Assert
        expect(result, isA<List<LocationModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'location_123');
        expect(result.first.city, 'New York');
      });
    });

    group('validateLocation', () {
      test('should return true when location is valid', () async {
        // Arrange
        final location = LocationModel(
          instructorId: 'instructor_456',
          name: 'Valid Location',
          address: '123 Test St',
          city: 'Test City',
          state: 'TS',
          country: 'USA',
          postalCode: '12345',
          latitude: 40.7128,
          longitude: -74.0060,
          phone: '+1-555-0123',
          email: 'valid@location.com',
          description: 'A valid test location',
          amenities: ['Mats', 'Props'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'success': true,
          'data': {
            'isValid': true,
            'validationErrors': [],
            'suggestions': []
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/locations/validate'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.validateLocation(location);

        // Assert
        expect(result, true);
      });

      test('should return false when location is invalid', () async {
        // Arrange
        final location = LocationModel(
          instructorId: '',
          name: '',
          address: '123 Test St',
          city: 'Test City',
          state: 'TS',
          country: 'USA',
          postalCode: '12345',
          latitude: 40.7128,
          longitude: -74.0060,
          phone: '+1-555-0123',
          email: 'invalid@location.com',
          description: 'An invalid test location',
          amenities: ['Mats', 'Props'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/locations/validate'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Validation failed"}', 400));

        // Act
        final result = await dataSource.validateLocation(location);

        // Assert
        expect(result, false);
      });
    });

    group('stream methods', () {
      test('should return stream of locations for getLocations', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'location_123',
              'instructorId': 'instructor_456',
              'name': 'Stream Yoga Studio',
              'address': '123 Main St',
              'city': 'New York',
              'state': 'NY',
              'country': 'USA',
              'postalCode': '10001',
              'latitude': 40.7589,
              'longitude': -73.9851,
              'phone': '+1-555-0123',
              'email': 'stream@yoga.com',
              'description': 'A streaming yoga studio',
              'amenities': ['Mats', 'Props'],
              'isActive': true,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocations().first;

        // Assert
        expect(result, isA<List<LocationModel>>());
        expect(result.length, 1);
        expect(result.first.id, 'location_123');
        expect(result.first.name, 'Stream Yoga Studio');
      });

      test('should return stream of locations for getLocationsByInstructor', () async {
        // Arrange
        const instructorId = 'instructor_456';
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'location_123',
              'instructorId': instructorId,
              'name': 'Instructor Yoga Studio',
              'address': '123 Main St',
              'city': 'New York',
              'state': 'NY',
              'country': 'USA',
              'postalCode': '10001',
              'latitude': 40.7589,
              'longitude': -73.9851,
              'phone': '+1-555-0123',
              'email': 'instructor@yoga.com',
              'description': 'An instructor yoga studio',
              'amenities': ['Mats', 'Props'],
              'isActive': true,
              'createdAt': 1640995200000,
              'updatedAt': 1640995200000,
            }
          ]
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/locations'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getLocationsByInstructor(instructorId).first;

        // Assert
        expect(result, isA<List<LocationModel>>());
        expect(result.length, 1);
        expect(result.first.instructorId, instructorId);
        expect(result.first.name, 'Instructor Yoga Studio');
      });
    });
  });
}
