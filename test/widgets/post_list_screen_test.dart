import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/post.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/post_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/ui/post_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'post_list_screen_test.mocks.dart';

@GenerateMocks([PostService, UserService, AuthService])
void main() {
  late MockPostService mockPostService;
  late MockUserService mockUserService;
  late MockAuthService mockAuthService;
  late MockUser mockUser;

  setUp(() {
    mockPostService = MockPostService();
    mockUserService = MockUserService();
    mockAuthService = MockAuthService();
    mockUser = MockUser(uid: 'author1'); // Mock user with a specific UID
  });

  final posts = [
    Post(
      id: '1',
      authorId: 'author1',
      content: 'Post 1',
      timestamp: Timestamp.now(),
    ),
    Post(
      id: '2',
      authorId: 'author2',
      content: 'Post 2',
      timestamp: Timestamp.now(),
    ),
  ];

  Future<void> pumpPostListScreen(WidgetTester tester, {required Stream<List<Post>> postStream}) async {
    when(mockPostService.getPosts()).thenAnswer((_) => postStream);
    when(mockAuthService.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PostService>.value(value: mockPostService),
          Provider<UserService>.value(value: mockUserService),
          Provider<AuthService>.value(value: mockAuthService),
        ],
        child: const MaterialApp(home: PostListScreen()),
      ),
    );
    await tester.pump(); // Let the stream builder update
  }

  testWidgets('displays a list of posts', (WidgetTester tester) async {
    await pumpPostListScreen(tester, postStream: Stream.value(posts));

    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
    // The delete button should be visible for the post authored by 'author1'
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('shows a message when there are no posts', (WidgetTester tester) async {
    await pumpPostListScreen(tester, postStream: Stream.value([]));

    expect(find.text('No posts yet.'), findsOneWidget);
  });

  testWidgets('calls deletePost when the delete button is tapped', (WidgetTester tester) async {
    when(mockPostService.deletePost(any)).thenAnswer((_) async {});

    await pumpPostListScreen(tester, postStream: Stream.value(posts));

    // Find the delete button associated with the first post
    final deleteButton = find.byIcon(Icons.delete);
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pump(); // Rebuild after tap

    // Verify that deletePost was called with the correct post ID
    verify(mockPostService.deletePost('1')).called(1);
  });
}
