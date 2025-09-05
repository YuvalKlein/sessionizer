import 'package:equatable/equatable.dart';

class SessionTypeEntity extends Equatable {
  final String? id;
  final String title;
  final bool notifyCancelation;
  final int createdTime;
  final int duration;
  final String durationUnit;
  final String details;
  final String idCreatedBy;
  final int maxPlayers;
  final int minPlayers;
  final bool showParticipants;
  final String category;
  final int price;

  const SessionTypeEntity({
    this.id,
    required this.title,
    this.notifyCancelation = false,
    required this.createdTime,
    required this.duration,
    this.durationUnit = 'minutes',
    this.details = '',
    required this.idCreatedBy,
    required this.maxPlayers,
    this.minPlayers = 1,
    this.showParticipants = true,
    this.category = '',
    required this.price,
  });

  @override
  List<Object?> get props => [
              id,
      title,
      notifyCancelation,
        createdTime,
        duration,
        durationUnit,
              details,
      idCreatedBy,
      maxPlayers,
      minPlayers,
      showParticipants,
        category,
        price,
      ];
}
