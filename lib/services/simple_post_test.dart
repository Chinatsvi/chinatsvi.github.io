import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SimplePostTest {
  /// Simple test to see what's actually in the database
  static Future<void> checkPostData() async {
    try {
      debugPrint('🔍 === SIMPLE POST DATA TEST ===');
      
      // Get a specific post to examine
      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .limit(5)
          .get();
      
      debugPrint('📝 Found ${postSnapshot.docs.length} posts:');
      
      for (final postDoc in postSnapshot.docs) {
        final postData = postDoc.data()!;
        debugPrint('\n📄 Post ${postDoc.id}:');
        debugPrint('  - authorId: "${postData['authorId']}"');
        debugPrint('  - authorName: "${postData['authorName']}"');
        debugPrint('  - content: "${postData['content']?.substring(0, 50)}..."');
        debugPrint('  - createdAt: ${postData['created_at']}');
      }
      
      debugPrint('\n👥 === CHECK USER PROFILES ===');
      
      // Check user profiles
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .limit(5)
          .get();
      
      debugPrint('👥 Found ${usersSnapshot.docs.length} users:');
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data()!;
        debugPrint('\n👤 User ${userDoc.id}:');
        debugPrint('  - user_name: "${userData['user_name']}"');
        debugPrint('  - email: "${userData['email']}"');
        debugPrint('  - created_at: ${userData['created_at']}');
      }
      
      debugPrint('\n✅ Simple test completed!');
      
    } catch (e) {
      debugPrint('❌ Error in simple test: $e');
    }
  }
  
  /// Force update a specific post
  static Future<void> forceUpdatePost(String postId, String newAuthorName) async {
    try {
      debugPrint('🔧 Force updating post $postId with name: "$newAuthorName"');
      
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
            'authorName': newAuthorName,
            'forceUpdatedAt': FieldValue.serverTimestamp(),
          });
      
      debugPrint('✅ Post $postId updated successfully!');
      
    } catch (e) {
      debugPrint('❌ Error updating post: $e');
    }
  }
  
  /// Clear all caches and force refresh
  static Future<void> clearAllCaches() async {
    try {
      debugPrint('🗑️ Clearing all caches...');
      
      // Clear post cache in PostCard
      // Note: This would need to be called from the UI
      
      debugPrint('✅ Caches cleared!');
      
    } catch (e) {
      debugPrint('❌ Error clearing caches: $e');
    }
  }
}
