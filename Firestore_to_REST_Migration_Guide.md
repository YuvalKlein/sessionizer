# Firestore to REST API Migration Guide

## Overview

This guide provides step-by-step instructions for migrating from Firebase Firestore to REST API implementation for the BookableSession feature.

## Prerequisites

- Flutter project with existing Firestore implementation
- Backend API endpoints implemented
- Firebase Authentication configured
- HTTP client dependency available

## Step 1: Add Dependencies

### 1.1 Update pubspec.yaml

```yaml
dependencies:
  http: ^1.1.0  # Add HTTP client
  # ... existing dependencies
```

### 1.2 Install Dependencies

```bash
flutter pub get
```

## Step 2: Create REST Data Source

### 2.1 Create the REST Implementation

The `BookableSessionRemoteRestDataSourceImpl` class has been created in:
```
lib/features/bookable_session/data/datasources/bookable_session_remote_rest_data_source.dart
```

### 2.2 Key Features

- ✅ HTTP client integration
- ✅ Firebase Auth token handling
- ✅ Automatic token refresh
- ✅ Comprehensive error handling
- ✅ Request/response logging
- ✅ Timeout handling
- ✅ Stream support for real-time updates

## Step 3: Update Dependency Injection

### 3.1 Add HTTP Client Registration

Update `lib/core/utils/injection_container.dart`:

```dart
// Add import
import 'package:http/http.dart' as http;

// Add to initializeDependencies()
Future<void> initializeDependencies() async {
  // ... existing dependencies
  
  // Add HTTP client
  sl.registerLazySingleton(() => http.Client());
  
  // ... rest of dependencies
}
```

### 3.2 Update BookableSession Data Source Registration

Replace the existing Firestore data source registration:

```dart
// Before (Firestore)
sl.registerLazySingleton<BookableSessionRemoteDataSource>(
  () => BookableSessionRemoteDataSourceImpl(firestore: sl()),
);

// After (REST)
sl.registerLazySingleton<BookableSessionRemoteDataSource>(
  () => BookableSessionRemoteRestDataSourceImpl(
    httpClient: sl(),
    firebaseAuth: sl(),
    baseUrl: AppConfig.apiBaseUrl, // Add this to AppConfig
  ),
);
```

### 3.3 Add API Configuration

Update `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // ... existing config
  
  // Add API base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api-domain.com',
  );
}
```

## Step 4: Environment Configuration

### 4.1 Development Environment

Create `.env.development`:

```env
API_BASE_URL=https://dev-api.your-domain.com
```

### 4.2 Production Environment

Create `.env.production`:

```env
API_BASE_URL=https://api.your-domain.com
```

### 4.3 Load Environment Variables

Update `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env.${Environment.current}");
  
  // Initialize dependencies
  await initializeDependencies();
  
  runApp(MyApp());
}
```

## Step 5: Update Repository Implementation

### 5.1 No Changes Required

The repository implementation (`BookableSessionRepositoryImpl`) doesn't need changes because it uses the same interface (`BookableSessionRemoteDataSource`).

### 5.2 Verify Interface Compatibility

Ensure the REST implementation implements the same interface:

```dart
class BookableSessionRemoteRestDataSourceImpl implements BookableSessionRemoteDataSource {
  // Implementation matches the interface exactly
}
```

## Step 6: Testing

### 6.1 Unit Tests

Create unit tests for the REST implementation:

```dart
// test/features/bookable_session/data/datasources/bookable_session_remote_rest_data_source_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:myapp/features/bookable_session/data/datasources/bookable_session_remote_rest_data_source.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('BookableSessionRemoteRestDataSourceImpl', () {
    late BookableSessionRemoteRestDataSourceImpl dataSource;
    late MockHttpClient mockHttpClient;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockFirebaseAuth = MockFirebaseAuth();
      dataSource = BookableSessionRemoteRestDataSourceImpl(
        httpClient: mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
        baseUrl: 'https://test-api.com',
      );
    });

    test('should return bookable sessions when GET request is successful', () async {
      // Arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{"success": true, "data": []}', 200));

      // Act
      final result = await dataSource.getAllBookableSessions().first;

      // Assert
      expect(result, isA<List<BookableSessionModel>>());
    });

    test('should throw ServerException when GET request fails', () async {
      // Arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{"error": "Server Error"}', 500));

      // Act & Assert
      expect(
        () => dataSource.getAllBookableSessions().first,
        throwsA(isA<ServerException>()),
      );
    });
  });
}
```

### 6.2 Integration Tests

Create integration tests with real API endpoints:

```dart
// integration_test/bookable_session_rest_api_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BookableSession REST API Integration Tests', () {
    testWidgets('should load bookable sessions from REST API', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act
      // Navigate to bookable sessions page
      // Wait for API call to complete

      // Assert
      // Verify sessions are loaded from REST API
    });
  });
}
```

## Step 7: Error Handling Updates

### 7.1 Update Exception Handling

The REST implementation includes new exception types:

```dart
// New exceptions
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}
```

### 7.2 Update Error Handling in UI

Update UI components to handle new error types:

```dart
// Example error handling
try {
  final sessions = await bookableSessionBloc.getBookableSessions();
} on UnauthorizedException catch (e) {
  // Handle authentication error
  showSnackBar('Please log in again');
} on NotFoundException catch (e) {
  // Handle not found error
  showSnackBar('Session not found');
} on ServerException catch (e) {
  // Handle server error
  showSnackBar('Server error: ${e.message}');
}
```

## Step 8: Performance Considerations

### 8.1 Caching

Implement caching for better performance:

```dart
// Add caching layer
class CachedBookableSessionRemoteDataSource implements BookableSessionRemoteDataSource {
  final BookableSessionRemoteDataSource _dataSource;
  final Map<String, List<BookableSessionModel>> _cache = {};
  
  // Implement caching logic
}
```

### 8.2 Connection Pooling

The HTTP client automatically handles connection pooling, but you can configure it:

```dart
// Configure HTTP client
final httpClient = http.Client();
// Connection pooling is handled automatically
```

### 8.3 Timeout Configuration

Configure timeouts appropriately:

```dart
BookableSessionRemoteRestDataSourceImpl(
  httpClient: sl(),
  firebaseAuth: sl(),
  baseUrl: AppConfig.apiBaseUrl,
  timeout: Duration(seconds: 30), // Adjust based on your needs
)
```

## Step 9: Monitoring and Logging

### 9.1 Add Request/Response Logging

The REST implementation includes comprehensive logging:

```dart
AppLogger.info('📡 GET /api/v1/bookable-sessions - Status: ${response.statusCode}');
AppLogger.error('❌ Error fetching bookable sessions: $e');
```

### 9.2 Monitor API Performance

Add performance monitoring:

```dart
// Example performance monitoring
final stopwatch = Stopwatch()..start();
try {
  final result = await dataSource.getBookableSessions(instructorId);
  AppLogger.info('⏱️ API call took ${stopwatch.elapsedMilliseconds}ms');
  return result;
} finally {
  stopwatch.stop();
}
```

## Step 10: Deployment

### 10.1 Environment-Specific Configuration

Configure different API URLs for different environments:

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static String get apiBaseUrl {
    if (kDebugMode) {
      return 'https://dev-api.your-domain.com';
    } else if (kProfileMode) {
      return 'https://staging-api.your-domain.com';
    } else {
      return 'https://api.your-domain.com';
    }
  }
}
```

### 10.2 Build Configuration

Update build configurations:

```yaml
# android/app/build.gradle
android {
    buildTypes {
        debug {
            buildConfigField "String", "API_BASE_URL", '"https://dev-api.your-domain.com"'
        }
        release {
            buildConfigField "String", "API_BASE_URL", '"https://api.your-domain.com"'
        }
    }
}
```

## Step 11: Rollback Plan

### 11.1 Feature Flag

Implement a feature flag to switch between implementations:

```dart
class AppConfig {
  static const bool useRestApi = bool.fromEnvironment('USE_REST_API', defaultValue: false);
}

// In dependency injection
if (AppConfig.useRestApi) {
  sl.registerLazySingleton<BookableSessionRemoteDataSource>(
    () => BookableSessionRemoteRestDataSourceImpl(/* ... */),
  );
} else {
  sl.registerLazySingleton<BookableSessionRemoteDataSource>(
    () => BookableSessionRemoteDataSourceImpl(firestore: sl()),
  );
}
```

### 11.2 Gradual Migration

Migrate one feature at a time:

1. Start with read-only operations
2. Add write operations
3. Add real-time updates
4. Remove Firestore implementation

## Step 12: Verification

### 12.1 Functional Testing

Verify all functionality works:

- [ ] Create bookable session
- [ ] Read bookable sessions
- [ ] Update bookable session
- [ ] Delete bookable session
- [ ] Search bookable sessions
- [ ] Error handling
- [ ] Authentication
- [ ] Pagination

### 12.2 Performance Testing

Test performance:

- [ ] Response times
- [ ] Memory usage
- [ ] Network usage
- [ ] Battery usage
- [ ] Cold start times

### 12.3 User Acceptance Testing

Test with real users:

- [ ] User workflows
- [ ] Error scenarios
- [ ] Offline behavior
- [ ] Network issues

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Firebase Auth configuration
   - Check token refresh logic
   - Ensure proper error handling

2. **Network Errors**
   - Check API endpoint URLs
   - Verify network connectivity
   - Check timeout configurations

3. **Data Format Issues**
   - Verify JSON serialization/deserialization
   - Check data model compatibility
   - Validate API response format

4. **Performance Issues**
   - Check caching implementation
   - Verify connection pooling
   - Monitor memory usage

### Debug Tools

1. **Network Inspector**
   - Use Flutter Inspector to monitor network calls
   - Check request/response details
   - Monitor performance metrics

2. **Logging**
   - Enable debug logging
   - Monitor error logs
   - Track performance metrics

3. **Testing**
   - Run unit tests
   - Run integration tests
   - Test error scenarios

## Conclusion

This migration guide provides a comprehensive approach to migrating from Firebase Firestore to REST API implementation. Follow the steps carefully and test thoroughly to ensure a smooth transition.

For additional support, refer to:
- API Documentation: `BookableSession_API_Documentation.md`
- Postman Collection: `BookableSession_API.postman_collection.json`
- Environment File: `BookableSession_API.postman_environment.json`
