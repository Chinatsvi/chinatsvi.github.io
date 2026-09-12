import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple diagnostic script to check posts and users
class PostDiagnostic {
  static Future<void> checkPostsAndUsers() async {
    print('🔍 Starting post and user diagnostic...');
    
    try {
      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }
      print('✅ Current user: ${currentUser.uid} (${currentUser.email})');
      
      // Check farmers collection
      final farmersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      print('👥 Found ${farmersSnapshot.docs.length} farmers in database');
      
      // Check posts collection
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      print('📝 Found ${postsSnapshot.docs.length} posts in database');
      
      // Check active posts
      final activePostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .get();
      print('✅ Found ${activePostsSnapshot.docs.length} active posts');
      
      // Check posts by current user
      final userPostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: currentUser.uid)
          .where('active', isEqualTo: true)
          .get();
      print('👤 Found ${userPostsSnapshot.docs.length} posts by current user');
      
      // Show details of first few posts
      if (activePostsSnapshot.docs.isNotEmpty) {
        print('\n📄 Sample post details:');
        for (int i = 0; i < activePostsSnapshot.docs.length && i < 3; i++) {
          final doc = activePostsSnapshot.docs[i];
          final data = doc.data();
          print('  Post ${i + 1}:');
          print('    ID: ${doc.id}');
          print('    Author: ${data['authorName']} (${data['authorId']})');
          print('    Content: "${data['content']}"');
          print('    Active: ${data['active']}');
          print('    Status: ${data['status']}');
          print('    Created: ${data['created_at']}');
          print('    Media: ${data['media']}');
        }
      }
      
      print('\n✅ Diagnostic completed successfully!');
      
    } catch (e) {
      print('❌ Error during diagnostic: $e');
    }
  }
  
  static Future<void> createTestPost() async {
    print('📝 Creating test post...');
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }
      
      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        print('❌ User profile not found');
        return;
      }
      
      final userData = userDoc.data()!;
      
      // Create test post
      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      
      await postRef.set({
        'authorId': currentUser.uid,
        'authorName': userData['user_name'] ?? 'Test Farmer',
        'authorAvatar': userData['profile_pic'] ?? '',
        'content': 'This is a test post created at ${DateTime.now()}',
        'content_type': 'text',
        'created_at': FieldValue.serverTimestamp(),
        'media': [],
        'hashtags': ['test'],
        'status': 'active',
        'analytics': {
          'viewsCount': 0,
          'commentsCount': 0,
          'sharesCount': 0,
          'reactionsCount': 0,
          'reactionEmojiCounts': {},
          'savesCount': 0,
          'likesCount': 0,
        },
        'likes': [],
        'reactions': {},
        'comments': [],
        'active': true, // Important: set active to true
      });
      
      print('✅ Test post created with ID: ${postRef.id}');
      
    } catch (e) {
      print('❌ Error creating test post: $e');
    }
  }
}
