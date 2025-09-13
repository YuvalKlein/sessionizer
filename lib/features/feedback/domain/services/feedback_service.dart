import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/feedback/domain/services/device_info_service.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/services/email_service.dart';

class FeedbackService {
  /// Submit feedback with voice recording, screenshot, and device info
  static Future<void> submitFeedback({
    required String audioPath,
    String? transcription,
    required DeviceInfo deviceInfo,
    String? screenshotPath,
  }) async {
    try {
      print('📝 Starting feedback submission...');
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email ?? 'anonymous@unknown.com';
      final userName = user?.displayName ?? 'Anonymous User';
      
      // Generate unique feedback ID
      final feedbackId = 'feedback_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload voice recording to Firebase Storage
      String? voiceFileUrl;
      try {
        voiceFileUrl = await _uploadVoiceFile(audioPath, feedbackId);
        print('✅ Voice file uploaded: $voiceFileUrl');
      } catch (e) {
        print('❌ Voice upload failed: $e');
      }
      
      // Upload screenshot to Firebase Storage
      String? screenshotUrl;
      if (screenshotPath != null) {
        try {
          screenshotUrl = await _uploadScreenshot(screenshotPath, feedbackId);
          print('✅ Screenshot uploaded: $screenshotUrl');
        } catch (e) {
          print('❌ Screenshot upload failed: $e');
        }
      }
      
      // Create feedback document
      final feedbackData = {
        'id': feedbackId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'transcription': transcription ?? 'Transcription not available',
        'voiceFileUrl': voiceFileUrl,
        'screenshotUrl': screenshotUrl,
        'deviceInfo': deviceInfo.toMap(),
        'pageUrl': html.window.location.href,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
        'priority': 'normal',
      };
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .set(feedbackData);
      
      print('✅ Feedback saved to Firestore');
      
      // Send email notification
      try {
        await _sendFeedbackNotificationEmail(feedbackData);
        print('✅ Feedback notification email sent');
      } catch (e) {
        print('❌ Email notification failed: $e');
        // Don't fail the entire process if email fails
      }
      
      print('🎉 Feedback submission completed successfully');
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Upload voice recording to Firebase Storage
  static Future<String?> _uploadVoiceFile(String audioPath, String feedbackId) async {
    try {
      // Get the blob from the object URL
      final response = await html.HttpRequest.request(
        audioPath,
        responseType: 'blob',
      );
      
      final blob = response.response as html.Blob;
      
      // Create reference in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('feedback')
          .child('voice')
          .child('$feedbackId.webm');
      
      // Upload the blob
      final uploadTask = storageRef.putBlob(blob);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading voice file: $e');
      return null;
    }
  }

  /// Upload screenshot to Firebase Storage
  static Future<String?> _uploadScreenshot(String screenshotPath, String feedbackId) async {
    try {
      // Get the blob from the object URL
      final response = await html.HttpRequest.request(
        screenshotPath,
        responseType: 'blob',
      );
      
      final blob = response.response as html.Blob;
      
      // Create reference in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('feedback')
          .child('screenshots')
          .child('$feedbackId.png');
      
      // Upload the blob
      final uploadTask = storageRef.putBlob(blob);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading screenshot: $e');
      return null;
    }
  }

  /// Send email notification about new feedback
  static Future<void> _sendFeedbackNotificationEmail(Map<String, dynamic> feedbackData) async {
    try {
      final emailService = sl<EmailService>();
      
      final subject = '📝 New Feedback Received - ARENNA';
      
      final textContent = '''
New feedback has been received from a user!

👤 User Information:
• Name: ${feedbackData['userName']}
• Email: ${feedbackData['userEmail']}
• User ID: ${feedbackData['userId']}

📱 Device Information:
• Device: ${feedbackData['deviceInfo']['deviceModel']}
• OS: ${feedbackData['deviceInfo']['osVersion']}
• Browser: ${feedbackData['deviceInfo']['browserName']} ${feedbackData['deviceInfo']['browserVersion']}
• Screen: ${feedbackData['deviceInfo']['screenResolution']}
• Platform: ${feedbackData['deviceInfo']['platform']}

🗣️ Feedback Content:
• Transcription: ${feedbackData['transcription']}

🔗 Links:
• Voice Recording: ${feedbackData['voiceFileUrl'] ?? 'Not available'}
• Screenshot: ${feedbackData['screenshotUrl'] ?? 'Not available'}
• Page URL: ${feedbackData['pageUrl']}

📅 Submitted: ${DateTime.now().toString()}

---
ARENNA Feedback System
''';

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>New Feedback Received</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff9500 0%, #ff6b35 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-section { background: white; padding: 20px; border-radius: 8px; margin: 15px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .info-row { display: flex; margin: 8px 0; }
        .info-label { font-weight: bold; width: 120px; color: #666; }
        .info-value { flex: 1; word-break: break-all; }
        .transcription { background: #e3f2fd; padding: 15px; border-radius: 8px; border-left: 4px solid #2196f3; margin: 15px 0; }
        .links { background: #f3e5f5; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .link { display: block; color: #1976d2; text-decoration: none; margin: 5px 0; }
        .link:hover { text-decoration: underline; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📝 New Feedback Received</h1>
        <p>A user has submitted feedback through the voice recording system</p>
    </div>
    
    <div class="content">
        <div class="info-section">
            <h3>👤 User Information</h3>
            <div class="info-row">
                <div class="info-label">Name:</div>
                <div class="info-value">${feedbackData['userName']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Email:</div>
                <div class="info-value">${feedbackData['userEmail']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">User ID:</div>
                <div class="info-value">${feedbackData['userId']}</div>
            </div>
        </div>

        <div class="info-section">
            <h3>📱 Device Information</h3>
            <div class="info-row">
                <div class="info-label">Device:</div>
                <div class="info-value">${feedbackData['deviceInfo']['deviceModel']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">OS:</div>
                <div class="info-value">${feedbackData['deviceInfo']['osVersion']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Browser:</div>
                <div class="info-value">${feedbackData['deviceInfo']['browserName']} ${feedbackData['deviceInfo']['browserVersion']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Screen:</div>
                <div class="info-value">${feedbackData['deviceInfo']['screenResolution']}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Platform:</div>
                <div class="info-value">${feedbackData['deviceInfo']['platform']}</div>
            </div>
        </div>

        <div class="transcription">
            <h3>🗣️ Feedback Transcription</h3>
            <p>${feedbackData['transcription']}</p>
        </div>

        <div class="links">
            <h3>🔗 Attachments</h3>
            ${feedbackData['voiceFileUrl'] != null ? '<a href="${feedbackData['voiceFileUrl']}" class="link" target="_blank">🎵 Voice Recording</a>' : '<p>Voice recording not available</p>'}
            ${feedbackData['screenshotUrl'] != null ? '<a href="${feedbackData['screenshotUrl']}" class="link" target="_blank">📸 Screenshot</a>' : '<p>Screenshot not available</p>'}
            <a href="${feedbackData['pageUrl']}" class="link" target="_blank">🌐 Page URL</a>
        </div>

        <div class="info-section">
            <h3>📅 Submission Details</h3>
            <div class="info-row">
                <div class="info-label">Submitted:</div>
                <div class="info-value">${DateTime.now().toString()}</div>
            </div>
            <div class="info-row">
                <div class="info-label">Feedback ID:</div>
                <div class="info-value">${feedbackData['id']}</div>
            </div>
        </div>
    </div>
    
    <div class="footer">
        <p>ARENNA Feedback System - Automated Notification</p>
    </div>
</body>
</html>
''';

      await emailService.sendEmail(
        to: 'yuklein@gmail.com',
        subject: subject,
        textContent: textContent,
        htmlContent: htmlContent,
        fromName: 'ARENNA Feedback System',
        fromEmail: 'noreply@arenna.link',
      );
    } catch (e) {
      print('❌ Error sending feedback notification email: $e');
      rethrow;
    }
  }
}
