import 'package:flutter/material.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/services/schedulable_session_service.dart';

class SchedulableSessionViewModel extends ChangeNotifier {
  final SchedulableSessionService _schedulableSessionService;

  SchedulableSessionViewModel(this._schedulableSessionService);

  bool _isLoading = false;
  String? _error;
  List<SchedulableSession> _schedulableSessions = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SchedulableSession> get schedulableSessions => _schedulableSessions;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Get schedulable sessions stream for an instructor
  Stream<List<SchedulableSession>> getSchedulableSessionsStream(String instructorId) {
    return _schedulableSessionService.getSchedulableSessionsStream(instructorId);
  }

  /// Get active schedulable sessions stream for an instructor
  Stream<List<SchedulableSession>> getActiveSchedulableSessionsStream(String instructorId) {
    return _schedulableSessionService.getActiveSchedulableSessionsStream(instructorId);
  }

  /// Create a new schedulable session
  Future<String?> createSchedulableSession(SchedulableSession schedulableSession) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final id = await _schedulableSessionService.createSchedulableSession(schedulableSession);
      
      return id;
    } catch (e) {
      _setError('Failed to create schedulable session: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing schedulable session
  Future<bool> updateSchedulableSession(String id, SchedulableSession schedulableSession) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _schedulableSessionService.updateSchedulableSession(id, schedulableSession);
      
      return true;
    } catch (e) {
      _setError('Failed to update schedulable session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a schedulable session
  Future<bool> deleteSchedulableSession(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _schedulableSessionService.deleteSchedulableSession(id);
      
      return true;
    } catch (e) {
      _setError('Failed to delete schedulable session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle active status of a schedulable session
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _schedulableSessionService.toggleActiveStatus(id, isActive);
      
      return true;
    } catch (e) {
      _setError('Failed to toggle status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Duplicate a schedulable session
  Future<String?> duplicateSchedulableSession(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final newId = await _schedulableSessionService.duplicateSchedulableSession(id);
      
      return newId;
    } catch (e) {
      _setError('Failed to duplicate schedulable session: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific schedulable session
  Future<SchedulableSession?> getSchedulableSession(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final schedulableSession = await _schedulableSessionService.getSchedulableSession(id);
      
      return schedulableSession;
    } catch (e) {
      _setError('Failed to get schedulable session: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get schedulable sessions by session type
  Stream<List<SchedulableSession>> getSchedulableSessionsByTypeStream(
    String instructorId,
    String sessionTypeId,
  ) {
    return _schedulableSessionService.getSchedulableSessionsByTypeStream(
      instructorId,
      sessionTypeId,
    );
  }

  /// Get schedulable sessions by location
  Stream<List<SchedulableSession>> getSchedulableSessionsByLocationStream(
    String instructorId,
    String locationId,
  ) {
    return _schedulableSessionService.getSchedulableSessionsByLocationStream(
      instructorId,
      locationId,
    );
  }

  /// Get schedulable sessions by schedule
  Stream<List<SchedulableSession>> getSchedulableSessionsByScheduleStream(
    String instructorId,
    String scheduleId,
  ) {
    return _schedulableSessionService.getSchedulableSessionsByScheduleStream(
      instructorId,
      scheduleId,
    );
  }

  /// Get count of schedulable sessions
  Future<int> getSchedulableSessionsCount(String instructorId) async {
    try {
      return await _schedulableSessionService.getSchedulableSessionsCount(instructorId);
    } catch (e) {
      _setError('Failed to get count: $e');
      return 0;
    }
  }

  /// Get count of active schedulable sessions
  Future<int> getActiveSchedulableSessionsCount(String instructorId) async {
    try {
      return await _schedulableSessionService.getActiveSchedulableSessionsCount(instructorId);
    } catch (e) {
      _setError('Failed to get active count: $e');
      return 0;
    }
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Validation methods
  
  bool validateSchedulableSession(SchedulableSession schedulableSession) {
    if (schedulableSession.sessionTypeId.isEmpty) {
      _setError('Session type is required');
      return false;
    }
    
    if (schedulableSession.scheduleId.isEmpty) {
      _setError('Schedule is required');
      return false;
    }
    
    if (schedulableSession.locationIds.isEmpty) {
      _setError('At least one location is required');
      return false;
    }
    
    if (schedulableSession.bufferBefore < 0) {
      _setError('Buffer before must be 0 or positive');
      return false;
    }
    
    if (schedulableSession.bufferAfter < 0) {
      _setError('Buffer after must be 0 or positive');
      return false;
    }
    
    if (schedulableSession.maxDaysAhead <= 0) {
      _setError('Max days ahead must be positive');
      return false;
    }
    
    if (schedulableSession.minHoursAhead < 0) {
      _setError('Min hours ahead must be 0 or positive');
      return false;
    }
    
    return true;
  }
}
