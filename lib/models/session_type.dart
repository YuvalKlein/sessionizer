import 'package:cloud_firestore/cloud_firestore.dart';

class SessionType {
  final String? id;
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
  final int price;

  SessionType({
    this.id,
    required this.title,
    this.timeZoneOffsetInHours = 0,
    this.notifyCancelation = false,
    required this.createdTime,
    required this.duration,
    this.durationUnit = 'minutes',
    this.details = '',
    required this.idCreatedBy,
    required this.idInstructor,
    this.playersIds = const [],
    required this.maxPlayers,
    this.minPlayers = 0,
    this.canceled = false,
    this.repeatingSession = false,
    this.attendanceData = const [],
    this.showParticipants = true,
    this.category = '',
    required this.price,
  });

  factory SessionType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionType(
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
      price: data['price'] ?? 0,
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
      'price': price,
    };
  }

  SessionType copyWith({
    String? id,
    String? title,
    num? timeZoneOffsetInHours,
    bool? notifyCancelation,
    int? createdTime,
    int? duration,
    String? durationUnit,
    String? details,
    String? idCreatedBy,
    String? idInstructor,
    List<String>? playersIds,
    int? maxPlayers,
    int? minPlayers,
    bool? canceled,
    bool? repeatingSession,
    List<dynamic>? attendanceData,
    bool? showParticipants,
    String? category,
    int? price,
  }) {
    return SessionType(
      id: id ?? this.id,
      title: title ?? this.title,
      timeZoneOffsetInHours: timeZoneOffsetInHours ?? this.timeZoneOffsetInHours,
      notifyCancelation: notifyCancelation ?? this.notifyCancelation,
      createdTime: createdTime ?? this.createdTime,
      duration: duration ?? this.duration,
      durationUnit: durationUnit ?? this.durationUnit,
      details: details ?? this.details,
      idCreatedBy: idCreatedBy ?? this.idCreatedBy,
      idInstructor: idInstructor ?? this.idInstructor,
      playersIds: playersIds ?? this.playersIds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      canceled: canceled ?? this.canceled,
      repeatingSession: repeatingSession ?? this.repeatingSession,
      attendanceData: attendanceData ?? this.attendanceData,
      showParticipants: showParticipants ?? this.showParticipants,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }
}
