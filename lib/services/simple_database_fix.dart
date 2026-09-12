import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SimpleDatabaseFix {
  /// Simple fix: Map known names to correct user IDs with fuzzy matching
  static Future<void> fixKnownPosts() async {
    try {
      debugPrint('🔧 Starting simple database fix with fuzzy matching...');

      // Get all users first to see what we have
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();

      debugPrint('👥 Found ${usersSnapshot.docs.length} users in database:');
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        debugPrint('  - "${userData['user_name']}" (${userDoc.id})');
      }

      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      debugPrint('📝 Found ${postsSnapshot.docs.length} posts to fix');

      // Build the mapping with fuzzy matching
      final nameToIdMap = <String, String>{};

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userName = userData['user_name'] as String? ?? '';
        nameToIdMap[userName.toLowerCase().trim()] = userDoc.id;
      }

      debugPrint('🗺️ Created fuzzy name-to-ID mapping:');
      for (final entry in nameToIdMap.entries) {
        debugPrint('  - "${entry.key}" → ${entry.value}');
      }

      int fixedCount = 0;
      int notFoundCount = 0;

      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final currentAuthorId = postData['authorId'] ?? '';
        final authorName = postData['authorName'] ?? '';

        debugPrint('🔍 Checking post ${postDoc.id}:');
        debugPrint('  - Current authorId: $currentAuthorId');
        debugPrint('  - authorName: "$authorName"');

        // Try fuzzy matching
        final searchName = authorName.toLowerCase().trim();
        final correctAuthorId = nameToIdMap[searchName];

        if (correctAuthorId != null && correctAuthorId != currentAuthorId) {
          debugPrint('  🔄 Fixing: $currentAuthorId → $correctAuthorId');

          await postDoc.reference.update({
            'authorId': correctAuthorId,
            'fixedAt': FieldValue.serverTimestamp(),
          });

          fixedCount++;
          debugPrint('  ✅ Post ${postDoc.id} fixed');
        } else if (correctAuthorId == null) {
          notFoundCount++;
          debugPrint('  ❌ No user found with name: "$authorName"');

          // Show similar names for debugging
          debugPrint('  🔍 Similar names:');
          for (final entry in nameToIdMap.entries) {
            if (entry.key.contains(searchName) ||
                searchName.contains(entry.key)) {
              debugPrint('    - "${entry.key}" → ${entry.value}');
            }
          }
        } else {
          debugPrint('  ℹ️ Post already has correct authorId');
        }
      }

      debugPrint('✅ Simple database fix completed!');
      debugPrint('  - Fixed: $fixedCount posts');
      debugPrint('  - Not found: $notFoundCount posts');
    } catch (e) {
      debugPrint('❌ Error fixing database: $e');
      rethrow;
    }
  }
}
