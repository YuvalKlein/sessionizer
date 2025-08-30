import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  FirebaseFirestore,
  GoogleSignIn,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  GoogleSignInAccount,
  GoogleSignInAuthentication
])
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
    late MockDocumentReference<Map<String, dynamic>> mockUserDocument;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUsersCollection = MockCollectionReference();
      mockUserDocument = MockDocumentReference();

      when(mockFirebaseFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc(any)).thenReturn(mockUserDocument);
      when(mockUserDocument.set(any)).thenAnswer((_) async => Future.value());

      authService = AuthService(
        mockFirebaseAuth,
        firestore: mockFirebaseFirestore,
        googleSignIn: mockGoogleSignIn,
      );
    });

    test('signIn success', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockUser.uid).thenReturn('123');
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);

      final user = await authService.signInWithEmailAndPassword('test@example.com', 'password123');
      expect(user, isNotNull);
      expect(user, isA<User>());
    });

    test('signIn failure - wrong password', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => authService.signInWithEmailAndPassword('test@example.com', 'wrongpassword'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('register success', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockUser.uid).thenReturn('123');
      when(mockUser.emailVerified).thenReturn(false);
      when(mockUser.photoURL).thenReturn(null);
      when(mockUser.phoneNumber).thenReturn(null);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.updateDisplayName(any)).thenAnswer((_) => Future.value());

      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);

      final user = await authService.registerWithEmailAndPassword('newuser@example.com', 'password123', 'New User');
      expect(user, isNotNull);
      expect(user, isA<User>());
      verify(mockUserDocument.set(any));
    });

    test('register failure - email already in use', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => authService.registerWithEmailAndPassword('test@example.com', 'password123', 'Test User'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
