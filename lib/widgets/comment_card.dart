import 'package:flutter/material.dart';
import 'comment_section.dart';

class CommentCard extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final List<Map<String, dynamic>>? postComments;
  final VoidCallback? onCommentAdded;
  final String? profileOwnerId;
  final int? initialCommentsCount;

  const CommentCard({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.postComments,
    this.onCommentAdded,
    this.profileOwnerId,
    this.initialCommentsCount,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: CommentSection(
        postId: widget.postId,
        currentUserId: widget.currentUserId,
        profileOwnerId: widget.profileOwnerId,
        initialCommentsCount: widget.initialCommentsCount,
      ),
    );
  }
}
