# Google Calendar Integration Setup

This guide explains how to set up Google Calendar integration for the Sessionizer app.

## 🎯 Features Implemented

✅ **Automatic Calendar Event Creation**: When a booking is confirmed, a calendar event is automatically created  
✅ **Guest List Management**: Both client and instructor are added as guests to the calendar event  
✅ **User Settings**: Users can enable/disable Google Calendar sync in their profile  
✅ **Event Details**: Includes session type, location, notes, and booking ID  
✅ **Reminders**: Automatic email (1 hour) and popup (15 minutes) reminders  

## 🔧 Setup Instructions

### Step 1: Google Cloud Console Setup

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project** (apiclientapp) or create a new one
3. **Enable Google Calendar API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### Step 2: Create OAuth2 Credentials

1. **Go to "APIs & Services" > "Credentials"**
2. **Click "Create Credentials" > "OAuth client ID"**
3. **Configure the OAuth consent screen** (if not done already):
   - User Type: External
   - App name: ARENNA
   - User support email: yuklein@gmail.com
   - Developer contact: yuklein@gmail.com
4. **Create OAuth2 Client ID**:
   - Application type: Web application
   - Name: ARENNA Calendar Sync
   - Authorized JavaScript origins:
     - `https://apiclientapp.web.app`
     - `http://localhost:8080` (for development)
     - `http://localhost:8081` (for development)
     - `http://localhost:8082` (for development)
   - Authorized redirect URIs:
     - `https://apiclientapp.web.app/oauth/callback`
     - `http://localhost:8080/oauth/callback` (for development)
     - `http://localhost:8081/oauth/callback` (for development)
     - `http://localhost:8082/oauth/callback` (for development)

### Step 3: Client ID Configuration

✅ **Already Configured**: Your client ID has been securely configured in the system.

**Security Note**: The client ID is stored in `lib/core/config/google_config.dart` and can be overridden via environment variables for additional security in production deployments.

### Step 4: Default Settings

✅ **Google Calendar Sync Enabled by Default**: All users now have Google Calendar sync enabled by default. They can disable it in their profile settings if desired.

### Step 5: Test the Integration

1. **Build and deploy the app**:
   ```bash
   ./build_production.ps1
   firebase deploy --only hosting
   ```

2. **Test the flow**:
   - Create a test booking (Google Calendar sync is enabled by default)
   - Authorize access to Google Calendar when prompted
   - Check that the event appears in Google Calendar
   - Both client and instructor should receive calendar invites

## 🔄 How It Works

### User Flow
1. **Default Enabled**: Google Calendar sync is enabled by default for all users
2. **Authentication**: OAuth2 popup for Google Calendar authorization (when first needed)
3. **Booking Creation**: When booking is confirmed, calendar event is automatically created
4. **Guest Management**: Both client and instructor receive calendar invites

### Technical Flow
1. **Authentication**: Uses `googleapis_auth` package for OAuth2
2. **API Calls**: Uses `googleapis` package for Calendar API
3. **Event Creation**: Creates events with attendees, reminders, and details
4. **Data Storage**: Saves `googleCalendarEventId` in booking document

## 📋 Event Details

Each calendar event includes:
- **Title**: "SessionType with InstructorName"
- **Description**: Session details, booking ID, notes
- **Attendees**: Client and instructor emails
- **Location**: Session location name
- **Reminders**: Email (1 hour) + Popup (15 minutes)
- **Permissions**: Guests cannot modify or invite others

## 🔒 Security & Privacy

- **Minimal Permissions**: Only requests calendar read/write access
- **User Control**: Users can disable sync anytime
- **Data Protection**: No calendar data stored in our database
- **Event Ownership**: Events created in user's primary calendar

## 🐛 Troubleshooting

### Common Issues

1. **"Failed to connect to Google Calendar"**:
   - Check OAuth2 client ID is correct
   - Verify authorized domains in Google Cloud Console
   - Ensure Calendar API is enabled

2. **Calendar events not created**:
   - Check browser console for errors
   - Verify user has Calendar sync enabled
   - Check Firebase logs for authentication issues

3. **Permission denied errors**:
   - Re-authorize Google Calendar access
   - Check OAuth consent screen configuration

### Development Testing

For local development:
1. Use `http://localhost:8080` in OAuth settings
2. Run: `flutter run -d chrome --web-port=8080`
3. Test with development environment (DevData collections)

## 📊 Database Structure

### User Document
```json
{
  "googleCalendarSync": {
    "enabled": true,
    "calendarId": "primary",
    "connectedAt": "2025-01-15T10:30:00Z"
  }
}
```

### Booking Document
```json
{
  "googleCalendarEventId": "abc123def456",
  "calendarSyncEnabled": true
}
```

## 🚀 Future Enhancements

Potential improvements:
- **Two-way sync**: Update bookings when calendar events change
- **Multiple calendars**: Allow users to choose which calendar to sync to
- **Bulk operations**: Sync existing bookings to calendar
- **Timezone handling**: Better timezone support for events
- **Conflict detection**: Check for calendar conflicts before booking

---

**Need help?** Contact yuklein@gmail.com for setup assistance.
