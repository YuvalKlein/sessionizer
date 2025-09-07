import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myapp/core/utils/logger.dart';

/// Utility functions for REST API operations
class RestUtils {
  /// Parse JSON response safely
  static Map<String, dynamic>? parseJsonSafely(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('❌ JSON parsing error: $e');
      return null;
    }
  }

  /// Parse JSON list response safely
  static List<Map<String, dynamic>>? parseJsonListSafely(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      AppLogger.error('❌ JSON list parsing error: $e');
      return null;
    }
  }

  /// Check if HTTP response is successful
  static bool isSuccessResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Check if HTTP response is client error
  static bool isClientError(http.Response response) {
    return response.statusCode >= 400 && response.statusCode < 500;
  }

  /// Check if HTTP response is server error
  static bool isServerError(http.Response response) {
    return response.statusCode >= 500 && response.statusCode < 600;
  }

  /// Get HTTP status code category
  static String getStatusCategory(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return 'success';
    if (statusCode >= 300 && statusCode < 400) return 'redirect';
    if (statusCode >= 400 && statusCode < 500) return 'client_error';
    if (statusCode >= 500 && statusCode < 600) return 'server_error';
    return 'unknown';
  }

  /// Format HTTP status code with description
  static String formatStatusCode(int statusCode) {
    switch (statusCode) {
      case 200:
        return '200 OK';
      case 201:
        return '201 Created';
      case 204:
        return '204 No Content';
      case 400:
        return '400 Bad Request';
      case 401:
        return '401 Unauthorized';
      case 403:
        return '403 Forbidden';
      case 404:
        return '404 Not Found';
      case 409:
        return '409 Conflict';
      case 422:
        return '422 Unprocessable Entity';
      case 500:
        return '500 Internal Server Error';
      case 503:
        return '503 Service Unavailable';
      default:
        return '$statusCode Unknown';
    }
  }

  /// Build query string from parameters
  static String buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    
    final queryParts = <String>[];
    params.forEach((key, value) {
      if (value.isNotEmpty) {
        queryParts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
      }
    });
    
    return queryParts.join('&');
  }

  /// Build URL with query parameters
  static String buildUrl(String baseUrl, Map<String, String>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return baseUrl;
    }
    
    final queryString = buildQueryString(queryParams);
    return queryString.isNotEmpty ? '$baseUrl?$queryString' : baseUrl;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize string for logging
  static String sanitizeForLogging(String input) {
    // Remove sensitive information
    return input
        .replaceAll(RegExp(r'password["\s]*:["\s]*[^,}]+', caseSensitive: false), 'password: [REDACTED]')
        .replaceAll(RegExp(r'token["\s]*:["\s]*[^,}]+', caseSensitive: false), 'token: [REDACTED]')
        .replaceAll(RegExp(r'authorization["\s]*:["\s]*[^,}]+', caseSensitive: false), 'authorization: [REDACTED]');
  }

  /// Format duration for logging
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  /// Format bytes for logging
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Check if string is empty or null
  static bool isEmptyOrNull(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Check if list is empty or null
  static bool isEmptyOrNull<T>(List<T>? list) {
    return list == null || list.isEmpty;
  }

  /// Get first non-null value from list
  static T? firstNonNull<T>(List<T?> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }

  /// Retry operation with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }

        AppLogger.warning('⚠️ Retry attempt $attempt/$maxAttempts failed: $e');
        await Future.delayed(delay);
        
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).clamp(
            0,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    throw Exception('Max retry attempts exceeded');
  }

  /// Execute operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return await operation().timeout(timeout);
  }

  /// Execute operation with retry and timeout
  static Future<T> withRetryAndTimeout<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 30),
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    return await retryWithBackoff(
      () => withTimeout(operation, timeout: timeout),
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
    );
  }

  /// Log HTTP request
  static void logRequest(String method, String url, Map<String, String>? headers, String? body) {
    if (!AppLogger.isLoggingEnabled) return;

    AppLogger.info('📤 $method $url');
    if (headers != null && headers.isNotEmpty) {
      AppLogger.info('📋 Headers: ${sanitizeForLogging(json.encode(headers))}');
    }
    if (body != null && body.isNotEmpty) {
      AppLogger.info('📦 Body: ${sanitizeForLogging(body)}');
    }
  }

  /// Log HTTP response
  static void logResponse(http.Response response, Duration duration) {
    if (!AppLogger.isLoggingEnabled) return;

    final statusCategory = getStatusCategory(response.statusCode);
    final statusIcon = statusCategory == 'success' ? '✅' : '❌';
    
    AppLogger.info('$statusIcon ${formatStatusCode(response.statusCode)} (${formatDuration(duration)})');
    AppLogger.info('📊 Response size: ${formatBytes(response.body.length)}');
    
    if (response.headers.isNotEmpty) {
      AppLogger.info('📋 Response headers: ${sanitizeForLogging(json.encode(response.headers))}');
    }
    
    if (response.body.isNotEmpty) {
      AppLogger.info('📦 Response body: ${sanitizeForLogging(response.body)}');
    }
  }

  /// Log error
  static void logError(String operation, dynamic error, StackTrace? stackTrace) {
    AppLogger.error('❌ $operation failed: $error');
    if (stackTrace != null) {
      AppLogger.error('📍 Stack trace: $stackTrace');
    }
  }

  /// Check network connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user agent string
  static String getUserAgent() {
    return 'Sessionizer-Mobile/1.0 (${Platform.operatingSystem})';
  }

  /// Generate request ID for tracking
  static String generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Format error message for user display
  static String formatErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Map<String, dynamic>) {
      return error['message'] ?? error['error'] ?? 'Unknown error';
    } else {
      return error.toString();
    }
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is FormatException) return false;
    return false;
  }

  /// Get error category
  static String getErrorCategory(dynamic error) {
    if (error is SocketException) return 'network';
    if (error is HttpException) return 'http';
    if (error is FormatException) return 'format';
    if (error is TimeoutException) return 'timeout';
    return 'unknown';
  }
}
