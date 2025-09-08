import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/utils/logger.dart';

class DependencyChecker {
  final FirebaseFirestore _firestore;

  DependencyChecker({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// Check if a location is being used by any bookable sessions
  Future<DependencyCheckResult> checkLocationDependencies(String locationId) async {
    try {
      AppLogger.info('🔍 Checking dependencies for location: $locationId');
      
      // Get current user to filter by instructorId
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ No authenticated user found');
        return DependencyCheckResult(
          hasDependencies: false,
          dependentSessions: [],
          message: 'User not authenticated',
        );
      }
      
      AppLogger.info('👤 Current user ID: ${user.uid}');
      
      // Query bookable sessions for current instructor only
      final querySnapshot = await _firestore
          .collection('bookable_sessions')
          .where('instructorId', isEqualTo: user.uid)
          .get();
      
      AppLogger.info('📊 Found ${querySnapshot.docs.length} bookable sessions for instructor ${user.uid}');
      
      // Log all bookable sessions and their locationIds
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        AppLogger.info('📋 Session ${doc.id}: title=${data['title']}, locationIds=${data['locationIds']}, instructorId=${data['instructorId']}');
      }
      
      // Filter sessions that use this location
      final dependentSessions = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final locationIds = data['locationIds'] as List<dynamic>? ?? [];
        final hasLocation = locationIds.contains(locationId);
        AppLogger.info('🔍 Session ${doc.id}: locationIds=$locationIds, contains $locationId: $hasLocation');
        return hasLocation;
      }).map((doc) {
        final data = doc.data();
        AppLogger.info('🔗 Dependent session: ${doc.id}, title: ${data['title']}, locationIds: ${data['locationIds']}');
        return DependentSession(
          id: doc.id,
          title: data['title'] ?? 'Bookable Session ${doc.id.substring(0, 8)}',
          instructorId: data['instructorId'] ?? '',
        );
      }).toList();

      final result = DependencyCheckResult(
        hasDependencies: dependentSessions.isNotEmpty,
        dependentSessions: dependentSessions,
        message: dependentSessions.isEmpty 
            ? null 
            : 'This location is being used by ${dependentSessions.length} bookable session(s). Please update or delete these sessions first.',
      );
      
      AppLogger.info('✅ Dependency check result: hasDependencies=${result.hasDependencies}, count=${dependentSessions.length}');
      return result;
    } catch (e) {
      AppLogger.error('❌ Failed to check location dependencies', e);
      return DependencyCheckResult(
        hasDependencies: false,
        dependentSessions: [],
        message: 'Unable to check dependencies. Please try again.',
      );
    }
  }

  /// Check if a schedule is being used by any bookable sessions
  Future<DependencyCheckResult> checkScheduleDependencies(String scheduleId) async {
    try {
      AppLogger.info('🔍 Checking dependencies for schedule: $scheduleId');
      
      // Get current user to filter by instructorId
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ No authenticated user found');
        return DependencyCheckResult(
          hasDependencies: false,
          dependentSessions: [],
          message: 'User not authenticated',
        );
      }
      
      // Query bookable sessions for current instructor only
      final querySnapshot = await _firestore
          .collection('bookable_sessions')
          .where('instructorId', isEqualTo: user.uid)
          .get();
      
      AppLogger.info('📊 Found ${querySnapshot.docs.length} bookable sessions for instructor ${user.uid}');
      
      // Filter sessions that use this schedule
      final dependentSessions = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final sessionScheduleId = data['scheduleId'] as String?;
        final hasSchedule = sessionScheduleId == scheduleId;
        AppLogger.info('🔍 Session ${doc.id}: scheduleId=$sessionScheduleId, matches $scheduleId: $hasSchedule');
        return hasSchedule;
      }).map((doc) {
        final data = doc.data();
        AppLogger.info('🔗 Dependent session: ${doc.id}, title: ${data['title']}, scheduleId: ${data['scheduleId']}');
        return DependentSession(
          id: doc.id,
          title: data['title'] ?? 'Bookable Session ${doc.id.substring(0, 8)}',
          instructorId: data['instructorId'] ?? '',
        );
      }).toList();

      final result = DependencyCheckResult(
        hasDependencies: dependentSessions.isNotEmpty,
        dependentSessions: dependentSessions,
        message: dependentSessions.isEmpty 
            ? null 
            : 'This schedule is being used by ${dependentSessions.length} bookable session(s). Please update or delete these sessions first.',
      );
      
      AppLogger.info('✅ Schedule dependency check result: hasDependencies=${result.hasDependencies}, count=${dependentSessions.length}');
      return result;
    } catch (e) {
      AppLogger.error('❌ Failed to check schedule dependencies', e);
      return DependencyCheckResult(
        hasDependencies: false,
        dependentSessions: [],
        message: 'Unable to check dependencies. Please try again.',
      );
    }
  }

  /// Check if a session type is being used by any bookable sessions
  Future<DependencyCheckResult> checkSessionTypeDependencies(String sessionTypeId) async {
    try {
      AppLogger.info('🔍 Checking dependencies for session type: $sessionTypeId');
      
      // Get current user to filter by instructorId
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ No authenticated user found');
        return DependencyCheckResult(
          hasDependencies: false,
          dependentSessions: [],
          message: 'User not authenticated',
        );
      }
      
      // Query bookable sessions for current instructor only
      final querySnapshot = await _firestore
          .collection('bookable_sessions')
          .where('instructorId', isEqualTo: user.uid)
          .get();
      
      AppLogger.info('📊 Found ${querySnapshot.docs.length} bookable sessions for instructor ${user.uid}');
      
      // Filter sessions that use this session type
      final dependentSessions = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final sessionTypeIds = data['sessionTypeIds'] as List<dynamic>? ?? [];
        final hasSessionType = sessionTypeIds.contains(sessionTypeId);
        AppLogger.info('🔍 Session ${doc.id}: sessionTypeIds=$sessionTypeIds, contains $sessionTypeId: $hasSessionType');
        return hasSessionType;
      }).map((doc) {
        final data = doc.data();
        AppLogger.info('🔗 Dependent session: ${doc.id}, title: ${data['title']}, sessionTypeIds: ${data['sessionTypeIds']}');
        return DependentSession(
          id: doc.id,
          title: data['title'] ?? 'Bookable Session ${doc.id.substring(0, 8)}',
          instructorId: data['instructorId'] ?? '',
        );
      }).toList();

      final result = DependencyCheckResult(
        hasDependencies: dependentSessions.isNotEmpty,
        dependentSessions: dependentSessions,
        message: dependentSessions.isEmpty 
            ? null 
            : 'This session type is being used by ${dependentSessions.length} bookable session(s). Please update or delete these sessions first.',
      );
      
      AppLogger.info('✅ Session type dependency check result: hasDependencies=${result.hasDependencies}, count=${dependentSessions.length}');
      return result;
    } catch (e) {
      AppLogger.error('❌ Failed to check session type dependencies', e);
      return DependencyCheckResult(
        hasDependencies: false,
        dependentSessions: [],
        message: 'Unable to check dependencies. Please try again.',
      );
    }
  }
}

class DependencyCheckResult {
  final bool hasDependencies;
  final List<DependentSession> dependentSessions;
  final String? message;

  DependencyCheckResult({
    required this.hasDependencies,
    required this.dependentSessions,
    this.message,
  });
}

class DependentSession {
  final String id;
  final String title;
  final String instructorId;

  DependentSession({
    required this.id,
    required this.title,
    required this.instructorId,
  });
}
