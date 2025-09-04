import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? photoUrl;
  final bool isInstructor;
  final bool isAdmin;
  final bool isVerified;
  final bool disabled;
  final String subscriptionType;
  final DateTime? createdTime;
  final List<String> recentAddresses;
  final List<String> savedAddresses;
  final List<String> sessionsIds;

  const UserProfileEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.photoUrl,
    required this.isInstructor,
    required this.isAdmin,
    required this.isVerified,
    required this.disabled,
    required this.subscriptionType,
    this.createdTime,
    required this.recentAddresses,
    required this.savedAddresses,
    required this.sessionsIds,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        phone,
        photoUrl,
        isInstructor,
        isAdmin,
        isVerified,
        disabled,
        subscriptionType,
        createdTime,
        recentAddresses,
        savedAddresses,
        sessionsIds,
      ];
}
