import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DirectPostNameFix {
  /// Direct fix: Update all post authorName fields to match current user profiles
  static Future<void> updateAllPostNames() async {
    try {
      debugPrint('🔧 Starting direct post name update...');
      
      // Get all users first
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      debugPrint('👥 Found ${usersSnapshot.docs.length} users:');
      
      // Create user name mapping
      final userToNameMap = <String, String>{};
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final userName = userData['user_name'] as String? ?? '';
        userToNameMap[userId] = userName;
        debugPrint('  - $userId → "$userName"');
      }
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      debugPrint('📝 Found ${postsSnapshot.docs.length} posts to update');
      
      int updatedCount = 0;
      int alreadyCorrect = 0;
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final postAuthorId = postData['authorId'] ?? '';
        final currentAuthorName = postData['authorName'] ?? '';
        
        debugPrint('🔍 Checking post ${postDoc.id}:');
        debugPrint('  - Post authorId: $postAuthorId');
        debugPrint('  - Current authorName: "$currentAuthorName"');
        
        // Get the correct name from user profile
        final correctName = userToNameMap[postAuthorId];
        
        if (correctName != null && correctName != currentAuthorName) {
          debugPrint('  🔄 Updating: "$currentAuthorName" → "$correctName"');
          
          await postDoc.reference.update({
            'authorName': correctName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          updatedCount++;
          debugPrint('  ✅ Post ${postDoc.id} updated');
        } else if (correctName == null) {
          debugPrint('  ❌ No user found for authorId: $postAuthorId');
        } else {
          debugPrint('  ℹ️ Post already has correct name');
          alreadyCorrect++;
        }
      }
      
      debugPrint('✅ Direct post name update completed!');
      debugPrint('  - Updated: $updatedCount posts');
      debugPrint('  - Already correct: $alreadyCorrect posts');
      
    } catch (e) {
      debugPrint('❌ Error updating post names: $e');
      rethrow;
    }
  }
  
  /// Fix both authorId and authorName for posts
  static Future<void> completePostFix() async {
    try {
      debugPrint('🔧 Starting complete post fix...');
      
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      debugPrint('👥 Found ${usersSnapshot.docs.length} users:');
      
      // Create user mappings
      final userToNameMap = <String, String>{};
      final nameToIdMap = <String, String>{};
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final userName = userData['user_name'] as String? ?? '';
        final normalizedName = userName.toLowerCase().trim();
        
        userToNameMap[userId] = userName;
        nameToIdMap[normalizedName] = userId;
        
        debugPrint('  - $userId → "$userName"');
      }
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      debugPrint('📝 Found ${postsSnapshot.docs.length} posts to fix');
      
      int fixedCount = 0;
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final currentAuthorId = postData['authorId'] ?? '';
        final currentAuthorName = postData['authorName'] ?? '';
        
        debugPrint('🔍 Checking post ${postDoc.id}:');
        debugPrint('  - Current authorId: $currentAuthorId');
        debugPrint('  - Current authorName: "$currentAuthorName"');
        
        // Try to find correct user by name
        final normalizedName = currentAuthorName.toLowerCase().trim();
        final correctAuthorId = nameToIdMap[normalizedName];
        final correctAuthorName = userToNameMap[correctAuthorId ?? currentAuthorId];
        
        bool needsUpdate = false;
        final updates = <String, dynamic>{};
        
        if (correctAuthorId != null && correctAuthorId != currentAuthorId) {
          updates['authorId'] = correctAuthorId;
          needsUpdate = true;
          debugPrint('  🔄 Fixing authorId: $currentAuthorId → $correctAuthorId');
        }
        
        if (correctAuthorName != null && correctAuthorName != currentAuthorName) {
          updates['authorName'] = correctAuthorName;
          needsUpdate = true;
          debugPrint('  🔄 Fixing authorName: "$currentAuthorName" → "$correctAuthorName"');
        }
        
        if (needsUpdate) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await postDoc.reference.update(updates);
          fixedCount++;
          debugPrint('  ✅ Post ${postDoc.id} fixed');
        } else {
          debugPrint('  ℹ️ Post already correct');
        }
      }
      
      debugPrint('✅ Complete post fix completed! Fixed $fixedCount posts');
      
    } catch (e) {
      debugPrint('❌ Error in complete post fix: $e');
      rethrow;
    }
  }
}
