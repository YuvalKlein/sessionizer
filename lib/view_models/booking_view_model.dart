import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/models/booking.dart';
import 'package:myapp/services/schedule_service.dart';
import 'package:myapp/services/booking_service.dart';

class BookingViewModel with ChangeNotifier {
  final ScheduleService _scheduleService;
  final BookingService _bookingService;

  BookingViewModel({
    required ScheduleService scheduleService,
    required BookingService bookingService,
  }) : _scheduleService = scheduleService,
       _bookingService = bookingService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Schedule? _schedule;
  List<DateTime> _availableSlots = [];
  List<DateTime> get availableSlots => _availableSlots;

  bool get isScheduleAvailable => _schedule != null;

  Future<void> loadScheduleAndInitialAvailability(
    String instructorId,
    DateTime day,
  ) async {
    _setLoading(true);
    try {
      _schedule = await _scheduleService.getDefaultSchedule(instructorId);
      if (_schedule != null) {
        await loadAvailabilityForDay(day);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAvailabilityForDay(DateTime day) async {
    _setLoading(true);
    _availableSlots = [];
    if (_schedule == null) {
      _setLoading(false);
      return;
    }

    try {
      final availability = await _scheduleService.getAvailabilityForDay(
        _schedule!,
        day,
      );
      final booked = await _bookingService.getBookedSlots(
        _schedule!.instructorId,
        day,
      );

      _calculateAvailableSlots(availability, booked);
    } finally {
      _setLoading(false);
    }
  }

  void _calculateAvailableSlots(
    List<Map<String, String>> availability,
    List<Booking> bookedSlots,
  ) {
    final List<DateTime> potentialSlots = [];
    final now = DateTime.now();

    for (var slot in availability) {
      final day = DateTime(now.year, now.month, now.day);
      final startTime = _parseTime(day, slot['startTime']!);
      final endTime = _parseTime(day, slot['endTime']!);

      DateTime current = startTime;
      while (current.isBefore(endTime)) {
        // Only add slots that are in the future
        if (current.isAfter(now)) {
          potentialSlots.add(current);
        }
        current = current.add(const Duration(minutes: 30));
      }
    }

    final bookedStartTimes = bookedSlots.map((b) => b.startTime).toSet();
    _availableSlots = potentialSlots
        .where((slot) => !bookedStartTimes.contains(slot))
        .toList();
  }

  Future<void> bookSlot({
    required DateTime slot,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String instructorId,
  }) async {
    if (_schedule == null) return;

    final bookingData = {
      'instructorId': instructorId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'scheduleId': _schedule!.id,
      'startTime': slot,
      'endTime': slot.add(const Duration(minutes: 30)),
    };

    await _bookingService.createBooking(bookingData);
    // Refresh availability after booking
    await loadAvailabilityForDay(slot);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  DateTime _parseTime(DateTime day, String timeStr) {
    final format = DateFormat.jm(); // 9:00 AM
    final dt = format.parse(timeStr);
    return DateTime(day.year, day.month, day.day, dt.hour, dt.minute);
  }
}
