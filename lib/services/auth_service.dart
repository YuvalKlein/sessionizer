import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    } catch (e) {
      print(e.toString());
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
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
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
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
