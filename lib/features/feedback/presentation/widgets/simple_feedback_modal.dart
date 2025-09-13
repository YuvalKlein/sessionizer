import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'dart:html' as html;
import 'dart:convert' as json;

class SimpleFeedbackModal extends StatefulWidget {
  final Map<String, dynamic>? pageContext;
  
  const SimpleFeedbackModal({super.key, this.pageContext});

  @override
  State<SimpleFeedbackModal> createState() => _SimpleFeedbackModalState();
}

class _SimpleFeedbackModalState extends State<SimpleFeedbackModal> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasText = false;
  String _feedbackType = 'general';

  final List<Map<String, dynamic>> _feedbackTypes = [
    {'value': 'bug', 'label': '🐛 Bug Report', 'color': Colors.red},
    {'value': 'feature', 'label': '💡 Feature Request', 'color': Colors.blue},
    {'value': 'improvement', 'label': '⚡ Improvement', 'color': Colors.orange},
    {'value': 'general', 'label': '💬 General Feedback', 'color': Colors.green},
    {'value': 'other', 'label': '📝 Other', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
    
    // Listen to text changes
    _feedbackController.addListener(() {
      setState(() {
        _hasText = _feedbackController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Help us improve ARENNA! Your feedback is valuable and will be sent directly to our development team.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Feedback Type Selection
            const Text(
              'Feedback Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feedbackTypes.map((type) {
                final isSelected = _feedbackType == type['value'];
                return FilterChip(
                  label: Text(type['label']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _feedbackType = type['value'];
                    });
                  },
                  selectedColor: (type['color'] as Color).withValues(alpha: 0.2),
                  checkmarkColor: type['color'],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Your Email (optional)',
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Feedback Text
            const Text(
              'Your Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200, // Fixed height instead of Expanded
              child: TextField(
                controller: _feedbackController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Tell us what you think! Describe any bugs, suggest improvements, or share your experience...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || !_hasText 
                        ? null 
                        : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Send Feedback'),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim()
          : user?.email ?? 'anonymous@unknown.com';
      
      // Try to get username from multiple sources
      String userName = 'Anonymous User';
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else if (user?.email != null) {
        // Extract name from email (before @)
        userName = user!.email!.split('@').first;
      } else if (_emailController.text.trim().isNotEmpty) {
        // Extract name from entered email
        userName = _emailController.text.trim().split('@').first;
      }

      // Collect device information
      final deviceInfo = _getDeviceInfo();
      
      // Generate unique feedback ID
      final feedbackId = 'feedback_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create feedback document
      final feedbackData = {
        'id': feedbackId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'feedbackType': _feedbackType,
        'feedbackText': _feedbackController.text.trim(),
        'deviceInfo': deviceInfo,
        'pageUrl': html.window.location.href,
        'pageContext': widget.pageContext,
        'hasPageContext': widget.pageContext != null,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
        'priority': _feedbackType == 'bug' ? 'high' : 'normal',
      };
      
      // Save to Firestore using the correct collection structure
      // Save to Firestore using proper collection path
      await FirestoreCollections.feedbackDoc(feedbackId).set(feedbackData);
      
      print('✅ Feedback saved to Firestore');
      
      // Send email notification with page context data
      await _sendEmailNotification(feedbackData);
      
      // Show success message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been sent successfully.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getDeviceInfo() {
    final userAgent = html.window.navigator.userAgent;
    final platform = html.window.navigator.platform ?? 'Unknown';
    final language = html.window.navigator.language ?? 'Unknown';
    
    return {
      'userAgent': userAgent,
      'platform': platform,
      'language': language,
      'screenWidth': html.window.screen?.width ?? 0,
      'screenHeight': html.window.screen?.height ?? 0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }


  Future<void> _sendEmailNotification(Map<String, dynamic> feedbackData) async {
    try {
      // Create proper JSON request to Firebase Function
      final request = html.HttpRequest();
      request.open('POST', 'https://us-central1-apiclientapp.cloudfunctions.net/sendFeedbackNotification');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Accept', 'application/json');
      
      final payload = {
        'feedbackId': feedbackData['id'].toString(),
        'userEmail': feedbackData['userEmail'].toString(),
        'userName': feedbackData['userName'].toString(),
        'feedbackType': feedbackData['feedbackType'].toString(),
        'feedbackText': feedbackData['feedbackText'].toString(),
        'pageUrl': feedbackData['pageUrl'].toString(),
        'pageContext': json.jsonEncode(widget.pageContext ?? {}),
        'hasPageContext': (widget.pageContext != null).toString(),
      };
      
      print('📧 Sending email notification with payload: $payload');
      print('📧 Feedback text: "${feedbackData['feedbackText']}"');
      print('📧 JSON payload: ${json.jsonEncode(payload)}');
      
      request.send(json.jsonEncode(payload));
      
      await request.onLoadEnd.first;
      
      print('📧 Response status: ${request.status}');
      print('📧 Response text: ${request.responseText}');
      
      if (request.status == 200) {
        print('✅ Feedback notification email sent successfully');
      } else {
        print('⚠️ Email notification failed: ${request.status} - ${request.responseText}');
      }
    } catch (e) {
      print('⚠️ Email notification error: $e');
      // Don't fail the feedback submission if email fails
    }
  }
}
