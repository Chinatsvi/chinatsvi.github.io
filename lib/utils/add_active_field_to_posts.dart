import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Migration script to add 'active' field to all existing posts
/// Run this once to update all posts to have active: true by default
class AddActiveFieldToPosts {
  static Future<void> migrateAllPosts() async {
    try {
      debugPrint('🔄 Starting migration: Adding active field to all posts...');

      final firestore = FirebaseFirestore.instance;

      // Get all posts that don't have the 'active' field
      final postsSnapshot = await firestore
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .get();

      debugPrint('📊 Found ${postsSnapshot.docs.length} posts to migrate');

      int updatedCount = 0;
      int errorCount = 0;

      // Update each post to add active: true
      for (final postDoc in postsSnapshot.docs) {
        try {
          final postData = postDoc.data();

          // Check if active field already exists
          if (postData.containsKey('active')) {
            debugPrint(
              '⏭️ Post ${postDoc.id} already has active field, skipping...',
            );
            continue;
          }

          // Add active: true to the post
          await postDoc.reference.update({'active': true});
          updatedCount++;

          if (kDebugMode) {
            debugPrint('✅ Updated post ${postDoc.id}');
          }

          // Add small delay to avoid Firestore rate limits
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          errorCount++;
          debugPrint('❌ Error updating post ${postDoc.id}: $e');
        }
      }

      debugPrint('🎉 Migration completed!');
      debugPrint('✅ Successfully updated: $updatedCount posts');
      debugPrint('❌ Failed to update: $errorCount posts');
    } catch (e) {
      debugPrint('💥 Migration failed: $e');
    }
  }

  /// Check how many posts are missing the active field
  static Future<void> checkMigrationNeeded() async {
    try {
      debugPrint('🔍 Checking migration status...');

      final firestore = FirebaseFirestore.instance;

      // Get all active posts
      final postsSnapshot = await firestore
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .get();

      int totalPosts = postsSnapshot.docs.length;
      int postsWithActive = 0;
      int postsWithoutActive = 0;

      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data();
        if (postData.containsKey('active')) {
          postsWithActive++;
        } else {
          postsWithoutActive++;
        }
      }

      debugPrint('📊 Migration Status Report:');
      debugPrint('   Total posts: $totalPosts');
      debugPrint('   Posts with active field: $postsWithActive');
      debugPrint('   Posts missing active field: $postsWithoutActive');

      if (postsWithoutActive > 0) {
        debugPrint(
          '⚠️ Migration needed! Run migrateAllPosts() to update posts.',
        );
      } else {
        debugPrint('✅ All posts have active field. Migration complete!');
      }
    } catch (e) {
      debugPrint('💥 Error checking migration status: $e');
    }
  }
}
