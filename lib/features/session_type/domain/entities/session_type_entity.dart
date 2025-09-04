import 'package:equatable/equatable.dart';

class SessionTypeEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionTypeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        id,
        name,
        description,
        color,
        isActive,
        createdAt,
        updatedAt,
      ];
}
