import 'package:flutter/material.dart';
import 'comment_section.dart';

class CommentCard extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final List<Map<String, dynamic>>? postComments; // Add comments from post
  final VoidCallback? onCommentAdded;
  final String? profileOwnerId; // Add profile owner ID

  const CommentCard({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.postComments, // Add post comments parameter
    this.onCommentAdded,
    this.profileOwnerId, // Add profile owner ID
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          /// COMMENT SECTION - Use post comments for instant loading
          CommentSection(
            postId: widget.postId,
            currentUserId: widget.currentUserId,
            profileOwnerId: widget.profileOwnerId,
            onCommentChanged: widget.onCommentAdded,
          ),
        ],
      ),
    );
  }
}
