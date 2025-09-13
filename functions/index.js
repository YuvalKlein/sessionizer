const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

// Initialize Firebase Admin
admin.initializeApp();

// Define the secret for Firebase Functions v2
const sendGridApiKey = defineSecret('SENDGRID_API_KEY');

// Simple booking confirmation function using v2 syntax with secrets
exports.sendBookingConfirmation = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendBookingConfirmation called');
      
      const { 
        clientName, 
        clientEmail, 
        instructorName, 
        sessionTitle, 
        bookingDateTime, 
        bookingId 
      } = req.body;

      console.log('Request data:', { clientName, clientEmail, instructorName, sessionTitle, bookingDateTime, bookingId });

      // Validate required fields
      if (!clientName || !clientEmail || !instructorName || !sessionTitle || !bookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required booking confirmation fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid key not available, returning mock response');
        res.status(200).json({ 
          success: true, 
          message: 'Mock email sent (SendGrid key not available)',
          emailData: { clientName, clientEmail, instructorName, sessionTitle, bookingDateTime, bookingId }
        });
        return;
      }

      // Initialize SendGrid with the secret
      sgMail.setApiKey(sendGridKey);
      console.log('SendGrid initialized with key');

      const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
          <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #8B5CF6; text-align: center; margin-bottom: 30px;">🎉 Booking Confirmed!</h2>
            <p>Hi <strong>${clientName}</strong>,</p>
            <p>Your session has been successfully booked!</p>
            <div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;">
              <p><strong>Instructor:</strong> ${instructorName}</p>
              <p><strong>Session:</strong> ${sessionTitle}</p>
              <p><strong>Date & Time:</strong> ${bookingDateTime}</p>
              <p><strong>Booking ID:</strong> ${bookingId}</p>
            </div>
            <p>We look forward to seeing you!</p>
            <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
          </div>
        </body>
      </html>
      `;

      const textContent = `
Booking Confirmed! 🎉

Hi ${clientName},

Your session has been successfully booked!

Details:
- Instructor: ${instructorName}
- Session: ${sessionTitle}
- Date & Time: ${bookingDateTime}
- Booking ID: ${bookingId}

We look forward to seeing you!

ARENNA Team
      `;

      const msg = {
        to: [clientEmail, 'yuklein@gmail.com'],  // Send to both client and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: 'Booking Confirmed! 🎉',
        text: textContent,
        html: htmlContent,
      };

      console.log('Sending booking confirmation email:', { clientEmail, bookingId });

      // Send email
      sgMail.send(msg).then(() => {
        console.log('Booking confirmation email sent successfully to:', clientEmail);
        res.status(200).json({ success: true, message: 'Booking confirmation email sent successfully' });
      }).catch((error) => {
        console.error('Error sending booking confirmation email:', error);
        res.status(500).json({ error: 'Failed to send booking confirmation email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendBookingConfirmation:', error);
      res.status(500).json({ error: 'Failed to send booking confirmation email: ' + error.message });
    }
  }
);

// Instructor booking notification function
exports.sendInstructorBookingNotification = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendInstructorBookingNotification called');
      
      const { 
        instructorName, 
        instructorEmail, 
        clientName, 
        sessionTitle, 
        bookingDateTime, 
        bookingId 
      } = req.body;

      console.log('Request data:', { instructorName, instructorEmail, clientName, sessionTitle, bookingDateTime, bookingId });

      // Validate required fields
      if (!instructorName || !instructorEmail || !clientName || !sessionTitle || !bookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required instructor notification fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid key not available, returning mock response');
        res.status(200).json({ 
          success: true, 
          message: 'Mock instructor email sent (SendGrid key not available)',
          emailData: { instructorName, instructorEmail, clientName, sessionTitle, bookingDateTime, bookingId }
        });
        return;
      }

      // Initialize SendGrid with the secret
      sgMail.setApiKey(sendGridKey);
      console.log('SendGrid initialized with key');

      const htmlContent = `
      <html>
        <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
          <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #8B5CF6; text-align: center; margin-bottom: 30px;">📅 New Booking!</h2>
            <p>Hi <strong>${instructorName}</strong>,</p>
            <p>You have a new booking!</p>
            <div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;">
              <p><strong>Client:</strong> ${clientName}</p>
              <p><strong>Session:</strong> ${sessionTitle}</p>
              <p><strong>Date & Time:</strong> ${bookingDateTime}</p>
              <p><strong>Booking ID:</strong> ${bookingId}</p>
            </div>
            <p>Please prepare for your session!</p>
            <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Team</p>
          </div>
        </body>
      </html>
      `;

      const textContent = `
New Booking! 📅

Hi ${instructorName},

You have a new booking!

Details:
- Client: ${clientName}
- Session: ${sessionTitle}
- Date & Time: ${bookingDateTime}
- Booking ID: ${bookingId}

Please prepare for your session!

ARENNA Team
      `;

      const msg = {
        to: [instructorEmail, 'yuklein@gmail.com'],  // Send to both instructor and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: 'New Booking! 📅',
        text: textContent,
        html: htmlContent,
      };

      console.log('Sending instructor notification email:', { instructorEmail, bookingId });

      // Send email
      sgMail.send(msg).then(() => {
        console.log('Instructor notification email sent successfully to:', instructorEmail);
        res.status(200).json({ success: true, message: 'Instructor notification email sent successfully' });
      }).catch((error) => {
        console.error('Error sending instructor notification email:', error);
        res.status(500).json({ error: 'Failed to send instructor notification email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendInstructorBookingNotification:', error);
      res.status(500).json({ error: 'Failed to send instructor notification email: ' + error.message });
    }
  }
);

// Booking reminder function
exports.sendBookingReminder = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendBookingReminder called');
      
      const { 
        clientName, 
        clientEmail, 
        instructorName, 
        sessionTitle, 
        bookingDateTime, 
        bookingId,
        hoursBefore
      } = req.body;

      console.log('Request data:', { clientName, clientEmail, instructorName, sessionTitle, bookingDateTime, bookingId, hoursBefore });

      // Validate required fields
      if (!clientName || !clientEmail || !instructorName || !sessionTitle || !bookingDateTime || !bookingId || !hoursBefore) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required booking reminder fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      const msg = {
        to: [clientEmail, 'yuklein@gmail.com'],  // Send to both client and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `⏰ Session Reminder - ${sessionTitle} (in ${hoursBefore} hours)`,
        text: `Hi ${clientName}! ⏰

This is a friendly reminder about your upcoming session.

📅 Session Details:
• Session: ${sessionTitle}
• Instructor: ${instructorName}
• Date & Time: ${bookingDateTime}
• Booking ID: ${bookingId}
• Reminder: ${hoursBefore} hours before

Don't forget to prepare for your session!

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`,
        html: `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Session Reminder</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%); color: #333; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .session-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
        .reminder-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">⏰</span> Session Reminder</h1>
        <p>Hi ${clientName}! Don't forget about your upcoming session.</p>
    </div>
    
    <div class="content">
        <p>This is a friendly reminder about your upcoming session:</p>
        
        <div class="session-details">
            <div class="detail-row">
                <div class="detail-label">Session:</div>
                <div class="detail-value">${sessionTitle}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Instructor:</div>
                <div class="detail-value">${instructorName}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Date & Time:</div>
                <div class="detail-value">${bookingDateTime}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Booking ID:</div>
                <div class="detail-value">${bookingId}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Reminder:</div>
                <div class="detail-value"><span class="reminder-badge">${hoursBefore} hours before</span></div>
            </div>
        </div>
        
        <p>Don't forget to prepare for your session!</p>
        
        <p>Best regards,<br>
        <strong>The ARENNA Team</strong></p>
    </div>
    
    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>`
      };

      sgMail.send(msg).then(() => {
        console.log('Booking reminder email sent successfully');
        res.status(200).json({ success: true, message: 'Booking reminder email sent successfully' });
      }).catch((error) => {
        console.error('Error sending booking reminder email:', error);
        res.status(500).json({ error: 'Failed to send booking reminder email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendBookingReminder:', error);
      res.status(500).json({ error: 'Failed to send booking reminder email: ' + error.message });
    }
  }
);

// Booking cancellation function
exports.sendBookingCancellation = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendBookingCancellation called');
      
      const { 
        clientName, 
        clientEmail, 
        instructorName, 
        sessionTitle, 
        bookingDateTime, 
        bookingId
      } = req.body;

      console.log('Request data:', { clientName, clientEmail, instructorName, sessionTitle, bookingDateTime, bookingId });

      // Validate required fields
      if (!clientName || !clientEmail || !instructorName || !sessionTitle || !bookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required booking cancellation fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      const msg = {
        to: [clientEmail, 'yuklein@gmail.com'],  // Send to both client and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `❌ Session Cancelled - ${sessionTitle}`,
        text: `Hi ${clientName},

We're sorry to inform you that your session has been cancelled.

📅 Cancelled Session Details:
• Session: ${sessionTitle}
• Instructor: ${instructorName}
• Date & Time: ${bookingDateTime}
• Booking ID: ${bookingId}

We apologize for any inconvenience this may cause. If you have any questions or would like to reschedule, please contact us.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`,
        html: `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Session Cancelled</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .session-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
        .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">❌</span> Session Cancelled</h1>
        <p>Hi ${clientName}, we're sorry to inform you that your session has been cancelled.</p>
    </div>
    
    <div class="content">
        <p>We apologize for any inconvenience this may cause. Here are the details of your cancelled session:</p>
        
        <div class="session-details">
            <div class="detail-row">
                <div class="detail-label">Session:</div>
                <div class="detail-value">${sessionTitle}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Instructor:</div>
                <div class="detail-value">${instructorName}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Date & Time:</div>
                <div class="detail-value">${bookingDateTime}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Booking ID:</div>
                <div class="detail-value">${bookingId}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Status:</div>
                <div class="detail-value"><span class="cancelled-badge">CANCELLED</span></div>
            </div>
        </div>
        
        <p>If you have any questions or would like to reschedule, please contact us.</p>
        
        <p>Best regards,<br>
        <strong>The ARENNA Team</strong></p>
    </div>
    
    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>`
      };

      sgMail.send(msg).then(() => {
        console.log('Booking cancellation email sent successfully');
        res.status(200).json({ success: true, message: 'Booking cancellation email sent successfully' });
      }).catch((error) => {
        console.error('Error sending booking cancellation email:', error);
        res.status(500).json({ error: 'Failed to send booking cancellation email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendBookingCancellation:', error);
      res.status(500).json({ error: 'Failed to send booking cancellation email: ' + error.message });
    }
  }
);

// Schedule change function
exports.sendScheduleChange = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendScheduleChange called');
      
      const { 
        clientName, 
        clientEmail, 
        instructorName, 
        message
      } = req.body;

      console.log('Request data:', { clientName, clientEmail, instructorName, message });

      // Validate required fields
      if (!clientName || !clientEmail || !instructorName || !message) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required schedule change fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      const msg = {
        to: [clientEmail, 'yuklein@gmail.com'],  // Send to both client and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `📅 Schedule Updated - ${instructorName}`,
        text: `Hi ${clientName},

Your instructor ${instructorName} has updated their schedule.

📅 Schedule Update:
${message}

Please check your upcoming sessions for any changes that might affect your bookings.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`,
        html: `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schedule Updated</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .message-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-left: 4px solid #4ecdc4; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">📅</span> Schedule Updated</h1>
        <p>Hi ${clientName}, your instructor has updated their schedule.</p>
    </div>
    
    <div class="content">
        <p>Your instructor <strong>${instructorName}</strong> has made changes to their schedule:</p>
        
        <div class="message-box">
            <p>${message}</p>
        </div>
        
        <p>Please check your upcoming sessions for any changes that might affect your bookings.</p>
        
        <p>Best regards,<br>
        <strong>The ARENNA Team</strong></p>
    </div>
    
    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>`
      };

      sgMail.send(msg).then(() => {
        console.log('Schedule change email sent successfully');
        res.status(200).json({ success: true, message: 'Schedule change email sent successfully' });
      }).catch((error) => {
        console.error('Error sending schedule change email:', error);
        res.status(500).json({ error: 'Failed to send schedule change email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendScheduleChange:', error);
      res.status(500).json({ error: 'Failed to send schedule change email: ' + error.message });
    }
  }
);

// Generic email function
exports.sendEmail = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendEmail called');
      
      const { 
        to, 
        subject, 
        textContent, 
        htmlContent, 
        fromName, 
        fromEmail
      } = req.body;

      console.log('Request data:', { to, subject, fromName, fromEmail });

      // Validate required fields
      if (!to || !subject || !textContent || !htmlContent) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required email fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      const msg = {
        to: [to, 'yuklein@gmail.com'],  // Send to both recipient and yuklein@gmail.com
        from: {
          email: fromEmail || 'noreply@arenna.link',
          name: fromName || 'ARENNA'
        },
        subject: subject,
        text: textContent,
        html: htmlContent
      };

      sgMail.send(msg).then(() => {
        console.log('Email sent successfully');
        res.status(200).json({ success: true, message: 'Email sent successfully' });
      }).catch((error) => {
        console.error('Error sending email:', error);
        res.status(500).json({ error: 'Failed to send email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendEmail:', error);
      res.status(500).json({ error: 'Failed to send email: ' + error.message });
    }
  }
);

// Instructor cancellation notification function
exports.sendInstructorCancellationNotification = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendInstructorCancellationNotification called');
      
      const { 
        instructorName, 
        instructorEmail, 
        clientName, 
        sessionTitle, 
        bookingDateTime, 
        bookingId
      } = req.body;

      console.log('Request data:', { instructorName, instructorEmail, clientName, sessionTitle, bookingDateTime, bookingId });

      // Validate required fields
      if (!instructorName || !instructorEmail || !clientName || !sessionTitle || !bookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required instructor cancellation notification fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      const msg = {
        to: [instructorEmail, 'yuklein@gmail.com'],  // Send to both instructor and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `❌ Booking Cancelled - ${sessionTitle}`,
        text: `Hi ${instructorName},

A booking has been cancelled by the client.

📅 Booking Details:
• Session: ${sessionTitle}
• Client: ${clientName}
• Date & Time: ${bookingDateTime}
• Booking ID: ${bookingId}

The client has cancelled this booking. You may want to check your schedule for any available slots.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`,
        html: `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Cancelled</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b6b 0%, #ff8e8e 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .detail-row { display: flex; margin: 10px 0; }
        .detail-label { font-weight: bold; width: 120px; color: #666; }
        .detail-value { flex: 1; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
        .emoji { font-size: 24px; }
        .cancelled-badge { background: #ff6b6b; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1><span class="emoji">❌</span> Booking Cancelled</h1>
        <p>Hi ${instructorName}! A client has cancelled their booking.</p>
    </div>
    
    <div class="content">
        <p>A booking has been cancelled by the client:</p>
        
        <div class="booking-details">
            <div class="detail-row">
                <div class="detail-label">Session:</div>
                <div class="detail-value">${sessionTitle}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Client:</div>
                <div class="detail-value">${clientName}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Date & Time:</div>
                <div class="detail-value">${bookingDateTime}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Booking ID:</div>
                <div class="detail-value">${bookingId}</div>
            </div>
            <div class="detail-row">
                <div class="detail-label">Status:</div>
                <div class="detail-value"><span class="cancelled-badge">Cancelled by Client</span></div>
            </div>
        </div>
        
        <p>The client has cancelled this booking. You may want to check your schedule for any available slots.</p>
        
        <p>Best regards,<br>
        <strong>The ARENNA Team</strong></p>
    </div>
    
    <div class="footer">
        <p>This is an automated message. Please do not reply to this email.</p>
    </div>
</body>
</html>`
      };

      sgMail.send(msg).then(() => {
        console.log('Instructor cancellation notification email sent successfully');
        res.status(200).json({ success: true, message: 'Instructor cancellation notification email sent successfully' });
      }).catch((error) => {
        console.error('Error sending instructor cancellation notification email:', error);
        res.status(500).json({ error: 'Failed to send instructor cancellation notification email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendInstructorCancellationNotification:', error);
      res.status(500).json({ error: 'Failed to send instructor cancellation notification email: ' + error.message });
    }
  }
);

// Booking reschedule function
exports.sendBookingReschedule = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendBookingReschedule called');
      
      const { 
        clientName, 
        clientEmail, 
        instructorName, 
        sessionTitle, 
        oldBookingDateTime, 
        newBookingDateTime, 
        bookingId 
      } = req.body;

      console.log('Request data:', { clientName, clientEmail, instructorName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId });

      // Validate required fields
      if (!clientName || !clientEmail || !instructorName || !sessionTitle || !oldBookingDateTime || !newBookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required reschedule fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      // Generate HTML content
      const htmlContent = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Booking Rescheduled</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              .detail-row { display: flex; margin: 10px 0; }
              .detail-label { font-weight: bold; width: 120px; color: #666; }
              .detail-value { flex: 1; }
              .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
              .emoji { font-size: 24px; }
              .rescheduled-badge { background: #3b82f6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
              .time-change { background: #dbeafe; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #3b82f6; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1><span class="emoji">🔄</span> Booking Rescheduled</h1>
              <p>Hi ${clientName}! Your booking has been rescheduled.</p>
            </div>
            
            <div class="content">
              <p>Your session has been successfully rescheduled:</p>
              
              <div class="booking-details">
                <div class="detail-row">
                  <div class="detail-label">Session:</div>
                  <div class="detail-value">${sessionTitle}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Instructor:</div>
                  <div class="detail-value">${instructorName}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Booking ID:</div>
                  <div class="detail-value">${bookingId}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Status:</div>
                  <div class="detail-value"><span class="rescheduled-badge">Rescheduled</span></div>
                </div>
              </div>
              
              <div class="time-change">
                <p><strong>Time Change:</strong></p>
                <p><strong>Old Time:</strong> ${oldBookingDateTime}</p>
                <p><strong>New Time:</strong> ${newBookingDateTime}</p>
              </div>
              
              <p>Please make note of the new time for your session.</p>
              
              <p>Best regards,<br>
              <strong>The ARENNA Team</strong></p>
            </div>
            
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </body>
        </html>
      `;

      // Generate text content
      const textContent = `Hi ${clientName},

Your booking has been rescheduled.

📅 Booking Details:
• Session: ${sessionTitle}
• Instructor: ${instructorName}
• Old Date & Time: ${oldBookingDateTime}
• New Date & Time: ${newBookingDateTime}
• Booking ID: ${bookingId}

Your session has been successfully rescheduled. Please make note of the new time.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`;

      const msg = {
        to: [clientEmail, 'yuklein@gmail.com'],  // Send to both client and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `🔄 Booking Rescheduled - ${sessionTitle}`,
        text: textContent,
        html: htmlContent,
      };

      console.log('Sending reschedule email to:', clientEmail);

      sgMail.send(msg).then(() => {
        console.log('Booking reschedule email sent successfully');
        res.status(200).json({ success: true, message: 'Booking reschedule email sent successfully' });
      }).catch((error) => {
        console.error('Error sending booking reschedule email:', error);
        res.status(500).json({ error: 'Failed to send booking reschedule email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendBookingReschedule:', error);
      res.status(500).json({ error: 'Failed to send booking reschedule email: ' + error.message });
    }
  }
);

// Instructor reschedule notification function
exports.sendInstructorRescheduleNotification = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendInstructorRescheduleNotification called');
      
      const { 
        instructorName, 
        instructorEmail, 
        clientName, 
        sessionTitle, 
        oldBookingDateTime, 
        newBookingDateTime, 
        bookingId 
      } = req.body;

      console.log('Request data:', { instructorName, instructorEmail, clientName, sessionTitle, oldBookingDateTime, newBookingDateTime, bookingId });

      // Validate required fields
      if (!instructorName || !instructorEmail || !clientName || !sessionTitle || !oldBookingDateTime || !newBookingDateTime || !bookingId) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required instructor reschedule fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      // Generate HTML content
      const htmlContent = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Booking Rescheduled</title>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              .detail-row { display: flex; margin: 10px 0; }
              .detail-label { font-weight: bold; width: 120px; color: #666; }
              .detail-value { flex: 1; }
              .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
              .emoji { font-size: 24px; }
              .rescheduled-badge { background: #3b82f6; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold; }
              .time-change { background: #dbeafe; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #3b82f6; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1><span class="emoji">🔄</span> Booking Rescheduled</h1>
              <p>Hi ${instructorName}! A booking has been rescheduled.</p>
            </div>
            
            <div class="content">
              <p>The following booking has been rescheduled:</p>
              
              <div class="booking-details">
                <div class="detail-row">
                  <div class="detail-label">Session:</div>
                  <div class="detail-value">${sessionTitle}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Client:</div>
                  <div class="detail-value">${clientName}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Booking ID:</div>
                  <div class="detail-value">${bookingId}</div>
                </div>
                <div class="detail-row">
                  <div class="detail-label">Status:</div>
                  <div class="detail-value"><span class="rescheduled-badge">Rescheduled</span></div>
                </div>
              </div>
              
              <div class="time-change">
                <p><strong>Time Change:</strong></p>
                <p><strong>Old Time:</strong> ${oldBookingDateTime}</p>
                <p><strong>New Time:</strong> ${newBookingDateTime}</p>
              </div>
              
              <p>Please make note of the new time for your session.</p>
              
              <p>Best regards,<br>
              <strong>The ARENNA Team</strong></p>
            </div>
            
            <div class="footer">
              <p>This is an automated message. Please do not reply to this email.</p>
            </div>
          </body>
        </html>
      `;

      // Generate text content
      const textContent = `Hi ${instructorName},

A booking has been rescheduled.

📅 Booking Details:
• Session: ${sessionTitle}
• Client: ${clientName}
• Old Date & Time: ${oldBookingDateTime}
• New Date & Time: ${newBookingDateTime}
• Booking ID: ${bookingId}

The booking has been rescheduled. Please make note of the new time.

Best regards,
The ARENNA Team

---
This is an automated message. Please do not reply to this email.`;

      const msg = {
        to: [instructorEmail, 'yuklein@gmail.com'],  // Send to both instructor and yuklein@gmail.com
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA'
        },
        subject: `🔄 Booking Rescheduled - ${sessionTitle}`,
        text: textContent,
        html: htmlContent,
      };

      console.log('Sending instructor reschedule notification to:', instructorEmail);

      sgMail.send(msg).then(() => {
        console.log('Instructor reschedule notification email sent successfully');
        res.status(200).json({ success: true, message: 'Instructor reschedule notification email sent successfully' });
      }).catch((error) => {
        console.error('Error sending instructor reschedule notification email:', error);
        res.status(500).json({ error: 'Failed to send instructor reschedule notification email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendInstructorRescheduleNotification:', error);
      res.status(500).json({ error: 'Failed to send instructor reschedule notification email: ' + error.message });
    }
  }
);

// Feedback notification function
exports.sendFeedbackNotification = onRequest(
  { secrets: [sendGridApiKey] },
  (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(200).send('');
      return;
    }

    try {
      console.log('sendFeedbackNotification called');
      console.log('Raw request body:', req.body);
      console.log('Request body type:', typeof req.body);
      
      const { 
        feedbackId,
        userEmail,
        userName,
        feedbackType,
        feedbackText,
        pageUrl,
        pageContext,
        hasPageContext
      } = req.body;

      console.log('Feedback data:', { feedbackId, userEmail, userName, feedbackType, feedbackText, pageUrl, hasPageContext });
      console.log('feedbackText length:', feedbackText ? feedbackText.length : 'undefined');
      console.log('feedbackText value:', feedbackText);
      console.log('Page context available:', hasPageContext);

      // Validate required fields
      if (!feedbackId || !feedbackText) {
        console.log('Missing required fields');
        res.status(400).json({ error: 'Missing required feedback fields' });
        return;
      }

      // Get the secret value at runtime
      const sendGridKey = sendGridApiKey.value();
      console.log('SendGrid key available:', !!sendGridKey);
      
      if (!sendGridKey) {
        console.log('SendGrid API key not available');
        res.status(500).json({ error: 'SendGrid API key not configured' });
        return;
      }

      // Configure SendGrid
      sgMail.setApiKey(sendGridKey);

      // Get feedback type emoji and color
      const typeInfo = {
        'bug': { emoji: '🐛', label: 'Bug Report', color: '#dc3545' },
        'feature': { emoji: '💡', label: 'Feature Request', color: '#007bff' },
        'improvement': { emoji: '⚡', label: 'Improvement', color: '#fd7e14' },
        'general': { emoji: '💬', label: 'General Feedback', color: '#28a745' },
        'other': { emoji: '📝', label: 'Other', color: '#6c757d' }
      }[feedbackType] || { emoji: '📝', label: 'Feedback', color: '#6c757d' };

      const msg = {
        to: ['yuklein@gmail.com'],
        from: {
          email: 'noreply@arenna.link',
          name: 'ARENNA Feedback System'
        },
        subject: `${typeInfo.emoji} New ${typeInfo.label} - ARENNA`,
        text: `New feedback received!

Feedback Type: ${typeInfo.label}
User: ${userName} (${userEmail})
Page: ${pageUrl}
Time: ${new Date().toISOString()}

Feedback:
${feedbackText}

Page Context: ${hasPageContext === 'true' ? 'Available (see HTML email)' : 'Not available'}

Feedback ID: ${feedbackId}

ARENNA Feedback System`,
        html: `<html>
<body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
  <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    <h2 style="color: ${typeInfo.color}; text-align: center; margin-bottom: 30px;">${typeInfo.emoji} New ${typeInfo.label}</h2>
    <p>Hi <strong>Yuval</strong>,</p>
    <p>New feedback has been received from a user!</p>
    <div style="background: #f8f9fa; padding: 20px; border-radius: 6px; margin: 20px 0;">
      <p><strong>User:</strong> ${userName} (${userEmail})</p>
      <p><strong>Type:</strong> ${typeInfo.label}</p>
      <p><strong>Page:</strong> ${pageUrl}</p>
      <p><strong>Time:</strong> ${new Date().toISOString()}</p>
    </div>
    <div style="background: #e3f2fd; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid ${typeInfo.color};">
      <p><strong>Feedback:</strong></p>
      <p>${feedbackText}</p>
    </div>
    ${hasPageContext === 'true' && pageContext ? `
    <div style="background: #f0f8ff; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #007bff;">
      <p><strong>📍 Page Context:</strong></p>
      ${(() => {
        try {
          const context = JSON.parse(pageContext);
          return `
          <p><strong>📱 Page:</strong> ${context.pageContext || 'Unknown'}</p>
          <p><strong>📄 Page Title:</strong> ${context.pageTitle || 'Unknown'}</p>
          <p><strong>🔗 Full URL:</strong> <a href="${context.pageUrl}" target="_blank">${context.pageUrl}</a></p>
          <p><strong>🛣️ Path:</strong> ${context.currentPath || 'N/A'}</p>
          <p><strong>#️⃣ Hash:</strong> ${context.currentHash || 'N/A'}</p>
          <p><strong>📏 Viewport:</strong> ${context.viewportWidth}x${context.viewportHeight}</p>
          <p><strong>📜 Scroll Position:</strong> X:${context.scrollX}, Y:${context.scrollY}</p>
          <p><strong>⏰ Timestamp:</strong> ${context.timestamp}</p>
          `;
        } catch (e) {
          return '<p>Page context data available but parsing failed</p>';
        }
      })()}
    </div>` : '<p><em>📍 Page context: Not available</em></p>'}
    <p><strong>Feedback ID:</strong> ${feedbackId}</p>
    <p style="color: #666; font-size: 14px; margin-top: 30px;">ARENNA Feedback System</p>
  </div>
</body>
</html>`
      };

      console.log('Sending feedback notification to yuklein@gmail.com');

      sgMail.send(msg).then(() => {
        console.log('Feedback notification email sent successfully');
        res.status(200).json({ success: true, message: 'Feedback notification email sent successfully' });
      }).catch((error) => {
        console.error('Error sending feedback notification email:', error);
        res.status(500).json({ error: 'Failed to send feedback notification email: ' + error.message });
      });

    } catch (error) {
      console.error('Error in sendFeedbackNotification:', error);
      res.status(500).json({ error: 'Failed to send feedback notification email: ' + error.message });
    }
  }
);