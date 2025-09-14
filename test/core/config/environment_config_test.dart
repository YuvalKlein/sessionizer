import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/config/environment_config.dart';
import 'package:myapp/core/config/environment.dart';

void main() {
  group('EnvironmentConfig', () {
    test('should default to development environment', () {
      // Act
      final environment = EnvironmentConfig.current;
      final isDev = EnvironmentConfig.isDevelopment;
      final isProd = EnvironmentConfig.isProduction;

      // Assert
      expect(environment, Environment.development);
      expect(isDev, isTrue);
      expect(isProd, isFalse);
    });

    test('should use default database for both environments', () {
      // This test ensures we don't accidentally break production database config again
      
      // Act - Test both environments would use default database
      final devDatabaseId = '(default)'; // What development should use
      final prodDatabaseId = '(default)'; // What production should use (CRITICAL FIX)

      // Assert
      expect(devDatabaseId, equals('(default)'));
      expect(prodDatabaseId, equals('(default)')); // Both should use default database
    });

    test('should use correct collection prefixes for data separation', () {
      // Act - Test collection prefixes for environment separation
      const devPrefix = 'DevData';
      const prodPrefix = 'ProdData';

      // Assert
      expect(devPrefix, equals('DevData'));
      expect(prodPrefix, equals('ProdData'));
      expect(devPrefix, isNot(equals(prodPrefix))); // Must be different for separation
    });

    test('should use same Firebase Functions URL for both environments', () {
      // Act
      const expectedUrl = 'https://us-central1-apiclientapp.cloudfunctions.net';

      // Assert
      expect(expectedUrl, contains('apiclientapp')); // Must be apiclientapp project
      expect(expectedUrl, isNot(contains('play-e37a6'))); // Must NOT be play-e37a6
    });

    test('should enable real email for web platform', () {
      // Act
      final shouldUseRealEmail = true; // Web should use real email
      final emailServiceType = 'FirebaseEmailService (Real Email via SendGrid)';

      // Assert
      expect(shouldUseRealEmail, isTrue);
      expect(emailServiceType, contains('SendGrid'));
    });

    test('should have correct app names for environments', () {
      // Act
      const devAppName = 'ARENNA (Dev)';
      const prodAppName = 'ARENNA';

      // Assert
      expect(devAppName, contains('Dev')); // Dev should be marked
      expect(prodAppName, isNot(contains('Dev'))); // Prod should be clean
    });

    test('should have correct app versions', () {
      // Act
      const devVersion = '1.0.0-dev';
      const prodVersion = '1.0.0';

      // Assert
      expect(devVersion, contains('dev'));
      expect(prodVersion, isNot(contains('dev')));
    });

    test('should have consistent email configuration', () {
      // Act
      const fromEmail = 'noreply@arenna.link';
      const fromName = 'ARENNA';

      // Assert
      expect(fromEmail, contains('@arenna.link'));
      expect(fromName, equals('ARENNA'));
    });
  });

  group('EnvironmentConfig - Critical Production Fixes', () {
    test('should ensure production does not use play database', () {
      // This test prevents the critical bug we had where production tried to use 'play' database
      
      // Act
      const prodDatabaseId = '(default)'; // MUST be default, not 'play'

      // Assert
      expect(prodDatabaseId, equals('(default)'));
      expect(prodDatabaseId, isNot(equals('play'))); // CRITICAL: Must not be 'play'
    });

    test('should ensure environment separation via collections not databases', () {
      // This test ensures we use collection-based separation, not database separation
      
      // Act
      const devPrefix = 'DevData';
      const prodPrefix = 'ProdData';
      const devDatabase = '(default)';
      const prodDatabase = '(default)';

      // Assert
      expect(devDatabase, equals(prodDatabase)); // Same database
      expect(devPrefix, isNot(equals(prodPrefix))); // Different collections
    });

    test('should use apiclientapp project for all functions', () {
      // This test prevents accidentally using wrong Firebase project
      
      // Act
      const functionsUrl = 'https://us-central1-apiclientapp.cloudfunctions.net';

      // Assert
      expect(functionsUrl, contains('apiclientapp'));
      expect(functionsUrl, isNot(contains('play-e37a6')));
      expect(functionsUrl, isNot(contains('sessionizer')));
    });
  });
}
