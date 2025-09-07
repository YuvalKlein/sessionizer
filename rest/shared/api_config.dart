import 'package:flutter/foundation.dart';

/// API Configuration for REST endpoints
class ApiConfig {
  /// Base URL for the API
  static String get baseUrl {
    if (kDebugMode) {
      return const String.fromEnvironment(
        'API_BASE_URL_DEBUG',
        defaultValue: 'https://dev-api.sessionizer.com',
      );
    } else if (kProfileMode) {
      return const String.fromEnvironment(
        'API_BASE_URL_PROFILE',
        defaultValue: 'https://staging-api.sessionizer.com',
      );
    } else {
      return const String.fromEnvironment(
        'API_BASE_URL_RELEASE',
        defaultValue: 'https://api.sessionizer.com',
      );
    }
  }

  /// API version
  static const String version = 'v1';

  /// Full API base URL with version
  static String get fullBaseUrl => '$baseUrl/api/$version';

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 1);

  /// Enable request/response logging
  static const bool enableLogging = kDebugMode;

  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  /// Cache duration for GET requests
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Maximum cache size
  static const int maxCacheSize = 100;

  /// Enable compression
  static const bool enableCompression = true;

  /// User agent string
  static const String userAgent = 'Sessionizer-Mobile/1.0';

  /// API endpoints
  static class Endpoints {
    static const String bookableSessions = '/bookable-sessions';
    static const String bookableSessionsSearch = '/bookable-sessions/search';
    static const String instructors = '/instructors';
    static const String locations = '/locations';
    static const String schedules = '/schedules';
    static const String sessionTypes = '/session-types';
    static const String bookings = '/bookings';
    static const String reviews = '/reviews';
    static const String notifications = '/notifications';
  }

  /// HTTP headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': userAgent,
        'Accept-Encoding': enableCompression ? 'gzip, deflate' : 'identity',
      };

  /// Error codes
  static class ErrorCodes {
    static const String unauthorized = 'UNAUTHORIZED';
    static const String forbidden = 'FORBIDDEN';
    static const String notFound = 'NOT_FOUND';
    static const String validationError = 'VALIDATION_ERROR';
    static const String conflict = 'CONFLICT';
    static const String internalServerError = 'INTERNAL_SERVER_ERROR';
    static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
    static const String timeout = 'TIMEOUT';
    static const String networkError = 'NETWORK_ERROR';
  }

  /// HTTP status codes
  static class StatusCodes {
    static const int ok = 200;
    static const int created = 201;
    static const int noContent = 204;
    static const int badRequest = 400;
    static const int unauthorized = 401;
    static const int forbidden = 403;
    static const int notFound = 404;
    static const int conflict = 409;
    static const int unprocessableEntity = 422;
    static const int internalServerError = 500;
    static const int serviceUnavailable = 503;
  }

  /// Rate limiting configuration
  static class RateLimit {
    static const int requestsPerHour = 1000;
    static const int requestsPerMinute = 100;
    static const Duration windowSize = Duration(hours: 1);
  }

  /// Pagination configuration
  static class Pagination {
    static const int defaultPage = 1;
    static const int defaultLimit = 20;
    static const int maxLimit = 100;
    static const int minLimit = 1;
  }

  /// Validation rules
  static class Validation {
    static const int maxStringLength = 255;
    static const int maxArrayLength = 100;
    static const int minArrayLength = 1;
    static const int maxBreakTimeMinutes = 1440; // 24 hours
    static const int maxBookingLeadTimeMinutes = 10080; // 7 days
    static const int maxFutureBookingLimitDays = 365;
    static const int maxDurationOverrideMinutes = 1440; // 24 hours
  }

  /// Feature flags
  static class FeatureFlags {
    static const bool enableCaching = true;
    static const bool enableRetry = true;
    static const bool enableOfflineSupport = false;
    static const bool enableRealTimeUpdates = true;
    static const bool enableAnalytics = true;
    static const bool enableCrashReporting = true;
  }

  /// Environment-specific configurations
  static Map<String, dynamic> get environmentConfig {
    if (kDebugMode) {
      return {
        'enableLogging': true,
        'enablePerformanceMonitoring': true,
        'enableAnalytics': false,
        'enableCrashReporting': false,
        'requestTimeout': 30,
        'maxRetryAttempts': 1,
      };
    } else if (kProfileMode) {
      return {
        'enableLogging': true,
        'enablePerformanceMonitoring': true,
        'enableAnalytics': true,
        'enableCrashReporting': true,
        'requestTimeout': 30,
        'maxRetryAttempts': 2,
      };
    } else {
      return {
        'enableLogging': false,
        'enablePerformanceMonitoring': true,
        'enableAnalytics': true,
        'enableCrashReporting': true,
        'requestTimeout': 30,
        'maxRetryAttempts': 3,
      };
    }
  }

  /// Get configuration value
  static T getConfig<T>(String key, T defaultValue) {
    final config = environmentConfig;
    return config[key] as T? ?? defaultValue;
  }

  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    return getConfig('enable$feature', false);
  }

  /// Get API endpoint URL
  static String getEndpointUrl(String endpoint) {
    return '$fullBaseUrl$endpoint';
  }

  /// Get bookable sessions endpoint
  static String get bookableSessionsUrl => getEndpointUrl(Endpoints.bookableSessions);

  /// Get bookable sessions search endpoint
  static String get bookableSessionsSearchUrl => getEndpointUrl(Endpoints.bookableSessionsSearch);

  /// Get instructors endpoint
  static String get instructorsUrl => getEndpointUrl(Endpoints.instructors);

  /// Get locations endpoint
  static String get locationsUrl => getEndpointUrl(Endpoints.locations);

  /// Get schedules endpoint
  static String get schedulesUrl => getEndpointUrl(Endpoints.schedules);

  /// Get session types endpoint
  static String get sessionTypesUrl => getEndpointUrl(Endpoints.sessionTypes);

  /// Get bookings endpoint
  static String get bookingsUrl => getEndpointUrl(Endpoints.bookings);

  /// Get reviews endpoint
  static String get reviewsUrl => getEndpointUrl(Endpoints.reviews);

  /// Get notifications endpoint
  static String get notificationsUrl => getEndpointUrl(Endpoints.notifications);
}
