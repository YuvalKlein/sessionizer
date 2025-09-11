import 'dart:html' as html;
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/data/models/user_model.dart';
import 'package:myapp/core/config/firestore_collections.dart';

class GoogleSignInService {
  static const String _clientId = '707974722454-o7f4paigfd3nkpihs3fvbto2m5obc1h0.apps.googleusercontent.com';
  
  Future<UserModel?> signInWithGoogle({required bool isInstructor}) async {
    try {
      AppLogger.info('🔐 Starting Google Sign-In with modern GSI');
      
      // Use Google Identity Services
      final result = await _signInWithGSI();
      if (result == null) {
        AppLogger.info('❌ Google Sign-In cancelled by user');
        return null;
      }
      
      AppLogger.info('✅ Google Sign-In successful, creating Firebase credential');
      
      // Create Firebase credential using access token
      final credential = GoogleAuthProvider.credential(
        accessToken: result['access_token'],
      );
      
      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Firebase sign-in failed');
      }
      
      final user = userCredential.user!;
      AppLogger.info('✅ Firebase authentication successful: ${user.uid}');
      
      // Check if user exists in Firestore
      final userDoc = await FirestoreCollections.user(user.uid).get();
      
      if (userDoc.exists) {
        AppLogger.info('✅ Existing user found, returning user data');
        return UserModel.fromFirestore(userDoc);
      } else {
        AppLogger.info('🆕 New user, creating profile');
        // Create new user profile
        final displayName = user.displayName ?? '';
        final nameParts = displayName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
        final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
        
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          firstName: firstName,
          lastName: lastName,
          phoneNumber: '000-000-0000', // Default value
          role: isInstructor ? 'instructor' : 'client',
          isInstructor: isInstructor,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await FirestoreCollections.user(user.uid).set(newUser.toMap());
        AppLogger.info('✅ New user profile created successfully');
        return newUser;
      }
    } catch (e) {
      AppLogger.error('❌ Google Sign-In error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }
  
  Future<Map<String, dynamic>?> _signInWithGSI() async {
    try {
      // Create a completer for the response
      final completer = Completer<Map<String, dynamic>?>();
      
      // Set up event listeners
      final successSubscription = html.window.onMessage.listen((event) {
        if (event.data is Map && event.data['type'] == 'googleSignInSuccess') {
          AppLogger.info('🔐 GSI success event received');
          // Convert LinkedMap to Map<String, dynamic>
          final response = event.data['response'];
          if (response is Map) {
            final convertedResponse = <String, dynamic>{};
            response.forEach((key, value) {
              convertedResponse[key.toString()] = value;
            });
            completer.complete(convertedResponse);
          } else {
            completer.complete(null);
          }
        }
      });
      
      final errorSubscription = html.window.onMessage.listen((event) {
        if (event.data is Map && event.data['type'] == 'googleSignInError') {
          AppLogger.error('❌ GSI error event received: ${event.data['error']}');
          completer.complete(null);
        }
      });
      
      // Initialize Google Sign-In
      _initializeGoogleSignIn();
      
      // Wait for user interaction
      final result = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          AppLogger.error('❌ Google Sign-In timeout');
          return null;
        },
      );
      
      // Clean up listeners
      successSubscription.cancel();
      errorSubscription.cancel();
      
      return result;
    } catch (e) {
      AppLogger.error('❌ GSI setup error: $e');
      return null;
    }
  }
  
  void _initializeGoogleSignIn() {
    final script = '''
      // Wait for Google Identity Services to load
      function waitForGoogle() {
        if (typeof google !== 'undefined' && google.accounts) {
          // Initialize OAuth2 for popup flow
          google.accounts.oauth2.initTokenClient({
            client_id: '$_clientId',
            scope: 'email profile',
            callback: function(response) {
              console.log('Google OAuth2 response received');
              window.postMessage({
                type: 'googleSignInSuccess',
                response: response
              }, '*');
            },
            error_callback: function(error) {
              console.error('Google OAuth2 error:', error);
              window.postMessage({
                type: 'googleSignInError',
                error: error
              }, '*');
            }
          }).requestAccessToken();
        } else {
          // Retry after a short delay
          setTimeout(waitForGoogle, 100);
        }
      }
      
      waitForGoogle();
    ''';
    
    final scriptElement = html.ScriptElement()
      ..text = script
      ..type = 'text/javascript';
    html.document.head!.append(scriptElement);
  }
}
