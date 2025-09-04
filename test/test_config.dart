import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

class TestConfig {
  static late FakeFirebaseFirestore fakeFirestore;
  static late MockFirebaseAuth mockAuth;
  static late MockGoogleSignIn mockGoogleSignIn;

  static void setup() {
    // Initialize test dependencies
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
  }

  static void tearDown() {
    // Clean up test dependencies
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
  }
}

// Test data constants
class TestData {
  static const String testUserId = 'test_user_123';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testDisplayName = 'Test User';
  
  static const String instructorUserId = 'instructor_123';
  static const String instructorEmail = 'instructor@example.com';
  static const String instructorDisplayName = 'Test Instructor';
  
  static const String testSessionId = 'session_123';
  static const String testBookingId = 'booking_123';
  
  static const Duration testTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
}

// Test helpers
class TestHelpers {
  static Future<void> pumpAndSettleWithTimeout(WidgetTester tester, {Duration? timeout}) async {
    await tester.pumpAndSettle(timeout ?? TestData.shortTimeout);
  }
  
  static Future<void> waitForWidget(WidgetTester tester, Finder finder, {Duration? timeout}) async {
    await tester.pumpAndSettle();
    await tester.pump(Duration(milliseconds: 100));
    
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds with 100ms intervals
    
    while (find.byType(finder).evaluate().isEmpty && attempts < maxAttempts) {
      await tester.pump(Duration(milliseconds: 100));
      attempts++;
    }
    
    if (attempts >= maxAttempts) {
      throw Exception('Widget not found within timeout: $finder');
    }
  }
}
