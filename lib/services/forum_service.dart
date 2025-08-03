import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> createPost({
    required String content,
    required String category,
    String? imageBase64,
  }) async {
    Map<String, dynamic>? postData;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return false;
      }
      print('Authenticated user: UID=${user.uid}, Email=${user.email}');

      final username = await UserService.getUserUsername();
      final displayName = username.isNotEmpty ? username : (user.displayName ?? 'Anonymous User');
      final trimmedContent = content.trim();
      final trimmedCategory = category.trim();

      if (trimmedContent.isEmpty || trimmedContent.length > 500) {
        print('Error: Content must be between 1 and 500 characters');
        return false;
      }
      if (trimmedCategory.isEmpty) {
        print('Error: Category must not be empty');
        return false;
      }
      if (imageBase64 != null && imageBase64.length > 1 * 1024 * 1024) {
        print('Error: Image size exceeds 1MB');
        return false;
      }

      postData = {
        'userId': user.uid,
        'userName': displayName,
        'userEmail': user.email ?? '',
        'content': trimmedContent,
        'category': trimmedCategory,
        'imageBase64': imageBase64,
        'upvotes': 0,
        'downvotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      print('Creating post with data: $postData');

      await _firestore.collection('forum_posts').add(postData);
      print('Post created successfully');
      return true;
    } catch (e) {
      print('Error creating forum post: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permission denied. Check Firestore rules and data: ${postData ?? "No post data available"}');
      }
      return false;
    }
  }

  static Future<bool> updatePost({
    required String postId,
    required String content,
    required String category,
    String? imageBase64,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return false;
      }

      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return false;
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != user.uid) {
        print('User does not have permission to edit this post');
        return false;
      }

      final trimmedContent = content.trim();
      final trimmedCategory = category.trim();

      if (trimmedContent.isEmpty || trimmedContent.length > 500) {
        print('Error: Content must be between 1 and 500 characters');
        return false;
      }
      if (trimmedCategory.isEmpty) {
        print('Error: Category must not be empty');
        return false;
      }
      if (imageBase64 != null && imageBase64.length > 1 * 1024 * 1024) {
        print('Error: Image size exceeds 1MB');
        return false;
      }

      await _firestore.collection('forum_posts').doc(postId).update({
        'content': trimmedContent,
        'category': trimmedCategory,
        'imageBase64': imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Post updated successfully');
      return true;
    } catch (e) {
      print('Error updating forum post: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot> getForumPosts({int limit = 20, DocumentSnapshot? startAfter}) {
    var query = _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots();
  }

  static Stream<QuerySnapshot> getForumPostsByCategory(String category, {int limit = 20, DocumentSnapshot? startAfter}) {
    var query = _firestore
        .collection('forum_posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots();
  }

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

  static Stream<QuerySnapshot> searchForumPosts(String searchQuery, {int limit = 20}) {
    if (searchQuery.isEmpty) {
      return getForumPosts(limit: limit);
    }

    return _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Future<bool> hasUserVoted(String postId, String userId, String voteType) async {
    final voteDoc = await _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('votes')
        .doc(userId)
        .get();
    return voteDoc.exists && voteDoc.data()?['voteType'] == voteType;
  }

  static Future<bool> upvotePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated for upvote');
        return false;
      }

      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return false;
      }

      final hasUpvoted = await hasUserVoted(postId, user.uid, 'upvote');
      final hasDownvoted = await hasUserVoted(postId, user.uid, 'downvote');

      return await _firestore.runTransaction<bool>((transaction) async {
        final postRef = _firestore.collection('forum_posts').doc(postId);
        final voteRef = postRef.collection('votes').doc(user.uid);

        if (hasUpvoted) {
          // User already upvoted, so remove the upvote
          transaction.delete(voteRef);
          transaction.update(postRef, {
            'upvotes': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // User hasn't upvoted, so add upvote and remove downvote if exists
          transaction.set(voteRef, {
            'userId': user.uid,
            'voteType': 'upvote',
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'upvotes': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (hasDownvoted) {
            transaction.delete(voteRef); // Delete existing vote
            transaction.update(postRef, {
              'downvotes': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            // Re-add upvote after deleting downvote
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': 'upvote',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
        return true;
      });
    } catch (e) {
      print('Error upvoting post: $e');
      return false;
    }
  }

  static Future<bool> downvotePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated for downvote');
        return false;
      }

      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post does not exist: $postId');
        return false;
      }

      final hasUpvoted = await hasUserVoted(postId, user.uid, 'upvote');
      final hasDownvoted = await hasUserVoted(postId, user.uid, 'downvote');

      return await _firestore.runTransaction<bool>((transaction) async {
        final postRef = _firestore.collection('forum_posts').doc(postId);
        final voteRef = postRef.collection('votes').doc(user.uid);

        if (hasDownvoted) {
          // User already downvoted, so remove the downvote
          transaction.delete(voteRef);
          transaction.update(postRef, {
            'downvotes': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // User hasn't downvoted, so add downvote and remove upvote if exists
          transaction.set(voteRef, {
            'userId': user.uid,
            'voteType': 'downvote',
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'downvotes': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          if (hasUpvoted) {
            transaction.delete(voteRef); // Delete existing vote
            transaction.update(postRef, {
              'upvotes': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            // Re-add downvote after deleting upvote
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': 'downvote',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
        return true;
      });
    } catch (e) {
      print('Error downvoting post: $e');
      return false;
    }
  }

  static Future<bool> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

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

  static Stream<QuerySnapshot> getComments(String postId, {int limit = 20, DocumentSnapshot? startAfter}) {
    var query = _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots();
  }

  static Future<bool> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc = await _firestore.collection('forum_posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != user.uid) return false;

      await _firestore.runTransaction((transaction) async {
        final voteDocs = await _firestore.collection('forum_posts').doc(postId).collection('votes').get();
        for (var doc in voteDocs.docs) {
          transaction.delete(doc.reference);
        }

        final commentDocs = await _firestore.collection('forum_posts').doc(postId).collection('comments').get();
        for (var doc in commentDocs.docs) {
          transaction.delete(doc.reference);
        }

        transaction.delete(_firestore.collection('forum_posts').doc(postId));
      });

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  static Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final existingReport = await _firestore
          .collection('reports')
          .where('postId', isEqualTo: postId)
          .where('reportedBy', isEqualTo: user.uid)
          .get();

      if (existingReport.docs.isNotEmpty) return false;

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