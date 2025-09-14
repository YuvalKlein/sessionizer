import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/services/cancellation_policy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CancellationPolicyService', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve agreement correctly', () async {
      // Arrange
      const userId = 'user-123';
      const sessionTypeId = 'session-type-456';

      // Act
      await CancellationPolicyService.saveAgreement(sessionTypeId, userId);
      final hasAgreed = await CancellationPolicyService.hasAgreed(sessionTypeId, userId);

      // Assert
      expect(hasAgreed, isTrue);
    });

    test('should return false for non-existent agreement', () async {
      // Arrange
      const userId = 'user-123';
      const sessionTypeId = 'session-type-456';

      // Act
      final hasAgreed = await CancellationPolicyService.hasAgreed(sessionTypeId, userId);

      // Assert
      expect(hasAgreed, isFalse);
    });

    test('should handle multiple agreements for same user', () async {
      // Arrange
      const userId = 'user-123';
      const sessionType1 = 'session-type-1';
      const sessionType2 = 'session-type-2';

      // Act
      await CancellationPolicyService.saveAgreement(sessionType1, userId);
      await CancellationPolicyService.saveAgreement(sessionType2, userId);

      // Assert
      expect(await CancellationPolicyService.hasAgreed(sessionType1, userId), isTrue);
      expect(await CancellationPolicyService.hasAgreed(sessionType2, userId), isTrue);
    });

    test('should isolate agreements between different users', () async {
      // Arrange
      const user1 = 'user-123';
      const user2 = 'user-456';
      const sessionTypeId = 'session-type-789';

      // Act
      await CancellationPolicyService.saveAgreement(sessionTypeId, user1);

      // Assert
      expect(await CancellationPolicyService.hasAgreed(sessionTypeId, user1), isTrue);
      expect(await CancellationPolicyService.hasAgreed(sessionTypeId, user2), isFalse);
    });

    test('should remove agreement correctly', () async {
      // Arrange
      const userId = 'user-123';
      const sessionTypeId = 'session-type-456';
      
      // Save agreement first
      await CancellationPolicyService.saveAgreement(sessionTypeId, userId);
      expect(await CancellationPolicyService.hasAgreed(sessionTypeId, userId), isTrue);

      // Act
      await CancellationPolicyService.removeAgreement(sessionTypeId, userId);

      // Assert
      expect(await CancellationPolicyService.hasAgreed(sessionTypeId, userId), isFalse);
    });
  });
}
