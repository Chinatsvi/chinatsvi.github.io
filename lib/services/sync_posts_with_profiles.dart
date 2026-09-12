import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SyncPostsWithProfiles {
  /// Sync all post authorName fields with current user profiles
  static Future<void> syncAllPostsWithCurrentProfiles() async {
    try {
      debugPrint('🔄 Starting sync of posts with current user profiles...');
      
      // Get all current users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      debugPrint('👥 Found ${usersSnapshot.docs.length} users:');
      
      // Create mapping of userId -> current profile name
      final userIdToNameMap = <String, String>{};
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final currentName = userData['user_name'] as String? ?? '';
        userIdToNameMap[userId] = currentName;
        debugPrint('  - $userId → "$currentName"');
      }
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      debugPrint('📝 Found ${postsSnapshot.docs.length} posts to sync');
      
      int syncedCount = 0;
      int alreadyCorrect = 0;
      int noUserFound = 0;
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final postAuthorId = postData['authorId'] ?? '';
        final currentPostName = postData['authorName'] ?? '';
        
        debugPrint('🔍 Checking post ${postDoc.id}:');
        debugPrint('  - Post authorId: $postAuthorId');
        debugPrint('  - Current post name: "$currentPostName"');
        
        // Get the current name from user profile
        final currentProfileName = userIdToNameMap[postAuthorId];
        
        if (currentProfileName != null) {
          if (currentProfileName != currentPostName) {
            debugPrint('  🔄 Syncing: "$currentPostName" → "$currentProfileName"');
            
            await postDoc.reference.update({
              'authorName': currentProfileName,
              'syncedAt': FieldValue.serverTimestamp(),
            });
            
            syncedCount++;
            debugPrint('  ✅ Post ${postDoc.id} synced');
          } else {
            debugPrint('  ℹ️ Post already has correct name');
            alreadyCorrect++;
          }
        } else {
          debugPrint('  ❌ No user found for authorId: $postAuthorId');
          noUserFound++;
        }
      }
      
      debugPrint('✅ Post sync completed!');
      debugPrint('  - Synced: $syncedCount posts');
      debugPrint('  - Already correct: $alreadyCorrect posts');
      debugPrint('  - No user found: $noUserFound posts');
      
    } catch (e) {
      debugPrint('❌ Error syncing posts: $e');
      rethrow;
    }
  }
  
  /// Get detailed sync report
  static Future<void> getSyncReport() async {
    try {
      debugPrint('📊 Generating sync report...');
      
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      final userIdToNameMap = <String, String>{};
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final currentName = userData['user_name'] as String? ?? '';
        userIdToNameMap[userId] = currentName;
      }
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      int needSync = 0;
      int alreadySynced = 0;
      int noUser = 0;
      
      debugPrint('📊 SYNC REPORT:');
      debugPrint('==================');
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final postAuthorId = postData['authorId'] ?? '';
        final currentPostName = postData['authorName'] ?? '';
        final currentProfileName = userIdToNameMap[postAuthorId];
        
        if (currentProfileName != null) {
          if (currentProfileName != currentPostName) {
            needSync++;
            debugPrint('🔄 NEEDS SYNC: Post ${postDoc.id}');
            debugPrint('   - Post name: "$currentPostName"');
            debugPrint('   - Profile name: "$currentProfileName"');
          } else {
            alreadySynced++;
          }
        } else {
          noUser++;
          debugPrint('❌ NO USER: Post ${postDoc.id} (authorId: $postAuthorId)');
        }
      }
      
      debugPrint('==================');
      debugPrint('📊 SUMMARY:');
      debugPrint('  - Need sync: $needSync posts');
      debugPrint('  - Already synced: $alreadySynced posts');
      debugPrint('  - No user found: $noUser posts');
      debugPrint('  - Total posts: ${postsSnapshot.docs.length}');
      
    } catch (e) {
      debugPrint('❌ Error generating report: $e');
    }
  }
}
