import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/data/models/user_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';
import 'package:myapp/core/services/google_signin_service.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle({required bool isInstructor});

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
  });

  Future<void> signOut();

  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignInService _googleSignInService;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignInService googleSignInService,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignInService = googleSignInService;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      print('🔄 Auth state changed: ${user?.uid}');
      if (user == null) {
        print('❌ No user - returning null');
        return null;
      }

      try {
        print('🔍 Looking for user document: ${user.uid}');
        final doc = await FirestoreCollections.user(user.uid).get();
        if (doc.exists) {
          print('✅ User document found - creating UserModel');
          return UserModel.fromFirestore(doc);
        }
        print('❌ User document not found');
        return null;
      } catch (e) {
        print('❌ Error fetching user data: $e');
        throw ServerException('Failed to fetch user data: $e');
      }
    });
  }

  @override
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    // This is a simplified version - in a real app, you'd want to cache this
    return null;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Sign in failed');
      }

      final userDoc = await FirestoreCollections.user(
        credential.user!.uid,
      ).get();
      if (!userDoc.exists) {
        throw const AuthException('User profile not found');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message =
              'Network error. Please check your connection and try again.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password. Please check your credentials.';
          break;
        default:
          message = 'Sign in failed: ${e.message ?? 'Unknown error'}';
      }
      throw AuthException(message);
    } catch (e) {
      print('❌ General exception during sign in: $e');
      // Check if it's a user profile not found error
      if (e.toString().contains('User profile not found')) {
        throw const AuthException('No account found with this email address.');
      }
      throw ServerException('Connection error. Please try again.');
    }
  }

  @override
  Future<UserModel> signInWithGoogle({required bool isInstructor}) async {
    try {
      final result = await _googleSignInService.signInWithGoogle(
        isInstructor: isInstructor,
      );
      if (result == null) {
        throw const AuthException('Google sign in cancelled');
      }

      // Create user document in Firestore if it doesn't exist
      final user = result.user!;
      final userDoc = await FirestoreCollections.user(user.uid).get();

      if (!userDoc.exists) {
        final userData = {
          'id': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'role': isInstructor ? 'instructor' : 'client',
          'isInstructor': isInstructor,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirestoreCollections.user(user.uid).set(userData);

        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          firstName: user.displayName?.split(' ').first ?? '',
          lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
          phoneNumber: user.phoneNumber ?? '',
          role: isInstructor ? 'instructor' : 'client',
          isInstructor: isInstructor,
        );
      } else {
        return UserModel.fromFirestore(userDoc);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException('Google sign in failed: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      print('🔐 Starting signup process for: $email');
      print('📊 Firestore instance: ${_firestore.app.name}');
      print('📊 Database ID: ${_firestore.databaseId}');
      print('📊 Firestore app options: ${_firestore.app.options.projectId}');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Sign up failed');
      }

      final user = credential.user!;
      print('✅ Firebase Auth user created: ${user.uid}');

      final newUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
        isInstructor: role == 'instructor',
        displayName: '$firstName $lastName',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('💾 Creating user document in Firestore...');
      print('📁 Collection path: sessionizer/users/users/${user.uid}');

      // Test write to see if we have permissions
      try {
        await FirestoreCollections.users.doc('test').set({'test': 'value'});
        print('✅ Test write successful - permissions are working');
        await FirestoreCollections.users.doc('test').delete();
        print('✅ Test cleanup successful');
      } catch (e) {
        print('❌ Test write failed: $e');
      }

      await FirestoreCollections.user(user.uid).set(newUser.toMap());
      print('✅ User document created successfully!');

      // Wait a moment for the auth state changes to pick up the new user
      await Future.delayed(const Duration(milliseconds: 100));

      return newUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account with this email already exists. Please sign in instead.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'network-request-failed':
          message =
              'Network error. Please check your connection and try again.';
          break;
        default:
          message = 'Sign up failed: ${e.message}';
      }
      throw AuthException(message);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw ServerException('Connection error. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      AppLogger.info('🔄 Starting sign out process...');

      // Sign out from Firebase Auth
      AppLogger.info('🔄 Signing out from Firebase Auth...');
      await _firebaseAuth.signOut();
      AppLogger.info('✅ Firebase Auth sign out successful');

      AppLogger.info('✅ Sign out process completed successfully');
    } catch (e) {
      AppLogger.error('❌ Sign out failed with error: $e');
      throw ServerException('Sign out failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user to delete');
      }

      await FirestoreCollections.user(user.uid).delete();
      await user.delete();
    } catch (e) {
      throw ServerException('Account deletion failed: $e');
    }
  }
}
