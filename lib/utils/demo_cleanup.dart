import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Delete ALL posts in the posts collection
Future<void> deleteAllPosts() async {
  final firestore = FirebaseFirestore.instance;

  try {
    final posts = await firestore.collection('posts').get();
    if (posts.docs.isEmpty) {
      developer.log('No posts found to delete.', name: 'DemoCleanup');
      return;
    }

    final batch = firestore.batch();
    for (var doc in posts.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    developer.log(
      'Deleted ${posts.docs.length} posts from posts collection.',
      name: 'DemoCleanup',
    );
  } catch (e) {
    developer.log('Error deleting posts: $e', name: 'DemoCleanup', error: e);
  }
}

/// Delete only posts with empty content or demo authors
Future<void> deleteBadPosts() async {
  final firestore = FirebaseFirestore.instance;

  try {
    final posts = await firestore.collection('posts').get();
    if (posts.docs.isEmpty) {
      developer.log('No posts found.', name: 'DemoCleanup');
      return;
    }

    final batch = firestore.batch();
    for (var doc in posts.docs) {
      final data = doc.data();
      final content = (data['content'] ?? '').toString();
      final authorName = (data['authorName'] ?? '').toString();

      if (content.isEmpty || authorName.startsWith('Demo User')) {
        batch.delete(doc.reference);
        developer.log(
          'Deleting post ${doc.id} by $authorName',
          name: 'DemoCleanup',
        );
      }
    }

    await batch.commit();
    developer.log('Cleanup complete.', name: 'DemoCleanup');
  } catch (e) {
    developer.log(
      'Error cleaning bad posts: $e',
      name: 'DemoCleanup',
      error: e,
    );
  }
}
