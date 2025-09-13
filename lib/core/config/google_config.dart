import 'package:myapp/core/config/environment_config.dart';

/// Google API configuration
class GoogleConfig {
  /// Get Google OAuth2 Client ID based on environment
  static String get clientId {
    // In production, this should come from environment variables or secure config
    // For now, we'll use the provided client ID
    const clientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '707974722454-g4e2nlvrgdve25cmvba3j26gco0sl915.apps.googleusercontent.com',
    );
    
    if (EnvironmentConfig.enableDebugLogging) {
      print('🔑 Using Google Client ID: ${clientId.substring(0, 12)}...');
    }
    
    return clientId;
  }

  /// Get authorized domains for OAuth2
  static List<String> get authorizedDomains {
    if (EnvironmentConfig.isDevelopment) {
      return [
        'http://localhost:8080',
        'http://localhost:8081', 
        'http://localhost:8082',
        'https://apiclientapp.web.app',
      ];
    } else {
      return [
        'https://apiclientapp.web.app',
      ];
    }
  }

  /// Check if Google Calendar integration is available
  static bool get isAvailable {
    return clientId.isNotEmpty && clientId != 'YOUR_GOOGLE_CLIENT_ID';
  }
}
