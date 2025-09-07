import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'api_config.dart';

/// Base class for all REST API data sources
abstract class RestBaseDataSource {
  final http.Client _httpClient;
  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;
  final Duration _timeout;

  RestBaseDataSource({
    required http.Client httpClient,
    required FirebaseAuth firebaseAuth,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
  })  : _httpClient = httpClient,
        _firebaseAuth = firebaseAuth,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _timeout = timeout;

  /// Get authentication token
  Future<String> _getAuthToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw UnauthorizedException('User not authenticated');
      }
      
      final token = await user.getIdToken();
      if (token == null) {
        throw UnauthorizedException('Failed to get authentication token');
      }
      
      return token;
    } catch (e) {
      AppLogger.error('❌ Error getting auth token: $e');
      if (e is UnauthorizedException) {
        rethrow;
      }
      throw UnauthorizedException('Authentication failed: $e');
    }
  }

  /// Build HTTP headers
  Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'User-Agent': ApiConfig.userAgent,
    };
  }

  /// Handle HTTP errors
  ServerException _handleHttpError(http.Response response) {
    AppLogger.error('❌ HTTP Error: ${response.statusCode} - ${response.body}');
    
    try {
      final errorData = json.decode(response.body);
      final message = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
      final code = errorData['code'] ?? 'UNKNOWN_ERROR';
      
      return ServerException('$message (Code: $code)');
    } catch (e) {
      return ServerException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Perform GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      AppLogger.info('🔍 GET $endpoint');
      
      final uri = _buildUri(endpoint, queryParams);
      final headers = requireAuth ? _buildHeaders(await _getAuthToken()) : ApiConfig.defaultHeaders;
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      AppLogger.info('📡 GET $endpoint - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error in GET $endpoint: $e');
      if (e is ServerException || e is NotFoundException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Failed to perform GET request: $e');
    }
  }

  /// Perform POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      AppLogger.info('➕ POST $endpoint');
      
      final uri = _buildUri(endpoint, queryParams);
      final headers = requireAuth ? _buildHeaders(await _getAuthToken()) : ApiConfig.defaultHeaders;
      
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);

      AppLogger.info('📡 POST $endpoint - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error in POST $endpoint: $e');
      if (e is ServerException || e is NotFoundException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Failed to perform POST request: $e');
    }
  }

  /// Perform PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      AppLogger.info('✏️ PUT $endpoint');
      
      final uri = _buildUri(endpoint, queryParams);
      final headers = requireAuth ? _buildHeaders(await _getAuthToken()) : ApiConfig.defaultHeaders;
      
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);

      AppLogger.info('📡 PUT $endpoint - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error in PUT $endpoint: $e');
      if (e is ServerException || e is NotFoundException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Failed to perform PUT request: $e');
    }
  }

  /// Perform DELETE request
  Future<void> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      AppLogger.info('🗑️ DELETE $endpoint');
      
      final uri = _buildUri(endpoint, queryParams);
      final headers = requireAuth ? _buildHeaders(await _getAuthToken()) : ApiConfig.defaultHeaders;
      
      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(_timeout);

      AppLogger.info('📡 DELETE $endpoint - Status: ${response.statusCode}');

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error in DELETE $endpoint: $e');
      if (e is ServerException || e is NotFoundException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Failed to perform DELETE request: $e');
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// Create stream from future for real-time updates
  Stream<T> createStreamFromFuture<T>(Future<T> Function() future) {
    return Stream.fromFuture(future()).asBroadcastStream();
  }

  /// Handle pagination
  Map<String, String> buildPaginationParams({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (sortBy != null) {
      params['sortBy'] = sortBy;
    }
    
    if (sortOrder != null) {
      params['sortOrder'] = sortOrder;
    }
    
    return params;
  }

  /// Handle search parameters
  Map<String, String> buildSearchParams({
    String? query,
    Map<String, String>? filters,
  }) {
    final params = <String, String>{};
    
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }
    
    if (filters != null) {
      params.addAll(filters);
    }
    
    return params;
  }
}

/// Custom exceptions for REST API
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  
  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  final String message;
  final List<Map<String, String>>? details;
  
  ValidationException(this.message, [this.details]);
  
  @override
  String toString() => 'ValidationException: $message';
}

class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
  
  @override
  String toString() => 'ConflictException: $message';
}
