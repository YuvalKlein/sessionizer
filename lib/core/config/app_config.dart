class AppConfig {
  // Google Sign-In Configuration (Public ID - safe to have default)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '707974722454-o7f4paigfd3nkpihs3fvbto2m5obc1h0.apps.googleusercontent.com',
  );
  
  // SendGrid Configuration (Secret API Key - must be provided via environment)
  static String get sendGridApiKey {
    // Try environment variable first (for development)
    const envApiKey = String.fromEnvironment('SENDGRID_API_KEY', defaultValue: '');
    if (envApiKey.isNotEmpty) return envApiKey;
    
    // No fallback - API key must be provided via environment
    throw Exception('SENDGRID_API_KEY environment variable is required');
  }
  
  // SendGrid From Address (Public - safe to have default)
  static const String sendGridFromEmail = String.fromEnvironment(
    'SENDGRID_FROM_EMAIL',
    defaultValue: 'noreply@arenna.link',
  );
  
  // SendGrid From Name (Public - safe to have default)
  static const String sendGridFromName = String.fromEnvironment(
    'SENDGRID_FROM_NAME',
    defaultValue: 'ARENNA',
  );
  
  // Add other environment variables here as needed
  // static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  // static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
}
