import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/post_service.dart';
import 'package:myapp/ui/create_post_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'create_post_screen_test.mocks.dart';

class MockUser extends Mock implements auth.User {
  @override
  String get uid => 'test_uid';
}

@GenerateMocks([PostService, AuthService])
void main() {
  late MockPostService mockPostService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockPostService = MockPostService();
    mockAuthService = MockAuthService();
  });

  testWidgets('shows validation error for empty content', (WidgetTester tester) async {
    when(mockAuthService.currentUser).thenReturn(MockUser());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PostService>.value(value: mockPostService),
          Provider<AuthService>.value(value: mockAuthService),
        ],
        child: const MaterialApp(home: CreatePostScreen()),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Please enter some content'), findsOneWidget);
  });

  testWidgets('calls addPost and shows loading indicator on valid submission', (WidgetTester tester) async {
    final user = MockUser();
    when(mockAuthService.currentUser).thenReturn(user);
    when(mockPostService.addPost(any, any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return Future.value();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PostService>.value(value: mockPostService),
          Provider<AuthService>.value(value: mockAuthService),
        ],
        child: const MaterialApp(home: CreatePostScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'New post');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    verify(mockPostService.addPost('New post', 'test_uid')).called(1);
  });
}
