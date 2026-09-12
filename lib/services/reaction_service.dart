import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../models/reaction_type.dart';
import '../models/user_profile.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class ReactionService {
  static ReactionService? _instance;
  static ReactionService get instance => _instance ??= ReactionService._();

  ReactionService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notification = NotificationService.instance;

  Future<void> togglePostReaction(
    String postId,
    ReactionType reactionType,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final postRef = _firestore.collection('posts').doc(postId);
      final reactionRef = postRef.collection('reactions').doc(currentUserId);

      final reactionDoc = await reactionRef.get();

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) throw Exception('Post not found');

        final postData = postDoc.data()!;
        var analytics = PostAnalytics.fromJson(postData['analytics'] ?? {});
        final reactions = List<Map<String, dynamic>>.from(
          postData['reactions'] ?? [],
        );

        if (reactionDoc.exists) {
          final existingReaction = reactionDoc.data()!;
          final existingType = ReactionType.values.firstWhere(
            (type) => type.name == existingReaction['type'],
            orElse: () => ReactionType.like,
          );

          if (existingType == reactionType) {
            transaction.delete(reactionRef);
            reactions.removeWhere((r) => r['userId'] == currentUserId);

            switch (reactionType) {
              case ReactionType.like:
                analytics = analytics.copyWith(
                  likesCount: analytics.likesCount - 1,
                );
                break;
              case ReactionType.love:
              case ReactionType.laugh:
              case ReactionType.angry:
              case ReactionType.sad:
              case ReactionType.wow:
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount - 1,
                );
                break;
            }
          } else {
            transaction.update(reactionRef, {
              'type': reactionType.name,
              'timestamp': DateTime.now(),
            });

            final reactionIndex = reactions.indexWhere(
              (r) => r['userId'] == currentUserId,
            );
            if (reactionIndex != -1) {
              reactions[reactionIndex]['type'] = reactionType.name;
              reactions[reactionIndex]['timestamp'] = DateTime.now();
            }

            switch (existingType) {
              case ReactionType.like:
                analytics = analytics.copyWith(
                  likesCount: analytics.likesCount - 1,
                );
                break;
              case ReactionType.love:
              case ReactionType.laugh:
              case ReactionType.angry:
              case ReactionType.sad:
              case ReactionType.wow:
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount - 1,
                );
                break;
            }

            switch (reactionType) {
              case ReactionType.like:
                analytics = analytics.copyWith(
                  likesCount: analytics.likesCount + 1,
                );
                break;
              case ReactionType.love:
                // No direct equivalent in PostAnalytics, using reactionsCount
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount + 1,
                );
                break;
              case ReactionType.laugh:
                // No direct equivalent in PostAnalytics, using reactionsCount
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount + 1,
                );
                break;
              case ReactionType.angry:
                // No direct equivalent in PostAnalytics, using reactionsCount
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount + 1,
                );
                break;
              case ReactionType.sad:
                // No direct equivalent in PostAnalytics, using reactionsCount
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount + 1,
                );
                break;
              case ReactionType.wow:
                // No direct equivalent in PostAnalytics, using reactionsCount
                analytics = analytics.copyWith(
                  reactionsCount: analytics.reactionsCount + 1,
                );
                break;
            }
          }
        } else {
          transaction.set(reactionRef, {
            'userId': currentUserId,
            'type': reactionType.name,
            'timestamp': DateTime.now(),
          });

          reactions.add({
            'userId': currentUserId,
            'type': reactionType.name,
            'timestamp': DateTime.now(),
          });

          switch (reactionType) {
            case ReactionType.like:
              analytics = analytics.copyWith(
                likesCount: analytics.likesCount + 1,
              );
              break;
            case ReactionType.love:
            case ReactionType.laugh:
            case ReactionType.angry:
            case ReactionType.sad:
            case ReactionType.wow:
              analytics = analytics.copyWith(
                reactionsCount: analytics.reactionsCount + 1,
              );
              break;
          }

          final postOwnerId = postData['userId'] as String;
          if (postOwnerId != currentUserId) {
            await _notification.sendNotification(
              userId: postOwnerId,
              title: 'New Reaction',
              body: 'Someone reacted to your post',
              type: NotificationType.like,
              data: {'relatedId': postId},
            );
          }
        }

        transaction.update(postRef, {
          'reactions': reactions,
          'analytics': analytics.toJson(),
        });
      });

      debugPrint('Post reaction toggled: $postId');
    } catch (e) {
      debugPrint('Error toggling post reaction: $e');
      rethrow;
    }
  }

  Future<bool> hasUserReacted(String postId, ReactionType reactionType) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final reactionDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(currentUserId)
          .get();

      if (!reactionDoc.exists) return false;

      final reactionData = reactionDoc.data()!;
      final userReactionType = ReactionType.values.firstWhere(
        (type) => type.name == reactionData['type'],
        orElse: () => ReactionType.like,
      );

      return userReactionType == reactionType;
    } catch (e) {
      debugPrint('Error checking user reaction: $e');
      return false;
    }
  }

  Future<ReactionType?> getUserReaction(String postId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final reactionDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(currentUserId)
          .get();

      if (!reactionDoc.exists) return null;

      final reactionData = reactionDoc.data()!;
      return ReactionType.values.firstWhere(
        (type) => type.name == reactionData['type'],
        orElse: () => ReactionType.like,
      );
    } catch (e) {
      debugPrint('Error getting user reaction: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPostReactions(
    String postId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting post reactions: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getUsersByReaction(
    String postId,
    ReactionType reactionType, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .where('type', isEqualTo: reactionType.name)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final userIds = snapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting users by reaction: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getUsersWhoShared(
    String postId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('shares')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final userIds = snapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting users who shared: $e');
      return [];
    }
  }

  Future<void> incrementViews(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) throw Exception('Post not found');

        final postData = postDoc.data()!;
        var analytics = PostAnalytics.fromJson(postData['analytics'] ?? {});

        analytics = analytics.copyWith(viewsCount: analytics.viewsCount + 1);
        transaction.update(postRef, {'analytics': analytics.toJson()});
      });

      debugPrint('Post view incremented: $postId');
    } catch (e) {
      debugPrint('Error incrementing post views: $e');
    }
  }

  Future<int> getViewsCount(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return 0;

      final postData = postDoc.data()!;
      final analytics = PostAnalytics.fromJson(postData['analytics'] ?? {});
      return analytics.viewsCount;
    } catch (e) {
      debugPrint('Error getting views count: $e');
      return 0;
    }
  }
}
