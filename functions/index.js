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
        to: clientEmail,
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
        to: instructorEmail,
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