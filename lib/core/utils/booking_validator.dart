/// Utility class for booking validation logic
class BookingValidator {
  /// Check if a booking time is valid based on minimum hours ahead requirement
  static bool isBookingTimeValid({
    required DateTime bookingTime,
    required int minHoursAhead,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final minAllowedTime = now.add(Duration(hours: minHoursAhead));
    return bookingTime.isAfter(minAllowedTime);
  }

  /// Check if a cancellation is within the cancellation window
  static bool isWithinCancellationWindow({
    required DateTime bookingTime,
    required int cancellationTimeBeforeMinutes,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final cancellationDeadline = bookingTime.subtract(Duration(minutes: cancellationTimeBeforeMinutes));
    return now.isAfter(cancellationDeadline);
  }

  /// Calculate cancellation fee based on session price and policy
  static int calculateCancellationFee({
    required int sessionPrice,
    required int feeAmount,
    required String feeType,
  }) {
    if (feeType == '%') {
      return (feeAmount * sessionPrice / 100).round();
    } else {
      return feeAmount;
    }
  }

  /// Check if user can book a session (combines multiple validation rules)
  static BookingValidationResult validateBooking({
    required DateTime bookingTime,
    required int minHoursAhead,
    required int maxDaysAhead,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    
    // Check if booking is in the past (highest priority)
    if (bookingTime.isBefore(now)) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Cannot book sessions in the past.',
      );
    }

    // Check minimum hours ahead
    if (!isBookingTimeValid(
      bookingTime: bookingTime,
      minHoursAhead: minHoursAhead,
      currentTime: now,
    )) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Booking must be at least $minHoursAhead hours in advance.',
      );
    }

    // Check maximum days ahead
    final maxAllowedTime = now.add(Duration(days: maxDaysAhead));
    if (bookingTime.isAfter(maxAllowedTime)) {
      return BookingValidationResult(
        isValid: false,
        errorMessage: 'Booking cannot be more than $maxDaysAhead days in advance.',
      );
    }

    return BookingValidationResult(isValid: true);
  }
}

/// Result of booking validation
class BookingValidationResult {
  final bool isValid;
  final String? errorMessage;

  const BookingValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
