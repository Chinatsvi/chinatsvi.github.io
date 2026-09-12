import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/screens/profile/farmer_profile_screen.dart';
import 'package:agribased/controllers/feed_controller.dart';
import 'package:agribased/services/comment_service.dart';
import 'package:agribased/widgets/user_info_display.dart';

class CommentThread extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final List<Map<String, dynamic>>? initialComments; // Add comments from post

  const CommentThread({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    this.initialComments, // Optional initial comments
  });

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(CommentThread oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force rebuild when postId changes to refresh comments
    if (oldWidget.postId != widget.postId) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;

    // Get user profile from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(widget.currentUserId)
        .get();
    final profilePic = userDoc.data()?['profile_pic'] ?? '';

    // Use CommentService which includes moderation
    await CommentService().addComment(
      postId: widget.postId,
      authorId: widget.currentUserId,
      authorName: widget.currentUserName,
      authorProfilePic: profilePic,
      content: text.trim(),
    );

    // Trigger feed refresh to update comments in real-time
    FeedController().refreshPosts();

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Comment list - Use post comments for instant loading
        if (widget.initialComments != null) ...[
          // Display comments from post document instantly
          ...widget.initialComments!.map((commentData) {
            final isOwner = commentData['userId'] == widget.currentUserId;

            return ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmerProfileScreen(
                        userId: commentData['userId'],
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: UserProfileImage(
                  userId: commentData['authorId'] ?? commentData['userId'] ?? '',
                  radius: 18,
                  initialImageUrl: commentData['profile_pic'] != null &&
                          commentData['profile_pic'].isNotEmpty &&
                          commentData['profile_pic'].startsWith('http')
                      ? commentData['profile_pic']
                      : '',
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmerProfileScreen(
                        userId: commentData['userId'],
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Text(
                  commentData['user_name'] ?? 'Farmer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Text(commentData['text'] ?? ''),
              trailing: isOwner
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          // Delete comment from post document
                          _deleteCommentFromPost(commentData);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
            );
          }).toList(),
        ],

        /// 🔹 Comment input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: "Write a comment...",
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (text) => _addComment(text),
          ),
        ),
      ],
    );
  }

  // Delete comment from post document
  Future<void> _deleteCommentFromPost(Map<String, dynamic> commentData) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'comments': FieldValue.arrayRemove([commentData]),
            'analytics.commentsCount': FieldValue.increment(-1),
          });

      FeedController().refreshPosts();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }
}
