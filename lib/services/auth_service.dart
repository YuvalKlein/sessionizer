import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '707974722454-e0k6vrq6c05v25vgs3qda2v324n53g97.apps.googleusercontent.com',
  );

  Future<User?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uuid': user.uid,
          'displayName': displayName,
          'email': email,
          'sessionsQuataExceeded': false,
          'deservesFreeTrial': true,
          'subscriptionType': 'free',
          'disabled': false,
          'recentAddresses': [],
          'savedAddresses': [],
          'authSource': 'email',
          'isVerified': user.emailVerified,
          'admin': false,
          'referralsIds': [],
          'photoURL': user.photoURL,
          'isInstructor': false,
          'phone': user.phoneNumber,
          'createdTime': DateTime.now().toIso8601String(),
          'referredById': null,
          'sessionsIds': [],
        });
      }
      return user;
    } catch (e, s) {
      developer.log('Error during email/password registration', name: 'myapp.auth', error: e, stackTrace: s);
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e, s) {
      developer.log('Error during email/password sign-in', name: 'myapp.auth', error: e, stackTrace: s);
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uuid': user.uid,
            'displayName': user.displayName,
            'email': user.email,
            'sessionsQuataExceeded': false,
            'deservesFreeTrial': true,
            'subscriptionType': 'free',
            'disabled': false,
            'recentAddresses': [],
            'savedAddresses': [],
            'authSource': 'google',
            'isVerified': user.emailVerified,
            'admin': false,
            'referralsIds': [],
            'photoURL': user.photoURL,
            'isInstructor': false,
            'phone': user.phoneNumber,
            'createdTime': DateTime.now().toIso8601String(),
            'referredById': null,
            'sessionsIds': [],
          });
        }
      }

      return user;
    } catch (e, s) {
      developer.log('Error during Google Sign-In', name: 'myapp.auth', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
