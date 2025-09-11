import 'package:flutter/foundation.dart';
import 'lib/core/config/environment.dart';

/// Test script to verify environment configuration
void main() {
  print('🧪 Testing Environment Configuration');
  print('=====================================');
  
  // Test environment detection
  print('📊 Environment Detection:');
  print('  - Current Environment: ${EnvironmentConfig.current}');
  print('  - Is Development: ${EnvironmentConfig.isDevelopment}');
  print('  - Is Production: ${EnvironmentConfig.isProduction}');
  print('');
  
  // Test collection configuration
  print('🗄️ Firestore Configuration:');
  print('  - Database ID: ${EnvironmentConfig.databaseId}');
  print('  - Collection Prefix: ${EnvironmentConfig.collectionPrefix}');
  print('  - Root Collection: ${EnvironmentConfig.collectionPrefix}');
  print('');
  
  // Test email configuration
  print('📧 Email Configuration:');
  print('  - Use Real Email: ${EnvironmentConfig.shouldUseRealEmail}');
  print('  - From Email: ${EnvironmentConfig.fromEmail}');
  print('  - From Name: ${EnvironmentConfig.fromName}');
  print('  - Functions URL: ${EnvironmentConfig.firebaseFunctionsUrl}');
  print('');
  
  // Test app configuration
  print('📱 App Configuration:');
  print('  - App Name: ${EnvironmentConfig.appName}');
  print('  - App Version: ${EnvironmentConfig.appVersion}');
  print('  - Debug Logging: ${EnvironmentConfig.enableDebugLogging}');
  print('  - Console Emails: ${EnvironmentConfig.enableConsoleEmails}');
  print('');
  
  // Test collection paths
  print('🔗 Collection Paths:');
  print('  - Users: ${EnvironmentConfig.collectionPrefix}/users/users');
  print('  - Bookings: ${EnvironmentConfig.collectionPrefix}/bookings/bookings');
  print('  - Sessions: ${EnvironmentConfig.collectionPrefix}/bookable_sessions/bookable_sessions');
  print('');
  
  print('✅ Environment test completed!');
}
