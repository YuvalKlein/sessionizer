import 'package:flutter/material.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/bookable_session/domain/usecases/get_bookable_sessions.dart';
import 'package:myapp/features/bookable_session/domain/entities/bookable_session_entity.dart';
import 'package:myapp/features/session_type/domain/usecases/get_session_types.dart';

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
      final getBookableSessions = sl<GetBookableSessions>();
      final getSessionTypes = sl<GetSessionTypes>();
      
      // Get bookable sessions for the instructor
      final sessionsResult = await getBookableSessions(GetBookableSessionsParams(instructorId: widget.instructorId));
      final sessionTypesResult = await getSessionTypes(NoParams());
      
      sessionsResult.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _sessionInfo = 'Session not found';
              _isLoading = false;
            });
          }
        },
        (sessions) {
          sessionTypesResult.fold(
            (failure) {
              if (mounted) {
                setState(() {
                  _sessionInfo = 'Session not found';
                  _isLoading = false;
                });
              }
            },
            (sessionTypes) {
              // Find the session by ID
              BookableSessionEntity? session;
              try {
                session = sessions.firstWhere((s) => s.id == widget.sessionId);
              } catch (e) {
                session = null;
              }
              
              if (session == null) {
                if (mounted) {
                  setState(() {
                    _sessionInfo = 'Session not found';
                    _isLoading = false;
                  });
                }
                return;
              }
              
              if (mounted) {
                setState(() {
                  // For now, we'll use a placeholder since session type lookup is not implemented
                  _sessionInfo = 'Session at Location TBD';
                  _isLoading = false;
                });
              }
            },
          );
        },
      );
    } catch (e) {
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


