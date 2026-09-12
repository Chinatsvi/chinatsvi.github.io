import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration script to update old comment field names and initialize counts
/// Run this once to migrate all existing comments and initialize counts
class CommentFieldMigration {
  static Future<void> migrateAllComments() async {
    print('Starting comment field migration...');

    try {
      // Get all posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      for (final postDoc in postsSnapshot.docs) {
        final postId = postDoc.id;
        print('Migrating comments for post: $postId');

        // Initialize comment count first
        await _initializeCommentCount(postId);

        // Initialize reactions field
        await _initializeReactions(postId);

        // Migrate main comments
        await _migrateComments(postId);

        // Migrate replies for each comment
        await _migrateReplies(postId);
      }

      print('Comment migration completed successfully!');
    } catch (e) {
      print('Migration failed: $e');
    }
  }

  static Future<void> _initializeReactions(String postId) async {
    final postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();

    if (!postDoc.exists) return;

    final data = postDoc.data() as Map<String, dynamic>?;

    // Check if reactions field exists and is properly initialized
    if (data == null || !data.containsKey('reactions')) {
      // Initialize empty reactions map
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'reactions': <String, String>{},
      });

      print('Initialized reactions field for post $postId');
    } else {
      // Ensure reactions field is a Map<String, String>
      final reactions = data['reactions'];
      if (reactions is! Map<String, String>) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {'reactions': <String, String>{}},
        );

        print('Fixed reactions field type for post $postId');
      }
    }
  }

  static Future<void> _initializeCommentCount(String postId) async {
    // Count actual comments in subcollection
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();

    final commentCount = commentsSnapshot.size;

    // Update the post document with the count
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'commentsCount': commentCount,
    });

    print('Initialized comment count for post $postId: $commentCount comments');
  }

  static Future<void> _migrateComments(String postId) async {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();

    for (final commentDoc in commentsSnapshot.docs) {
      final data = commentDoc.data();

      // Check if old fields exist and new fields don't
      if (data.containsKey('userName') && !data.containsKey('user_name')) {
        await commentDoc.reference.update({
          'user_name': data['userName'],
          'profile_pic': data['userProfile'] ?? '',
        });

        // Optionally remove old fields after successful migration
        await commentDoc.reference.update({
          'userName': FieldValue.delete(),
          'userProfile': FieldValue.delete(),
        });

        print('Migrated comment: ${commentDoc.id}');
      }
    }
  }

  static Future<void> _migrateReplies(String postId) async {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();

    for (final commentDoc in commentsSnapshot.docs) {
      final commentId = commentDoc.id;

      final repliesSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .get();

      for (final replyDoc in repliesSnapshot.docs) {
        final data = replyDoc.data();

        // Check if old fields exist and new fields don't
        if (data.containsKey('userName') && !data.containsKey('user_name')) {
          await replyDoc.reference.update({
            'user_name': data['userName'],
            'profile_pic': data['userProfile'] ?? '',
          });

          // Optionally remove old fields after successful migration
          await replyDoc.reference.update({
            'userName': FieldValue.delete(),
            'userProfile': FieldValue.delete(),
          });

          print('Migrated reply: ${replyDoc.id}');
        }
      }
    }
  }
}

/// Usage example:
/// Call this function once to migrate all existing comments
///
/// void main() async {
///   await CommentFieldMigration.migrateAllComments();
/// }
