import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionInfoDisplay extends StatefulWidget {
  final String sessionId;
  final String instructorId;
  final TextStyle? style;

  const SessionInfoDisplay({
    super.key,
    required this.sessionId,
    required this.instructorId,
    this.style,
  });

  @override
  State<SessionInfoDisplay> createState() => _SessionInfoDisplayState();
}

class _SessionInfoDisplayState extends State<SessionInfoDisplay> {
  String _sessionInfo = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    try {
      // Check if sessionId is empty or null
      if (widget.sessionId.isEmpty) {
        if (mounted) {
          setState(() {
            _sessionInfo = 'Session not found';
            _isLoading = false;
          });
        }
        return;
      }

      // First try to get from bookable_sessions
      final bookableSessionDoc = await FirebaseFirestore.instance
          .collection('bookable_sessions')
          .doc(widget.sessionId)
          .get();
      
      if (bookableSessionDoc.exists) {
        final sessionData = bookableSessionDoc.data()!;
        final title = sessionData['title'] as String?;
        if (title != null && title.isNotEmpty) {
          if (mounted) {
            setState(() {
              _sessionInfo = title;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      // If not found in bookable_sessions, try to get session type name from booking
      // Try both sessionId and bookableSessionId fields for compatibility
      QuerySnapshot bookingQuery;
      try {
        bookingQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('sessionId', isEqualTo: widget.sessionId)
            .limit(1)
            .get();
      } catch (e) {
        // If sessionId field doesn't exist, try bookableSessionId
        bookingQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('bookableSessionId', isEqualTo: widget.sessionId)
            .limit(1)
            .get();
      }
      
      if (bookingQuery.docs.isNotEmpty) {
        final bookingData = bookingQuery.docs.first.data() as Map<String, dynamic>?;
        final sessionTypeId = bookingData?['sessionTypeId'] as String?;
        
        if (sessionTypeId != null && sessionTypeId.isNotEmpty) {
          final sessionTypeDoc = await FirebaseFirestore.instance
              .collection('session_types')
              .doc(sessionTypeId)
              .get();
          
          if (sessionTypeDoc.exists) {
            final sessionTypeData = sessionTypeDoc.data()!;
            final title = sessionTypeData['title'] as String?;
            if (title != null && title.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _sessionInfo = title;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _sessionInfo = 'Session not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting session info: $e');
      if (mounted) {
        setState(() {
          _sessionInfo = 'Session not found';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text(
        'Loading...',
        style: widget.style ?? const TextStyle(color: Colors.grey),
      );
    }

    return Text(
      _sessionInfo,
      style: widget.style,
    );
  }
}


