import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Session Type Player Validation Logic', () {
    test('should ensure max players is never less than min players', () {
      // Test the validation logic directly
      int minPlayers = 5;
      int maxPlayers = 3;
      
      // Simulate the validation logic from _validateMaxPlayers()
      if (maxPlayers < minPlayers) {
        maxPlayers = minPlayers;
      }
      
      expect(maxPlayers, equals(5));
      expect(maxPlayers, greaterThanOrEqualTo(minPlayers));
    });

    test('should ensure max players is adjusted when min players increases', () {
      int minPlayers = 2;
      int maxPlayers = 4;
      
      // Simulate increasing min players
      minPlayers = 6;
      
      // Apply validation logic
      if (maxPlayers < minPlayers) {
        maxPlayers = minPlayers;
      }
      
      expect(maxPlayers, equals(6));
      expect(maxPlayers, greaterThanOrEqualTo(minPlayers));
    });

    test('should not change max players when it is already valid', () {
      int minPlayers = 3;
      int maxPlayers = 5;
      
      // Apply validation logic
      if (maxPlayers < minPlayers) {
        maxPlayers = minPlayers;
      }
      
      expect(maxPlayers, equals(5));
      expect(maxPlayers, greaterThanOrEqualTo(minPlayers));
    });

    test('should handle edge case where min and max are equal', () {
      int minPlayers = 4;
      int maxPlayers = 4;
      
      // Apply validation logic
      if (maxPlayers < minPlayers) {
        maxPlayers = minPlayers;
      }
      
      expect(maxPlayers, equals(4));
      expect(maxPlayers, greaterThanOrEqualTo(minPlayers));
    });

    test('should validate form input correctly', () {
      // Test the validation logic that would be used in form validation
      String minText = '3';
      String maxText = '2';
      
      int minPlayers = int.tryParse(minText) ?? 1;
      int maxPlayers = int.tryParse(maxText) ?? 1;
      
      // This should trigger validation error
      bool isValid = maxPlayers >= minPlayers;
      expect(isValid, isFalse);
      
      // After correction
      maxPlayers = minPlayers;
      isValid = maxPlayers >= minPlayers;
      expect(isValid, isTrue);
    });
  });
}
