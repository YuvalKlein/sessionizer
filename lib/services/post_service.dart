import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');

  Future<void> addPost(String content, String authorId) async {
    try {
      await _postsCollection.add({
        'content': content,
        'authorId': authorId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle errors, e.g., by logging or showing a notification
      print('Error adding post: $e');
    }
  }

  Stream<List<Post>> getPosts() {
    return _postsCollection.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }
}
