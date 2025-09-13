import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  http.Client? _authClient;

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

      // Try to load existing tokens first
      final existingTokens = await _loadStoredTokens();
      if (existingTokens != null) {
        final (accessToken, refreshToken) = existingTokens;
        
        // Try to use existing tokens
        if (await _validateAccessToken(accessToken)) {
          _createAuthenticatedClient(accessToken, refreshToken);
          print('✅ Using existing Google Calendar tokens');
          return true;
        } else if (refreshToken != null) {
          // Try to refresh the token
          final refreshed = await _refreshAccessToken(refreshToken);
          if (refreshed) {
            print('✅ Google Calendar tokens refreshed');
            return true;
          }
        }
        
        // Clear invalid tokens
        await _clearStoredTokens();
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
      
      print('🔗 Starting Google Calendar OAuth2 flow with client ID: ${clientId.substring(0, 12)}...');
      
      // Debug OAuth URL generation
      final redirectUri = '${html.window.location.origin}/oauth/callback';
      final scope = _scopes.join(' ');
      final state = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('🔍 Debug OAuth parameters:');
      print('   Client ID: $clientId');
      print('   Redirect URI: $redirectUri');
      print('   Scope: $scope');
      print('   State: $state');
      
      // Try different OAuth URL formats to see which works
      final authUrls = [
        // Google OAuth2 v2 endpoint
        'https://accounts.google.com/o/oauth2/v2/auth'
            '?client_id=$clientId'
            '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
            '&scope=${Uri.encodeComponent(scope)}'
            '&response_type=code'
            '&access_type=offline'
            '&prompt=consent'
            '&state=$state',
        
        // Alternative OAuth endpoint
        'https://accounts.google.com/oauth/authorize'
            '?client_id=$clientId'
            '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
            '&scope=${Uri.encodeComponent(scope)}'
            '&response_type=code'
            '&access_type=offline'
            '&prompt=consent'
            '&state=$state',
        
        // Google Identity Services approach
        'https://accounts.google.com/o/oauth2/auth'
            '?client_id=$clientId'
            '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
            '&scope=${Uri.encodeComponent(scope)}'
            '&response_type=code'
            '&access_type=offline'
            '&prompt=consent'
            '&state=$state',
      ];
      
      // Try the first URL format
      final authUrl = authUrls[0];
      print('🔗 Testing OAuth URL: $authUrl');
      
      // For now, let's use a direct redirect approach instead of popup
      // This avoids CORS issues but requires user to manually return
      print('🔗 Due to CORS restrictions, opening OAuth in same window');
      print('📋 Please complete authorization and return to the app');
      
      // Store the current page so we can return after OAuth
      html.window.localStorage['oauth_return_url'] = html.window.location.href;
      html.window.localStorage['oauth_state'] = state;
      
      // Redirect to OAuth URL in same window
      html.window.location.href = authUrl;
      
      // Return false for now - the real authentication will happen after redirect
      return false;
      
    } catch (e) {
      print('❌ Error in web auth initialization: $e');
      return false;
    }
  }

  /// Wait for authorization code using localStorage communication
  Future<String?> _waitForAuthorizationCode(html.WindowBase popup, String expectedState) async {
    print('⏳ Waiting for user authorization...');
    
    final completer = Completer<String?>();
    final storageKey = 'oauth_result_$expectedState';
    
    // Clear any existing OAuth result
    html.window.localStorage.remove(storageKey);
    
    // Poll localStorage for OAuth result
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        // Check if popup is closed
        if (popup.closed == true) {
          print('❌ OAuth popup was closed by user');
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }
        
        // Check localStorage for OAuth result
        final oauthResult = html.window.localStorage[storageKey];
        if (oauthResult != null) {
          popup.close();
          timer.cancel();
          
          try {
            final result = jsonDecode(oauthResult);
            final code = result['code'] as String?;
            final state = result['state'] as String?;
            final error = result['error'] as String?;
            
            // Clean up localStorage
            html.window.localStorage.remove(storageKey);
            
            if (error != null) {
              print('❌ OAuth error: $error');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
              return;
            }
            
            // Verify state parameter for CSRF protection
            if (state != expectedState) {
              print('❌ State parameter mismatch - possible CSRF attack');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
              return;
            }
            
            if (code != null) {
              print('✅ Authorization code received via localStorage');
              if (!completer.isCompleted) {
                completer.complete(code);
              }
            } else {
              print('❌ No authorization code in result');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            }
          } catch (e) {
            print('❌ Error parsing OAuth result: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        }
      } catch (e) {
        // Continue polling
      }
      
      // Timeout after 5 minutes
      if (timer.tick > 600) { // 600 * 500ms = 5 minutes
        popup.close();
        timer.cancel();
        print('❌ OAuth timeout - user took too long to authorize');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    });
    
    return await completer.future;
  }

  /// Exchange authorization code for access and refresh tokens
  Future<bool> exchangeCodeForTokens(String authCode, String redirectUri, String clientId) async {
    try {
      print('🔄 Exchanging authorization code for tokens...');
      
      // Create token exchange request
      final tokenUrl = 'https://oauth2.googleapis.com/token';
      final body = {
        'client_id': clientId,
        'code': authCode,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      };
      
      // Make token exchange request
      final request = html.HttpRequest();
      request.open('POST', tokenUrl);
      request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      
      final formData = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final completer = Completer<bool>();
      
      request.onLoad.listen((_) {
        if (request.status == 200) {
          try {
            final response = jsonDecode(request.responseText!);
            final accessToken = response['access_token'] as String?;
            final refreshToken = response['refresh_token'] as String?;
            
            if (accessToken != null) {
              // Create authenticated client
              _createAuthenticatedClient(accessToken, refreshToken);
              print('✅ Tokens received and client created');
              completer.complete(true);
            } else {
              print('❌ No access token in response');
              completer.complete(false);
            }
          } catch (e) {
            print('❌ Error parsing token response: $e');
            completer.complete(false);
          }
        } else {
          print('❌ Token exchange failed: ${request.status} ${request.responseText}');
          completer.complete(false);
        }
      });
      
      request.onError.listen((_) {
        print('❌ Network error during token exchange');
        completer.complete(false);
      });
      
      request.send(formData);
      
      return await completer.future;
    } catch (e) {
      print('❌ Error exchanging code for tokens: $e');
      return false;
    }
  }

  /// Create authenticated client with access token
  void _createAuthenticatedClient(String accessToken, String? refreshToken) {
    // Create a simple authenticated client
    _authClient = _SimpleAuthClient(accessToken, refreshToken);
    _calendarApi = calendar.CalendarApi(_authClient!);
    print('✅ Google Calendar API client created');
    
    // Store tokens for future use
    _storeTokens(accessToken, refreshToken);
  }

  /// Load stored tokens from SharedPreferences
  Future<(String, String?)?> _loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final accessToken = prefs.getString('gcal_access_token_${user.uid}');
      final refreshToken = prefs.getString('gcal_refresh_token_${user.uid}');
      
      if (accessToken != null) {
        return (accessToken, refreshToken);
      }
      
      return null;
    } catch (e) {
      print('❌ Error loading stored tokens: $e');
      return null;
    }
  }

  /// Store tokens in SharedPreferences
  Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await prefs.setString('gcal_access_token_${user.uid}', accessToken);
      if (refreshToken != null) {
        await prefs.setString('gcal_refresh_token_${user.uid}', refreshToken);
      }
      
      print('✅ Google Calendar tokens stored');
    } catch (e) {
      print('❌ Error storing tokens: $e');
    }
  }

  /// Clear stored tokens
  Future<void> _clearStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await prefs.remove('gcal_access_token_${user.uid}');
      await prefs.remove('gcal_refresh_token_${user.uid}');
      
      print('✅ Google Calendar tokens cleared');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  /// Validate access token by making a test API call
  Future<bool> _validateAccessToken(String accessToken) async {
    try {
      final request = html.HttpRequest();
      request.open('GET', 'https://www.googleapis.com/calendar/v3/users/me/calendarList');
      request.setRequestHeader('Authorization', 'Bearer $accessToken');
      
      final completer = Completer<bool>();
      
      request.onLoad.listen((_) {
        completer.complete(request.status == 200);
      });
      
      request.onError.listen((_) {
        completer.complete(false);
      });
      
      request.send();
      
      final isValid = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      
      print('🔍 Access token validation: ${isValid ? "valid" : "invalid"}');
      return isValid;
    } catch (e) {
      print('❌ Error validating access token: $e');
      return false;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken(String refreshToken) async {
    try {
      print('🔄 Refreshing Google Calendar access token...');
      
      final clientId = GoogleConfig.clientId;
      final tokenUrl = 'https://oauth2.googleapis.com/token';
      
      final body = {
        'client_id': clientId,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      };
      
      final request = html.HttpRequest();
      request.open('POST', tokenUrl);
      request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      
      final formData = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final completer = Completer<bool>();
      
      request.onLoad.listen((_) {
        if (request.status == 200) {
          try {
            final response = jsonDecode(request.responseText!);
            final newAccessToken = response['access_token'] as String?;
            final newRefreshToken = response['refresh_token'] as String? ?? refreshToken;
            
            if (newAccessToken != null) {
              _createAuthenticatedClient(newAccessToken, newRefreshToken);
              print('✅ Access token refreshed successfully');
              completer.complete(true);
            } else {
              print('❌ No access token in refresh response');
              completer.complete(false);
            }
          } catch (e) {
            print('❌ Error parsing refresh response: $e');
            completer.complete(false);
          }
        } else {
          print('❌ Token refresh failed: ${request.status} ${request.responseText}');
          completer.complete(false);
        }
      });
      
      request.onError.listen((_) {
        print('❌ Network error during token refresh');
        completer.complete(false);
      });
      
      request.send(formData);
      
      return await completer.future;
    } catch (e) {
      print('❌ Error refreshing access token: $e');
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

      // Check if we're using mock client for testing
      if (_authClient is _SimpleAuthClient && 
          (_authClient as _SimpleAuthClient).accessToken == 'mock_access_token') {
        // Mock event creation for testing
        final mockEventId = 'mock_event_${DateTime.now().millisecondsSinceEpoch}';
        print('✅ Mock calendar event created successfully: $mockEventId');
        print('🔗 Mock event details: $title at $location');
        print('👥 Mock attendees: $clientEmail, $instructorEmail');
        print('📅 Mock event time: ${startTime.toString()} - ${endTime.toString()}');
        return mockEventId;
      }

      // Real Google Calendar API call
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
      
      // Clear stored tokens
      await _clearStoredTokens();
      
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

/// Simple authenticated HTTP client for Google APIs
class _SimpleAuthClient extends http.BaseClient {
  final String _accessToken;
  final String? _refreshToken;
  final http.Client _client = http.Client();

  _SimpleAuthClient(this._accessToken, this._refreshToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add authorization header
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.headers['Accept'] = 'application/json';
    
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }

  /// Get the access token
  String get accessToken => _accessToken;

  /// Get the refresh token
  String? get refreshToken => _refreshToken;
}
