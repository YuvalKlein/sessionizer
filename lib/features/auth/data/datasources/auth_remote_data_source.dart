import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  Future<UserModel> signInWithGoogle({
    required bool isInstructor,
  });
  
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isInstructor,
  });
  
  Future<void> signOut();
  
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

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
        final doc = await _firestore.collection('sessionizer').doc('users').collection('users').doc(user.uid).get();
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
      
      final userDoc = await _firestore.collection('sessionizer').doc('users').collection('users').doc(credential.user!.uid).get();
      if (!userDoc.exists) {
        throw const AuthException('User profile not found');
      }
      
      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw AuthException('Sign in failed: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle({
    required bool isInstructor,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw const AuthException('Google sign in failed');
      }

      final user = userCredential.user!;
      final userDoc = await _firestore.collection('sessionizer').doc('users').collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      } else {
        // Create new user profile
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isInstructor: isInstructor,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestore.collection('sessionizer').doc('users').collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
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
    required String name,
    required bool isInstructor,
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
        displayName: name,
        photoUrl: user.photoURL,
        isInstructor: isInstructor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('💾 Creating user document in Firestore...');
      print('📁 Collection path: sessionizer/users/users/${user.uid}');
      
      // Test write to see if we have permissions
      try {
        await _firestore.collection('test').doc('test').set({'test': 'value'});
        print('✅ Test write successful - permissions are working');
        await _firestore.collection('test').doc('test').delete();
        print('✅ Test cleanup successful');
      } catch (e) {
        print('❌ Test write failed: $e');
      }
      
      await _firestore.collection('sessionizer').doc('users').collection('users').doc(user.uid).set(newUser.toMap());
      print('✅ User document created successfully!');
      
      // Wait a moment for the auth state changes to pick up the new user
      await Future.delayed(const Duration(milliseconds: 100));
      
      return newUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.message}');
      throw AuthException('Sign up failed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      AppLogger.info('🔄 Starting sign out process...');
      
      // Always sign out from Firebase Auth first
      AppLogger.info('🔄 Signing out from Firebase Auth...');
      await _firebaseAuth.signOut();
      AppLogger.info('✅ Firebase Auth sign out successful');
      
      // For web platform, only use Firebase Auth sign out
      // Google Sign-In sign out on web can cause issues
      if (!kIsWeb) {
        try {
          AppLogger.info('🔄 Signing out from Google Sign-In (non-web platform)...');
          await _googleSignIn.signOut();
          AppLogger.info('✅ Google Sign-In sign out successful');
        } catch (googleError) {
          AppLogger.warning('⚠️ Google Sign-In signOut failed (this is OK): $googleError');
        }
      } else {
        AppLogger.info('🌐 Web platform detected - skipping Google Sign-In sign out');
      }
      
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
      
      await _firestore.collection('sessionizer').doc('users').collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      throw ServerException('Account deletion failed: $e');
    }
  }
}
