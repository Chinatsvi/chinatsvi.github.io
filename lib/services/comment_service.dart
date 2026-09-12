import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/comment_model.dart';
import 'package:agribased/services/smart_moderation_service.dart';
import 'dart:developer' as developer;

/// Fire-and-forget helper for non-blocking operations
void unawaited(Future<void> future) {
  // Intentionally not awaiting - fire and forget
}

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorProfilePic,
    bool authorVerified = false,
    required String content,
  }) async {
    // 🔍 SMART MODERATION: Check comment before posting
    final commentId = DateTime.now().millisecondsSinceEpoch.toString();
    
    developer.log('🔄 Checking comment for moderation...', name: 'CommentService');
    final moderationResult = await SmartModerationService.moderateContent(
      content: content,
      postId: commentId,
      userId: authorId,
      userName: authorName,
      authorProfilePic: authorProfilePic,
    );

    // If high confidence violation detected, reject the comment
    if (moderationResult == false) {
      throw Exception(
        'Your comment was rejected due to policy violations. '
        'Please review our community guidelines.',
      );
    }

    // If moderate confidence (null), log it but still allow posting
    if (moderationResult == null) {
      developer.log(
        '⚠️ Comment flagged for admin review but allowing publication',
        name: 'CommentService',
      );
    }

    // Create comment data with unique ID
    final commentData = {
      'id': commentId,
      'userId': authorId,
      'user_name': authorName,
      'author_verified': authorVerified,
      'profile_pic': authorProfilePic,
      'text': content,
      'created_at': Timestamp.now(),
    };

    // Store comment directly in post document - instant and stable like major apps
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([commentData]),
      'analytics.commentsCount': FieldValue.increment(1),
    });

    developer.log('✅ Comment created successfully', name: 'CommentService');
  }

  Future<void> editComment({
    required String postId,
    required String commentId,
    required String newContent,
    required String userId,
    required String userName,
  }) async {
    // 🔍 SMART MODERATION: Check edited comment before updating
    developer.log('🔄 Checking edited comment for moderation...', name: 'CommentService');
    
    final moderationResult = await SmartModerationService.moderateContent(
      content: newContent,
      postId: commentId,
      userId: userId,
      userName: userName,
    );

    // If high confidence violation detected, reject the edit
    if (moderationResult == false) {
      throw Exception(
        'Your comment edit was rejected due to policy violations. '
        'Please review our community guidelines.',
      );
    }

    // Get current post data
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (!postDoc.exists) return;

    final postData = postDoc.data() as Map<String, dynamic>?;
    final comments = List<Map<String, dynamic>>.from(
      postData?['comments'] as List<dynamic>? ?? [],
    );

    // Find and update the comment
    final commentIndex = comments.indexWhere(
      (comment) => comment['id'] == commentId,
    );
    if (commentIndex != -1) {
      comments[commentIndex]['text'] = newContent;
      comments[commentIndex]['updatedAt'] = Timestamp.now();

      // Update the post document
      await _firestore.collection('posts').doc(postId).update({
        'comments': comments,
      });

      developer.log('✅ Comment updated successfully', name: 'CommentService');
    }
  }

  Future<void> editReply({
    required String postId,
    required String commentId,
    required String replyId,
    required String newContent,
  }) async {
    try {
      developer.log(
        'Editing reply $replyId in comment $commentId for post $postId',
        name: 'CommentService',
      );

      // Update the reply document directly
      final replyRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId);

      await replyRef.update({'text': newContent, 'updatedAt': Timestamp.now()});

      developer.log('Reply updated successfully', name: 'CommentService');
    } catch (e) {
      developer.log('Error editing reply: $e', name: 'CommentService');
      rethrow;
    }
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    // Get current post data
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (!postDoc.exists) return;

    final postData = postDoc.data() as Map<String, dynamic>?;
    final comments = List<Map<String, dynamic>>.from(
      postData?['comments'] as List<dynamic>? ?? [],
    );

    // Remove the comment
    final updatedComments = comments
        .where((comment) => comment['id'] != commentId)
        .toList();

    // Update the post document
    await _firestore.collection('posts').doc(postId).update({
      'comments': updatedComments,
      'analytics.commentsCount': FieldValue.increment(-1),
    });
  }
}
