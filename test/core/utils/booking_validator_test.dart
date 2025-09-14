import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/utils/booking_validator.dart';

void main() {
  group('BookingValidator - Booking Time Validation', () {
    test('should allow booking when time is after minimum hours ahead', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 14, 14, 0); // 2:00 PM (4 hours later)
      const minHoursAhead = 2;

      // Act
      final result = BookingValidator.isBookingTimeValid(
        bookingTime: bookingTime,
        minHoursAhead: minHoursAhead,
        currentTime: currentTime,
      );

      // Assert
      expect(result, isTrue);
    });

    test('should reject booking when time is before minimum hours ahead', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 14, 11, 0); // 11:00 AM (1 hour later)
      const minHoursAhead = 2;

      // Act
      final result = BookingValidator.isBookingTimeValid(
        bookingTime: bookingTime,
        minHoursAhead: minHoursAhead,
        currentTime: currentTime,
      );

      // Assert
      expect(result, isFalse);
    });

    test('should handle exact minimum hours ahead boundary', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 14, 12, 0); // 12:00 PM (exactly 2 hours later)
      const minHoursAhead = 2;

      // Act
      final result = BookingValidator.isBookingTimeValid(
        bookingTime: bookingTime,
        minHoursAhead: minHoursAhead,
        currentTime: currentTime,
      );

      // Assert
      expect(result, isFalse); // Should be false because it's not AFTER the minimum time
    });
  });

  group('BookingValidator - Cancellation Window', () {
    test('should detect when within cancellation window', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 14, 11, 0); // 11:00 AM
      const cancellationTimeBeforeMinutes = 120; // 2 hours = 120 minutes

      // Act
      final result = BookingValidator.isWithinCancellationWindow(
        bookingTime: bookingTime,
        cancellationTimeBeforeMinutes: cancellationTimeBeforeMinutes,
        currentTime: currentTime,
      );

      // Assert
      expect(result, isTrue); // Within cancellation window (1 hour before, but policy is 2 hours)
    });

    test('should detect when outside cancellation window', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 8, 0); // 8:00 AM
      final bookingTime = DateTime(2025, 9, 14, 11, 0); // 11:00 AM
      const cancellationTimeBeforeMinutes = 120; // 2 hours = 120 minutes

      // Act
      final result = BookingValidator.isWithinCancellationWindow(
        bookingTime: bookingTime,
        cancellationTimeBeforeMinutes: cancellationTimeBeforeMinutes,
        currentTime: currentTime,
      );

      // Assert
      expect(result, isFalse); // Outside cancellation window (3 hours before, policy is 2 hours)
    });
  });

  group('BookingValidator - Cancellation Fee Calculation', () {
    test('should calculate percentage-based fee correctly', () {
      // Act
      final result = BookingValidator.calculateCancellationFee(
        sessionPrice: 120,
        feeAmount: 50,
        feeType: '%',
      );

      // Assert
      expect(result, equals(60)); // 50% of $120 = $60
    });

    test('should return fixed dollar amount', () {
      // Act
      final result = BookingValidator.calculateCancellationFee(
        sessionPrice: 200,
        feeAmount: 25,
        feeType: r'$',
      );

      // Assert
      expect(result, equals(25)); // Fixed $25
    });

    test('should handle percentage rounding', () {
      // Act
      final result = BookingValidator.calculateCancellationFee(
        sessionPrice: 77,
        feeAmount: 13,
        feeType: '%',
      );

      // Assert
      expect(result, equals(10)); // 13% of $77 = $10.01, rounded to $10
    });
  });

  group('BookingValidator - Complete Booking Validation', () {
    test('should allow valid booking within all constraints', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 16, 14, 0); // Sept 16, 2:00 PM (2 days later)

      // Act
      final result = BookingValidator.validateBooking(
        bookingTime: bookingTime,
        minHoursAhead: 2,
        maxDaysAhead: 7,
        currentTime: currentTime,
      );

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('should reject booking too close to current time', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 14, 11, 0); // 11:00 AM (1 hour later)

      // Act
      final result = BookingValidator.validateBooking(
        bookingTime: bookingTime,
        minHoursAhead: 2,
        maxDaysAhead: 7,
        currentTime: currentTime,
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('at least 2 hours in advance'));
    });

    test('should reject booking too far in the future', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 25, 14, 0); // Sept 25 (11 days later)

      // Act
      final result = BookingValidator.validateBooking(
        bookingTime: bookingTime,
        minHoursAhead: 2,
        maxDaysAhead: 7,
        currentTime: currentTime,
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('cannot be more than 7 days in advance'));
    });

    test('should reject booking in the past', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 13, 14, 0); // Yesterday

      // Act
      final result = BookingValidator.validateBooking(
        bookingTime: bookingTime,
        minHoursAhead: 2,
        maxDaysAhead: 7,
        currentTime: currentTime,
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Cannot book sessions in the past'));
    });

    test('should handle edge case at maximum days boundary', () {
      // Arrange
      final currentTime = DateTime(2025, 9, 14, 10, 0); // 10:00 AM
      final bookingTime = DateTime(2025, 9, 21, 9, 0); // Exactly 7 days later, but 1 hour earlier

      // Act
      final result = BookingValidator.validateBooking(
        bookingTime: bookingTime,
        minHoursAhead: 2,
        maxDaysAhead: 7,
        currentTime: currentTime,
      );

      // Assert
      expect(result.isValid, isTrue); // Should be valid as it's within 7 days
    });
  });
}
