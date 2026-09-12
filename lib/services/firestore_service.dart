import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/user_profile.dart';
import 'package:agribased/models/post_model.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/follow_state_manager.dart';

class FirestoreService {
  // Singleton
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FollowStateManager _stateManager = FollowStateManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// ----------------------
  /// USERS / FARMERS
  /// ----------------------
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('farmers').doc(userId).get();
      if (!doc.exists) throw Exception('User not found');
      return UserProfile.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      developer.log('Error getting user profile: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore
        .collection('farmers')
        .doc(userId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserProfile.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
              : null,
        );
  }

  /// ----------------------
  /// FOLLOW SYSTEM
  /// ----------------------
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await _firestore.collection('farmers').doc(currentUserId).get();
    if (!doc.exists) return false;
    final following = List<String>.from(doc.data()?['following'] ?? []);
    return following.contains(targetUserId);
  }

  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final currentUserRef = _firestore.collection('farmers').doc(currentUserId);
    final targetUserRef = _firestore.collection('farmers').doc(targetUserId);

    final currentUserDoc = await currentUserRef.get();
    final following = List<String>.from(
      currentUserDoc.data()?['following'] ?? [],
    );

    if (following.contains(targetUserId)) {
      // Unfollow - update both user document arrays AND subcollections
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      // Also remove from subcollections
      await currentUserRef.collection('following').doc(targetUserId).delete();
      await targetUserRef.collection('followers').doc(currentUserId).delete();

      // Update FollowStateManager cache
      _stateManager.updateFollowState(currentUserId, targetUserId, false);
    } else {
      // Follow - update both user document arrays AND subcollections
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      // Also add to subcollections
      await currentUserRef.collection('following').doc(targetUserId).set({
        'followedAt': FieldValue.serverTimestamp(),
      });
      await targetUserRef.collection('followers').doc(currentUserId).set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Update FollowStateManager cache
      _stateManager.updateFollowState(currentUserId, targetUserId, true);
    }
  }

  /// ----------------------
  /// POSTS
  /// ----------------------
  Future<void> createPost(Post post) async {
    final farmerDoc = await _firestore
        .collection('farmers')
        .doc(post.authorId)
        .get();
    if (!farmerDoc.exists) {
      throw Exception("Farmer profile missing for UID ${post.authorId}");
    }
    final farmerData = farmerDoc
        .data()!; // Safe to use ! since we checked exists

    final docRef = _firestore.collection('posts').doc(post.id);
    final postWithId = post.copyWith(id: docRef.id);

    final map = postWithId.toFirestoreMap();
    map['authorName'] = farmerData['user_name'] ?? 'Farmer';
    map['authorAvatar'] = farmerData['profile_pic'] ?? '';
    map['createdAt'] = FieldValue.serverTimestamp(); // ✅ unified field

    await docRef.set(map);
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final likes = List<String>.from(snap.data()?['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      final analytics = PostAnalytics.fromJson(
        Map<String, dynamic>.from(snap.data()?['analytics'] ?? {}),
      );
      final updatedAnalytics = analytics.copyWith(reactionsCount: likes.length);

      tx.update(ref, {'likes': likes, 'analytics': updatedAnalytics.toJson()});
    });
  }

  Future<void> incrementView(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'analytics.viewsCount': FieldValue.increment(1),
    });
  }

  Stream<List<Post>> streamPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true) // ✅ unified field
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  /// ----------------------
  /// MARKETPLACE
  /// ----------------------
  Future<void> createMarketplaceItem(MarketplaceItem item) async {
    await _firestore.collection('Marketplace').doc(item.id).set({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(), // ✅ unified field
    });
  }

  Future<void> updateMarketplaceItem(MarketplaceItem item) async {
    await _firestore
        .collection('Marketplace')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteMarketplaceItem(String itemId) async {
    await _firestore.collection('Marketplace').doc(itemId).delete();
  }

  Stream<List<MarketplaceItem>> streamMarketplaceItems({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('Marketplace') // ✅ capital M
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true) // ✅ unified field
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    return query.snapshots().asyncMap((snap) async {
      final items = snap.docs
          .map(
            (doc) => MarketplaceItem.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Filter out items from deactivated farmers
      final List<MarketplaceItem> activeItems = [];

      for (final item in items) {
        try {
          final farmerDoc = await _firestore
              .collection('farmers')
              .doc(item.sellerId)
              .get();
          if (farmerDoc.exists) {
            final farmerData = farmerDoc.data() as Map<String, dynamic>;
            final isDeactivated = farmerData['isDeactivated'] ?? false;

            // Only include item if farmer is not deactivated
            if (!isDeactivated) {
              activeItems.add(item);
            }
          }
        } catch (e) {
          // If farmer doc doesn't exist or error occurs, exclude the item
          developer.log(
            'Error checking farmer status for item ${item.id}: $e',
            name: 'FirestoreService',
          );
        }
      }

      return activeItems;
    });
  }

  Stream<List<MarketplaceItem>> streamMarketplaceItemsByUser(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('Marketplace') // ✅ capital M
        .where('sellerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true) // ✅ unified field
        .limit(limit)
        .snapshots()
        .asyncMap((snap) async {
          final items = snap.docs
              .map(
                (doc) => MarketplaceItem.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList();

          // Filter out items from deactivated farmers
          final List<MarketplaceItem> activeItems = [];

          for (final item in items) {
            try {
              final farmerDoc = await _firestore
                  .collection('farmers')
                  .doc(item.sellerId)
                  .get();
              if (farmerDoc.exists) {
                final farmerData = farmerDoc.data() as Map<String, dynamic>;
                final isDeactivated = farmerData['isDeactivated'] ?? false;

                // Only include item if farmer is not deactivated
                if (!isDeactivated) {
                  activeItems.add(item);
                }
              }
            } catch (e) {
              // If farmer doc doesn't exist or error occurs, exclude the item
              developer.log(
                'Error checking farmer status for item ${item.id}: $e',
                name: 'FirestoreService',
              );
            }
          }

          return activeItems;
        });
  }
}
