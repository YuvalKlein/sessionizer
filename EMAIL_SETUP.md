# Email Notification Setup Guide

## Firebase Trigger Email Extension Setup

To enable email notifications for booking confirmations, you need to set up the Firebase Trigger Email extension.

### Step 1: Install the Extension

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Extensions** in the left sidebar
4. Click **Browse the catalog**
5. Search for "Trigger Email from Firestore"
6. Click on the extension and then **Install**

### Step 2: Configure the Extension

During installation, you'll need to provide:

#### SMTP Connection URI
For Gmail (recommended for testing):
```
smtps://your-email@gmail.com:your-app-password@smtp.gmail.com:465
```

**Important**: Use an App Password, not your regular Gmail password:
1. Enable 2-Factor Authentication on your Gmail account
2. Go to Google Account settings → Security → App passwords
3. Generate an app password for "Mail"
4. Use this app password in the SMTP URI

#### Default FROM Address
```
yuklein@gmail.com
```

#### Other Settings
- **Collection name**: `mail` (default)
- **SMTP connection URI**: (as configured above)
- **Default FROM address**: `yuklein@gmail.com`
- **Default REPLY TO address**: `yuklein@gmail.com`

### Step 3: Deploy Firestore Rules

The Firestore rules have been updated to allow the mail collection. Deploy them:

```bash
firebase deploy --only firestore:rules
```

### Step 4: Test the Email System

1. Create a booking in the app
2. Check the Firebase Console → Firestore → `mail` collection
3. You should see a new document created with the email details
4. The extension will automatically send the email to `yuklein@gmail.com`

### Step 5: Monitor Email Delivery

- Check the Firebase Console → Functions → Logs for any errors
- Check your Gmail inbox for the booking confirmation emails
- The extension will automatically delete the mail documents after sending

## Email Template

The system generates both HTML and plain text versions of the email with:
- Client name
- Instructor name  
- Session title
- Date and time
- Booking ID
- Professional styling

## Troubleshooting

### Common Issues

1. **Emails not sending**: Check the Firebase Functions logs
2. **SMTP authentication failed**: Verify your app password is correct
3. **Permission denied**: Ensure Firestore rules are deployed
4. **No mail documents created**: Check if the booking creation is working

### Testing

To test without creating actual bookings, you can manually add a document to the `mail` collection:

```javascript
// In Firebase Console → Firestore → Add document to 'mail' collection
{
  "to": ["yuklein@gmail.com"],
  "message": {
    "subject": "Test Email",
    "text": "This is a test email",
    "html": "<h1>Test Email</h1><p>This is a test email</p>"
  },
  "createdAt": "2024-01-01T00:00:00.000Z",
  "type": "test"
}
```

## Production Setup

When ready for production:

1. Change the email address from `yuklein@gmail.com` to the actual client email
2. Update the SMTP settings to use a professional email service
3. Consider using SendGrid, Mailgun, or AWS SES for better deliverability
4. Update the FROM address to your business email

## Code Changes Made

- Updated `NotificationRemoteDataSourceImpl` to send emails via Firestore `mail` collection
- Added email templates with HTML and plain text versions
- Integrated email sending into the booking confirmation flow
- Added Firestore security rules for the `mail` collection
- All emails currently go to `yuklein@gmail.com` for testing
