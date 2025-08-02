import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new forum post
  static Future<bool> createPost({
    required String content,
    required String category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get username from Firestore
      final username = await UserService.getUserUsername();
      final displayName = username.isNotEmpty ? username : (user.displayName ?? 'Anonymous User');

      await _firestore.collection('forum_posts').add({
        'userId': user.uid,
        'userName': displayName,
        'userEmail': user.email ?? '',
        'content': content,
        'category': category,
        'upvotes': 0,
        'downvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating forum post: $e');
      return false;
    }
  }

  // Get all forum posts with real-time updates
  static Stream<QuerySnapshot> getForumPosts() {
    return _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get forum posts by category - simplified to avoid index issues
  static Stream<QuerySnapshot> getForumPostsByCategory(String category) {
    return _firestore
        .collection('forum_posts')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  // Get categories
  static List<String> getCategories() {
    return [
      'General Discussion',
      'Waste Segregation Tips',
      'Recycling Guide',
      'Community Events',
      'Questions & Help',
      'Success Stories',
      'Environmental News',
    ];
  }

  // Enhanced search that works with current Firestore rules
  static Stream<QuerySnapshot> searchForumPosts(String searchQuery) {
    if (searchQuery.isEmpty) {
      return getForumPosts();
    }
    
    // Use a simple approach that doesn't require complex indexes
    return _firestore
        .collection('forum_posts')
        .snapshots();
  }

  // Upvote a post
  static Future<bool> upvotePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated for upvote');
        return false;
      }

      // Check if post exists first
      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return false;
      }

      await _firestore.collection('forum_posts').doc(postId).update({
        'upvotes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully upvoted post: $postId');
      return true;
    } catch (e) {
      print('Error upvoting post: $e');
      return false;
    }
  }

  // Downvote a post
  static Future<bool> downvotePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated for downvote');
        return false;
      }

      // Check if post exists first
      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return false;
      }

      await _firestore.collection('forum_posts').doc(postId).update({
        'downvotes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully downvoted post: $postId');
      return true;
    } catch (e) {
      print('Error downvoting post: $e');
      return false;
    }
  }

  // Add comment to a post
  static Future<bool> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get username from Firestore
      final username = await UserService.getUserUsername();
      final displayName = username.isNotEmpty ? username : (user.displayName ?? 'Anonymous User');

      await _firestore
          .collection('forum_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': displayName,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get comments for a post
  static Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Delete a post (only by the author)
  static Future<bool> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != user.uid) return false;

      await _firestore.collection('forum_posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Report a post
  static Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': user.uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      print('Error reporting post: $e');
      return false;
    }
  }
} 