import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Environment configuration for the application
class EnvironmentConfig {
  /// Check if we're running in development mode
  static bool get isDevelopment {
    return EnvironmentConfig.current == Environment.development;
  }
  
  /// Check if we're running in production mode
  static bool get isProduction {
    return EnvironmentConfig.current == Environment.production;
  }
  
  /// Get the current environment
  static Environment get current {
    const String envString = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (envString.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'development':
      default:
        return Environment.development;
    }
  }
  
  /// Check if Google Sign-In is available
  static bool get isGoogleSignInAvailable {
    // For development, Google Sign-In is disabled
    return isProduction;
  }
  
  /// Check if we're running on web
  static bool get isWeb {
    return kIsWeb;
  }
  
  /// Check if we're running on mobile (iOS/Android)
  static bool get isMobile {
    return !kIsWeb;
  }
  
  /// Get the current environment name
  static String get environmentName {
    if (isDevelopment) return 'development';
    if (isProduction) return 'production';
    return 'unknown';
  }
  
  /// Check if we should use real email sending
  static bool get shouldUseRealEmail {
    // Use real email in both development and production web mode
    // API key is handled by Firebase Functions
    if (isWeb) {
      return true;
    }
    
    // Use console logging for mobile
    return false;
  }
  
  /// Get the appropriate email service type
  static String get emailServiceType {
    if (shouldUseRealEmail) {
      return 'FirebaseEmailService (Real Email via SendGrid)';
    } else {
      return 'SimpleEmailService (Console Logging)';
    }
  }
  
  /// Print environment information
  static void printEnvironmentInfo() {
    print('🔧 Environment Configuration:');
    print('   - Mode: ${isDevelopment ? 'Development' : 'Production'}');
    print('   - Platform: ${isWeb ? 'Web' : 'Mobile'}');
    print('   - Email Service: $emailServiceType');
    print('   - Real Email: ${shouldUseRealEmail ? 'Yes' : 'No'}');
  }
  
  // Database configuration
  static String get databaseId {
    switch (current) {
      case Environment.development:
        return '(default)'; // Development database
      case Environment.production:
        return '(default)'; // Production also uses default database with ProdData collection
    }
  }
  
  // Collection prefix for environment separation
  static String get collectionPrefix {
    switch (current) {
      case Environment.development:
        return 'DevData';
      case Environment.production:
        return 'ProdData';
    }
  }
  
  // Email configuration
  static String get fromEmail => 'noreply@arenna.link';
  static String get fromName => 'ARENNA';
  
  // Firebase Functions URLs
  static String get firebaseFunctionsUrl {
    switch (current) {
      case Environment.development:
        return 'https://us-central1-apiclientapp.cloudfunctions.net';
      case Environment.production:
        return 'https://us-central1-apiclientapp.cloudfunctions.net';
    }
  }
  
  // Debug settings
  static bool get enableDebugLogging => isDevelopment;
  static bool get enableConsoleEmails => isDevelopment;
  
  // App configuration
  static String get appName {
    switch (current) {
      case Environment.development:
        return 'ARENNA (Dev)';
      case Environment.production:
        return 'ARENNA';
    }
  }
  
  static String get appVersion {
    switch (current) {
      case Environment.development:
        return '1.0.0-dev';
      case Environment.production:
        return '1.0.0';
    }
  }
}

