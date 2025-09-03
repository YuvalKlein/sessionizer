import 'package:flutter/foundation.dart';
import 'package:myapp/models/availability_slot.dart';
import 'package:myapp/models/booking.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/models/schedulable_session.dart';
import 'package:myapp/models/session_type.dart';
import 'package:myapp/services/booking_service.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/services/schedulable_session_service.dart';
import 'package:myapp/services/session_type_service.dart';

class AvailabilityService with ChangeNotifier {
  final ScheduleService _scheduleService;
  final SchedulableSessionService _schedulableSessionService;
  final SessionTypeService _sessionTypeService;
  final BookingService _bookingService;

  AvailabilityService({
    required ScheduleService scheduleService,
    required SchedulableSessionService schedulableSessionService,
    required SessionTypeService sessionTypeService,
    required BookingService bookingService,
  }) : _scheduleService = scheduleService,
       _schedulableSessionService = schedulableSessionService,
       _sessionTypeService = sessionTypeService,
       _bookingService = bookingService;

  /// Get availability for a specific instructor and date range
  Future<List<DayAvailability>> getAvailabilityForDateRange({
    required String instructorId,
    required DateTime startDate,
    required DateTime endDate,
    String? sessionTypeId,
    List<String>? locationIds,
    int? slotDurationMinutes,
  }) async {
    debugPrint('=== AVAILABILITY SERVICE CALLED ===');
    debugPrint('Instructor ID: $instructorId');
    debugPrint('Date range: ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}');
    try {
      // Get all active schedulable sessions for instructor
      final schedulableSessions = await _getActiveSchedulableSessions(
        instructorId, 
        sessionTypeId, 
        locationIds,
      );

      debugPrint('Found ${schedulableSessions.length} schedulable sessions for instructor $instructorId');

      if (schedulableSessions.isEmpty) {
        debugPrint('No schedulable sessions found - returning empty availability');
        return _generateEmptyAvailability(startDate, endDate);
      }

      // Get existing bookings for the date range
      final existingBookings = await _getBookingsInRange(
        instructorId, 
        startDate, 
        endDate,
      );

      // Process each day
      final result = <DayAvailability>[];
      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      
      while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
        final dayAvailability = await _calculateDayAvailability(
          date: currentDate,
          schedulableSessions: schedulableSessions,
          existingBookings: existingBookings,
          slotDurationMinutes: slotDurationMinutes,
        );
        
        result.add(dayAvailability);
        currentDate = currentDate.add(Duration(days: 1));
      }

      return result;
    } catch (e) {
      debugPrint('Error calculating availability: $e');
      return _generateEmptyAvailability(startDate, endDate);
    }
  }

  /// Check if a specific time slot is available for booking
  Future<bool> isTimeSlotAvailable({
    required String schedulableSessionId,
    required DateTime requestedStartTime,
    required DateTime requestedEndTime,
  }) async {
    try {
      final schedulableSession = await _schedulableSessionService.getSchedulableSession(schedulableSessionId);
      if (schedulableSession == null || !schedulableSession.isActive) {
        return false;
      }

      // Check booking time constraints
      if (!schedulableSession.isBookingAllowed(requestedStartTime)) {
        return false;
      }

      // Get session type for duration validation
      final sessionType = await _sessionTypeService.getSessionType(schedulableSession.sessionTypeId);
      if (sessionType == null) {
        return false;
      }

      // Check if slot can accommodate the session
      if (!schedulableSession.canAccommodateTimeSlot(
        requestedStartTime, 
        requestedEndTime, 
        sessionType.duration,
      )) {
        return false;
      }

      // Check schedule availability
      final schedule = await _scheduleService.getSchedule(schedulableSession.scheduleId);
      if (schedule == null) {
        return false;
      }

      if (!_isTimeInSchedule(requestedStartTime, requestedEndTime, schedule)) {
        return false;
      }

      // Check for existing bookings (including buffer times)
      final existingBookings = await _bookingService.getBookedSlots(
        schedulableSession.instructorId,
        requestedStartTime,
      );

      final bufferStartTime = requestedStartTime.subtract(Duration(minutes: schedulableSession.bufferBefore));
      final bufferEndTime = requestedEndTime.add(Duration(minutes: schedulableSession.bufferAfter));

      for (final booking in existingBookings) {
        if (_timesOverlap(bufferStartTime, bufferEndTime, booking.startTime, booking.endTime)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking time slot availability: $e');
      return false;
    }
  }

  // Private helper methods will be added in next part...
  
  Future<List<SchedulableSession>> _getActiveSchedulableSessions(
    String instructorId, 
    String? sessionTypeId, 
    List<String>? locationIds,
  ) async {
    var sessions = await _schedulableSessionService.getActiveSchedulableSessionsStream(instructorId).first;

    if (sessionTypeId != null) {
      sessions = sessions.where((s) => s.sessionTypeId == sessionTypeId).toList();
    }

    if (locationIds != null && locationIds.isNotEmpty) {
      sessions = sessions.where((s) => 
        s.locationIds.any((locId) => locationIds.contains(locId))
      ).toList();
    }

    return sessions;
  }

  Future<List<Booking>> _getBookingsInRange(
    String instructorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final bookings = <Booking>[];
    var currentDate = startDate;
    
    while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
      final dayBookings = await _bookingService.getBookedSlots(instructorId, currentDate);
      bookings.addAll(dayBookings);
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return bookings;
  }

  Future<DayAvailability> _calculateDayAvailability({
    required DateTime date,
    required List<SchedulableSession> schedulableSessions,
    required List<Booking> existingBookings,
    required int slotDurationMinutes,
  }) async {
    final allSlots = <AvailabilitySlot>[];

    for (final schedulableSession in schedulableSessions) {
      final sessionType = await _sessionTypeService.getSessionType(schedulableSession.sessionTypeId);
      final schedule = await _scheduleService.getSchedule(schedulableSession.scheduleId);
      
      if (sessionType == null || schedule == null) continue;

      final slots = _generateSlotsForSchedulableSession(
        date: date,
        schedulableSession: schedulableSession,
        sessionType: sessionType,
        schedule: schedule,
        existingBookings: existingBookings,
        slotDurationMinutes: slotDurationMinutes,
      );

      allSlots.addAll(slots);
    }

    allSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return DayAvailability(date: date, slots: allSlots);
  }

  List<AvailabilitySlot> _generateSlotsForSchedulableSession({
    required DateTime date,
    required SchedulableSession schedulableSession,
    required SessionType sessionType,
    required Schedule schedule,
    required List<Booking> existingBookings,
    int? slotDurationMinutes,
  }) {
    final slots = <AvailabilitySlot>[];
    final dayOfWeek = _getDayOfWeek(date);
    final availableRanges = _getAvailableRangesForDay(date, dayOfWeek, schedule);
    final effectiveDuration = schedulableSession.getEffectiveDuration(sessionType.duration);
    final actualSlotInterval = slotDurationMinutes ?? schedulableSession.slotIntervalMinutes;

    for (final range in availableRanges) {
      var currentTime = range.start;
      
      while (currentTime.add(Duration(minutes: effectiveDuration)).isBefore(range.end) ||
             currentTime.add(Duration(minutes: effectiveDuration)) == range.end) {
        
        final slotEndTime = currentTime.add(Duration(minutes: actualSlotInterval));
        
        final canAccommodate = schedulableSession.canAccommodateTimeSlot(
          currentTime, slotEndTime, sessionType.duration);

        String? conflictReason;
        bool isAvailable = canAccommodate;

        if (!canAccommodate) {
          conflictReason = 'Insufficient time for session and buffers';
          isAvailable = false;
        } else if (!schedulableSession.isBookingAllowed(currentTime)) {
          conflictReason = 'Outside booking time constraints';
          isAvailable = false;
        } else {
          final bufferStart = currentTime.subtract(Duration(minutes: schedulableSession.bufferBefore));
          final bufferEnd = slotEndTime.add(Duration(minutes: schedulableSession.bufferAfter));
          
          for (final booking in existingBookings) {
            if (_timesOverlap(bufferStart, bufferEnd, booking.startTime, booking.endTime)) {
              conflictReason = 'Conflicts with existing booking';
              isAvailable = false;
              break;
            }
          }
        }

        slots.add(AvailabilitySlot(
          startTime: currentTime,
          endTime: slotEndTime,
          schedulableSessionId: schedulableSession.id!,
          sessionTypeId: schedulableSession.sessionTypeId,
          scheduleId: schedulableSession.scheduleId,
          locationIds: schedulableSession.locationIds,
          duration: effectiveDuration,
          bufferBefore: schedulableSession.bufferBefore,
          bufferAfter: schedulableSession.bufferAfter,
          isAvailable: isAvailable,
          conflictReason: conflictReason,
        ));

        currentTime = currentTime.add(Duration(minutes: actualSlotInterval));
      }
    }

    return slots;
  }

  bool _isTimeInSchedule(DateTime startTime, DateTime endTime, Schedule schedule) {
    final date = DateTime(startTime.year, startTime.month, startTime.day);
    final dayOfWeek = _getDayOfWeek(date);
    final availableRanges = _getAvailableRangesForDay(date, dayOfWeek, schedule);

    for (final range in availableRanges) {
      if ((startTime.isAfter(range.start) || startTime == range.start) && 
          (endTime.isBefore(range.end) || endTime == range.end)) {
        return true;
      }
    }
    return false;
  }

  bool _timesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  List<TimeRange> _getAvailableRangesForDay(DateTime date, String dayOfWeek, Schedule schedule) {
    final ranges = <TimeRange>[];

    debugPrint('Getting availability for $dayOfWeek (${date.toString().split(' ')[0]})');

    // Check holidays first (these override everything)
    if (schedule.holidays != null) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (schedule.holidays!.containsKey(dateKey)) {
        debugPrint('Date $dateKey is a holiday - no availability');
        return []; // No availability on holidays
      }
    }

    // Check specific date overrides
    if (schedule.specificDateAvailability != null) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (schedule.specificDateAvailability!.containsKey(dateKey)) {
        final daySlots = schedule.specificDateAvailability![dateKey] as List?;
        if (daySlots != null) {
          for (final slot in daySlots) {
            final slotMap = slot as Map<String, dynamic>;
            final startTime = _parseTimeOnDate(date, slotMap['startTime'] as String);
            final endTime = _parseTimeOnDate(date, slotMap['endTime'] as String);
            ranges.add(TimeRange(start: startTime, end: endTime));
          }
        }
        return ranges;
      }
    }

    // Fall back to weekly availability
    if (schedule.weeklyAvailability != null && schedule.weeklyAvailability!.containsKey(dayOfWeek)) {
      final daySlots = schedule.weeklyAvailability![dayOfWeek] as List?;
      debugPrint('Found ${daySlots?.length ?? 0} weekly slots for $dayOfWeek');
      if (daySlots != null) {
        for (final slot in daySlots) {
          final slotMap = slot as Map<String, dynamic>;
          final startTime = _parseTimeOnDate(date, slotMap['startTime'] as String);
          final endTime = _parseTimeOnDate(date, slotMap['endTime'] as String);
          ranges.add(TimeRange(start: startTime, end: endTime));
          debugPrint('Added weekly slot: ${slotMap['startTime']} - ${slotMap['endTime']}');
        }
      }
    } else {
      debugPrint('No weekly availability found for $dayOfWeek');
    }

    debugPrint('Total ranges for $dayOfWeek: ${ranges.length}');
    return ranges;
  }

  DateTime _parseTimeOnDate(DateTime date, String timeString) {
    debugPrint('Parsing time: "$timeString"');
    
    // Handle different time formats
    String cleanTime = timeString.trim();
    
    // If it's in "HH:MM AM/PM" format, convert to 24-hour
    if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
      final isPM = cleanTime.contains('PM');
      final timeWithoutAmPm = cleanTime.replaceAll(RegExp(r'\s*(AM|PM)'), '').trim();
      
      if (timeWithoutAmPm.contains(':')) {
        final parts = timeWithoutAmPm.split(':');
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        // Convert to 24-hour format
        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }
        
        debugPrint('Converted "$timeString" to $hour:$minute');
        return DateTime(date.year, date.month, date.day, hour, minute);
      } else {
        // Just hour with AM/PM
        var hour = int.parse(timeWithoutAmPm);
        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }
        debugPrint('Converted "$timeString" to $hour:00');
        return DateTime(date.year, date.month, date.day, hour, 0);
      }
    }
    
    // Handle "HH:MM" format
    if (cleanTime.contains(':')) {
      final timeParts = cleanTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      debugPrint('Parsed "$timeString" as $hour:$minute');
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    
    // Handle just hour (assume minutes = 0)
    final hour = int.parse(cleanTime);
    debugPrint('Parsed "$timeString" as $hour:00');
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  String _getDayOfWeek(DateTime date) {
    const dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday', 
      'friday', 'saturday', 'sunday'
    ];
    return dayNames[date.weekday - 1];
  }

  List<DayAvailability> _generateEmptyAvailability(DateTime startDate, DateTime endDate) {
    final result = <DayAvailability>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    
    while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
      result.add(DayAvailability(date: currentDate, slots: []));
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return result;
  }
}

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({required this.start, required this.end});

  Duration get duration => end.difference(start);

  @override
  String toString() {
    return 'TimeRange(${start.toIso8601String()} - ${end.toIso8601String()})';
  }
}