
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionTemplate {
  final String id;
  final String title;
  final num timeZoneOffsetInHours;
  final bool notifyCancelation;
  final int createdTime;
  final int duration;
  final String durationUnit;
  final String details;
  final String idCreatedBy;
  final String idInstructor;
  final List<String> playersIds;
  final int maxPlayers;
  final int minPlayers;
  final bool canceled;
  final bool repeatingSession;
  final List<dynamic> attendanceData;
  final bool showParticipants;
  final String category;

  SessionTemplate({
    required this.id,
    required this.title,
    required this.timeZoneOffsetInHours,
    required this.notifyCancelation,
    required this.createdTime,
    required this.duration,
    required this.durationUnit,
    required this.details,
    required this.idCreatedBy,
    required this.idInstructor,
    required this.playersIds,
    required this.maxPlayers,
    required this.minPlayers,
    required this.canceled,
    required this.repeatingSession,
    required this.attendanceData,
    required this.showParticipants,
    required this.category,
  });

  factory SessionTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionTemplate(
      id: doc.id,
      title: data['title'] ?? '',
      timeZoneOffsetInHours: data['timeZoneOffsetInHours'] ?? 0,
      notifyCancelation: data['notifyCancelation'] ?? false,
      createdTime: data['createdTime'] ?? 0,
      duration: data['duration'] ?? 0,
      durationUnit: data['durationUnit'] ?? 'minutes',
      details: data['details'] ?? '',
      idCreatedBy: data['idCreatedBy'] ?? '',
      idInstructor: data['idInstructor'] ?? '',
      playersIds: List<String>.from(data['playersIds'] ?? []),
      maxPlayers: data['maxPlayers'] ?? 0,
      minPlayers: data['minPlayers'] ?? 0,
      canceled: data['canceled'] ?? false,
      repeatingSession: data['repeatingSession'] ?? false,
      attendanceData: List<dynamic>.from(data['attendanceData'] ?? []),
      showParticipants: data['showParticipants'] ?? false,
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'timeZoneOffsetInHours': timeZoneOffsetInHours,
      'notifyCancelation': notifyCancelation,
      'createdTime': createdTime,
      'duration': duration,
      'durationUnit': durationUnit,
      'details': details,
      'idCreatedBy': idCreatedBy,
      'idInstructor': idInstructor,
      'playersIds': playersIds,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'canceled': canceled,
      'repeatingSession': repeatingSession,
      'attendanceData': attendanceData,
      'showParticipants': showParticipants,
      'category': category,
    };
  }
}
