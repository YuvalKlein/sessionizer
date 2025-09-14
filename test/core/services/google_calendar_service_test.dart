import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/services/google_calendar_service.dart';

void main() {
  group('GoogleCalendarService', () {
    late GoogleCalendarService service;

    setUp(() {
      service = GoogleCalendarService.instance;
    });

    test('should be a singleton', () {
      // Act
      final instance1 = GoogleCalendarService.instance;
      final instance2 = GoogleCalendarService.instance;

      // Assert
      expect(instance1, same(instance2));
    });

    test('should start with calendar sync enabled', () {
      // Act
      final isEnabled = service.isCalendarSyncEnabled();

      // Assert
      expect(isEnabled, isTrue);
    });

    test('should allow toggling calendar sync', () {
      // Act
      service.setCalendarSyncEnabled(false);
      final isDisabled = service.isCalendarSyncEnabled();
      
      service.setCalendarSyncEnabled(true);
      final isEnabled = service.isCalendarSyncEnabled();

      // Assert
      expect(isDisabled, isFalse);
      expect(isEnabled, isTrue);
    });

    test('should start as not connected', () {
      // Act
      final isConnected = service.isConnected;

      // Assert
      expect(isConnected, isFalse);
    });

    test('should handle createBookingEvent when not connected', () async {
      // Act
      final result = await service.createBookingEvent(
        bookingId: 'booking-123',
        title: 'Test Session',
        description: 'Test Description',
        startTime: DateTime.now().add(Duration(hours: 2)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        location: 'Test Location',
        clientEmail: 'client@example.com',
        instructorEmail: 'instructor@example.com',
      );

      // Assert
      expect(result, isNull); // Should return null when not connected
    });

    test('should handle updateBookingEvent when not connected', () async {
      // Act
      final result = await service.updateBookingEvent(
        eventId: 'event-123',
        title: 'Updated Session',
        description: 'Updated Description',
        startTime: DateTime.now().add(Duration(hours: 2)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        location: 'Updated Location',
      );

      // Assert
      expect(result, isFalse); // Should return false when not connected
    });

    test('should handle deleteBookingEvent when not connected', () async {
      // Act
      final result = await service.deleteBookingEvent('event-123');

      // Assert
      expect(result, isFalse); // Should return false when not connected
    });
  });

  group('GoogleCalendarService - Edge Cases', () {
    late GoogleCalendarService service;

    setUp(() {
      service = GoogleCalendarService.instance;
    });

    test('should handle empty attendee list', () async {
      // Act
      final result = await service.createBookingEvent(
        bookingId: 'booking-123',
        title: 'Test Session',
        description: 'Test Description',
        startTime: DateTime.now().add(Duration(hours: 2)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        location: 'Test Location',
        clientEmail: '',
        instructorEmail: '',
      );

      // Assert
      expect(result, isNull); // Should handle gracefully
    });

    test('should handle null description', () async {
      // Act
      final result = await service.createBookingEvent(
        bookingId: 'booking-123',
        title: 'Test Session',
        description: '', // Empty description
        startTime: DateTime.now().add(Duration(hours: 2)),
        endTime: DateTime.now().add(Duration(hours: 3)),
        location: 'Test Location',
        clientEmail: 'test@example.com',
        instructorEmail: 'instructor@example.com',
      );

      // Assert
      expect(result, isNull); // Should handle gracefully
    });

    test('should handle past booking times gracefully', () async {
      // Act
      final result = await service.createBookingEvent(
        bookingId: 'booking-123',
        title: 'Past Session',
        description: 'Past session test',
        startTime: DateTime.now().subtract(Duration(hours: 2)), // Past time
        endTime: DateTime.now().subtract(Duration(hours: 1)),
        location: 'Test Location',
        clientEmail: 'test@example.com',
        instructorEmail: 'instructor@example.com',
      );

      // Assert
      expect(result, isNull); // Should handle gracefully
    });
  });
}
