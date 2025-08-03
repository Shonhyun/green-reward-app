import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/forum_service.dart';
import '../widgets/create_post_widget.dart';
import '../widgets/comments_widget.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class ReportForumScreen extends StatefulWidget {
  const ReportForumScreen({super.key});

  @override
  State<ReportForumScreen> createState() => _ReportForumScreenState();
}

class _ReportForumScreenState extends State<ReportForumScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isFiltering = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;
  List<QueryDocumentSnapshot> _posts = [];
  final Set<String> _postIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isFetchingMore) {
        _loadMorePosts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _lastDocument = null;
      _posts = [];
      _postIds.clear();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
      _lastDocument = null;
      _posts = [];
      _postIds.clear();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _isFiltering = category != 'All Categories';
      _lastDocument = null;
      _posts = [];
      _postIds.clear();
    });
  }

  Future<void> _loadMorePosts() async {
    if (_isFetchingMore) return;
    setState(() {
      _isFetchingMore = true;
    });

    try {
      Query<Map<String, dynamic>> query;
      if (_selectedCategory != 'All Categories') {
        query = FirebaseFirestore.instance
            .collection('forum_posts')
            .where('category', isEqualTo: _selectedCategory)
            .orderBy('createdAt', descending: true)
            .limit(20);
      } else {
        query = FirebaseFirestore.instance
            .collection('forum_posts')
            .orderBy('createdAt', descending: true)
            .limit(20);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final newPosts = snapshot.docs.where((doc) => !_postIds.contains(doc.id)).toList();

      setState(() {
        _posts.addAll(newPosts);
        _postIds.addAll(newPosts.map((doc) => doc.id));
        if (newPosts.isNotEmpty) {
          _lastDocument = newPosts.last;
        }
        _isFetchingMore = false;
      });
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() {
        _isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more posts: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostWidget(
        onPostCreated: () {
          setState(() {
            _posts = [];
            _postIds.clear();
            _lastDocument = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post created successfully! 🎉'),
              backgroundColor: const Color(0xFF2ECC71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditPost(String postId, String content, String category, {String? imageBase64}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostWidget(
        postId: postId,
        initialContent: content,
        initialCategory: category,
        initialImageBase64: imageBase64,
        onPostUpdated: () {
          setState(() {
            _posts = [];
            _postIds.clear();
            _lastDocument = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post updated successfully! 🎉'),
              backgroundColor: const Color(0xFF2ECC71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComments(String postId, String postContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsWidget(
        postId: postId,
        postContent: postContent,
      ),
    );
  }

  void _showPostOptions(String postId, String userId, String content, String category, {String? imageBase64}) {
    final currentUser = _auth.currentUser;
    final isAuthor = currentUser?.uid == userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (isAuthor) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                ),
                title: const Text('Edit Post', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                subtitle: const Text('Modify your post content'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPost(postId, content, category, imageBase64: imageBase64);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                subtitle: const Text('Remove this post permanently'),
                onTap: () async {
                  Navigator.pop(context);
                  _showDeleteConfirmation(postId);
                },
              ),
            ] else ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag, color: Colors.orange, size: 20),
                ),
                title: const Text('Report Post', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                subtitle: const Text('Report inappropriate content'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(postId);
                },
              ),
            ],
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, color: Colors.blue, size: 20),
              ),
              title: const Text('Copy Text', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              subtitle: const Text('Copy post content to clipboard'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Text copied to clipboard'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Post'),
          ],
        ),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final success = await ForumService.deletePost(postId);
              setState(() => _isLoading = false);

              if (success) {
                setState(() {
                  _posts = [];
                  _postIds.clear();
                  _lastDocument = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Post deleted successfully'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete post. You may not have permission.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String postId) {
    String selectedReason = 'Inappropriate content';
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'False information',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.orange),
            SizedBox(width: 8),
            Text('Report Post'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select a reason for reporting this post:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                labelText: 'Reason',
                prefixIcon: const Icon(Icons.report),
              ),
              items: reasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                selectedReason = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final success = await ForumService.reportPost(
                postId: postId,
                reason: selectedReason,
              );
              setState(() => _isLoading = false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Post reported successfully'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to report post. You may have already reported it.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _upvotePost(String postId) async {
    try {
      final hasUpvoted = await ForumService.hasUserVoted(postId, _auth.currentUser!.uid, 'upvote');
      final success = await ForumService.upvotePost(postId);
      if (success) {
        setState(() {
          _posts = [];
          _postIds.clear();
          _lastDocument = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasUpvoted ? 'Upvote removed! 🥳' : 'Upvoted successfully! 👍'),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update vote. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _downvotePost(String postId) async {
    try {
      final hasDownvoted = await ForumService.hasUserVoted(postId, _auth.currentUser!.uid, 'downvote');
      final success = await ForumService.downvotePost(postId);
      if (success) {
        setState(() {
          _posts = [];
          _postIds.clear();
          _lastDocument = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasDownvoted ? 'Downvote removed! 🥳' : 'Downvoted successfully! 👎'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update vote. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _formatTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Stream<QuerySnapshot> _getPostsStream() {
    try {
      Query<Map<String, dynamic>> query;
      if (_selectedCategory != 'All Categories') {
        query = FirebaseFirestore.instance
            .collection('forum_posts')
            .where('category', isEqualTo: _selectedCategory)
            .orderBy('createdAt', descending: true)
            .limit(20);
      } else {
        query = FirebaseFirestore.instance
            .collection('forum_posts')
            .orderBy('createdAt', descending: true)
            .limit(20);
      }

      return query.snapshots();
    } catch (e) {
      print('Error getting posts stream: $e');
      return Stream.empty();
    }
  }

  List<QueryDocumentSnapshot> _filterPosts(List<QueryDocumentSnapshot> posts, String searchQuery) {
    if (searchQuery.isEmpty) {
      return posts;
    }

    final query = searchQuery.toLowerCase();
    return posts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final content = (data['content'] ?? '').toString().toLowerCase();
      final userName = (data['userName'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      return content.contains(query) ||
          userName.contains(query) ||
          category.contains(query);
    }).toList();
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No posts found for "$_searchQuery"';
    } else if (_isFiltering) {
      return 'No posts in "$_selectedCategory"';
    } else {
      return 'No posts yet';
    }
  }

  String _getEmptyStateSubtitle() {
    if (_searchQuery.isNotEmpty) {
      return 'Try a different search term or clear filters';
    } else if (_isFiltering) {
      return 'Try changing the category or clear filters';
    } else {
      return 'Be the first to share something!';
    }
  }

  Widget _buildModernForumPostCard({
    required String postId,
    required String userName,
    required String content,
    required String category,
    required int upvotes,
    required int downvotes,
    required String timeAgo,
    required String userId,
    String? imageBase64,
  }) {
    final isOwnPost = _auth.currentUser?.uid == userId;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2ECC71),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              subtitle: Text(
                '$category • $timeAgo',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF666666)),
                onPressed: () {
                  _showPostOptions(postId, userId, content, category, imageBase64: imageBase64);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (imageBase64 != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: upvotes > 0 ? const Color(0xFF2ECC71) : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => _upvotePost(postId),
                      ),
                      Text(
                        upvotes.toString(),
                        style: TextStyle(
                          color: upvotes > 0 ? const Color(0xFF2ECC71) : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: downvotes > 0 ? Colors.orange : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => _downvotePost(postId),
                      ),
                      Text(
                        downvotes.toString(),
                        style: TextStyle(
                          color: downvotes > 0 ? Colors.orange : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.grey, size: 20),
                    onPressed: () => _showComments(postId, content),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All Categories', ...ForumService.getCategories()];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2ECC71),
                      Color(0xFF27AE60),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            ),
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                const Text(
                                  'Community Forum',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Share & Connect',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _showCreatePost,
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search posts, users, or categories...',
                            hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF9E9E9E)),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _onCategoryChanged(value);
                            }
                          },
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2ECC71)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getPostsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFF666666),
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Error loading posts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => setState(() {}),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2ECC71),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.connectionState == ConnectionState.waiting && _posts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF2ECC71),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Loading posts...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              final newPosts = snapshot.data!.docs.where((doc) => !_postIds.contains(doc.id)).toList();
                              _posts.addAll(newPosts);
                              _postIds.addAll(newPosts.map((doc) => doc.id));
                              if (newPosts.isNotEmpty) {
                                _lastDocument = newPosts.last;
                              }
                            }

                            final filteredPosts = _filterPosts(_posts, _searchQuery);

                            if (filteredPosts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        _searchQuery.isNotEmpty
                                            ? Icons.search_off
                                            : _isFiltering
                                                ? Icons.filter_list_off
                                                : Icons.forum_outlined,
                                        color: Colors.grey[400],
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _getEmptyStateMessage(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getEmptyStateSubtitle(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_searchQuery.isNotEmpty || _isFiltering) ...[
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (_searchQuery.isNotEmpty) {
                                            _clearSearch();
                                          }
                                          if (_isFiltering) {
                                            _onCategoryChanged('All Categories');
                                          }
                                        },
                                        icon: const Icon(Icons.clear_all),
                                        label: const Text('Clear Filters'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2ECC71),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: _showCreatePost,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create Post'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2ECC71),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: filteredPosts.length + (_isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredPosts.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2ECC71),
                                      ),
                                    ),
                                  );
                                }

                                final post = filteredPosts[index].data() as Map<String, dynamic>;
                                final postId = filteredPosts[index].id;
                                final userName = post['userName'] ?? 'Anonymous';
                                final content = post['content'] ?? '';
                                final category = post['category'] ?? 'General Discussion';
                                final imageBase64 = post['imageBase64'] as String?;
                                final upvotes = post['upvotes'] ?? 0;
                                final downvotes = post['downvotes'] ?? 0;
                                final createdAt = post['createdAt'] as Timestamp?;
                                final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : 'Unknown time';
                                final userId = post['userId'] ?? '';

                                return _buildModernForumPostCard(
                                  postId: postId,
                                  userName: userName,
                                  content: content,
                                  category: category,
                                  upvotes: upvotes,
                                  downvotes: downvotes,
                                  timeAgo: timeAgo,
                                  userId: userId,
                                  imageBase64: imageBase64,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}