import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';

/// Factory for creating REST API clients
class RestClientFactory {
  static final RestClientFactory _instance = RestClientFactory._internal();
  factory RestClientFactory() => _instance;
  RestClientFactory._internal();

  /// Create HTTP client with configuration
  http.Client createHttpClient() {
    return http.Client();
  }

  /// Create Firebase Auth instance
  FirebaseAuth createFirebaseAuth() {
    return FirebaseAuth.instance;
  }

  /// Get base URL for current environment
  String getBaseUrl() {
    return ApiConfig.baseUrl;
  }

  /// Get full API base URL with version
  String getFullBaseUrl() {
    return ApiConfig.fullBaseUrl;
  }

  /// Get request timeout
  Duration getRequestTimeout() {
    return ApiConfig.requestTimeout;
  }

  /// Create REST client configuration
  RestClientConfig createConfig() {
    return RestClientConfig(
      baseUrl: getBaseUrl(),
      timeout: getRequestTimeout(),
      enableLogging: ApiConfig.enableLogging,
      enablePerformanceMonitoring: ApiConfig.enablePerformanceMonitoring,
      enableCaching: ApiConfig.FeatureFlags.enableCaching,
      enableRetry: ApiConfig.FeatureFlags.enableRetry,
      maxRetryAttempts: ApiConfig.maxRetryAttempts,
      retryDelay: ApiConfig.retryDelay,
    );
  }
}

/// Configuration for REST clients
class RestClientConfig {
  final String baseUrl;
  final Duration timeout;
  final bool enableLogging;
  final bool enablePerformanceMonitoring;
  final bool enableCaching;
  final bool enableRetry;
  final int maxRetryAttempts;
  final Duration retryDelay;

  const RestClientConfig({
    required this.baseUrl,
    required this.timeout,
    required this.enableLogging,
    required this.enablePerformanceMonitoring,
    required this.enableCaching,
    required this.enableRetry,
    required this.maxRetryAttempts,
    required this.retryDelay,
  });

  /// Create a copy with updated values
  RestClientConfig copyWith({
    String? baseUrl,
    Duration? timeout,
    bool? enableLogging,
    bool? enablePerformanceMonitoring,
    bool? enableCaching,
    bool? enableRetry,
    int? maxRetryAttempts,
    Duration? retryDelay,
  }) {
    return RestClientConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      timeout: timeout ?? this.timeout,
      enableLogging: enableLogging ?? this.enableLogging,
      enablePerformanceMonitoring: enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableCaching: enableCaching ?? this.enableCaching,
      enableRetry: enableRetry ?? this.enableRetry,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

/// REST client builder for easy configuration
class RestClientBuilder {
  String? _baseUrl;
  Duration? _timeout;
  bool? _enableLogging;
  bool? _enablePerformanceMonitoring;
  bool? _enableCaching;
  bool? _enableRetry;
  int? _maxRetryAttempts;
  Duration? _retryDelay;

  RestClientBuilder baseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    return this;
  }

  RestClientBuilder timeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  RestClientBuilder enableLogging(bool enable) {
    _enableLogging = enable;
    return this;
  }

  RestClientBuilder enablePerformanceMonitoring(bool enable) {
    _enablePerformanceMonitoring = enable;
    return this;
  }

  RestClientBuilder enableCaching(bool enable) {
    _enableCaching = enable;
    return this;
  }

  RestClientBuilder enableRetry(bool enable) {
    _enableRetry = enable;
    return this;
  }

  RestClientBuilder maxRetryAttempts(int attempts) {
    _maxRetryAttempts = attempts;
    return this;
  }

  RestClientBuilder retryDelay(Duration delay) {
    _retryDelay = delay;
    return this;
  }

  RestClientConfig build() {
    final factory = RestClientFactory();
    final defaultConfig = factory.createConfig();
    
    return RestClientConfig(
      baseUrl: _baseUrl ?? defaultConfig.baseUrl,
      timeout: _timeout ?? defaultConfig.timeout,
      enableLogging: _enableLogging ?? defaultConfig.enableLogging,
      enablePerformanceMonitoring: _enablePerformanceMonitoring ?? defaultConfig.enablePerformanceMonitoring,
      enableCaching: _enableCaching ?? defaultConfig.enableCaching,
      enableRetry: _enableRetry ?? defaultConfig.enableRetry,
      maxRetryAttempts: _maxRetryAttempts ?? defaultConfig.maxRetryAttempts,
      retryDelay: _retryDelay ?? defaultConfig.retryDelay,
    );
  }
}
