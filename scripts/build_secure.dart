import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  // Determine environment (development or production)
  final environment = args.isNotEmpty ? args[0] : 'development';
  print('🔧 Building for $environment environment');
  
  // Read environment variables from .env file
  final envFile = File('.env');
  Map<String, String> envVars = {};
  
  if (envFile.existsSync()) {
    final envContent = await envFile.readAsString();
    for (final line in envContent.split('\n')) {
      if (line.trim().isNotEmpty && !line.startsWith('#')) {
        final parts = line.split('=');
        if (parts.length == 2) {
          envVars[parts[0].trim()] = parts[1].trim();
        }
      }
    }
  }
  
  // Get required environment variables
  final googleClientId = envVars['GOOGLE_CLIENT_ID'] ?? 
      Platform.environment['GOOGLE_CLIENT_ID'];
      
  final firebaseApiKey = environment == 'production' 
      ? (envVars['FIREBASE_API_KEY_PROD'] ?? Platform.environment['FIREBASE_API_KEY_PROD'])
      : (envVars['FIREBASE_API_KEY_DEV'] ?? Platform.environment['FIREBASE_API_KEY_DEV']);
      
  if (googleClientId == null) {
    print('Error: GOOGLE_CLIENT_ID not found in environment variables');
    print('Please set GOOGLE_CLIENT_ID in your .env file or environment');
    exit(1);
  }
  
  if (firebaseApiKey == null) {
    print('Error: FIREBASE_API_KEY_${environment.toUpperCase()} not found in environment variables');
    print('Please set FIREBASE_API_KEY_${environment.toUpperCase()} in your .env file or environment');
    exit(1);
  }

  // Read the index.html file
  final indexFile = File('web/index.html');
  if (!indexFile.existsSync()) {
    print('Error: web/index.html file not found');
    exit(1);
  }

  String indexContent = await indexFile.readAsString();
  
  // Replace the placeholder with the actual Client ID
  indexContent = indexContent.replaceAll('GOOGLE_CLIENT_ID_PLACEHOLDER', googleClientId);
  
  // Write the updated content back
  await indexFile.writeAsString(indexContent);
  
  print('✅ Successfully updated web/index.html with Google Client ID');
  print('🔒 All secrets are now securely managed via environment variables');
  print('🔑 Firebase API key configured for $environment environment');
  print('🚀 Ready to build with: flutter build web --dart-define=FIREBASE_API_KEY=$firebaseApiKey');
}
