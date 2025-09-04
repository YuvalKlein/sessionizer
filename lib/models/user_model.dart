import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final bool isInstructor;
  final bool admin;
  final String authSource;
  final String createdTime;
  final bool deservesFreeTrial;
  final bool disabled;
  final bool isVerified;
  final String? phone;
  final String? photoURL;
  final List<String> recentAddresses;
  final List<String> referralsIds;
  final String? referredById;
  final List<String> savedAddresses;
  final List<String> sessionsIds;
  final String subscriptionType;
  final String uuid;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.isInstructor = false,
    this.admin = false,
    this.authSource = 'email',
    required this.createdTime,
    this.deservesFreeTrial = true,
    this.disabled = false,
    this.isVerified = false,
    this.phone,
    this.photoURL,
    this.recentAddresses = const [],
    this.referralsIds = const [],
    this.referredById,
    this.savedAddresses = const [],
    this.sessionsIds = const [],
    this.subscriptionType = 'free',
    required this.uuid,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['email']?.split('@')[0] ?? 'Unknown',
      isInstructor: data['isInstructor'] ?? false,
      admin: data['admin'] ?? false,
      authSource: data['authSource'] ?? 'email',
      createdTime: data['createdTime'] ?? DateTime.now().toIso8601String(),
      deservesFreeTrial: data['deservesFreeTrial'] ?? true,
      disabled: data['disabled'] ?? false,
      isVerified: data['isVerified'] ?? false,
      phone: data['phone'],
      photoURL: data['photoURL'],
      recentAddresses: List<String>.from(data['recentAddresses'] ?? []),
      referralsIds: List<String>.from(data['referralsIds'] ?? []),
      referredById: data['referredById'],
      savedAddresses: List<String>.from(data['savedAddresses'] ?? []),
      sessionsIds: List<String>.from(data['sessionsIds'] ?? []),
      subscriptionType: data['subscriptionType'] ?? 'free',
      uuid: data['uuid'] ?? doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'isInstructor': isInstructor,
      'admin': admin,
      'authSource': authSource,
      'createdTime': createdTime,
      'deservesFreeTrial': deservesFreeTrial,
      'disabled': disabled,
      'isVerified': isVerified,
      'phone': phone,
      'photoURL': photoURL,
      'recentAddresses': recentAddresses,
      'referralsIds': referralsIds,
      'referredById': referredById,
      'savedAddresses': savedAddresses,
      'sessionsIds': sessionsIds,
      'subscriptionType': subscriptionType,
      'uuid': uuid,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isInstructor,
    bool? admin,
    String? authSource,
    String? createdTime,
    bool? deservesFreeTrial,
    bool? disabled,
    bool? isVerified,
    String? phone,
    String? photoURL,
    List<String>? recentAddresses,
    List<String>? referralsIds,
    String? referredById,
    List<String>? savedAddresses,
    List<String>? sessionsIds,
    String? subscriptionType,
    String? uuid,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isInstructor: isInstructor ?? this.isInstructor,
      admin: admin ?? this.admin,
      authSource: authSource ?? this.authSource,
      createdTime: createdTime ?? this.createdTime,
      deservesFreeTrial: deservesFreeTrial ?? this.deservesFreeTrial,
      disabled: disabled ?? this.disabled,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      recentAddresses: recentAddresses ?? this.recentAddresses,
      referralsIds: referralsIds ?? this.referralsIds,
      referredById: referredById ?? this.referredById,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      sessionsIds: sessionsIds ?? this.sessionsIds,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      uuid: uuid ?? this.uuid,
    );
  }
}
