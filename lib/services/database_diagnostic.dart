import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseDiagnostic {
  /// Complete database diagnostic to understand the issue
  static Future<void> runFullDiagnostic() async {
    try {
      debugPrint('🔍 Starting full database diagnostic...');
      
      // 1. Check all users in farmers collection
      debugPrint('\n👥 === ALL USERS IN FARMERS COLLECTION ===');
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      debugPrint('Found ${usersSnapshot.docs.length} users:');
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        debugPrint('  📝 User ${userDoc.id}:');
        debugPrint('    - user_name: "${userData['user_name']}"');
        debugPrint('    - email: "${userData['email']}"');
        debugPrint('    - profile_pic: "${userData['profile_pic']}"');
        debugPrint('    - created_at: ${userData['created_at']}');
        debugPrint('    - updated_at: ${userData['updated_at']}');
      }
      
      // 2. Check all posts and their author information
      debugPrint('\n📝 === ALL POSTS AND THEIR AUTHORS ===');
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      debugPrint('Found ${postsSnapshot.docs.length} posts:');
      
      // Collect all unique authorIds and authorNames
      final authorIds = <String>{};
      final authorNames = <String>{};
      final authorToPostMap = <String, List<String>>{};
      final nameToPostMap = <String, List<String>>{};
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final authorId = postData['authorId'] ?? '';
        final authorName = postData['authorName'] ?? '';
        
        authorIds.add(authorId);
        authorNames.add(authorName);
        
        authorToPostMap.putIfAbsent(authorId, () => []).add(postDoc.id);
        nameToPostMap.putIfAbsent(authorName, () => []).add(postDoc.id);
        
        debugPrint('  📄 Post ${postDoc.id}:');
        debugPrint('    - authorId: "$authorId"');
        debugPrint('    - authorName: "$authorName"');
        debugPrint('    - created_at: ${postData['created_at']}');
      }
      
      // 3. Show summary of unique authors
      debugPrint('\n📊 === AUTHOR SUMMARY ===');
      debugPrint('Unique authorIds (${authorIds.length}):');
      for (final authorId in authorIds) {
        final posts = authorToPostMap[authorId] ?? [];
        debugPrint('  - $authorId (${posts.length} posts)');
      }
      
      debugPrint('\nUnique authorNames (${authorNames.length}):');
      for (final authorName in authorNames) {
        final posts = nameToPostMap[authorName] ?? [];
        debugPrint('  - "$authorName" (${posts.length} posts)');
      }
      
      // 4. Check for mismatches
      debugPrint('\n🔍 === AUTHOR ID TO NAME MAPPINGS ===');
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final authorId = postData['authorId'] ?? '';
        final authorName = postData['authorName'] ?? '';
        
        // Check if this authorId exists in users
        final userExists = usersSnapshot.docs.any((doc) => doc.id == authorId);
        debugPrint('  📄 Post ${postDoc.id}:');
        debugPrint('    - authorId: "$authorId" → User exists: $userExists');
        debugPrint('    - authorName: "$authorName"');
        
        if (!userExists) {
          debugPrint('    ⚠️  WARNING: authorId not found in users collection!');
        }
      }
      
      // 5. Check for users with no posts
      debugPrint('\n🔍 === USERS WITH NO POSTS ===');
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final hasPosts = authorIds.contains(userId);
        if (!hasPosts) {
          final userData = userDoc.data();
          debugPrint('  👤 User ${userId}: "${userData['user_name']}" - NO POSTS');
        }
      }
      
      debugPrint('\n✅ Database diagnostic completed!');
      
    } catch (e) {
      debugPrint('❌ Error in diagnostic: $e');
      rethrow;
    }
  }
  
  /// Create missing users based on post authorNames
  static Future<void> createMissingUsers() async {
    try {
      debugPrint('🔧 Creating missing users based on post authorNames...');
      
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      // Get all existing users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      final existingUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      
      int createdCount = 0;
      
      for (final postDoc in postsSnapshot.docs) {
        final postData = postDoc.data()!;
        final authorId = postData['authorId'] ?? '';
        final authorName = postData['authorName'] ?? '';
        
        // If user doesn't exist, create them
        if (!existingUserIds.contains(authorId) && authorName.isNotEmpty) {
          debugPrint('👤 Creating user: $authorId with name "$authorName"');
          
          await FirebaseFirestore.instance
              .collection('farmers')
              .doc(authorId)
              .set({
                'user_name': authorName,
                'email': '$authorId@example.com', // Placeholder email
                'profile_pic': 'assets/images/default_avatar.png',
                'created_at': FieldValue.serverTimestamp(),
                'updated_at': FieldValue.serverTimestamp(),
                'phone': '',
                'location': '',
                'bio': '',
              });
          
          createdCount++;
          debugPrint('  ✅ User created: $authorId');
        }
      }
      
      debugPrint('✅ Created $createdCount missing users!');
      
    } catch (e) {
      debugPrint('❌ Error creating missing users: $e');
      rethrow;
    }
  }
}
