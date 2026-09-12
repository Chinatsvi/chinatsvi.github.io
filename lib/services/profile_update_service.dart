import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:agribased/widgets/optimized_post_card.dart';
import 'package:agribased/controllers/feed_controller.dart';
import 'package:agribased/services/optimized_user_service.dart';

class ProfileUpdateService {
  static final ProfileUpdateService _instance =
      ProfileUpdateService._internal();
  static ProfileUpdateService get instance => _instance;
  ProfileUpdateService._internal();

  /// Updates user profile across all posts with batch processing
  Future<void> updateUserProfileAcrossPosts({
    required String userId,
    required String newDisplayName,
    required String? newAvatarUrl,
    FeedController? feedController, // Optional feed controller for refresh
  }) async {
    try {
      debugPrint('🔄 Starting profile update for user: $userId');
      debugPrint('  - New Display Name: $newDisplayName');
      debugPrint('  - New Avatar URL: $newAvatarUrl');

      // Step 1: Clear PostCard cache to force refresh
      _clearPostCardCache(userId);

      // Step 2: Update recent posts (visible in feed) - IMMEDIATE
      await _updateRecentPosts(userId, newDisplayName, newAvatarUrl);

      // Step 3: Refresh feed to show updated posts immediately
      if (feedController != null) {
        debugPrint('🔄 Refreshing feed to show updated posts...');
        await feedController.refreshPosts();
      }

      // Step 4: Update older posts in background - BATCH PROCESSING
      _updateOlderPostsInBackground(userId, newDisplayName, newAvatarUrl);

      debugPrint('✅ Profile update initiated successfully');
    } catch (e) {
      debugPrint('❌ Error updating profile across posts: $e');
      rethrow;
    }
  }

  /// Clears the OptimizedPostCard profile cache for a specific user
  void _clearPostCardCache(String userId) {
    try {
      // Clear the static cache in OptimizedPostCard using the public method
      OptimizedPostCard.clearProfileCache(userId);
      debugPrint('🗑️ Cleared OptimizedPostCard cache for user: $userId');
    } catch (e) {
      debugPrint('⚠️ Error clearing OptimizedPostCard cache: $e');
    }

    try {
      // ALSO clear OptimizedUserCache - this is checked BEFORE PostCard cache
      // in _loadCachedUser() and was causing stale profile pictures
      OptimizedUserCache.clearUserCache(userId);
      debugPrint('🗑️ Cleared OptimizedUserCache for user: $userId');
    } catch (e) {
      debugPrint('⚠️ Error clearing OptimizedUserCache: $e');
    }
  }

  /// Updates recent posts (last 50 posts) immediately
  Future<void> _updateRecentPosts(
    String userId,
    String newDisplayName,
    String? newAvatarUrl,
  ) async {
    try {
      debugPrint('📱 Starting profile update for posts...');

      // Use a simpler query that doesn't require composite index
      // Get posts by authorId first, then sort in memory
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .limit(100) // Get more posts to sort locally
          .get();

      debugPrint('📱 Found ${postsQuery.docs.length} posts to update');

      // Sort posts by createdAt locally (no index needed)
      final sortedPosts = postsQuery.docs.toList();
      sortedPosts.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime); // Most recent first
      });

      // Take only the first 50 (most recent)
      final recentPosts = sortedPosts.take(50).toList();

      debugPrint('📱 Updating ${recentPosts.length} most recent posts');

      // Update each recent post individually
      for (final doc in recentPosts) {
        debugPrint('📝 Updating post ${doc.id}:');
        debugPrint('  - Current authorName: ${doc['authorName']}');
        debugPrint('  - New authorName: $newDisplayName');
        debugPrint('  - Current authorAvatar: ${doc['authorAvatar']}');
        debugPrint('  - New authorAvatar: $newAvatarUrl');

        try {
          await doc.reference.update({
            'authorName': newDisplayName,
            'authorAvatar': newAvatarUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('  ✅ Post ${doc.id} updated successfully');
        } catch (e) {
          debugPrint('  ❌ Failed to update post ${doc.id}: $e');
          // Continue with other posts even if one fails
        }
      }

      debugPrint('✅ Recent posts update completed');
    } catch (e) {
      debugPrint('❌ Error updating recent posts: $e');
      // Don't rethrow - allow profile save to continue even if post updates fail
    }
  }

  /// Updates older posts in background using batch processing
  void _updateOlderPostsInBackground(
    String userId,
    String newDisplayName,
    String? newAvatarUrl,
  ) {
    // Run in background to avoid blocking UI
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        debugPrint('🔄 Starting background update for older posts');

        // Use a simple query without orderBy to avoid index requirements
        final allPostsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .get();

        debugPrint(
          '🔄 Found ${allPostsQuery.docs.length} total posts for background update',
        );

        // Sort all posts by createdAt locally
        final allPosts = allPostsQuery.docs.toList();
        allPosts.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime); // Most recent first
        });

        // Skip first 50 (already updated in immediate update)
        final olderPosts = allPosts.skip(50).toList();

        // Process in batches of 100
        for (int i = 0; i < olderPosts.length; i += 100) {
          final batch = FirebaseFirestore.instance.batch();
          final batchPosts = olderPosts.skip(i).take(100).toList();

          // Add updates to batch
          for (final doc in batchPosts) {
            batch.update(doc.reference, {
              'authorName': newDisplayName,
              'authorAvatar': newAvatarUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Commit batch
          try {
            await batch.commit();
            debugPrint(
              '🔄 Background batch ${i ~/ 100 + 1} completed: ${batchPosts.length} posts',
            );
          } catch (e) {
            debugPrint('❌ Background batch failed: $e');
            // Continue with next batch even if one fails
          }

          // Small delay between batches to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 100));
        }

        debugPrint('✅ Background update completed for older posts');
      } catch (e) {
        debugPrint('❌ Error in background update: $e');
        // Background errors shouldn't affect the user experience
      }
    });
  }

  /// Updates a single post (for real-time updates)
  Future<void> updateSinglePost({
    required String postId,
    required String newDisplayName,
    required String? newAvatarUrl,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'authorName': newDisplayName,
        'authorAvatar': newAvatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Single post updated: $postId');
    } catch (e) {
      debugPrint('❌ Error updating single post: $e');
    }
  }

  /// Gets count of posts that need updating
  Future<int> getPostCountForUser(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting post count: $e');
      return 0;
    }
  }
}
