import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/post_model.dart';
import '../../widgets/optimized_post_card.dart';
import '../../widgets/comment_section.dart'; //
import 'edit_post_screen.dart'; //

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final DocumentSnapshot? initialPostSnapshot;
  final String? highlightedCommentId;
  final String? highlightedReplyId;
  final bool isAdminPreview;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPostSnapshot,
    this.highlightedCommentId,
    this.highlightedReplyId,
    this.isAdminPreview = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  DocumentSnapshot? _postSnapshot;
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPostSnapshot != null) {
      _postSnapshot = widget.initialPostSnapshot;
      _isDeleted = !widget.initialPostSnapshot!.exists;
    } else {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
    if (mounted) {
      setState(() {
        _postSnapshot = snapshot;
        _isDeleted = !snapshot.exists;
      });
    }
  }

  String? _extractPrimaryImageUrl(Map<String, dynamic>? postData) {
    if (postData == null) return null;

    final directImage = postData['imageUrl']?.toString().trim();
    if (directImage != null && directImage.isNotEmpty && directImage.startsWith('http')) {
      return directImage;
    }

    final directMedia = postData['mediaUrl']?.toString().trim();
    if (directMedia != null && directMedia.isNotEmpty && directMedia.startsWith('http')) {
      return directMedia;
    }

    final mediaList = postData['media'];
    if (mediaList is List) {
      for (final item in mediaList) {
        if (item is Map) {
          final url = item['url'] ?? item['downloadUrl'] ?? item['publicUrl'];
          if (url is String && url.trim().isNotEmpty && url.startsWith('http')) {
            return url.trim();
          }
        } else if (item is String && item.trim().isNotEmpty && item.startsWith('http')) {
          return item.trim();
        }
      }
    }

    final mediaUrlsList = postData['mediaUrls'];
    if (mediaUrlsList is List) {
      for (final item in mediaUrlsList) {
        if (item is String && item.trim().isNotEmpty && item.startsWith('http')) {
          return item.trim();
        }
      }
    }

    return null;
  }

  Widget _buildAdminPreviewBody(Map<String, dynamic>? postData) {
    final content = (postData?['content'] ?? '').toString().trim();
    final authorName = (postData?['authorName'] ?? postData?['userName'] ?? 'Unknown').toString();
    final imageUrl = _extractPrimaryImageUrl(postData);
    final status = (postData?['status'] ?? 'active').toString();
    final createdAt = postData?['createdAt'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Preview'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reviewing this post for boost approval',
                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${status.isNotEmpty ? status : 'active'}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Created: $createdAt',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 16),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 240,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 240,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                  ),
                ),
              ),
            if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                content.isNotEmpty ? content : 'No visible text is available for this post.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    if (_isDeleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Post has been deleted",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (_postSnapshot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_postSnapshot!.exists) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text("Post not found")),
      );
    }

    final postData = _postSnapshot!.data() as Map<String, dynamic>?;
    final hasContent = (postData?['content']?.toString().trim().isNotEmpty ?? false) ||
        (postData?['imageUrl']?.toString().trim().isNotEmpty ?? false) ||
        (postData?['mediaUrl']?.toString().trim().isNotEmpty ?? false) ||
        (postData?['media'] is List && (postData?['media'] as List).isNotEmpty) ||
        (postData?['mediaUrls'] is List && (postData?['mediaUrls'] as List).isNotEmpty);

    if (widget.isAdminPreview) {
      return _buildAdminPreviewBody(postData);
    }

    if (!hasContent) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "This post has no visible content.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "The post preview cannot show media or text for this post. You can still review the boost request.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final post = Post.fromFirestore(_postSnapshot!);

      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Full post card with stats
              OptimizedPostCard(
                postId: widget.postId,
                post: _postSnapshot!.data() as Map<String, dynamic>,
                currentUserId: currentUserId,
                showStats: true,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditPostScreen(postId: widget.postId, post: post),
                    ),
                  );
                },
                onDelete: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .delete();

                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Post deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Update UI state to show deleted state
                      setState(() {
                        _isDeleted = true;
                        _postSnapshot = null;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error deleting post: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // Full threaded comment section
              CommentSection(
                postId: widget.postId,
                currentUserId: currentUserId,
                initialCommentsCount: post.analytics.commentsCount,
                highlightedCommentId: widget.highlightedCommentId,
                highlightedReplyId: widget.highlightedReplyId,
                onCommentChanged: () {
                  // Silently refresh post data to get updated comment count
                  _loadPost();
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Handle parsing errors gracefully
      return Scaffold(
        appBar: AppBar(
          title: const Text("Post"),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Error Loading Post",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "This post cannot be displayed due to a data format issue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }
  }
}
