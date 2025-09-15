import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  GoogleSignIn? _googleSignIn;
  bool _initializationFailed = false;
  
  // Safe initialization that won't fail during service creation

  Future<UserCredential?> signInWithGoogle({required bool isInstructor}) async {
    try {
      developer.log('🔐 Starting Google Sign-In process...');
      
      // Check if Google Sign-In is properly configured
      if (_initializationFailed) {
        throw Exception('Google Sign-In is currently unavailable. Please use email and password to sign in.');
      }
      
      try {
        // Initialize GoogleSignIn lazily to avoid startup errors
        if (_googleSignIn == null) {
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
            clientId: '707974722454-o7f4paigfd3nkpihs3fvbto2m5obc1h0.apps.googleusercontent.com',
          );
        }
        
        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        
        if (googleUser == null) {
          developer.log('🚫 User cancelled Google Sign-In');
          return null;
        }

        developer.log('✅ Google Sign-In successful for: ${googleUser.email}');

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        
        developer.log('✅ Firebase authentication successful');
        return userCredential;
      } catch (e) {
        if (e.toString().contains('ClientID not set') || e.toString().contains('appClientId != null')) {
          developer.log('⚠️ Google Sign-In not configured for development environment');
          _initializationFailed = true;
          throw Exception('Google Sign-In is currently unavailable. Please use email and password to sign in.');
        }
        rethrow;
      }
      
    } catch (e) {
      developer.log('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
        developer.log('✅ Google Sign-Out successful');
      }
    } catch (e) {
      developer.log('❌ Google Sign-Out failed: $e');
      rethrow;
    }
  }
}