import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserNameUpdateService {
  static final UserNameUpdateService _instance =
      UserNameUpdateService._internal();
  static UserNameUpdateService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _batchSize = 100; // Process 100 posts at a time for safety

  UserNameUpdateService._internal();

  /// Update user name across all posts and comments in batches
  Future<void> updateUserNameAcrossAllPosts(
    String userId,
    String newName, {
    String? newAvatar,
  }) async {
    if (kDebugMode) {
      print('🔄 Starting user name update for user: $userId -> $newName');
      if (newAvatar != null) {
        print('🔄 Also updating avatar for user: $userId -> $newAvatar');
      }
      print('🔄 Service instance: ${instance.hashCode}');
    }

    try {
      // Update user profile first
      await _updateUserProfile(userId, newName, newAvatar);

      // Update posts in batches
      await _updatePostsInBatches(userId, newName, newAvatar);

      // Update comments in batches
      await _updateCommentsInBatches(userId, newName, newAvatar);

      // Update replies in batches
      await _updateRepliesInBatches(userId, newName, newAvatar);

      if (kDebugMode) {
        print('✅ User name update completed for: $userId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error updating user name: $e');
        print('❌ Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Update user profile document
  Future<void> _updateUserProfile(
    String userId,
    String newName,
    String? newAvatar,
  ) async {
    try {
      final updateData = {
        'user_name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newAvatar != null) {
        updateData['profile_pic'] = newAvatar;
      }

      await _firestore.collection('farmers').doc(userId).update(updateData);
      if (kDebugMode) {
        print('✅ Updated user profile for: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
    }
  }

  /// Update posts in batches
  Future<void> _updatePostsInBatches(
    String userId,
    String newName,
    String? newAvatar,
  ) async {
    QuerySnapshot postsSnapshot;

    try {
      // Get all posts by this user
      postsSnapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();

      if (postsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No posts found for user: $userId');
        }
        return;
      }

      final posts = postsSnapshot.docs;
      if (kDebugMode) {
        print('📝 Found ${posts.length} posts to update');
      }

      // Process posts in batches
      for (int i = 0; i < posts.length; i += _batchSize) {
        final end = (i + _batchSize < posts.length)
            ? i + _batchSize
            : posts.length;
        final batch = posts.sublist(i, end);

        await _processBatch(
          batch,
          'posts',
          userId,
          newName,
          i ~/ _batchSize + 1,
          (posts.length ~/ _batchSize) + 1,
          newAvatar: newAvatar,
        );

        // Small delay between batches to avoid overwhelming Firestore
        if (i + _batchSize < posts.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating posts: $e');
      }
    }
  }

  /// Update comments in batches
  Future<void> _updateCommentsInBatches(
    String userId,
    String newName,
    String? newAvatar,
  ) async {
    QuerySnapshot postsSnapshot;

    try {
      // Get all posts first
      postsSnapshot = await _firestore.collection('posts').get();

      if (postsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No posts found for comments update');
        }
        return;
      }

      final allComments = <DocumentSnapshot>[];

      // Collect all comments from all posts
      for (var postDoc in postsSnapshot.docs) {
        final commentsSnapshot = await postDoc.reference
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get();
        allComments.addAll(commentsSnapshot.docs);
      }

      if (allComments.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No comments found for user: $userId');
        }
        return;
      }

      if (kDebugMode) {
        print('💬 Found ${allComments.length} comments to update');
      }

      // Process comments in batches
      for (int i = 0; i < allComments.length; i += _batchSize) {
        final end = (i + _batchSize < allComments.length)
            ? i + _batchSize
            : allComments.length;
        final batch = allComments.sublist(i, end);

        await _processBatch(
          batch,
          'comments',
          userId,
          newName,
          i ~/ _batchSize + 1,
          (allComments.length ~/ _batchSize) + 1,
          newAvatar: newAvatar,
        );

        // Small delay between batches
        if (i + _batchSize < allComments.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating comments: $e');
      }
    }
  }

  /// Update replies in batches
  Future<void> _updateRepliesInBatches(
    String userId,
    String newName,
    String? newAvatar,
  ) async {
    QuerySnapshot postsSnapshot;

    try {
      // Get all posts
      postsSnapshot = await _firestore.collection('posts').get();

      if (postsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No posts found for replies update');
        }
        return;
      }

      final allReplies = <DocumentSnapshot>[];

      // Collect all replies by this user from all posts
      for (var postDoc in postsSnapshot.docs) {
        final commentsSnapshot = await postDoc.reference
            .collection('comments')
            .get();

        for (var commentDoc in commentsSnapshot.docs) {
          final repliesSnapshot = await commentDoc.reference
              .collection('replies')
              .where('userId', isEqualTo: userId)
              .get();
          allReplies.addAll(repliesSnapshot.docs);
        }
      }

      if (allReplies.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No replies found for user: $userId');
        }
        return;
      }

      if (kDebugMode) {
        print('💭 Found ${allReplies.length} replies to update');
      }

      // Process replies in batches
      for (int i = 0; i < allReplies.length; i += _batchSize) {
        final end = (i + _batchSize < allReplies.length)
            ? i + _batchSize
            : allReplies.length;
        final batch = allReplies.sublist(i, end);

        await _processBatch(
          batch,
          'replies',
          userId,
          newName,
          i ~/ _batchSize + 1,
          (allReplies.length ~/ _batchSize) + 1,
          newAvatar: newAvatar,
        );

        // Small delay between batches
        if (i + _batchSize < allReplies.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating replies: $e');
      }
    }
  }

  /// Process a batch of documents
  Future<void> _processBatch(
    List<DocumentSnapshot> batch,
    String collectionType,
    String userId,
    String newName,
    int batchNumber,
    int totalBatches, {
    String? newAvatar,
  }) async {
    try {
      final batchWrite = _firestore.batch();

      for (var doc in batch) {
        final updateData = {
          'userName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (newAvatar != null) {
          updateData['userProfile'] = newAvatar;
        }

        batchWrite.update(doc.reference, updateData);
      }

      await batchWrite.commit();

      if (kDebugMode) {
        print(
          '✅ Updated $collectionType batch $batchNumber/$totalBatches (${batch.length} documents)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing $collectionType batch $batchNumber: $e');
      }

      // Retry logic for failed batches
      await _retryFailedBatch(
        batch,
        collectionType,
        userId,
        newName,
        batchNumber,
        totalBatches,
        newAvatar: newAvatar,
      );
    }
  }

  /// Retry failed batch with exponential backoff
  Future<void> _retryFailedBatch(
    List<DocumentSnapshot> batch,
    String collectionType,
    String userId,
    String newName,
    int batchNumber,
    int totalBatches, {
    String? newAvatar,
  }) async {
    const int maxRetries = 3;
    const List<int> retryDelays = [1000, 2000, 4000]; // 1s, 2s, 4s

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await Future.delayed(Duration(milliseconds: retryDelays[attempt]));

        final batchWrite = _firestore.batch();

        for (var doc in batch) {
          final updateData = {
            'userName': newName,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (newAvatar != null) {
            updateData['userProfile'] = newAvatar;
          }

          batchWrite.update(doc.reference, updateData);
        }

        await batchWrite.commit();

        if (kDebugMode) {
          print(
            '✅ Retry successful for $collectionType batch $batchNumber (attempt ${attempt + 1})',
          );
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print(
            '❌ Retry $attempt + 1 failed for $collectionType batch $batchNumber: $e',
          );
        }
      }
    }

    if (kDebugMode) {
      print('❌ All retries failed for $collectionType batch $batchNumber');
    }
  }
}
