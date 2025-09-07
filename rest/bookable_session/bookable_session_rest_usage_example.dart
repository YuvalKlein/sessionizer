import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/config/api_config.dart';
import 'package:myapp/features/bookable_session/data/datasources/bookable_session_remote_rest_data_source.dart';
import 'package:myapp/features/bookable_session/data/models/bookable_session_model.dart';

/// Example usage of BookableSessionRemoteRestDataSourceImpl
class BookableSessionRestUsageExample {
  late BookableSessionRemoteRestDataSourceImpl _dataSource;

  /// Initialize the REST data source
  void initializeDataSource() {
    _dataSource = BookableSessionRemoteRestDataSourceImpl(
      httpClient: http.Client(),
      firebaseAuth: FirebaseAuth.instance,
      baseUrl: ApiConfig.baseUrl,
      timeout: ApiConfig.requestTimeout,
    );
  }

  /// Example: Get all bookable sessions for an instructor
  Future<void> getInstructorSessions(String instructorId) async {
    try {
      print('🔍 Fetching bookable sessions for instructor: $instructorId');
      
      final sessions = await _dataSource
          .getBookableSessions(instructorId)
          .first;
      
      print('✅ Found ${sessions.length} bookable sessions');
      
      for (final session in sessions) {
        print('📋 Session: ${session.id}');
        print('   - Instructor: ${session.instructorId}');
        print('   - Session Types: ${session.sessionTypeIds}');
        print('   - Locations: ${session.locationIds}');
        print('   - Break Time: ${session.breakTimeInMinutes} minutes');
        print('   - Lead Time: ${session.bookingLeadTimeInMinutes} minutes');
        print('   - Future Limit: ${session.futureBookingLimitInDays} days');
        print('   - Created: ${session.createdAt}');
        print('   - Updated: ${session.updatedAt}');
        print('---');
      }
    } catch (e) {
      print('❌ Error fetching sessions: $e');
    }
  }

  /// Example: Get all active bookable sessions
  Future<void> getAllActiveSessions() async {
    try {
      print('🔍 Fetching all active bookable sessions');
      
      final sessions = await _dataSource
          .getAllBookableSessions()
          .first;
      
      print('✅ Found ${sessions.length} active bookable sessions');
      
      // Group by instructor
      final groupedSessions = <String, List<BookableSessionModel>>{};
      for (final session in sessions) {
        groupedSessions.putIfAbsent(session.instructorId, () => []).add(session);
      }
      
      for (final entry in groupedSessions.entries) {
        print('👨‍🏫 Instructor ${entry.key}: ${entry.value.length} sessions');
      }
    } catch (e) {
      print('❌ Error fetching all sessions: $e');
    }
  }

  /// Example: Get a specific bookable session
  Future<void> getSpecificSession(String sessionId) async {
    try {
      print('🔍 Fetching bookable session: $sessionId');
      
      final session = await _dataSource.getBookableSession(sessionId);
      
      print('✅ Found session: ${session.id}');
      print('   - Instructor: ${session.instructorId}');
      print('   - Session Types: ${session.sessionTypeIds}');
      print('   - Locations: ${session.locationIds}');
      print('   - Availability: ${session.availabilityIds}');
    } catch (e) {
      print('❌ Error fetching session: $e');
    }
  }

  /// Example: Create a new bookable session
  Future<void> createNewSession() async {
    try {
      print('➕ Creating new bookable session');
      
      final newSession = BookableSessionModel(
        instructorId: 'instructor_123',
        sessionTypeIds: ['type_1', 'type_2'],
        locationIds: ['loc_1', 'loc_2'],
        availabilityIds: ['avail_1', 'avail_2'],
        breakTimeInMinutes: 15,
        bookingLeadTimeInMinutes: 30,
        futureBookingLimitInDays: 7,
        durationOverride: 60,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final createdSession = await _dataSource.createBookableSession(newSession);
      
      print('✅ Created session: ${createdSession.id}');
      print('   - Instructor: ${createdSession.instructorId}');
      print('   - Session Types: ${createdSession.sessionTypeIds}');
      print('   - Locations: ${createdSession.locationIds}');
      print('   - Created: ${createdSession.createdAt}');
    } catch (e) {
      print('❌ Error creating session: $e');
    }
  }

  /// Example: Update an existing bookable session
  Future<void> updateExistingSession(String sessionId) async {
    try {
      print('✏️ Updating bookable session: $sessionId');
      
      // First, get the existing session
      final existingSession = await _dataSource.getBookableSession(sessionId);
      
      // Update some fields
      final updatedSession = existingSession.copyWith(
        breakTimeInMinutes: 20,
        bookingLeadTimeInMinutes: 45,
        futureBookingLimitInDays: 14,
        updatedAt: DateTime.now(),
      );
      
      final result = await _dataSource.updateBookableSession(updatedSession);
      
      print('✅ Updated session: ${result.id}');
      print('   - Break Time: ${result.breakTimeInMinutes} minutes');
      print('   - Lead Time: ${result.bookingLeadTimeInMinutes} minutes');
      print('   - Future Limit: ${result.futureBookingLimitInDays} days');
      print('   - Updated: ${result.updatedAt}');
    } catch (e) {
      print('❌ Error updating session: $e');
    }
  }

  /// Example: Delete a bookable session
  Future<void> deleteSession(String sessionId) async {
    try {
      print('🗑️ Deleting bookable session: $sessionId');
      
      await _dataSource.deleteBookableSession(sessionId);
      
      print('✅ Successfully deleted session: $sessionId');
    } catch (e) {
      print('❌ Error deleting session: $e');
    }
  }

  /// Example: Handle different error types
  Future<void> handleErrors() async {
    try {
      // This will likely fail with authentication error
      await _dataSource.getBookableSessions('invalid_instructor').first;
    } on UnauthorizedException catch (e) {
      print('🔐 Authentication error: ${e.message}');
      print('   - User needs to log in again');
    } on NotFoundException catch (e) {
      print('🔍 Not found error: ${e.message}');
      print('   - Resource does not exist');
    } on ServerException catch (e) {
      print('⚠️ Server error: ${e.message}');
      print('   - Server is experiencing issues');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Example: Stream-based real-time updates
  void listenToSessions(String instructorId) {
    print('👂 Listening to real-time updates for instructor: $instructorId');
    
    _dataSource.getBookableSessions(instructorId).listen(
      (sessions) {
        print('📡 Received update: ${sessions.length} sessions');
        // Handle real-time updates here
        for (final session in sessions) {
          print('   - ${session.id}: ${session.updatedAt}');
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
      },
    );
  }

  /// Example: Batch operations
  Future<void> batchOperations() async {
    try {
      print('🔄 Performing batch operations');
      
      // Get all sessions
      final allSessions = await _dataSource.getAllBookableSessions().first;
      print('📊 Total sessions: ${allSessions.length}');
      
      // Filter by instructor
      final instructorSessions = allSessions
          .where((session) => session.instructorId == 'instructor_123')
          .toList();
      print('👨‍🏫 Instructor sessions: ${instructorSessions.length}');
      
      // Filter by session type
      final yogaSessions = allSessions
          .where((session) => session.sessionTypeIds.contains('yoga_type'))
          .toList();
      print('🧘 Yoga sessions: ${yogaSessions.length}');
      
      // Filter by location
      final downtownSessions = allSessions
          .where((session) => session.locationIds.contains('downtown_loc'))
          .toList();
      print('🏙️ Downtown sessions: ${downtownSessions.length}');
      
    } catch (e) {
      print('❌ Error in batch operations: $e');
    }
  }

  /// Example: Performance monitoring
  Future<void> performanceMonitoring() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('⏱️ Starting performance test');
      
      final sessions = await _dataSource.getAllBookableSessions().first;
      
      stopwatch.stop();
      print('✅ Performance test completed');
      print('   - Sessions fetched: ${sessions.length}');
      print('   - Time taken: ${stopwatch.elapsedMilliseconds}ms');
      print('   - Average per session: ${stopwatch.elapsedMilliseconds / sessions.length}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('❌ Performance test failed after ${stopwatch.elapsedMilliseconds}ms: $e');
    }
  }

  /// Example: Configuration usage
  void showConfiguration() {
    print('⚙️ API Configuration:');
    print('   - Base URL: ${ApiConfig.baseUrl}');
    print('   - Full Base URL: ${ApiConfig.fullBaseUrl}');
    print('   - Request Timeout: ${ApiConfig.requestTimeout}');
    print('   - Max Retry Attempts: ${ApiConfig.maxRetryAttempts}');
    print('   - Enable Logging: ${ApiConfig.enableLogging}');
    print('   - Enable Performance Monitoring: ${ApiConfig.enablePerformanceMonitoring}');
    print('   - Cache Duration: ${ApiConfig.cacheDuration}');
    print('   - Max Cache Size: ${ApiConfig.maxCacheSize}');
    print('   - User Agent: ${ApiConfig.userAgent}');
  }

  /// Example: Feature flags
  void showFeatureFlags() {
    print('🚩 Feature Flags:');
    print('   - Caching: ${ApiConfig.FeatureFlags.enableCaching}');
    print('   - Retry: ${ApiConfig.FeatureFlags.enableRetry}');
    print('   - Offline Support: ${ApiConfig.FeatureFlags.enableOfflineSupport}');
    print('   - Real-time Updates: ${ApiConfig.FeatureFlags.enableRealTimeUpdates}');
    print('   - Analytics: ${ApiConfig.FeatureFlags.enableAnalytics}');
    print('   - Crash Reporting: ${ApiConfig.FeatureFlags.enableCrashReporting}');
  }

  /// Example: Error codes
  void showErrorCodes() {
    print('🚨 Error Codes:');
    print('   - Unauthorized: ${ApiConfig.ErrorCodes.unauthorized}');
    print('   - Forbidden: ${ApiConfig.ErrorCodes.forbidden}');
    print('   - Not Found: ${ApiConfig.ErrorCodes.notFound}');
    print('   - Validation Error: ${ApiConfig.ErrorCodes.validationError}');
    print('   - Conflict: ${ApiConfig.ErrorCodes.conflict}');
    print('   - Internal Server Error: ${ApiConfig.ErrorCodes.internalServerError}');
    print('   - Service Unavailable: ${ApiConfig.ErrorCodes.serviceUnavailable}');
    print('   - Timeout: ${ApiConfig.ErrorCodes.timeout}');
    print('   - Network Error: ${ApiConfig.ErrorCodes.networkError}');
  }

  /// Example: Validation rules
  void showValidationRules() {
    print('✅ Validation Rules:');
    print('   - Max String Length: ${ApiConfig.Validation.maxStringLength}');
    print('   - Max Array Length: ${ApiConfig.Validation.maxArrayLength}');
    print('   - Min Array Length: ${ApiConfig.Validation.minArrayLength}');
    print('   - Max Break Time: ${ApiConfig.Validation.maxBreakTimeMinutes} minutes');
    print('   - Max Booking Lead Time: ${ApiConfig.Validation.maxBookingLeadTimeMinutes} minutes');
    print('   - Max Future Booking Limit: ${ApiConfig.Validation.maxFutureBookingLimitDays} days');
    print('   - Max Duration Override: ${ApiConfig.Validation.maxDurationOverrideMinutes} minutes');
  }
}

/// Main function to run examples
void main() async {
  final example = BookableSessionRestUsageExample();
  
  // Initialize the data source
  example.initializeDataSource();
  
  // Show configuration
  example.showConfiguration();
  example.showFeatureFlags();
  example.showErrorCodes();
  example.showValidationRules();
  
  // Run examples (uncomment as needed)
  // await example.getInstructorSessions('instructor_123');
  // await example.getAllActiveSessions();
  // await example.getSpecificSession('session_123');
  // await example.createNewSession();
  // await example.updateExistingSession('session_123');
  // await example.deleteSession('session_123');
  // await example.handleErrors();
  // example.listenToSessions('instructor_123');
  // await example.batchOperations();
  // await example.performanceMonitoring();
}
