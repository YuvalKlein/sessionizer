import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/auth_service.dart';
import 'auth_service_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  User,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference<Map<String, dynamic>>();
    mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();

    authService = AuthService(
      mockFirebaseAuth,
      firestore: mockFirebaseFirestore,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService', () {
    test('signInWithGoogle returns a User on successful sign in', () async {
      final mockGoogleSignInAccount = MockGoogleSignInAccount();
      final mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();
      final mockDocumentSnapshot = MockDocumentSnapshot();

      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken).thenReturn('accessToken');
      when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');

      when(mockFirebaseFirestore.collection('users')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(false);

      final result = await authService.signInWithGoogle();

      expect(result, isA<User>());
      verify(mockFirebaseFirestore.collection('users').doc(mockUser.uid).set(any)).called(1);
    });
  });
}
