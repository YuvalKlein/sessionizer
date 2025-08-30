import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/post.dart';
import 'package:myapp/services/post_service.dart';
import 'package:myapp/ui/post_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'post_list_screen_test.mocks.dart';

@GenerateMocks([PostService])
void main() {
  late MockPostService mockPostService;

  setUp(() {
    mockPostService = MockPostService();
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

  testWidgets('displays a list of posts', (WidgetTester tester) async {
    when(mockPostService.getPosts()).thenAnswer((_) => Stream.value(posts));

    await tester.pumpWidget(
      Provider<PostService>.value(
        value: mockPostService,
        child: const MaterialApp(home: PostListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
  });

  testWidgets('shows a message when there are no posts', (WidgetTester tester) async {
    when(mockPostService.getPosts()).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      Provider<PostService>.value(
        value: mockPostService,
        child: const MaterialApp(home: PostListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('No posts yet.'), findsOneWidget);
  });

  testWidgets('calls deletePost when the delete button is tapped', (WidgetTester tester) async {
    when(mockPostService.getPosts()).thenAnswer((_) => Stream.value(posts));
    when(mockPostService.deletePost(any)).thenAnswer((_) async {});

    await tester.pumpWidget(
      Provider<PostService>.value(
        value: mockPostService,
        child: const MaterialApp(home: PostListScreen()),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete).first);

    verify(mockPostService.deletePost('1')).called(1);
  });
}
