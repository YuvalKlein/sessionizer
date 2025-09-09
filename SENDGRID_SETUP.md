# SendGrid Email Integration Setup

This guide explains how to set up SendGrid for email notifications in the Sessionizer app.

## Overview

The app now uses SendGrid instead of Firebase Trigger Email for sending email notifications. This provides better reliability, deliverability, and email template management.

## Features

- ✅ Booking confirmation emails
- ✅ Booking reminder emails  
- ✅ Booking cancellation emails
- ✅ Schedule change notifications
- ✅ Beautiful HTML email templates
- ✅ Plain text fallback
- ✅ Professional email styling

## Setup Instructions

### 1. Create SendGrid Account

1. Go to [SendGrid.com](https://sendgrid.com)
2. Sign up for a free account (100 emails/day free tier)
3. Verify your email address

### 2. Get API Key

1. In SendGrid dashboard, go to **Settings** → **API Keys**
2. Click **Create API Key**
3. Choose **Restricted Access** for security
4. Give it a name like "Sessionizer App"
5. Set permissions:
   - **Mail Send**: Full Access
   - **Mail Settings**: Read Access (optional)
6. Click **Create & View**
7. **Copy the API key immediately** (you won't see it again)

### 3. Configure Environment Variables

Add the following environment variables to your build configuration:

#### For Development (Flutter run)
```bash
# Windows PowerShell
$env:SENDGRID_API_KEY="your_api_key_here"
$env:SENDGRID_FROM_EMAIL="noreply@yourdomain.com"
$env:SENDGRID_FROM_NAME="Sessionizer"

# Or set in your IDE's run configuration
```

#### For Production Build
```bash
flutter build web --dart-define=SENDGRID_API_KEY=your_api_key_here --dart-define=SENDGRID_FROM_EMAIL=noreply@yourdomain.com --dart-define=SENDGRID_FROM_NAME=Sessionizer
```

### 4. Domain Authentication (Recommended)

For better deliverability, authenticate your domain:

1. In SendGrid dashboard, go to **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Follow the DNS setup instructions
4. This allows you to send from `noreply@yourdomain.com`

### 5. Test the Integration

1. Run the app: `flutter run -d chrome --web-port=8080`
2. Create a booking to trigger a confirmation email
3. Check the console logs for email sending status
4. Verify emails are received

## Configuration

### Email Templates

The app includes beautiful HTML email templates for:

- **Booking Confirmation**: Welcome message with session details
- **Booking Reminder**: Friendly reminder before sessions
- **Booking Cancellation**: Apology message for cancelled sessions  
- **Schedule Change**: Notification about instructor schedule updates

### Customization

You can customize email templates in `lib/core/services/email_service.dart`:

- Modify HTML templates in the `_generate*Html()` methods
- Update text templates in the `_generate*Text()` methods
- Change styling in the CSS sections
- Add your branding colors and logos

### From Address

Update the default from address in `lib/core/config/app_config.dart`:

```dart
static const String sendGridFromEmail = String.fromEnvironment(
  'SENDGRID_FROM_EMAIL',
  defaultValue: 'noreply@yourdomain.com', // Change this
);
```

## Troubleshooting

### Common Issues

1. **"Invalid API Key" Error**
   - Verify the API key is correct
   - Check that the key has Mail Send permissions
   - Ensure no extra spaces in the environment variable

2. **Emails Not Received**
   - Check spam/junk folder
   - Verify the recipient email address
   - Check SendGrid activity feed for delivery status
   - Ensure domain authentication is set up

3. **"From Address Not Verified" Error**
   - Verify your sender email in SendGrid
   - Set up domain authentication
   - Use a verified sender address

### Debug Mode

Enable debug logging by checking the console output:

```
📧 Sending email to: user@example.com
📧 Subject: 🎉 Booking Confirmed - Session Title
✅ Email sent successfully
```

### SendGrid Dashboard

Monitor email activity in the SendGrid dashboard:
- **Activity Feed**: See all sent emails
- **Statistics**: Track delivery rates
- **Suppressions**: Manage bounced emails

## Security Notes

- Never commit API keys to version control
- Use environment variables for all sensitive data
- Rotate API keys regularly
- Use restricted access API keys with minimal permissions

## Migration from Firebase Trigger Email

The app has been updated to use SendGrid instead of Firebase Trigger Email:

- ✅ All email functionality moved to SendGrid
- ✅ Old Firebase email methods removed
- ✅ Better error handling and logging
- ✅ Professional email templates
- ✅ Improved deliverability

No changes needed to existing booking or notification logic - emails will now be sent via SendGrid automatically.

## Support

For SendGrid-specific issues:
- [SendGrid Documentation](https://docs.sendgrid.com/)
- [SendGrid Support](https://support.sendgrid.com/)

For app-specific issues, check the console logs and ensure all environment variables are set correctly.
