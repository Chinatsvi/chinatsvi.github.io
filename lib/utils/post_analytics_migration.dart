import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Migration script to update existing posts with correct comment and reaction counts
/// Run this once to populate the analytics fields for existing posts
class PostAnalyticsMigration {
  static Future<void> migrateAllPosts() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    debugPrint('Starting post analytics migration...');

    try {
      // Get all posts
      final postsSnapshot = await firestore.collection('posts').get();

      debugPrint('Found ${postsSnapshot.docs.length} posts to migrate');

      for (final postDoc in postsSnapshot.docs) {
        final postId = postDoc.id;
        final postData = postDoc.data();

        // Get actual comment count
        final commentsSnapshot = await firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .get();

        final actualCommentCount = commentsSnapshot.docs.length;

        // Get actual reaction count + emoji breakdown from reactions subcollection
        final reactionsSnapshot = await firestore
            .collection('posts')
            .doc(postId)
            .collection('reactions')
            .get();

        final actualReactionCount = reactionsSnapshot.docs.length;
        final Map<String, int> reactionEmojiCounts = {};
        for (final doc in reactionsSnapshot.docs) {
          final data = doc.data();
          final emoji = data['emoji']?.toString();
          if (emoji == null || emoji.isEmpty) continue;
          reactionEmojiCounts[emoji] = (reactionEmojiCounts[emoji] ?? 0) + 1;
        }

        // Get actual likes count
        final likes = List<String>.from(postData['likes'] ?? []);
        final actualLikesCount = likes.length;

        // Update the post with correct counts
        await firestore.collection('posts').doc(postId).update({
          'analytics.commentsCount': actualCommentCount,
          'analytics.reactionsCount': actualReactionCount,
          'analytics.reactionEmojiCounts': reactionEmojiCounts,
          'analytics.likesCount': actualLikesCount,
        });

        debugPrint(
          'Updated post $postId: $actualCommentCount comments, $actualReactionCount reactions, $actualLikesCount likes',
        );
      }

      debugPrint('Migration completed successfully!');
    } catch (e) {
      debugPrint('Migration failed: $e');
      rethrow;
    }
  }

  /// Helper method to run migration for a single post
  static Future<void> migrateSinglePost(String postId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Get the post
      final postDoc = await firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        debugPrint('Post $postId not found');
        return;
      }

      final postData = postDoc.data()!;

      // Get actual comment count
      final commentsSnapshot = await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      final actualCommentCount = commentsSnapshot.docs.length;

      // Get actual reaction count + emoji breakdown from reactions subcollection
      final reactionsSnapshot = await firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .get();

      final actualReactionCount = reactionsSnapshot.docs.length;
      final Map<String, int> reactionEmojiCounts = {};
      for (final doc in reactionsSnapshot.docs) {
        final data = doc.data();
        final emoji = data['emoji']?.toString();
        if (emoji == null || emoji.isEmpty) continue;
        reactionEmojiCounts[emoji] = (reactionEmojiCounts[emoji] ?? 0) + 1;
      }

      // Get actual likes count
      final likes = List<String>.from(postData['likes'] ?? []);
      final actualLikesCount = likes.length;

      // Update the post with correct counts
      await firestore.collection('posts').doc(postId).update({
        'analytics.commentsCount': actualCommentCount,
        'analytics.reactionsCount': actualReactionCount,
        'analytics.reactionEmojiCounts': reactionEmojiCounts,
        'analytics.likesCount': actualLikesCount,
      });

      debugPrint(
        'Updated post $postId: $actualCommentCount comments, $actualReactionCount reactions, $actualLikesCount likes',
      );
    } catch (e) {
      debugPrint('Failed to migrate post $postId: $e');
      rethrow;
    }
  }
}
