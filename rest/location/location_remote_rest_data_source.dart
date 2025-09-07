import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/location/data/models/location_model.dart';
import '../shared/rest_base_data_source.dart';
import '../shared/rest_response_model.dart';
import '../shared/api_config.dart';

abstract class LocationRemoteRestDataSource {
  Stream<List<LocationModel>> getLocations();
  Stream<List<LocationModel>> getLocationsByInstructor(String instructorId);
  Future<LocationModel> getLocation(String id);
  Future<LocationModel> createLocation(LocationModel location);
  Future<LocationModel> updateLocation(LocationModel location);
  Future<void> deleteLocation(String id);
  
  // Additional REST-specific methods
  Future<List<LocationModel>> searchLocations({
    String? query,
    String? instructorId,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  });
  
  Future<List<LocationModel>> getLocationsNearby({
    required double latitude,
    required double longitude,
    double radius = 10.0, // in kilometers
    int page = 1,
    int limit = 20,
  });
  
  Future<Map<String, dynamic>> getLocationStats(String instructorId);
}

class LocationRemoteRestDataSourceImpl extends RestBaseDataSource implements LocationRemoteRestDataSource {
  LocationRemoteRestDataSourceImpl({
    required http.Client httpClient,
    required FirebaseAuth firebaseAuth,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
  }) : super(
         httpClient: httpClient,
         firebaseAuth: firebaseAuth,
         baseUrl: baseUrl,
         timeout: timeout,
       );

  @override
  Stream<List<LocationModel>> getLocations() {
    return createStreamFromFuture(() => _fetchLocations());
  }

  @override
  Stream<List<LocationModel>> getLocationsByInstructor(String instructorId) {
    return createStreamFromFuture(() => _fetchLocationsByInstructor(instructorId));
  }

  @override
  Future<LocationModel> getLocation(String id) async {
    try {
      AppLogger.info('🔍 Fetching location: $id');
      
      final response = await get('/locations/$id');
      
      AppLogger.info('✅ Location fetched successfully');
      return LocationModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching location: $e');
      if (e is NotFoundException) {
        throw ServerException('Location not found');
      }
      rethrow;
    }
  }

  @override
  Future<LocationModel> createLocation(LocationModel location) async {
    try {
      AppLogger.info('➕ Creating location: ${location.name}');
      
      final response = await post(
        '/locations',
        body: location.toMap(),
      );
      
      AppLogger.info('✅ Location created successfully');
      return LocationModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error creating location: $e');
      if (e is ValidationException) {
        throw ServerException('Invalid location data: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<LocationModel> updateLocation(LocationModel location) async {
    try {
      AppLogger.info('✏️ Updating location: ${location.id}');
      
      final response = await put(
        '/locations/${location.id}',
        body: location.toMap(),
      );
      
      AppLogger.info('✅ Location updated successfully');
      return LocationModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error updating location: $e');
      if (e is NotFoundException) {
        throw ServerException('Location not found');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    try {
      AppLogger.info('🗑️ Deleting location: $id');
      
      await delete('/locations/$id');
      
      AppLogger.info('✅ Location deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting location: $e');
      if (e is NotFoundException) {
        throw ServerException('Location not found');
      }
      rethrow;
    }
  }

  @override
  Future<List<LocationModel>> searchLocations({
    String? query,
    String? instructorId,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Searching locations');
      
      final queryParams = buildPaginationParams(page: page, limit: limit);
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (city != null) {
        queryParams['city'] = city;
      }
      if (state != null) {
        queryParams['state'] = state;
      }
      if (country != null) {
        queryParams['country'] = country;
      }
      if (latitude != null) {
        queryParams['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        queryParams['longitude'] = longitude.toString();
      }
      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }
      
      final response = await get('/locations/search', queryParams: queryParams);
      
      AppLogger.info('✅ Search completed successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error searching locations: $e');
      rethrow;
    }
  }

  @override
  Future<List<LocationModel>> getLocationsNearby({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('📍 Finding locations nearby: $latitude, $longitude (radius: ${radius}km)');
      
      final queryParams = buildPaginationParams(page: page, limit: limit);
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
      queryParams['radius'] = radius.toString();
      
      final response = await get('/locations/nearby', queryParams: queryParams);
      
      AppLogger.info('✅ Nearby locations found successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error finding nearby locations: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getLocationStats(String instructorId) async {
    try {
      AppLogger.info('📊 Fetching location stats for instructor: $instructorId');
      
      final response = await get('/locations/stats/$instructorId');
      
      AppLogger.info('✅ Location stats fetched successfully');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching location stats: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<List<LocationModel>> _fetchLocations() async {
    try {
      AppLogger.info('🔍 Fetching all locations');
      
      final response = await get('/locations');
      
      AppLogger.info('✅ Locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching locations: $e');
      rethrow;
    }
  }

  Future<List<LocationModel>> _fetchLocationsByInstructor(String instructorId) async {
    try {
      AppLogger.info('🔍 Fetching locations for instructor: $instructorId');
      
      final response = await get('/locations', queryParams: {'instructorId': instructorId});
      
      AppLogger.info('✅ Instructor locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching instructor locations: $e');
      rethrow;
    }
  }

  /// Get locations with advanced filtering
  Future<List<LocationModel>> getLocationsWithFilters({
    String? instructorId,
    String? city,
    String? state,
    String? country,
    String? sortBy = 'name',
    String? sortOrder = 'asc',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Fetching locations with filters');
      
      final queryParams = buildPaginationParams(
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (city != null) {
        queryParams['city'] = city;
      }
      if (state != null) {
        queryParams['state'] = state;
      }
      if (country != null) {
        queryParams['country'] = country;
      }
      
      final response = await get('/locations', queryParams: queryParams);
      
      AppLogger.info('✅ Filtered locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching filtered locations: $e');
      rethrow;
    }
  }

  /// Validate location data
  Future<bool> validateLocation(LocationModel location) async {
    try {
      AppLogger.info('✅ Validating location data');
      
      final response = await post(
        '/locations/validate',
        body: location.toMap(),
      );
      
      AppLogger.info('✅ Location validation completed');
      return response['data']['isValid'] ?? false;
    } catch (e) {
      AppLogger.error('❌ Error validating location: $e');
      return false;
    }
  }

  /// Get location by coordinates
  Future<LocationModel?> getLocationByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      AppLogger.info('📍 Finding location by coordinates: $latitude, $longitude');
      
      final response = await get(
        '/locations/coordinates',
        queryParams: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );
      
      AppLogger.info('✅ Location found by coordinates');
      return LocationModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error finding location by coordinates: $e');
      return null;
    }
  }

  /// Get locations by city
  Future<List<LocationModel>> getLocationsByCity(String city) async {
    try {
      AppLogger.info('🏙️ Fetching locations in city: $city');
      
      final response = await get(
        '/locations/city/$city',
      );
      
      AppLogger.info('✅ City locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching city locations: $e');
      rethrow;
    }
  }

  /// Get locations by state
  Future<List<LocationModel>> getLocationsByState(String state) async {
    try {
      AppLogger.info('🗺️ Fetching locations in state: $state');
      
      final response = await get(
        '/locations/state/$state',
      );
      
      AppLogger.info('✅ State locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching state locations: $e');
      rethrow;
    }
  }

  /// Get locations by country
  Future<List<LocationModel>> getLocationsByCountry(String country) async {
    try {
      AppLogger.info('🌍 Fetching locations in country: $country');
      
      final response = await get(
        '/locations/country/$country',
      );
      
      AppLogger.info('✅ Country locations fetched successfully');
      return (response['data'] as List)
          .map((item) => LocationModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching country locations: $e');
      rethrow;
    }
  }
}
