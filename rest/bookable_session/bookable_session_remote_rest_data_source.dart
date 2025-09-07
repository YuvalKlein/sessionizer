import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';

abstract class BookableSessionRemoteRestDataSource {
  Stream<List<BookableSessionModel>> getBookableSessions(String instructorId);
  Stream<List<BookableSessionModel>> getAllBookableSessions();
  Future<BookableSessionModel> getBookableSession(String id);
  Future<BookableSessionModel> createBookableSession(BookableSessionModel bookableSession);
  Future<BookableSessionModel> updateBookableSession(BookableSessionModel bookableSession);
  Future<void> deleteBookableSession(String id);
}

class BookableSessionRemoteRestDataSourceImpl implements BookableSessionRemoteRestDataSource {
  final http.Client _httpClient;
  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;
  final Duration _timeout;

  BookableSessionRemoteRestDataSourceImpl({
    required http.Client httpClient,
    required FirebaseAuth firebaseAuth,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
  })  : _httpClient = httpClient,
        _firebaseAuth = firebaseAuth,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _timeout = timeout;

  @override
  Stream<List<BookableSessionModel>> getBookableSessions(String instructorId) {
    return _createStreamFromFuture(() => _fetchBookableSessions(instructorId));
  }

  @override
  Stream<List<BookableSessionModel>> getAllBookableSessions() {
    return _createStreamFromFuture(() => _fetchAllBookableSessions());
  }

  @override
  Future<BookableSessionModel> getBookableSession(String id) async {
    try {
      AppLogger.info('🔍 Fetching bookable session: $id');
      
      final token = await _getAuthToken();
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions/$id'),
            headers: _buildHeaders(token),
          )
          .timeout(_timeout);

      AppLogger.info('📡 GET /api/v1/bookable-sessions/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BookableSessionModel.fromMap(data['data']);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Bookable session not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching bookable session: $e');
      if (e is ServerException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to fetch bookable session: $e');
    }
  }

  @override
  Future<BookableSessionModel> createBookableSession(BookableSessionModel bookableSession) async {
    try {
      AppLogger.info('➕ Creating bookable session for instructor: ${bookableSession.instructorId}');
      
      final token = await _getAuthToken();
      final requestBody = bookableSession.toMap();
      
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions'),
            headers: _buildHeaders(token),
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      AppLogger.info('📡 POST /api/v1/bookable-sessions - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BookableSessionModel.fromMap(data['data']);
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error creating bookable session: $e');
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to create bookable session: $e');
    }
  }

  @override
  Future<BookableSessionModel> updateBookableSession(BookableSessionModel bookableSession) async {
    try {
      AppLogger.info('✏️ Updating bookable session: ${bookableSession.id}');
      
      final token = await _getAuthToken();
      final requestBody = bookableSession.toMap();
      
      final response = await _httpClient
          .put(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions/${bookableSession.id}'),
            headers: _buildHeaders(token),
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      AppLogger.info('📡 PUT /api/v1/bookable-sessions/${bookableSession.id} - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BookableSessionModel.fromMap(data['data']);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Bookable session not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error updating bookable session: $e');
      if (e is ServerException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to update bookable session: $e');
    }
  }

  @override
  Future<void> deleteBookableSession(String id) async {
    try {
      AppLogger.info('🗑️ Deleting bookable session: $id');
      
      final token = await _getAuthToken();
      final response = await _httpClient
          .delete(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions/$id'),
            headers: _buildHeaders(token),
          )
          .timeout(_timeout);

      AppLogger.info('📡 DELETE /api/v1/bookable-sessions/$id - Status: ${response.statusCode}');

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw NotFoundException('Bookable session not found');
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error deleting bookable session: $e');
      if (e is ServerException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to delete bookable session: $e');
    }
  }

  // Private helper methods

  Future<List<BookableSessionModel>> _fetchBookableSessions(String instructorId) async {
    try {
      AppLogger.info('🔍 Fetching bookable sessions for instructor: $instructorId');
      
      final token = await _getAuthToken();
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions?instructorId=$instructorId'),
            headers: _buildHeaders(token),
          )
          .timeout(_timeout);

      AppLogger.info('📡 GET /api/v1/bookable-sessions?instructorId=$instructorId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessions = (data['data'] as List)
            .map((item) => BookableSessionModel.fromMap(item))
            .toList();
        
        AppLogger.info('✅ Found ${sessions.length} bookable sessions for instructor $instructorId');
        return sessions;
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching bookable sessions: $e');
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to fetch bookable sessions: $e');
    }
  }

  Future<List<BookableSessionModel>> _fetchAllBookableSessions() async {
    try {
      AppLogger.info('🔍 Fetching all active bookable sessions');
      
      final token = await _getAuthToken();
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/api/v1/bookable-sessions?isActive=true'),
            headers: _buildHeaders(token),
          )
          .timeout(_timeout);

      AppLogger.info('📡 GET /api/v1/bookable-sessions?isActive=true - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessions = (data['data'] as List)
            .map((item) => BookableSessionModel.fromMap(item))
            .toList();
        
        AppLogger.info('✅ Found ${sessions.length} active bookable sessions');
        return sessions;
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching all bookable sessions: $e');
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to fetch all bookable sessions: $e');
    }
  }

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
      throw UnauthorizedException('Authentication failed: $e');
    }
  }

  Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'User-Agent': 'Sessionizer-Mobile/1.0',
    };
  }

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

  Stream<List<BookableSessionModel>> _createStreamFromFuture(
    Future<List<BookableSessionModel>> Function() future,
  ) {
    return Stream.fromFuture(future()).asBroadcastStream();
  }
}

// Custom exceptions for better error handling
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
