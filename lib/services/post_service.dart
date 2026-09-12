import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:agribased/models/post_model.dart';
import 'moderation_service.dart';

class PostService {
  static PostService? _instance;
  static PostService get instance => _instance ??= PostService._();
  PostService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // -----------------------------------------------------------
  // CREATE POST
  // -----------------------------------------------------------
  Future<Post> createPost({
    required String content,
    List<PostMedia> media = const [],
    List<String> hashtags = const [],
    String? location,
    String? feeling,
    bool isPublic = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 🔎 Resolve farmer identity from Firestore
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(user.uid)
          .get();
      if (!farmerDoc.exists) {
        throw Exception("Farmer profile missing for UID ${user.uid}");
      }
      final farmerData = farmerDoc.data() ?? {};
      final userName = farmerData['user_name'] ?? 'Farmer';
      final userProfile = farmerData['profile_pic'] ?? '';

      final postRef = _firestore.collection('posts').doc();

      // 🔍 SMART MODERATION: Schedule background moderation after posting
      debugPrint('🔄 Scheduling background moderation...');
      final List<String> mediaUrls = media.map((m) => m.url).toList();
      final post = Post(
        id: postRef.id,
        authorId: user.uid,
        authorName: userName, // ✅ from Firestore
        authorAvatar: userProfile, // ✅ from Firestore
        content: content,
        contentType: media.isEmpty ? 'text' : media.first.type,
        media: media,
        likes: [],
        hashtags: hashtags,
        status: PostStatus.active,
        analytics: PostAnalytics(),
        createdAt: DateTime.now(), // local field for model
        groupVisibility: isPublic ? 'public' : 'private',
        feelingTag: feeling,
        locationTag: location,
      );

      final map = post.toFirestoreMap();
      map['created_at'] = FieldValue.serverTimestamp(); // ✅ Firestore timestamp
      map['is_visible'] = true; // ✅ Posts are visible by default
      map['is_under_review'] = false; // ✅ Not under review initially

      await postRef.set(map);

      unawaited(_runBackgroundModeration(
        postId: postRef.id,
        content: content,
        userId: user.uid,
        userName: userName,
        authorProfilePic: userProfile,
        mediaUrls: mediaUrls.isNotEmpty ? mediaUrls : null,
      ));

      return post;
    } catch (e) {
      debugPrint("Error creating post: $e");
      rethrow;
    }
  }

  Future<void> _runBackgroundModeration({
    required String postId,
    required String content,
    required String userId,
    required String userName,
    required String authorProfilePic,
    List<String>? mediaUrls,
  }) async {
    try {
      debugPrint('🔍 Running background AI moderation for post $postId');

      final moderationPassed = await ModerationService.checkContent(
        text: content,
        postId: postId,
        userId: userId,
      );

      if (!moderationPassed) {
        debugPrint('🚫 Background moderation flagged post $postId');
        await _firestore.collection('posts').doc(postId).update({
          'communityHidden': true,
          'moderationStatus': 'violation_detected',
          'moderatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('✅ Background moderation passed for post $postId');
      }
    } catch (e) {
      debugPrint('❌ Background moderation error for post $postId: $e');
    }
  }

  // -----------------------------------------------------------
  // UPLOAD MEDIA TO FIREBASE
  // -----------------------------------------------------------
  Future<PostMedia> uploadPostMedia(
    Uint8List fileBytes,
    String fileName,
    String type,
  ) async {
    try {
      final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child('post_media').child(path);
      
      await ref.putData(fileBytes);
      final downloadUrl = await ref.getDownloadURL();

      return PostMedia(url: downloadUrl, type: type);
    } catch (e) {
      debugPrint("Error uploading media: $e");
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // DELETE MEDIA
  // -----------------------------------------------------------
  Future<void> deleteMedia(String path) async {
    try {
      final ref = _storage.ref().child('post_media').child(path);
      await ref.delete();
    } catch (e) {
      debugPrint("Error deleting media: $e");
    }
  }

  // -----------------------------------------------------------
  // GET SINGLE POST
  // -----------------------------------------------------------
  Future<Post?> getPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromFirestore(doc);
  }

  // -----------------------------------------------------------
  // STREAM POSTS
  // -----------------------------------------------------------
  Stream<List<Post>> getPostsStream({String? userId, int limit = 20}) {
    Query query = _firestore
        .collection('posts')
        .where('is_visible', isEqualTo: true) // ✅ Only show approved posts
        .orderBy('created_at', descending: true) // ✅ fixed field name
        .limit(limit);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Get posts for authenticated user only (including under review)
  Stream<List<Post>> getUserPostsStream({required String userId, int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }
}
