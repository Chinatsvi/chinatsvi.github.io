import 'package:flutter/material.dart';
import '../models/post_model.dart';

/// A widget that displays analytics for a Post.
/// This is separate from the PostAnalytics data model.
class PostAnalyticsWidget extends StatelessWidget {
  final Post post;

  const PostAnalyticsWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildStat(Icons.remove_red_eye, '${post.analytics.viewsCount}'),
        const SizedBox(width: 12),
        _buildStat(Icons.thumb_up, '${post.likes.length}'),
        const SizedBox(width: 12),
        _buildStat(Icons.comment, '${post.analytics.commentsCount}'),
        const SizedBox(width: 12),
        _buildStat(Icons.share, '${post.analytics.sharesCount}'),
      ],
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
