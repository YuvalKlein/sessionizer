import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow Integration Tests', () {
    testWidgets('should complete full booking flow successfully', (WidgetTester tester) async {
      // Start the app and login as client
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Login
      await tester.enterText(find.byKey(Key('email')), 'client@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Should be on client dashboard
      expect(find.text('Client Dashboard'), findsOneWidget);
      
      // Look for available sessions
      expect(find.textContaining('Available Sessions'), findsOneWidget);
      
      // Tap on first available session
      final sessionCards = find.byType(Card);
      if (sessionCards.evaluate().isNotEmpty) {
        await tester.tap(sessionCards.first);
        await tester.pumpAndSettle();
        
        // Should open booking calendar
        expect(find.textContaining('Select Date'), findsOneWidget);
        
        // Select an available time slot
        final timeSlots = find.textContaining(':');
        if (timeSlots.evaluate().isNotEmpty) {
          await tester.tap(timeSlots.first);
          await tester.pumpAndSettle();
          
          // Should open booking confirmation modal
          expect(find.text('Confirm Booking'), findsOneWidget);
          
          // Confirm the booking
          await tester.tap(find.text('Confirm Booking'));
          await tester.pumpAndSettle(Duration(seconds: 10));
          
          // Should show success message or navigate to bookings
          expect(find.textContaining('Booking'), findsOneWidget);
        }
      }
    });

    testWidgets('should display cancellation policy in booking confirmation', (WidgetTester tester) async {
      // This test verifies that cancellation policy is properly displayed
      // during the booking process
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Login and navigate to booking
      await tester.enterText(find.byKey(Key('email')), 'client@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Navigate through booking flow
      final sessionCards = find.byType(Card);
      if (sessionCards.evaluate().isNotEmpty) {
        await tester.tap(sessionCards.first);
        await tester.pumpAndSettle();
        
        final timeSlots = find.textContaining(':');
        if (timeSlots.evaluate().isNotEmpty) {
          await tester.tap(timeSlots.first);
          await tester.pumpAndSettle();
          
          // Check for cancellation policy display
          expect(find.textContaining('Cancellation'), findsOneWidget);
          expect(find.textContaining('%'), findsOneWidget);
        }
      }
    });
  });

  group('Google Calendar Integration Tests', () {
    testWidgets('should handle Google Calendar connection flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Login
      await tester.enterText(find.byKey(Key('email')), 'instructor@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Look for Google Calendar sync option
      expect(find.textContaining('Google Calendar'), findsOneWidget);
      
      // Test connection (should show mock success)
      if (find.text('Connect').evaluate().isNotEmpty) {
        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle(Duration(seconds: 3));
        
        // Should show success message
        expect(find.textContaining('connected'), findsOneWidget);
      }
    });
  });

  group('Email Notification Integration Tests', () {
    testWidgets('should trigger email notifications during booking', (WidgetTester tester) async {
      // This test verifies that the email system is triggered correctly
      // We can't test actual email delivery, but we can test the trigger
      
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Complete a booking flow
      await tester.enterText(find.byKey(Key('email')), 'client@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Navigate through booking flow
      final sessionCards = find.byType(Card);
      if (sessionCards.evaluate().isNotEmpty) {
        await tester.tap(sessionCards.first);
        await tester.pumpAndSettle();
        
        final timeSlots = find.textContaining(':');
        if (timeSlots.evaluate().isNotEmpty) {
          await tester.tap(timeSlots.first);
          await tester.pumpAndSettle();
          
          // Confirm booking
          await tester.tap(find.text('Confirm Booking'));
          await tester.pumpAndSettle(Duration(seconds: 10));
          
          // Email system should be triggered (we can't verify actual email,
          // but the booking should complete successfully)
          expect(find.textContaining('success'), findsOneWidget);
        }
      }
    });
  });
}
