import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

class PostController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------
  // Posts
  // -----------------------------

  Future<String> createPost({
    required Post post,
    String collection = 'posts',
    String? locationTag,
    String? feelingTag,
  }) async {
    try {
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(post.authorId)
          .get();

      Map<String, dynamic> farmerData;

      if (!farmerDoc.exists) {
        debugPrint(
          '⚠️ Farmer profile missing for UID ${post.authorId}, creating comprehensive default profile...',
        );

        // Create a comprehensive default farmer profile
        await _firestore.collection('farmers').doc(post.authorId).set({
          'user_name': post.authorName.isNotEmpty ? post.authorName : 'Farmer',
          'profile_pic': post.authorAvatar.isNotEmpty ? post.authorAvatar : '',
          'created_at': FieldValue.serverTimestamp(),
          'uid': post.authorId,
          'email': '',
          'phone': '',
          'bio': 'Default bio - please update your profile',
          'location': '',
          'farm_name': '',
          'farm_size': '',
          'verified': false, // Start as unverified
          'status': 'active', // Set farmer status to active
        });

        debugPrint(
          '✅ Created comprehensive default farmer profile for ${post.authorId}',
        );
        farmerData = {
          'user_name': post.authorName.isNotEmpty ? post.authorName : 'Farmer',
          'profile_pic': post.authorAvatar.isNotEmpty ? post.authorAvatar : '',
          'uid': post.authorId,
          'email': '',
          'phone': '',
          'bio': 'Default bio - please update your profile',
          'location': '',
          'farm_name': '',
          'farm_size': '',
          'verified': false,
          'status': 'active',
        };
      } else {
        debugPrint('✅ Found existing farmer profile for ${post.authorId}');
        farmerData = farmerDoc.data() ?? {};
      }

      final effectiveRef = post.id.isNotEmpty
          ? _firestore.collection(collection).doc(post.id)
          : _firestore.collection(collection).doc();

      // Create a new Post with the correct ID
      final postWithId = Post(
        id: effectiveRef.id,
        authorId: post.authorId,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        content: post.content,
        contentType: post.contentType,
        createdAt: post.createdAt,
        media: post.media,
        hashtags: post.hashtags,
        status: post.status,
        analytics: post.analytics,
        likes: post.likes,
        reactions: post.reactions,
        groupId: post.groupId,
        groupVisibility: post.groupVisibility,
        feelingTag: post.feelingTag,
        locationTag: post.locationTag,
        repostOf: post.repostOf,
        caption: post.caption,
      );

      final map = postWithId.toFirestoreMap();

      // 🔎 ALWAYS override with explicit values (takes precedence over toFirestoreMap)
      map['authorName'] = farmerData['user_name'] ?? 'Farmer';
      map['authorAvatar'] = farmerData['profile_pic'] ?? '';

      // DEBUG: Log profile picture info
      debugPrint(
        '🔧 POST CREATE: authorName="${map['authorName']}", authorAvatar="${map['authorAvatar']}"',
      );
      debugPrint(
        '🔧 POST CREATE: farmerData profile_pic="${farmerData['profile_pic']}"',
      );

      // DEBUG: Log verification data
      debugPrint('🔧 POST CREATE: farmerData keys=${farmerData.keys.toList()}');
      debugPrint(
        '🔧 POST CREATE: isVerified=${farmerData['isVerified']}, status=${farmerData['verificationStatus']}, paid=${farmerData['verificationPaid']}',
      );

      map['status'] = 'active'; // ✅ EXPLICIT: Override any enum value
      map['active'] = true; // ✅ EXPLICIT: Override any missing value
      // Verification fields are now handled by cache, not stored in posts

      map['created_at'] = FieldValue.serverTimestamp();
      map['verified'] = false; // Add verified field - default to false

      // DEBUG: Log what we're saving
      debugPrint(
        '🔧 POST CREATE: status="${map['status']}", active=${map['active']}',
      );

      await effectiveRef.set(map);
      return effectiveRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<Post?> getPost({
    required String postId,
    String collection = 'posts',
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(postId).get();
      if (!doc.exists) return null;
      return Post.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching post: $e');
      return null;
    }
  }

  Stream<List<Post>> getPostsStream({
    String? authorId,
    String? groupId,
    int? limit,
    String collection = 'posts',
  }) {
    Query query = _firestore
        .collection(collection)
        .where('active', isEqualTo: true)
        .orderBy('created_at', descending: true);

    if (authorId != null) {
      query = query.where('authorId', isEqualTo: authorId);
    }
    if (groupId != null) {
      query = query.where('group_id', isEqualTo: groupId);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
    );
  }

  Future<void> updateFarmerPosts({
    required String authorId,
    String? updatedName,
    String? updatedProfilePic,
  }) async {
    try {
      final posts = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: authorId)
          .get();

      final batch = _firestore.batch();
      for (final doc in posts.docs) {
        batch.update(doc.reference, {
          if (updatedName != null) 'authorName': updatedName,
          if (updatedProfilePic != null) 'authorAvatar': updatedProfilePic,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating farmer posts: $e');
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String authorId,
    String collection = 'posts',
  }) async {
    final ref = _firestore.collection(collection).doc(postId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final likes = List<String>.from(data['likes'] ?? const []);
      final currentLikesCount = data['likesCount'] ?? 0;

      int newLikesCount;
      if (likes.contains(authorId)) {
        likes.remove(authorId);
        newLikesCount = currentLikesCount - 1;
      } else {
        likes.add(authorId);
        newLikesCount = currentLikesCount + 1;
      }

      // Update both the likes array and the flat count
      tx.update(ref, {'likes': likes, 'likesCount': newLikesCount});
    });
  }

  Future<void> addReaction({
    required String postId,
    required String authorId,
    required String emoji,
    String collection = 'posts',
  }) async {
    final ref = _firestore.collection(collection).doc(postId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactions = Map<String, String>.from(data['reactions'] ?? {});
      final oldReaction = reactions[authorId];

      if (oldReaction == emoji) {
        // Remove reaction if same emoji
        reactions.remove(authorId);
      } else {
        // Add/update reaction
        reactions[authorId] = emoji;
      }

      // Update reactions map
      tx.update(ref, {'reactions': reactions});
    });
  }

  Future<void> deletePost({
    required String postId,
    String collection = 'posts',
  }) async {
    try {
      await _firestore.collection(collection).doc(postId).delete();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> incrementView({
    required String postId,
    String collection = 'posts',
  }) async {
    try {
      await _firestore.collection(collection).doc(postId).update({
        'analytics.viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view: $e');
    }
  }

  // -----------------------------
  // Comments & Replies
  // -----------------------------

  Future<void> addComment({
    required String postId,
    required Comment comment,
    String collection = 'posts',
  }) async {
    final farmerDoc = await _firestore
        .collection('farmers')
        .doc(comment.authorId)
        .get();
    final farmerData = farmerDoc.data() ?? {};

    // Use CommentService which includes moderation
    await CommentService().addComment(
      postId: postId,
      authorId: comment.authorId,
      authorName: farmerData['user_name'] ?? 'Farmer',
      authorProfilePic: farmerData['profile_pic'] ?? '',
      content: comment.content,
    );

    // Update comment count on post using FieldValue.increment
    final postRef = _firestore.collection(collection).doc(postId);
    await postRef.update({'commentsCount': FieldValue.increment(1)});
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    String collection = 'posts',
  }) async {
    final postRef = _firestore.collection(collection).doc(postId);

    await _firestore.runTransaction((tx) async {
      // Delete the comment
      await postRef.collection('comments').doc(commentId).delete();

      // Update comment count on post using FieldValue.increment
      tx.update(postRef, {'commentsCount': FieldValue.increment(-1)});
    });
  }

  Future<void> addReply({
    required String postId,
    required String commentId,
    required Comment reply,
    String collection = 'posts',
  }) async {
    final farmerDoc = await _firestore
        .collection('farmers')
        .doc(reply.authorId)
        .get();
    final farmerData = farmerDoc.data() ?? {};

    final commentRef = _firestore
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await commentRef.collection('replies').add({
      'authorId': reply.authorId,
      'authorName': farmerData['user_name'] ?? 'Farmer',
      'authorAvatar': farmerData['profile_pic'] ?? '',
      'text': reply.content,
      'timestamp': Timestamp.now(),
      'likes': <String>[],
      'likes_count': 0,
    });

    await commentRef.update({'replies_count': FieldValue.increment(1)});
  }

  Future<void> deleteReply({
    required String postId,
    required String commentId,
    required String replyId,
    String collection = 'posts',
  }) async {
    final replyRef = _firestore
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId);

    await replyRef.delete();

    final commentRef = _firestore
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    await commentRef.update({'replies_count': FieldValue.increment(-1)});
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String authorId,
    String collection = 'posts',
  }) async {
    final commentRef = _firestore
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(commentRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final likes = List<String>.from(data['likes'] ?? const []);

      if (likes.contains(authorId)) {
        likes.remove(authorId);
      } else {
        likes.add(authorId);
      }

      tx.update(commentRef, {'likes': likes, 'likes_count': likes.length});
    });
  }

  Future<void> toggleReplyLike({
    required String postId,
    required String commentId,
    required String replyId,
    required String authorId,
    String collection = 'posts',
  }) async {
    final replyRef = _firestore
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(replyRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final likes = List<String>.from(data['likes'] ?? const []);

      if (likes.contains(authorId)) {
        likes.remove(authorId);
      } else {
        likes.add(authorId);
      }

      tx.update(replyRef, {'likes': likes, 'likes_count': likes.length});
    });
  }
}
