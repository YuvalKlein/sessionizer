import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final bool isInstructor;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.isInstructor = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? data['displayName'] ?? data['email']?.split('@')[0] ?? 'Unknown',
      isInstructor: data['isInstructor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'name': name, 'isInstructor': isInstructor};
  }
}
