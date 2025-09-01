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
  Query,
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

    // Stub the firestore collection/doc calls
    when(
      mockFirebaseFirestore.collection('users'),
    ).thenReturn(mockCollectionReference);
    when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);

    authService = AuthService(
      mockFirebaseAuth,
      firestore: mockFirebaseFirestore,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService', () {
    final mockUser = MockUser();
    when(mockUser.uid).thenReturn('123');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.email).thenReturn('test@example.com');

    group('signInWithGoogle', () {
      test(
        'returns a User and creates a new document when user is new',
        () async {
          final mockGoogleSignInAccount = MockGoogleSignInAccount();
          final mockGoogleSignInAuthentication =
              MockGoogleSignInAuthentication();
          final mockUserCredential = MockUserCredential();
          final mockDocumentSnapshot =
              MockDocumentSnapshot<Map<String, dynamic>>();

          when(
            mockGoogleSignIn.signIn(),
          ).thenAnswer((_) async => mockGoogleSignInAccount);
          when(
            mockGoogleSignInAccount.authentication,
          ).thenAnswer((_) async => mockGoogleSignInAuthentication);
          when(
            mockGoogleSignInAuthentication.accessToken,
          ).thenReturn('accessToken');
          when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
          when(
            mockFirebaseAuth.signInWithCredential(any),
          ).thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          when(
            mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(false);
          when(mockDocumentReference.set(any)).thenAnswer((_) async => {});

          final result = await authService.signInWithGoogle(false);

          expect(result, isA<User>());
          verify(mockDocumentReference.set(any)).called(1);
        },
      );

      test(
        'returns a User and does not create a new document when user exists',
        () async {
          final mockGoogleSignInAccount = MockGoogleSignInAccount();
          final mockGoogleSignInAuthentication =
              MockGoogleSignInAuthentication();
          final mockUserCredential = MockUserCredential();
          final mockDocumentSnapshot =
              MockDocumentSnapshot<Map<String, dynamic>>();

          when(
            mockGoogleSignIn.signIn(),
          ).thenAnswer((_) async => mockGoogleSignInAccount);
          when(
            mockGoogleSignInAccount.authentication,
          ).thenAnswer((_) async => mockGoogleSignInAuthentication);
          when(
            mockGoogleSignInAuthentication.accessToken,
          ).thenReturn('accessToken');
          when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
          when(
            mockFirebaseAuth.signInWithCredential(any),
          ).thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          when(
            mockDocumentReference.get(),
          ).thenAnswer((_) async => mockDocumentSnapshot);
          when(mockDocumentSnapshot.exists).thenReturn(true);

          final result = await authService.signInWithGoogle(false);

          expect(result, isA<User>());
          verifyNever(mockDocumentReference.set(any));
        },
      );

      test('returns null when Google Sign-In is cancelled', () async {
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await authService.signInWithGoogle(false);

        expect(result, isNull);
      });
    });

    group('registerWithEmailAndPassword', () {
      test('returns a User on successful registration', () async {
        final mockUserCredential = MockUserCredential();

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.updateDisplayName(any)).thenAnswer((_) async => {});
        when(mockDocumentReference.set(any)).thenAnswer((_) async => {});

        final result = await authService.registerWithEmailAndPassword(
          'test@example.com',
          'password',
          'Test User',
          false,
        );

        expect(result, isA<User>());
        verify(mockUser.updateDisplayName('Test User')).called(1);
        verify(
          mockDocumentReference.set({
            'displayName': 'Test User',
            'email': 'test@example.com',
            'isInstructor': false,
          }),
        ).called(1);
      });
    });

    group('signOut', () {
      test('calls signOut on both FirebaseAuth and GoogleSignIn', () async {
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

        await authService.signOut();

        verify(mockGoogleSignIn.signOut()).called(1);
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });
  });
}
