import 'package:flutter/material.dart';
import 'package:myapp/features/feedback/presentation/widgets/simple_feedback_modal.dart';
import 'dart:html' as html;

class FloatingFeedbackButton extends StatelessWidget {
  const FloatingFeedbackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: FloatingActionButton.extended(
        onPressed: () => _showFeedbackModal(context),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.feedback, size: 20),
        label: const Text(
          'Feedback',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        heroTag: "feedback_button", // Unique hero tag to avoid conflicts
      ),
    );
  }

  void _showFeedbackModal(BuildContext context) async {
    // Capture page context before opening modal
    Map<String, dynamic> pageContext;
    try {
      pageContext = _capturePageContext();
      print('📋 Page context captured: ${pageContext['pageContext']}');
    } catch (e) {
      print('📋 Page context capture error: $e');
      pageContext = {'pageContext': 'Error capturing context'};
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SimpleFeedbackModal(pageContext: pageContext),
      );
    }
  }

  Map<String, dynamic> _capturePageContext() {
    try {
      // Capture detailed page context instead of visual screenshot
      final currentUrl = html.window.location.href;
      final pageTitle = html.document.title;
      final currentPath = html.window.location.pathname;
      final currentHash = html.window.location.hash;
      
      // Try to determine what page/section user is on
      // For Flutter web apps, the route info is usually in the hash
      final fullRoute = currentHash ?? currentPath ?? '';
      String pageContext = 'Unknown Page';
      
      if (fullRoute.contains('client-dashboard')) {
        pageContext = 'Client Dashboard';
      } else if (fullRoute.contains('instructor-dashboard')) {
        pageContext = 'Instructor Dashboard';
      } else if (fullRoute.contains('bookings')) {
        pageContext = 'My Bookings Page';
      } else if (fullRoute.contains('calendar')) {
        pageContext = 'Booking Calendar';
      } else if (fullRoute.contains('sessions')) {
        pageContext = 'Sessions Page';
      } else if (fullRoute.contains('profile')) {
        pageContext = 'Profile Page';
      } else if (fullRoute.contains('login')) {
        pageContext = 'Login Page';
      } else if (fullRoute.contains('signup')) {
        pageContext = 'Sign Up Page';
      } else if (fullRoute.contains('schedule')) {
        pageContext = 'Schedule Management';
      } else if (fullRoute.contains('notification')) {
        pageContext = 'Notifications';
      }
      
      // Get viewport information
      final viewportWidth = html.window.innerWidth ?? 0;
      final viewportHeight = html.window.innerHeight ?? 0;
      final scrollX = html.window.scrollX ?? 0;
      final scrollY = html.window.scrollY ?? 0;
      
      return {
        'pageUrl': currentUrl,
        'pageTitle': pageTitle,
        'pageContext': pageContext,
        'currentPath': currentPath,
        'currentHash': currentHash,
        'viewportWidth': viewportWidth,
        'viewportHeight': viewportHeight,
        'scrollX': scrollX,
        'scrollY': scrollY,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('📋 Error capturing page context: $e');
      return {
        'pageUrl': html.window.location.href,
        'pageContext': 'Error capturing context',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
