import 'package:flutter/foundation.dart';

/// Environment configuration for the application
class EnvironmentConfig {
  /// Check if we're running in development mode
  static bool get isDevelopment {
    return kDebugMode || !kReleaseMode;
  }
  
  /// Check if we're running in production mode
  static bool get isProduction {
    return kReleaseMode && !kDebugMode;
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
    // Use real email in production web mode (API key is handled by Firebase Functions)
    if (isProduction && isWeb) {
      return true;
    }
    
    // Use console logging in development
    return false;
  }
  
  /// Get the appropriate email service type
  static String get emailServiceType {
    if (shouldUseRealEmail) {
      return 'FirebaseEmailService (Production)';
    } else {
      return 'WebEmailService (Development/Console)';
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
}

