import 'package:flutter/material.dart';
import 'package:myapp/models/session.dart';
import 'package:myapp/services/session_service.dart';

class SessionViewModel extends ChangeNotifier {
  final SessionService _sessionService;

  SessionViewModel(this._sessionService);

  Stream<List<Session>> getSessions(String userId, bool isInstructor) {
    return _sessionService.getSessions(userId, isInstructor);
  }
}
