import 'package:flutter/material.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/schedulable_session/domain/usecases/get_schedulable_sessions.dart';
import 'package:myapp/features/schedulable_session/domain/entities/schedulable_session_entity.dart';
import 'package:myapp/features/session_type/domain/usecases/get_session_types.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';

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
      final getSchedulableSessions = sl<GetSchedulableSessions>();
      final getSessionTypes = sl<GetSessionTypes>();
      
      // Get schedulable sessions for the instructor
      final sessionsResult = await getSchedulableSessions(GetSchedulableSessionsParams(instructorId: widget.instructorId));
      final sessionTypesResult = await getSessionTypes(NoParams());
      
      sessionsResult.fold(
        (failure) {
          setState(() {
            _sessionInfo = 'Session not found';
            _isLoading = false;
          });
        },
        (sessions) {
          sessionTypesResult.fold(
            (failure) {
              setState(() {
                _sessionInfo = 'Session not found';
                _isLoading = false;
              });
            },
            (sessionTypes) {
              // Find the session by ID
              SchedulableSessionEntity? session;
              try {
                session = sessions.firstWhere((s) => s.id == widget.sessionId);
              } catch (e) {
                session = null;
              }
              
              if (session == null) {
                setState(() {
                  _sessionInfo = 'Session not found';
                  _isLoading = false;
                });
                return;
              }
              
              // Find the session type - TODO: Update for new structure
              SessionTypeEntity? sessionType;
              // try {
              //   sessionType = sessionTypes.firstWhere((st) => st.id == session!.sessionTypeId);
              // } catch (e) {
              //   sessionType = null;
              // }
              
              if (sessionType == null) {
                setState(() {
                  _sessionInfo = 'Session type not found';
                  _isLoading = false;
                });
                return;
              }
              
              setState(() {
                // For now, we'll use a placeholder for location since it's not in the current data model
                _sessionInfo = '${sessionType!.title} at Location TBD';
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _sessionInfo = 'Session not found';
        _isLoading = false;
      });
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
