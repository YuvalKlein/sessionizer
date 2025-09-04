class AvailabilitySlot {
  final DateTime startTime;
  final DateTime endTime;
  final String schedulableSessionId;
  final String sessionTypeId;
  final String scheduleId;
  final List<String> locationIds;
  final int duration; // effective duration including overrides
  final int bufferBefore;
  final int bufferAfter;
  final bool isAvailable;
  final String? conflictReason; // If not available, why?

  AvailabilitySlot({
    required this.startTime,
    required this.endTime,
    required this.schedulableSessionId,
    required this.sessionTypeId,
    required this.scheduleId,
    required this.locationIds,
    required this.duration,
    required this.bufferBefore,
    required this.bufferAfter,
    required this.isAvailable,
    this.conflictReason,
  });

  /// Total time needed including buffers
  int get totalTimeNeeded => bufferBefore + duration + bufferAfter;

  /// Actual session start time (accounting for buffer before)
  DateTime get sessionStartTime => startTime.add(Duration(minutes: bufferBefore));

  /// Actual session end time (accounting for buffer after)
  DateTime get sessionEndTime => endTime.subtract(Duration(minutes: bufferAfter));

  @override
  String toString() {
    return 'AvailabilitySlot(${startTime.toIso8601String()} - ${endTime.toIso8601String()}, '
           'duration: ${duration}min, available: $isAvailable'
           '${conflictReason != null ? ', reason: $conflictReason' : ''})';
  }

  AvailabilitySlot copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? schedulableSessionId,
    String? sessionTypeId,
    String? scheduleId,
    List<String>? locationIds,
    int? duration,
    int? bufferBefore,
    int? bufferAfter,
    bool? isAvailable,
    String? conflictReason,
  }) {
    return AvailabilitySlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      schedulableSessionId: schedulableSessionId ?? this.schedulableSessionId,
      sessionTypeId: sessionTypeId ?? this.sessionTypeId,
      scheduleId: scheduleId ?? this.scheduleId,
      locationIds: locationIds ?? this.locationIds,
      duration: duration ?? this.duration,
      bufferBefore: bufferBefore ?? this.bufferBefore,
      bufferAfter: bufferAfter ?? this.bufferAfter,
      isAvailable: isAvailable ?? this.isAvailable,
      conflictReason: conflictReason ?? this.conflictReason,
    );
  }
}

class DayAvailability {
  final DateTime date;
  final List<AvailabilitySlot> slots;
  final bool hasAvailability;

  DayAvailability({
    required this.date,
    required this.slots,
  }) : hasAvailability = slots.any((slot) => slot.isAvailable);

  /// Get only available slots
  List<AvailabilitySlot> get availableSlots => 
      slots.where((slot) => slot.isAvailable).toList();

  /// Get only unavailable slots
  List<AvailabilitySlot> get unavailableSlots => 
      slots.where((slot) => !slot.isAvailable).toList();

  @override
  String toString() {
    return 'DayAvailability(${date.toIso8601String().split('T')[0]}, '
           '${availableSlots.length}/${slots.length} available)';
  }
}
