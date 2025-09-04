import 'package:flutter/foundation.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/services/enhanced_booking_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';

class EnhancedBookingViewModel extends ChangeNotifier {
  final EnhancedBookingService _bookingService;
  final SessionTypeService _sessionTypeService;
  final LocationService _locationService;

  EnhancedBookingViewModel({
    required EnhancedBookingService bookingService,
    required SessionTypeService sessionTypeService,
    required LocationService locationService,
  }) : _bookingService = bookingService,
       _sessionTypeService = sessionTypeService,
       _locationService = locationService;

  // State
  List<SchedulableSession> _schedulableSessions = [];
  List<SessionType> _sessionTypes = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _availableSlots = [];
  SchedulableSession? _selectedSchedulableSession;
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SchedulableSession> get schedulableSessions => _schedulableSessions;
  List<SessionType> get sessionTypes => _sessionTypes;
  List<Map<String, dynamic>> get locations => _locations;
  List<Map<String, dynamic>> get availableSlots => _availableSlots;
  SchedulableSession? get selectedSchedulableSession => _selectedSchedulableSession;
  DateTime? get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSchedulableSessions => _schedulableSessions.isNotEmpty;

  /// Load schedulable sessions for an instructor
  Future<void> loadSchedulableSessions(String instructorId) async {
    _setLoading(true);
    _clearError();

    try {
      _schedulableSessions = await _bookingService.getSchedulableSessions(instructorId);
      
      // Load related data
      await _loadRelatedData();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load schedulable sessions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load related data (session types and locations)
  Future<void> _loadRelatedData() async {
    try {
      // Load session types
      final sessionTypeIds = _schedulableSessions
          .map((s) => s.sessionTypeId)
          .toSet()
          .toList();
      
      _sessionTypes = [];
      for (final sessionTypeId in sessionTypeIds) {
        final sessionType = await _sessionTypeService.getSessionType(sessionTypeId);
        if (sessionType != null) {
          _sessionTypes.add(sessionType);
        }
      }

      // Load locations
      _locations = await _locationService.getLocations();
    } catch (e) {
      debugPrint('Error loading related data: $e');
    }
  }

  /// Select a schedulable session
  void selectSchedulableSession(SchedulableSession schedulableSession) {
    _selectedSchedulableSession = schedulableSession;
    _availableSlots = []; // Clear previous slots
    notifyListeners();
  }

  /// Load available slots for a specific date
  Future<void> loadAvailableSlots(DateTime date) async {
    if (_selectedSchedulableSession == null) return;

    _setLoading(true);
    _clearError();
    _selectedDate = date;

    try {
      _availableSlots = await _bookingService.getAvailableSlots(
        schedulableSessionId: _selectedSchedulableSession!.id!,
        date: date,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load available slots: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Book a slot
  Future<bool> bookSlot({
    required Map<String, dynamic> slot,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String locationId,
  }) async {
    if (_selectedSchedulableSession == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final bookingId = await _bookingService.createBooking(
        schedulableSessionId: _selectedSchedulableSession!.id!,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        startTime: slot['startTime'],
        locationId: locationId,
      );

      if (bookingId != null) {
        // Refresh available slots
        if (_selectedDate != null) {
          await loadAvailableSlots(_selectedDate!);
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to book slot: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get session type for a schedulable session
  SessionType? getSessionTypeForSchedulableSession(SchedulableSession schedulableSession) {
    try {
      return _sessionTypes.firstWhere(
        (st) => st.id == schedulableSession.sessionTypeId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get location name by ID
  String getLocationName(String locationId) {
    final location = _locations.firstWhere(
      (loc) => loc['id'] == locationId,
      orElse: () => {'name': 'Unknown Location'},
    );
    return location['name'] as String;
  }

  /// Get available locations for a schedulable session
  List<Map<String, dynamic>> getAvailableLocationsForSession(SchedulableSession schedulableSession) {
    debugPrint('Getting locations for session: ${schedulableSession.title}');
    debugPrint('Session location IDs: ${schedulableSession.locationIds}');
    debugPrint('All locations: ${_locations.length}');
    for (var loc in _locations) {
      debugPrint('Location: ${loc['name']} (${loc['id']})');
    }
    
    final availableLocations = _locations.where((location) {
      return schedulableSession.locationIds.contains(location['id']);
    }).toList();
    
    debugPrint('Available locations found: ${availableLocations.length}');
    return availableLocations;
  }

  /// Check if a day has available slots (for calendar display)
  Future<bool> hasAvailabilityForDay(DateTime day) async {
    if (_selectedSchedulableSession == null) return false;
    
    try {
      final slots = await _bookingService.getAvailableSlots(
        schedulableSessionId: _selectedSchedulableSession!.id!,
        date: day,
      );
      return slots.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking availability for day $day: $e');
      return false;
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.cancelBooking(bookingId);
      
      // Refresh available slots if we have a selected date
      if (_selectedDate != null && _selectedSchedulableSession != null) {
        await loadAvailableSlots(_selectedDate!);
      }
      
      return true;
    } catch (e) {
      _setError('Failed to cancel booking: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear selection
  void clearSelection() {
    _selectedSchedulableSession = null;
    _selectedDate = null;
    _availableSlots = [];
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }
}
