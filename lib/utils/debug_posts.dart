import 'package:cloud_firestore/cloud_firestore.dart';

class DebugPosts {
  static Future<void> checkAllPosts() async {
    print('🔍 DEBUGGING ALL POSTS IN DATABASE...\n');

    try {
      // Get ALL posts without any filters
      final allPosts = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      print('📊 Total posts found: ${allPosts.docs.length}\n');

      if (allPosts.docs.isEmpty) {
        print('❌ NO POSTS FOUND IN DATABASE AT ALL!');
        return;
      }

      for (int i = 0; i < allPosts.docs.length; i++) {
        final doc = allPosts.docs[i];
        final data = doc.data();

        print('📄 POST ${i + 1}:');
        print('  ID: ${doc.id}');
        print('  Content: ${data['content'] ?? 'NO CONTENT'}');
        print('  Author: ${data['authorName'] ?? 'NO AUTHOR'}');
        print('  Status: ${data['status'] ?? 'MISSING'}');
        print('  Active: ${data['active'] ?? 'MISSING'}');
        print('  Created: ${data['created_at'] ?? 'MISSING'}');
        print('  ---');
      }

      // Now test the actual feed query
      print('\n🔍 TESTING FEED QUERY (active=true, status=active):');
      final feedPosts = await FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .where('active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      print('📊 Feed query results: ${feedPosts.docs.length} posts');

      if (feedPosts.docs.isEmpty) {
        print('❌ FEED QUERY RETURNS NO POSTS!');

        // Check what status values actually exist
        print('\n🔍 CHECKING ALL STATUS VALUES IN DATABASE:');
        final statusSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .get();

        final statusCounts = <String, int>{};
        for (final doc in statusSnapshot.docs) {
          final status = doc.data()['status']?.toString() ?? 'NULL';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        print('📈 Status field distribution:');
        statusCounts.forEach((status, count) {
          print('  - "$status": $count posts');
        });

        // Try without active filter
        print('\n🔍 TESTING WITHOUT ACTIVE FILTER (status=active only):');
        final statusOnlyPosts = await FirebaseFirestore.instance
            .collection('posts')
            .where('status', isEqualTo: 'active')
            .orderBy('created_at', descending: true)
            .limit(10)
            .get();

        print('📊 Status-only query: ${statusOnlyPosts.docs.length} posts');

        // Try with different status values
        print('\n🔍 TESTING WITH status="active" (string):');
        final stringStatusPosts = await FirebaseFirestore.instance
            .collection('posts')
            .where('status', isEqualTo: 'active')
            .where('active', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .limit(10)
            .get();

        print('📊 String status query: ${stringStatusPosts.docs.length} posts');
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }
}
