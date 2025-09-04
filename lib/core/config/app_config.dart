class AppConfig {
  // Google Sign-In Configuration
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '707974722454-o7f4paigfd3nkpihs3fvbto2m5obc1h0.apps.googleusercontent.com',
  );
  
  // Add other environment variables here as needed
  // static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  // static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
}
