import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/data/models/user_model.dart';
import '../shared/rest_base_data_source.dart';
import '../shared/rest_response_model.dart';
import '../shared/api_config.dart';

abstract class AuthRemoteRestDataSource {
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
  
  Future<void> sendPasswordResetEmail(String email);
  
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  });
  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteRestDataSourceImpl extends RestBaseDataSource implements AuthRemoteRestDataSource {
  final GoogleSignIn _googleSignIn;

  AuthRemoteRestDataSourceImpl({
    required http.Client httpClient,
    required FirebaseAuth firebaseAuth,
    required String baseUrl,
    required GoogleSignIn googleSignIn,
    Duration timeout = const Duration(seconds: 30),
  }) : _googleSignIn = googleSignIn,
       super(
         httpClient: httpClient,
         firebaseAuth: firebaseAuth,
         baseUrl: baseUrl,
         timeout: timeout,
       );

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      try {
        AppLogger.info('🔍 Auth state changed, fetching user profile');
        final response = await get('/auth/profile');
        return UserModel.fromMap(response['data']);
      } catch (e) {
        AppLogger.error('❌ Failed to fetch user profile: $e');
        return null;
      }
    });
  }

  @override
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    
    // In a real implementation, you might want to cache this
    return null;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔐 Signing in with email and password');
      
      // First, authenticate with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw const AuthException('Sign in failed');
      }
      
      // Get the Firebase ID token
      final token = await credential.user!.getIdToken();
      
      // Use the token to authenticate with the REST API
      final response = await post(
        '/auth/signin',
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );
      
      AppLogger.info('✅ Sign in successful');
      return UserModel.fromMap(response['data']);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase auth error: ${e.message}');
      throw AuthException('Sign in failed: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Sign in error: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Sign in failed: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle({
    required bool isInstructor,
  }) async {
    try {
      AppLogger.info('🔐 Signing in with Google');
      
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw const AuthException('Google sign in failed');
      }

      // Get the Firebase ID token
      final token = await userCredential.user!.getIdToken();
      
      // Use the token to authenticate with the REST API
      final response = await post(
        '/auth/google-signin',
        body: {
          'idToken': token,
          'isInstructor': isInstructor,
        },
        requireAuth: false,
      );
      
      AppLogger.info('✅ Google sign in successful');
      return UserModel.fromMap(response['data']);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase auth error: ${e.message}');
      throw AuthException('Google sign in failed: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Google sign in error: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Google sign in failed: $e');
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
      AppLogger.info('📝 Signing up with email and password');
      
      // First, create user with Firebase
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw const AuthException('Sign up failed');
      }

      // Get the Firebase ID token
      final token = await credential.user!.getIdToken();
      
      // Use the token to create user profile via REST API
      final response = await post(
        '/auth/signup',
        body: {
          'email': email,
          'password': password,
          'name': name,
          'isInstructor': isInstructor,
        },
        requireAuth: false,
      );
      
      AppLogger.info('✅ Sign up successful');
      return UserModel.fromMap(response['data']);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase auth error: ${e.message}');
      throw AuthException('Sign up failed: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Sign up error: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Sign up failed: $e');
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
      
      // Sign out from Google Sign-In (non-web platforms only)
      if (!kIsWeb) {
        try {
          AppLogger.info('🔄 Signing out from Google Sign-In...');
          await _googleSignIn.signOut();
          AppLogger.info('✅ Google Sign-In sign out successful');
        } catch (googleError) {
          AppLogger.warning('⚠️ Google Sign-In signOut failed: $googleError');
        }
      } else {
        AppLogger.info('🌐 Web platform detected - skipping Google Sign-In sign out');
      }
      
      // Notify the REST API about sign out
      try {
        await post('/auth/signout');
        AppLogger.info('✅ REST API sign out successful');
      } catch (e) {
        AppLogger.warning('⚠️ REST API sign out failed: $e');
        // Don't throw here as the local sign out was successful
      }
      
      AppLogger.info('✅ Sign out process completed successfully');
    } catch (e) {
      AppLogger.error('❌ Sign out failed: $e');
      throw ServerException('Sign out failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      AppLogger.info('🗑️ Starting account deletion process...');
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user to delete');
      }
      
      // Delete account via REST API first
      await delete('/auth/account');
      AppLogger.info('✅ REST API account deletion successful');
      
      // Delete Firebase user
      await user.delete();
      AppLogger.info('✅ Firebase account deletion successful');
      
      AppLogger.info('✅ Account deletion completed successfully');
    } catch (e) {
      AppLogger.error('❌ Account deletion failed: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Account deletion failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('📧 Sending password reset email to: $email');
      
      await post(
        '/auth/password-reset',
        body: {'email': email},
        requireAuth: false,
      );
      
      AppLogger.info('✅ Password reset email sent successfully');
    } catch (e) {
      AppLogger.error('❌ Password reset email failed: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Password reset email failed: $e');
    }
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      AppLogger.info('✏️ Updating user profile');
      
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (photoUrl != null) body['photoUrl'] = photoUrl;
      
      await put('/auth/profile', body: body);
      
      AppLogger.info('✅ Profile updated successfully');
    } catch (e) {
      AppLogger.error('❌ Profile update failed: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Profile update failed: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔐 Changing password');
      
      await put(
        '/auth/password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      AppLogger.info('✅ Password changed successfully');
    } catch (e) {
      AppLogger.error('❌ Password change failed: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Password change failed: $e');
    }
  }

  /// Get user profile from REST API
  Future<UserModel> getUserProfile() async {
    try {
      AppLogger.info('🔍 Fetching user profile');
      
      final response = await get('/auth/profile');
      return UserModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Failed to fetch user profile: $e');
      if (e is NotFoundException) {
        throw AuthException('User profile not found');
      }
      rethrow;
    }
  }

  /// Refresh user profile
  Future<UserModel> refreshUserProfile() async {
    try {
      AppLogger.info('🔄 Refreshing user profile');
      
      // Force refresh the Firebase token
      await _firebaseAuth.currentUser?.reload();
      final token = await _firebaseAuth.currentUser?.getIdToken(true);
      
      if (token == null) {
        throw const AuthException('Failed to refresh authentication token');
      }
      
      final response = await get('/auth/profile');
      return UserModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Failed to refresh user profile: $e');
      if (e is AuthException) rethrow;
      throw ServerException('Failed to refresh user profile: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;
      
      // Verify the token is still valid
      final token = await user.getIdToken();
      return token != null;
    } catch (e) {
      AppLogger.error('❌ Authentication check failed: $e');
      return false;
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      return await user.getIdToken();
    } catch (e) {
      AppLogger.error('❌ Failed to get auth token: $e');
      return null;
    }
  }
}
