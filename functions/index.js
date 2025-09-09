const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

// Initialize Firebase Admin
admin.initializeApp();

// Set SendGrid API key from Firebase config
sgMail.setApiKey(functions.config().sendgrid.key);

// Email sending function
exports.sendEmail = functions.https.onCall(async (data, context) => {
  try {
    // Verify the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const { to, subject, htmlContent, textContent, fromName, fromEmail } = data;

    // Validate required fields
    if (!to || !subject || !htmlContent || !textContent) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required email fields');
    }

    const msg = {
      to: to,
      from: {
        email: fromEmail || 'noreply@arenna.link',
        name: fromName || 'ARENNA'
      },
      subject: subject,
      text: textContent,
      html: htmlContent,
    };

    console.log('Sending email:', { to, subject, from: msg.from });

    await sgMail.send(msg);
    
    console.log('Email sent successfully to:', to);
    
    return { success: true, message: 'Email sent successfully' };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email: ' + error.message);
  }
});

// Booking confirmation email function
exports.sendBookingConfirmation = functions.https.onCall(async (data, context) => {
  try {
    // Verify the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const { 
      clientName, 
      clientEmail, 
      instructorName, 
      sessionTitle, 
      bookingDateTime, 
      bookingId 
    } = data;

    // Validate required fields
    if (!clientName || !clientEmail || !instructorName || !sessionTitle || !bookingDateTime || !bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required booking confirmation fields');
    }

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

    await sgMail.send(msg);
    
    console.log('Booking confirmation email sent successfully to:', clientEmail);
    
    return { success: true, message: 'Booking confirmation email sent successfully' };
  } catch (error) {
    console.error('Error sending booking confirmation email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send booking confirmation email: ' + error.message);
  }
});

// Instructor notification email function
exports.sendInstructorNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const { 
      instructorName, 
      instructorEmail, 
      clientName, 
      sessionTitle, 
      bookingDateTime, 
      bookingId 
    } = data;

    // Validate required fields
    if (!instructorName || !instructorEmail || !clientName || !sessionTitle || !bookingDateTime || !bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required instructor notification fields');
    }

    const htmlContent = `
    <html>
      <body style="font-family: Arial, sans-serif; background-color: #f8f9fa; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <h2 style="color: #10B981; text-align: center; margin-bottom: 30px;">📅 New Booking Received!</h2>
          <p>Hi <strong>${instructorName}</strong>,</p>
          <p>You have received a new booking!</p>
          <div style="background: #f0fdf4; padding: 20px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #10B981;">
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
New Booking Received! 📅

Hi ${instructorName},

You have received a new booking!

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
      subject: 'New Booking Received! 📅',
      text: textContent,
      html: htmlContent,
    };

    console.log('Sending instructor notification email:', { instructorEmail, bookingId });

    await sgMail.send(msg);
    
    console.log('Instructor notification email sent successfully to:', instructorEmail);
    
    return { success: true, message: 'Instructor notification email sent successfully' };
  } catch (error) {
    console.error('Error sending instructor notification email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send instructor notification email: ' + error.message);
  }
});
