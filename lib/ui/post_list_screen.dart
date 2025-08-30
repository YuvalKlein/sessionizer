import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/post.dart';
import 'package:myapp/services/post_service.dart';
import 'package:myapp/services/user_service.dart';
import 'package:provider/provider.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = Provider.of<PostService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/create_post'),
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: postService.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(post.content),
                  subtitle: StreamBuilder(
                    stream: userService.getUserStream(post.authorId),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      if (userSnapshot.hasError || !userSnapshot.hasData) {
                        return const Text('Unknown author');
                      }
                      final user = userSnapshot.data!.data()!;
                      final formattedDate = DateFormat.yMd().add_jm().format(post.timestamp.toDate());
                      return Text('By: ${user['email']} at $formattedDate');
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => postService.deletePost(post.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
