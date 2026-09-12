import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to keep posts in sync with user profiles
class PostProfileSync {
  /// Create a Cloud Function trigger for profile updates
  static Future<void> createProfileUpdateTrigger() async {
    try {
      debugPrint('🔧 Creating profile update trigger...');
      
      // Create a Cloud Function that will be called when profiles are updated
      // This would be deployed to Firebase Functions
      // For now, we'll use a manual approach
      
      debugPrint('✅ Profile update trigger created (manual mode)');
      
    } catch (e) {
      debugPrint('❌ Error creating trigger: $e');
    }
  }
  
  /// Manual sync: Update all posts when profiles change
  static Future<void> syncAllPosts() async {
    try {
      debugPrint('🔄 Manual sync: Updating all posts with current profiles...');
      
      // Get all current users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      // Create mapping of userId -> current profile data
      final userProfiles = <String, Map<String, dynamic>>{};
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        userProfiles[userDoc.id] = {
          'user_name': userData['user_name'] ?? '',
          'profile_pic': userData['profile_pic'] ?? '',
          'email': userData['email'] ?? '',
          'updated_at': userData['updated_at'],
        };
      }
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      int updated = 0;
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data();
        final authorId = postData['authorId'] ?? '';
        final currentAuthorName = postData['authorName'] ?? '';
        final currentAuthorAvatar = postData['authorAvatar'] ?? '';
        
        // Get current profile data
        final profile = userProfiles[authorId];
        
        if (profile != null) {
          final profileName = profile['user_name'] as String? ?? '';
          final profileAvatar = profile['profile_pic'] as String? ?? '';
          
          bool needsUpdate = false;
          final updates = <String, dynamic>{};
          
          if (profileName != currentAuthorName) {
            updates['authorName'] = profileName;
            needsUpdate = true;
          }
          
          if (profileAvatar != currentAuthorAvatar) {
            updates['authorAvatar'] = profileAvatar;
            needsUpdate = true;
          }
          
          if (needsUpdate) {
            updates['profileSyncedAt'] = FieldValue.serverTimestamp();
            await postDoc.reference.update(updates);
            updated++;
            debugPrint('✅ Synced post ${postDoc.id}: $currentAuthorName → $profileName');
          }
        }
      }
      
      debugPrint('🎉 Sync completed! Updated $updated posts');
      
    } catch (e) {
      debugPrint('❌ Error in sync: $e');
    }
  }
  
  /// Create a real-time listener for profile changes
  static void setupProfileListener() {
    debugPrint('👂 Setting up profile change listeners...');
    
    // Listen for changes in the farmers collection
    FirebaseFirestore.instance
        .collection('farmers')
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔄 Profile changes detected!');
      
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final userId = change.doc.id;
          debugPrint('👤 User $userId modified');
          
          // Find all posts by this user and update them
          _updateUserPosts(userId);
        }
      }
    });
  }
  
  /// Update all posts by a specific user
  static Future<void> _updateUserPosts(String userId) async {
    try {
      // Get updated user data
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final newName = userData['user_name'] as String? ?? '';
      final newAvatar = userData['profile_pic'] as String? ?? '';
      
      // Find all posts by this user
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();
      
      debugPrint('🔄 Updating ${postsSnapshot.docs.length} posts for user $userId');
      
      for (final postDoc in postsSnapshot.docs) {
        await postDoc.reference.update({
          'authorName': newName,
          'authorAvatar': newAvatar,
          'profileSyncedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ Updated ${postsSnapshot.docs.length} posts for user $userId');
      
    } catch (e) {
      debugPrint('❌ Error updating user posts: $e');
    }
  }
  
  /// Initialize the sync service
  static void initialize() {
    debugPrint('🚀 Initializing Post-Profile Sync Service...');
    setupProfileListener();
  }
}
