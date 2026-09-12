import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseFixService {
  /// Fix posts with wrong authorId by matching authorName to correct user
  static Future<void> fixPostAuthorIds() async {
    try {
      debugPrint('🔧 Starting database fix for post authorId corruption...');

      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      debugPrint('📊 Found ${postsSnapshot.docs.length} posts to check');

      int fixedCount = 0;

      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final currentAuthorId = postData['authorId'] ?? '';
        final authorName = postData['authorName'] ?? '';

        debugPrint('🔍 Checking post ${postDoc.id}:');
        debugPrint('  - Current authorId: $currentAuthorId');
        debugPrint('  - authorName: $authorName');

        // Find the correct user by authorName
        debugPrint('  🔍 Searching for user with name: "$authorName"');
        final userSnapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .where('user_name', isEqualTo: authorName)
            .limit(1)
            .get();

        debugPrint(
          '  📊 Found ${userSnapshot.docs.length} users with that name',
        );

        if (userSnapshot.docs.isNotEmpty) {
          final correctAuthorId = userSnapshot.docs.first.id;
          final userData = userSnapshot.docs.first.data();

          debugPrint('  ✅ Found user:');
          debugPrint('    - ID: $correctAuthorId');
          debugPrint('    - Name: ${userData['user_name']}');
          debugPrint('    - Email: ${userData['email']}');

          if (correctAuthorId != currentAuthorId) {
            debugPrint(
              '  🔄 Updating post authorId from $currentAuthorId to $correctAuthorId',
            );

            await postDoc.reference.update({
              'authorId': correctAuthorId,
              'fixedAt': FieldValue.serverTimestamp(),
            });

            fixedCount++;
            debugPrint('  ✅ Post ${postDoc.id} fixed');
          } else {
            debugPrint('  ℹ️ Post already has correct authorId');
          }
        } else {
          debugPrint('  ❌ No user found with name: "$authorName"');

          // Try to find similar names
          final allUsersSnapshot = await FirebaseFirestore.instance
              .collection('farmers')
              .limit(5)
              .get();

          debugPrint('  🔍 Available users (first 5):');
          for (final userDoc in allUsersSnapshot.docs) {
            final userData = userDoc.data();
            debugPrint('    - ${userData['user_name']} (${userDoc.id})');
          }
        }
      }

      debugPrint('✅ Database fix completed! Fixed $fixedCount posts');
    } catch (e) {
      debugPrint('❌ Error fixing database: $e');
      rethrow;
    }
  }
}
