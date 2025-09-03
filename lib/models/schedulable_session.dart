import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulableSession {
  final String? id;
  final String instructorId;
  final String sessionTypeId;
  final List<String> locationIds;
  final String scheduleId;
  
  // Buffer & Timing Rules
  final int bufferBefore; // minutes before session
  final int bufferAfter;  // minutes after session
  
  // Booking Constraints
  final int maxDaysAhead;    // how far in advance can be booked
  final int minHoursAhead;   // minimum hours before session can be booked
  
  // Override Options
  final int? durationOverride; // override session type duration if needed
  
  // Status & Metadata
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Optional Settings
  final String? notes; // internal notes for instructor
  final Map<String, dynamic>? customSettings; // future extensibility

  SchedulableSession({
    this.id,
    required this.instructorId,
    required this.sessionTypeId,
    required this.locationIds,
    required this.scheduleId,
    this.bufferBefore = 15,
    this.bufferAfter = 10,
    this.maxDaysAhead = 7,
    this.minHoursAhead = 2,
    this.durationOverride,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.customSettings,
  });

  factory SchedulableSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchedulableSession(
      id: doc.id,
      instructorId: data['instructorId'] ?? '',
      sessionTypeId: data['sessionTypeId'] ?? '',
      locationIds: List<String>.from(data['locationIds'] ?? []),
      scheduleId: data['scheduleId'] ?? '',
      bufferBefore: data['bufferBefore'] ?? 15,
      bufferAfter: data['bufferAfter'] ?? 10,
      maxDaysAhead: data['maxDaysAhead'] ?? 7,
      minHoursAhead: data['minHoursAhead'] ?? 2,
      durationOverride: data['durationOverride'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      customSettings: data['customSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'instructorId': instructorId,
      'sessionTypeId': sessionTypeId,
      'locationIds': locationIds,
      'scheduleId': scheduleId,
      'bufferBefore': bufferBefore,
      'bufferAfter': bufferAfter,
      'maxDaysAhead': maxDaysAhead,
      'minHoursAhead': minHoursAhead,
      'durationOverride': durationOverride,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
      'customSettings': customSettings,
    };
  }

  SchedulableSession copyWith({
    String? id,
    String? instructorId,
    String? sessionTypeId,
    List<String>? locationIds,
    String? scheduleId,
    int? bufferBefore,
    int? bufferAfter,
    int? maxDaysAhead,
    int? minHoursAhead,
    int? durationOverride,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    Map<String, dynamic>? customSettings,
  }) {
    return SchedulableSession(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      sessionTypeId: sessionTypeId ?? this.sessionTypeId,
      locationIds: locationIds ?? this.locationIds,
      scheduleId: scheduleId ?? this.scheduleId,
      bufferBefore: bufferBefore ?? this.bufferBefore,
      bufferAfter: bufferAfter ?? this.bufferAfter,
      maxDaysAhead: maxDaysAhead ?? this.maxDaysAhead,
      minHoursAhead: minHoursAhead ?? this.minHoursAhead,
      durationOverride: durationOverride ?? this.durationOverride,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  // Helper methods for business logic
  
  /// Get the effective duration (override or from session type)
  int getEffectiveDuration(int sessionTypeDuration) {
    return durationOverride ?? sessionTypeDuration;
  }
  
  /// Calculate total time needed (duration + buffers)
  int getTotalTimeSlot(int sessionTypeDuration) {
    return bufferBefore + getEffectiveDuration(sessionTypeDuration) + bufferAfter;
  }
  
  /// Check if booking is within allowed time window
  bool isBookingAllowed(DateTime requestedDateTime) {
    final now = DateTime.now();
    final maxBookingDate = now.add(Duration(days: maxDaysAhead));
    final minBookingTime = now.add(Duration(hours: minHoursAhead));
    
    return requestedDateTime.isAfter(minBookingTime) && 
           requestedDateTime.isBefore(maxBookingDate);
  }
  
  /// Check if this schedulable session can accommodate a time slot
  bool canAccommodateTimeSlot(DateTime startTime, DateTime endTime, int sessionTypeDuration) {
    final requiredDuration = Duration(minutes: getTotalTimeSlot(sessionTypeDuration));
    final availableDuration = endTime.difference(startTime);
    
    return availableDuration >= requiredDuration;
  }

  @override
  String toString() {
    return 'SchedulableSession(id: $id, sessionTypeId: $sessionTypeId, '
           'scheduleId: $scheduleId, locationIds: $locationIds, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchedulableSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
