import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

void main() {
  group('SessionTypeEntity - Cancellation Fee Calculations', () {
    test('should return 0 when hasCancellationFee is false', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 100,
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        hasCancellationFee: false,
        cancellationFeeAmount: 50,
        cancellationFeeType: '%',
      );

      // Act
      final result = sessionType.getActualCancellationFee();

      // Assert
      expect(result, equals(0));
    });

    test('should calculate percentage-based cancellation fee correctly', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 120, // $120 session
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        hasCancellationFee: true,
        cancellationFeeAmount: 50, // 50%
        cancellationFeeType: '%',
      );

      // Act
      final result = sessionType.getActualCancellationFee();

      // Assert
      expect(result, equals(60)); // 50% of $120 = $60
    });

    test('should return fixed dollar amount when type is dollar', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 200, // Price doesn't matter for fixed fee
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        hasCancellationFee: true,
        cancellationFeeAmount: 25, // $25 fixed fee
        cancellationFeeType: r'$',
      );

      // Act
      final result = sessionType.getActualCancellationFee();

      // Assert
      expect(result, equals(25)); // Fixed $25 regardless of session price
    });

    test('should handle 100% cancellation fee correctly', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 150,
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        hasCancellationFee: true,
        cancellationFeeAmount: 100, // 100%
        cancellationFeeType: '%',
      );

      // Act
      final result = sessionType.getActualCancellationFee();

      // Assert
      expect(result, equals(150)); // 100% of $150 = $150
    });
  });

  group('SessionTypeEntity - Cancellation Time Calculations', () {
    test('should convert hours to minutes correctly', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 100,
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        cancellationTimeBefore: 24,
        cancellationTimeUnit: 'hours',
      );

      // Act
      final result = sessionType.getCancellationTimeInMinutes();

      // Assert
      expect(result, equals(1440)); // 24 hours = 1440 minutes
    });

    test('should return minutes directly when unit is minutes', () {
      // Arrange
      final sessionType = SessionTypeEntity(
        id: 'test-id',
        title: 'Test Session',
        createdTime: DateTime.now().millisecondsSinceEpoch,
        duration: 60,
        price: 100,
        idCreatedBy: 'instructor-1',
        maxPlayers: 1,
        cancellationTimeBefore: 120,
        cancellationTimeUnit: 'minutes',
      );

      // Act
      final result = sessionType.getCancellationTimeInMinutes();

      // Assert
      expect(result, equals(120)); // 120 minutes = 120 minutes
    });
  });
}
