import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/config/environment_config.dart';
import 'package:myapp/core/config/google_config.dart';

/// Service for integrating with Google Calendar API
class GoogleCalendarService {
  static const List<String> _scopes = [
    calendar.CalendarApi.calendarScope,
  ];

  static GoogleCalendarService? _instance;
  calendar.CalendarApi? _calendarApi;
  auth.AutoRefreshingAuthClient? _authClient;

  GoogleCalendarService._();

  static GoogleCalendarService get instance {
    _instance ??= GoogleCalendarService._();
    return _instance!;
  }

  /// Initialize Google Calendar service with authentication
  Future<bool> initialize() async {
    try {
      print('🗓️ Initializing Google Calendar service...');
      
      // Check if user is authenticated with Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated with Firebase');
        return false;
      }

      // For web platform, we'll use OAuth2 flow
      if (EnvironmentConfig.isWeb) {
        return await _initializeWebAuth();
      } else {
        print('❌ Google Calendar sync only supported on web platform');
        return false;
      }
    } catch (e) {
      print('❌ Error initializing Google Calendar service: $e');
      return false;
    }
  }

  /// Initialize web-based OAuth2 authentication
  Future<bool> _initializeWebAuth() async {
    try {
      // Get client ID from secure configuration
      final clientId = GoogleConfig.clientId;
      
      if (!GoogleConfig.isAvailable) {
        print('❌ Google Calendar integration not configured');
        return false;
      }
      
      // For now, we'll simulate successful initialization
      // This will need proper OAuth2 implementation when ready for production
      print('🔗 Google Calendar OAuth2 flow would start here with client ID: ${clientId.substring(0, 12)}...');
      print('⚠️ Google Calendar integration is configured but OAuth2 flow needs implementation');
      
      // TODO: Implement proper OAuth2 flow using googleapis_auth
      // This is a placeholder that allows the rest of the system to work
      return false; // Return false until proper OAuth2 is implemented
      
    } catch (e) {
      print('❌ Error in web auth initialization: $e');
      return false;
    }
  }

  /// Check if Google Calendar is connected and authenticated
  bool get isConnected => _calendarApi != null && _authClient != null;

  /// Create a calendar event for a booking
  Future<String?> createBookingEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String clientEmail,
    required String instructorEmail,
    required String clientName,
    required String instructorName,
    String? location,
  }) async {
    if (!isConnected) {
      print('❌ Google Calendar not connected');
      return null;
    }

    try {
      print('🗓️ Creating calendar event: $title');

      final event = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: startTime,
          timeZone: 'America/New_York', // TODO: Make this configurable
        ),
        end: calendar.EventDateTime(
          dateTime: endTime,
          timeZone: 'America/New_York', // TODO: Make this configurable
        ),
        location: location,
        attendees: [
          calendar.EventAttendee(
            email: clientEmail,
            displayName: clientName,
            responseStatus: 'needsAction',
          ),
          calendar.EventAttendee(
            email: instructorEmail,
            displayName: instructorName,
            responseStatus: 'accepted', // Instructor auto-accepts
          ),
        ],
        reminders: calendar.EventReminders(
          useDefault: false,
          overrides: [
            calendar.EventReminder(
              method: 'email',
              minutes: 60, // 1 hour before
            ),
            calendar.EventReminder(
              method: 'popup',
              minutes: 15, // 15 minutes before
            ),
          ],
        ),
        guestsCanModify: false,
        guestsCanInviteOthers: false,
        guestsCanSeeOtherGuests: true,
      );

      // Create the event in the primary calendar
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      
      print('✅ Calendar event created successfully: ${createdEvent.id}');
      print('🔗 Event link: ${createdEvent.htmlLink}');
      
      return createdEvent.id;
    } catch (e) {
      print('❌ Error creating calendar event: $e');
      return null;
    }
  }

  /// Update an existing calendar event
  Future<bool> updateBookingEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String clientEmail,
    required String instructorEmail,
    required String clientName,
    required String instructorName,
    String? location,
  }) async {
    if (!isConnected) {
      print('❌ Google Calendar not connected');
      return false;
    }

    try {
      print('🗓️ Updating calendar event: $eventId');

      final event = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: startTime,
          timeZone: 'America/New_York', // TODO: Make this configurable
        ),
        end: calendar.EventDateTime(
          dateTime: endTime,
          timeZone: 'America/New_York', // TODO: Make this configurable
        ),
        location: location,
        attendees: [
          calendar.EventAttendee(
            email: clientEmail,
            displayName: clientName,
            responseStatus: 'needsAction',
          ),
          calendar.EventAttendee(
            email: instructorEmail,
            displayName: instructorName,
            responseStatus: 'accepted',
          ),
        ],
      );

      await _calendarApi!.events.update(event, 'primary', eventId);
      
      print('✅ Calendar event updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating calendar event: $e');
      return false;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteBookingEvent(String eventId) async {
    if (!isConnected) {
      print('❌ Google Calendar not connected');
      return false;
    }

    try {
      print('🗓️ Deleting calendar event: $eventId');
      
      await _calendarApi!.events.delete('primary', eventId);
      
      print('✅ Calendar event deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting calendar event: $e');
      return false;
    }
  }

  /// Get user's calendar list
  Future<List<calendar.CalendarListEntry>> getCalendars() async {
    if (!isConnected) {
      print('❌ Google Calendar not connected');
      return [];
    }

    try {
      final calendarList = await _calendarApi!.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      print('❌ Error getting calendar list: $e');
      return [];
    }
  }

  /// Disconnect from Google Calendar
  Future<void> disconnect() async {
    try {
      _authClient?.close();
      _authClient = null;
      _calendarApi = null;
      print('✅ Disconnected from Google Calendar');
    } catch (e) {
      print('❌ Error disconnecting from Google Calendar: $e');
    }
  }

  /// Check if a user has Google Calendar sync enabled (default: true)
  static bool isCalendarSyncEnabled(Map<String, dynamic>? userData) {
    // Default to true if not explicitly set to false
    final syncData = userData?['googleCalendarSync'];
    if (syncData == null) return true; // Default enabled for new users
    return syncData['enabled'] != false; // Enabled unless explicitly disabled
  }

  /// Get the calendar ID for a user (defaults to 'primary')
  static String getCalendarId(Map<String, dynamic>? userData) {
    return userData?['googleCalendarSync']?['calendarId'] ?? 'primary';
  }
}
