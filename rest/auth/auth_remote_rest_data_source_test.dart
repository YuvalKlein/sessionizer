import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/features/auth/data/models/user_model.dart';
import 'auth_remote_rest_data_source.dart';

import 'auth_remote_rest_data_source_test.mocks.dart';

@GenerateMocks([http.Client, FirebaseAuth, User, GoogleSignIn, GoogleSignInAccount, GoogleSignInAuthentication])
void main() {
  group('AuthRemoteRestDataSourceImpl', () {
    late AuthRemoteRestDataSourceImpl dataSource;
    late MockClient mockHttpClient;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockGoogleAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;

    const baseUrl = 'https://test-api.com';
    const authToken = 'test-auth-token';

    setUp(() {
      mockHttpClient = MockClient();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockGoogleSignIn = MockGoogleSignIn();
      mockGoogleAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
      
      dataSource = AuthRemoteRestDataSourceImpl(
        httpClient: mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
        baseUrl: baseUrl,
        googleSignIn: mockGoogleSignIn,
      );

      // Setup common mock behavior
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken()).thenAnswer((_) async => authToken);
    });

    group('signInWithEmailAndPassword', () {
      test('should return user when sign in is successful', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'user_123',
            'email': email,
            'displayName': 'Test User',
            'photoUrl': null,
            'isInstructor': false,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signin'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<UserModel>());
        expect(result.id, 'user_123');
        expect(result.email, email);
        expect(result.displayName, 'Test User');
        expect(result.isInstructor, false);
      });

      test('should throw AuthException when credentials are invalid', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signin'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Invalid credentials"}', 401));

        // Act & Assert
        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('should return user when sign up is successful', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        const name = 'New User';
        const isInstructor = false;
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'user_456',
            'email': email,
            'displayName': name,
            'photoUrl': null,
            'isInstructor': isInstructor,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signup'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 201));

        // Act
        final result = await dataSource.signUpWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
          isInstructor: isInstructor,
        );

        // Assert
        expect(result, isA<UserModel>());
        expect(result.id, 'user_456');
        expect(result.email, email);
        expect(result.displayName, name);
        expect(result.isInstructor, isInstructor);
      });

      test('should throw AuthException when email already exists', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'password123';
        const name = 'Existing User';
        const isInstructor = false;

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signup'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"error": "Email already exists"}', 409));

        // Act & Assert
        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: email,
            password: password,
            name: name,
            isInstructor: isInstructor,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should return user when Google sign in is successful', () async {
        // Arrange
        const isInstructor = false;
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'user_789',
            'email': 'user@gmail.com',
            'displayName': 'Google User',
            'photoUrl': 'https://lh3.googleusercontent.com/photo.jpg',
            'isInstructor': isInstructor,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
        when(mockGoogleAccount.authentication).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('access_token');
        when(mockGoogleAuth.idToken).thenReturn('id_token');

        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/google-signin'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.signInWithGoogle(isInstructor: isInstructor);

        // Assert
        expect(result, isA<UserModel>());
        expect(result.id, 'user_789');
        expect(result.email, 'user@gmail.com');
        expect(result.displayName, 'Google User');
        expect(result.isInstructor, isInstructor);
      });

      test('should throw AuthException when Google sign in is cancelled', () async {
        // Arrange
        const isInstructor = false;

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => dataSource.signInWithGoogle(isInstructor: isInstructor),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signout'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signout'),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should handle REST API sign out failure gracefully', () async {
        // Arrange
        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/signout'),
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Network error'));

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        // Should not throw even if REST API fails
      });
    });

    group('deleteAccount', () {
      test('should delete account successfully', () async {
        // Arrange
        when(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/auth/account'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        // Act
        await dataSource.deleteAccount();

        // Assert
        verify(mockHttpClient.delete(
          Uri.parse('$baseUrl/api/v1/auth/account'),
          headers: anyNamed('headers'),
        )).called(1);
        verify(mockUser.delete()).called(1);
      });

      test('should throw AuthException when no user to delete', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.deleteAccount(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('should send password reset email successfully', () async {
        // Arrange
        const email = 'user@example.com';
        when(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/password-reset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        await dataSource.sendPasswordResetEmail(email);

        // Assert
        verify(mockHttpClient.post(
          Uri.parse('$baseUrl/api/v1/auth/password-reset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        // Arrange
        const displayName = 'Updated Name';
        const photoUrl = 'https://example.com/photo.jpg';

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/auth/profile'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        await dataSource.updateProfile(
          displayName: displayName,
          photoUrl: photoUrl,
        );

        // Assert
        verify(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/auth/profile'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('changePassword', () {
      test('should change password successfully', () async {
        // Arrange
        const currentPassword = 'oldpassword';
        const newPassword = 'newpassword';

        when(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/auth/password'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        await dataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

        // Assert
        verify(mockHttpClient.put(
          Uri.parse('$baseUrl/api/v1/auth/password'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });
    });

    group('getUserProfile', () {
      test('should return user profile when successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'user_123',
            'email': 'user@example.com',
            'displayName': 'Test User',
            'photoUrl': null,
            'isInstructor': false,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/auth/profile'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.getUserProfile();

        // Assert
        expect(result, isA<UserModel>());
        expect(result.id, 'user_123');
        expect(result.email, 'user@example.com');
      });

      test('should throw AuthException when profile not found', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/auth/profile'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

        // Act & Assert
        expect(
          () => dataSource.getUserProfile(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () async {
        // Arrange
        when(mockUser.getIdToken()).thenAnswer((_) async => authToken);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, true);
      });

      test('should return false when user is not authenticated', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, false);
      });

      test('should return false when token is null', () async {
        // Arrange
        when(mockUser.getIdToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, false);
      });
    });

    group('getAuthToken', () {
      test('should return auth token when user is authenticated', () async {
        // Arrange
        when(mockUser.getIdToken()).thenAnswer((_) async => authToken);

        // Act
        final result = await dataSource.getAuthToken();

        // Assert
        expect(result, authToken);
      });

      test('should return null when user is not authenticated', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await dataSource.getAuthToken();

        // Assert
        expect(result, null);
      });
    });

    group('authStateChanges', () {
      test('should emit user when authenticated', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'id': 'user_123',
            'email': 'user@example.com',
            'displayName': 'Test User',
            'photoUrl': null,
            'isInstructor': false,
            'createdAt': 1640995200000,
            'updatedAt': 1640995200000,
          }
        };

        when(mockHttpClient.get(
          Uri.parse('$baseUrl/api/v1/auth/profile'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await dataSource.authStateChanges.first;

        // Assert
        expect(result, isA<UserModel>());
        expect(result?.id, 'user_123');
      });

      test('should emit null when not authenticated', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await dataSource.authStateChanges.first;

        // Assert
        expect(result, null);
      });
    });
  });
}
