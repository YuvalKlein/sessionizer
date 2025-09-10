# Email System Environment Configuration Guide

## 🎯 Overview

The email system now automatically detects the environment and chooses the appropriate email service:

- **Development**: Uses `WebEmailService` with console logging
- **Production**: Uses `FirebaseEmailService` with real email sending

## 🔧 How It Works

### Environment Detection

The system uses `EnvironmentConfig` class to detect:

1. **Development Mode**: `kDebugMode` or `!kReleaseMode`
2. **Production Mode**: `kReleaseMode` and `!kDebugMode`
3. **Platform**: Web vs Mobile
4. **API Key**: Presence of `SENDGRID_API_KEY` environment variable

### Email Service Selection Logic

```dart
if (EnvironmentConfig.shouldUseRealEmail) {
  // Production: Use FirebaseEmailService for real email sending
  return FirebaseEmailService();
} else {
  // Development: Use WebEmailService for console logging
  return WebEmailService();
}
```

## 🚀 Usage

### Development (Default)

```bash
# Run in development mode - emails logged to console
flutter run -d chrome --web-port=8080
```

**Result**: 
- ✅ Console logging of email content
- ❌ No real emails sent
- 🔧 Perfect for development and testing

### Production

```bash
# Build for production with real email sending
.\build_production.ps1
```

**Result**:
- ✅ Real emails sent via SendGrid
- ✅ Professional HTML/text templates
- ✅ Instructor notifications

### Development Build

```bash
# Build for development with console logging
.\build_development.ps1
```

## 📁 Files Created

### Core Files
- `lib/core/config/environment_config.dart` - Environment detection logic
- `lib/core/utils/injection_container.dart` - Updated with smart factory

### Build Scripts
- `build_production.ps1` - Production build with real email
- `build_development.ps1` - Development build with console logging

## 🔍 Environment Detection Details

### Development Mode
- **Condition**: `kDebugMode` is true
- **Email Service**: `WebEmailService`
- **Behavior**: Logs email content to console
- **Use Case**: Development, testing, debugging

### Production Mode
- **Condition**: `kReleaseMode` is true AND `SENDGRID_API_KEY` is provided
- **Email Service**: `FirebaseEmailService`
- **Behavior**: Sends real emails via SendGrid
- **Use Case**: Live production environment

### Fallback
- **Condition**: Production mode but no API key OR error creating FirebaseEmailService
- **Email Service**: `WebEmailService`
- **Behavior**: Logs email content to console
- **Use Case**: Graceful degradation

## 🎛️ Environment Variables

### Required for Production
```bash
SENDGRID_API_KEY=your_sendgrid_api_key_here
SENDGRID_FROM_EMAIL=noreply@arenna.link
SENDGRID_FROM_NAME=ARENNA
```

### Development
No environment variables needed - uses console logging by default.

## 📊 Console Output

### Development Mode
```
🔧 Environment Configuration:
   - Mode: Development
   - Platform: Web
   - Email Service: WebEmailService (Development/Console)
   - Real Email: No

📧 WEB EMAIL SERVICE - Email would be sent:
📧 To: yuklein@gmail.com
📧 Subject: Booking Confirmed! 🎉
📧 HTML Content Length: 1008 characters
✅ WEB EMAIL SERVICE - Email "sent" successfully
```

### Production Mode
```
🔧 Environment Configuration:
   - Mode: Production
   - Platform: Web
   - Email Service: FirebaseEmailService (Production)
   - Real Email: Yes

📧 Calling Firebase Function to send email to: yuklein@gmail.com
✅ Email sent successfully via Firebase Function
```

## 🛠️ Customization

### Adding New Environment Detection

Edit `lib/core/config/environment_config.dart`:

```dart
static bool get shouldUseRealEmail {
  // Add your custom logic here
  if (isProduction && isWeb && hasApiKey) {
    return true;
  }
  return false;
}
```

### Adding New Email Services

1. Create new service implementing `EmailService`
2. Update `_createEmailService()` in `injection_container.dart`
3. Add environment detection logic

## 🚨 Troubleshooting

### Emails Not Sending in Production
1. Check if `SENDGRID_API_KEY` is set
2. Verify Firebase Functions are deployed
3. Check console for error messages

### Console Logging Not Working
1. Ensure you're in development mode (`flutter run` not `flutter build`)
2. Check if `kDebugMode` is true
3. Look for environment configuration logs

### Build Scripts Not Working
1. Ensure PowerShell execution policy allows scripts
2. Check if environment variables are set correctly
3. Verify Flutter is in PATH

## 📝 Summary

The email system now intelligently adapts to your environment:

- **Development**: Safe console logging for testing
- **Production**: Real email delivery for users
- **Automatic**: No manual configuration needed
- **Fallback**: Graceful degradation if issues occur

This ensures you can develop safely without sending real emails, while production automatically uses the full email system! 🎉

