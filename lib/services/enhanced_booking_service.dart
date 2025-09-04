import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/booking.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/services/schedulable_session_service.dart';
import 'package:myapp/services/session_type_service.dart';
import 'package:myapp/services/location_service.dart';

class EnhancedBookingService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final SchedulableSessionService _schedulableSessionService;
  final SessionTypeService _sessionTypeService;
  final LocationService _locationService;

  EnhancedBookingService({
    FirebaseFirestore? firestore,
    SchedulableSessionService? schedulableSessionService,
    SessionTypeService? sessionTypeService,
    LocationService? locationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _schedulableSessionService = schedulableSessionService ?? SchedulableSessionService(),
       _sessionTypeService = sessionTypeService ?? SessionTypeService(),
       _locationService = locationService ?? LocationService();

  /// Get all schedulable sessions for an instructor
  Future<List<SchedulableSession>> getSchedulableSessions(String instructorId) async {
    return await _schedulableSessionService.getSchedulableSessionsForInstructor(instructorId);
  }

  /// Get available time slots for a specific schedulable session on a given date
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String schedulableSessionId,
    required DateTime date,
  }) async {
    try {
      // Get the schedulable session
      final schedulableSession = await _schedulableSessionService.getSchedulableSession(schedulableSessionId);
      if (schedulableSession == null) {
        return [];
      }

      // Get the schedule for the date
      final schedule = await _getScheduleForDate(schedulableSession.scheduleId, date);
      if (schedule == null) {
        return [];
      }

      // Get existing bookings for this date and instructor
      final bookings = await _getBookingsForDate(schedulableSession.instructorId, date);

      // Calculate available slots
      return _calculateAvailableSlots(
        schedulableSession: schedulableSession,
        schedule: schedule,
        date: date,
        bookings: bookings,
      );
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }

  /// Create a new booking
  Future<String?> createBooking({
    required String schedulableSessionId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required DateTime startTime,
    required String locationId,
  }) async {
    try {
      // Get the schedulable session
      final schedulableSession = await _schedulableSessionService.getSchedulableSession(schedulableSessionId);
      if (schedulableSession == null) {
        throw 'Schedulable session not found';
      }

      // Calculate end time based on session type duration
      final sessionType = await _sessionTypeService.getSessionType(schedulableSession.sessionTypeId);
      final duration = sessionType?.duration ?? 60;
      final endTime = startTime.add(Duration(minutes: duration));

      // Check for conflicts
      final hasConflict = await _checkBookingConflict(
        schedulableSession.instructorId,
        startTime,
        endTime,
      );
      
      if (hasConflict) {
        throw 'Time slot is no longer available';
      }

      // Create the booking
      final bookingData = {
        'instructorId': schedulableSession.instructorId,
        'clientId': clientId,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'scheduleId': schedulableSession.scheduleId,
        'schedulableSessionId': schedulableSessionId,
        'sessionTypeId': schedulableSession.sessionTypeId,
        'locationId': locationId,
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  /// Get bookings for a specific date and instructor
  Future<List<Booking>> _getBookingsForDate(String instructorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  /// Check if there's a booking conflict
  Future<bool> _checkBookingConflict(String instructorId, DateTime startTime, DateTime endTime) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .where('startTime', isLessThan: endTime)
        .where('endTime', isGreaterThan: startTime)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get schedule data for a specific date
  Future<Map<String, dynamic>?> _getScheduleForDate(String scheduleId, DateTime date) async {
    // This is a simplified version - in a real app, you'd get the actual schedule
    // For now, we'll return a mock schedule
    return {
      'id': scheduleId,
      'name': 'Default Schedule',
      'availability': [
        {'dayOfWeek': date.weekday, 'startTime': '09:00', 'endTime': '17:00'}
      ]
    };
  }

  /// Calculate available slots based on schedule, buffers, and existing bookings
  List<Map<String, dynamic>> _calculateAvailableSlots({
    required SchedulableSession schedulableSession,
    required Map<String, dynamic> schedule,
    required DateTime date,
    required List<Booking> bookings,
  }) {
    final availableSlots = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Get schedule availability for this day
    final dayAvailability = schedule['availability']?.firstWhere(
      (avail) => avail['dayOfWeek'] == date.weekday,
      orElse: () => null,
    );

    if (dayAvailability == null) {
      return availableSlots;
    }

    // Parse start and end times
    final startTime = _parseTime(date, dayAvailability['startTime']);
    final endTime = _parseTime(date, dayAvailability['endTime']);

    // Generate slots based on slot interval
    DateTime current = startTime;
    while (current.isBefore(endTime)) {
      final slotEnd = current.add(Duration(minutes: schedulableSession.slotIntervalMinutes));
      
      // Check if slot is in the future and respects booking constraints
      if (current.isAfter(now) && 
          _isWithinBookingConstraints(current, schedulableSession) &&
          !_isSlotBooked(current, slotEnd, bookings) &&
          !_hasBufferConflict(current, slotEnd, bookings, schedulableSession.bufferBefore + schedulableSession.bufferAfter)) {
        
        availableSlots.add({
          'startTime': current,
          'endTime': slotEnd,
          'schedulableSessionId': schedulableSession.id,
          'sessionTypeId': schedulableSession.sessionTypeId,
          'locationIds': schedulableSession.locationIds,
        });
      }
      
      current = current.add(Duration(minutes: schedulableSession.slotIntervalMinutes));
    }

    return availableSlots;
  }

  /// Check if a time slot is within booking constraints
  bool _isWithinBookingConstraints(DateTime slotTime, SchedulableSession schedulableSession) {
    final now = DateTime.now();
    final daysAhead = slotTime.difference(now).inDays;
    final hoursAhead = slotTime.difference(now).inHours;

    return daysAhead <= schedulableSession.maxDaysAhead &&
           hoursAhead >= schedulableSession.minHoursAhead;
  }

  /// Check if a slot is already booked
  bool _isSlotBooked(DateTime startTime, DateTime endTime, List<Booking> bookings) {
    return bookings.any((booking) =>
        (startTime.isBefore(booking.endTime) && endTime.isAfter(booking.startTime)));
  }

  /// Check if there's a buffer conflict
  bool _hasBufferConflict(DateTime startTime, DateTime endTime, List<Booking> bookings, int bufferMinutes) {
    final bufferStart = startTime.subtract(Duration(minutes: bufferMinutes));
    final bufferEnd = endTime.add(Duration(minutes: bufferMinutes));

    return bookings.any((booking) =>
        (bufferStart.isBefore(booking.endTime) && bufferEnd.isAfter(booking.startTime)));
  }

  /// Parse time string to DateTime
  DateTime _parseTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      rethrow;
    }
  }

  /// Get bookings for a client
  Stream<QuerySnapshot> getClientBookingsStream(String clientId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('startTime', descending: false)
        .snapshots();
  }

  /// Get bookings for an instructor
  Stream<QuerySnapshot> getInstructorBookingsStream(String instructorId) {
    return _firestore
        .collection('bookings')
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('startTime', descending: false)
        .snapshots();
  }
}
