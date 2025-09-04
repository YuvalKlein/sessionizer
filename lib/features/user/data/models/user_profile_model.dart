import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.phone,
    super.photoUrl,
    required super.isInstructor,
    required super.isAdmin,
    required super.isVerified,
    required super.disabled,
    required super.subscriptionType,
    super.createdTime,
    required super.recentAddresses,
    required super.savedAddresses,
    required super.sessionsIds,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoURL'],
      isInstructor: data['isInstructor'] ?? false,
      isAdmin: data['admin'] ?? false,
      isVerified: data['isVerified'] ?? false,
      disabled: data['disabled'] ?? false,
      subscriptionType: data['subscriptionType'] ?? 'free',
      createdTime: data['createdTime'] != null
          ? DateTime.tryParse(data['createdTime'])
          : null,
      recentAddresses: List<String>.from(data['recentAddresses'] ?? []),
      savedAddresses: List<String>.from(data['savedAddresses'] ?? []),
      sessionsIds: List<String>.from(data['sessionsIds'] ?? []),
    );
  }

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
      isInstructor: entity.isInstructor,
      isAdmin: entity.isAdmin,
      isVerified: entity.isVerified,
      disabled: entity.disabled,
      subscriptionType: entity.subscriptionType,
      createdTime: entity.createdTime,
      recentAddresses: entity.recentAddresses,
      savedAddresses: entity.savedAddresses,
      sessionsIds: entity.sessionsIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'photoURL': photoUrl,
      'isInstructor': isInstructor,
      'admin': isAdmin,
      'isVerified': isVerified,
      'disabled': disabled,
      'subscriptionType': subscriptionType,
      'createdTime': createdTime?.toIso8601String(),
      'recentAddresses': recentAddresses,
      'savedAddresses': savedAddresses,
      'sessionsIds': sessionsIds,
    };
  }
}
