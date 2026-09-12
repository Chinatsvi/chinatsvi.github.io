import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/follow_model.dart';
import '../models/user_profile.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class FollowService {
  static FollowService? _instance;
  static FollowService get instance => _instance ??= FollowService._();

  FollowService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  // Using AuthService directly since it has static methods
  final NotificationService _notification = NotificationService.instance;

  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null || currentUserId == targetUserId) return;

      final batch = _firestore.batch();

      final followRef = _firestore
          .collection('followers')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      final followingRef = _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!currentUserDoc.exists || !targetUserDoc.exists) return;

      final currentUser = UserProfile.fromJson({
        ...?currentUserDoc.data(),
        'id': currentUserDoc.id,
      });
      final targetUser = UserProfile.fromJson({
        ...?targetUserDoc.data(),
        'id': targetUserDoc.id,
      });

      final follow = Follow(
        id: followRef.id,
        followerId: currentUserId,
        followerName: currentUser.userName,
        followerProfilePic: currentUser.profilePic,
        followingId: targetUserId,
        followingName: targetUser.userName,
        followingProfilePic: targetUser.profilePic,
        createdAt: DateTime.now(),
      );

      batch.set(followRef, follow.toMap());

      final following = Follow(
        id: followingRef.id,
        followerId: currentUserId,
        followerName: currentUser.userName,
        followerProfilePic: currentUser.profilePic,
        followingId: targetUserId,
        followingName: targetUser.userName,
        followingProfilePic: targetUser.profilePic,
        createdAt: DateTime.now(),
      );

      batch.set(followingRef, following.toMap());

      await batch.commit();

      await _updateFollowCounts(currentUserId, targetUserId, true);

      await _notification.sendNewFollowerNotification(
        currentUserId,
        targetUserId,
      );

      debugPrint('Successfully followed user: $targetUserId');
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null || currentUserId == targetUserId) return;

      final batch = _firestore.batch();

      final followRef = _firestore
          .collection('followers')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      final followingRef = _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      batch.delete(followRef);
      batch.delete(followingRef);

      await batch.commit();

      await _updateFollowCounts(currentUserId, targetUserId, false);

      debugPrint('Successfully unfollowed user: $targetUserId');
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null || currentUserId == targetUserId) return false;

      final doc = await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  Future<List<UserProfile>> getFollowers(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('followers')
          .doc(userId)
          .collection('followers')
          .limit(limit)
          .get();

      final followerIds = snapshot.docs.map((doc) => doc.id).toList();

      if (followerIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followerIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getFollowing(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('following')
          .doc(userId)
          .collection('following')
          .limit(limit)
          .get();

      final followingIds = snapshot.docs.map((doc) => doc.id).toList();

      if (followingIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  Stream<List<UserProfile>> getFollowersStream(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('followers')
        .doc(userId)
        .collection('followers')
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          final followerIds = snapshot.docs.map((doc) => doc.id).toList();

          if (followerIds.isEmpty) return [];

          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: followerIds)
              .get();

          return usersSnapshot.docs
              .map((doc) => UserProfile.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<UserProfile>> getFollowingStream(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('following')
        .doc(userId)
        .collection('following')
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          final followingIds = snapshot.docs.map((doc) => doc.id).toList();

          if (followingIds.isEmpty) return [];

          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: followingIds)
              .get();

          return usersSnapshot.docs
              .map((doc) => UserProfile.fromJson(doc.data()))
              .toList();
        });
  }

  Future<int> getFollowersCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('followers')
          .doc(userId)
          .collection('followers')
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('following')
          .doc(userId)
          .collection('following')
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  Stream<int> getFollowersCountStream(String userId) {
    return _firestore
        .collection('followers')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> getFollowingCountStream(String userId) {
    return _firestore
        .collection('following')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> sendFollowRequest(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null || currentUserId == targetUserId) return;

      final requestRef = _firestore
          .collection('follow_requests')
          .doc(targetUserId)
          .collection('requests')
          .doc(currentUserId);

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!currentUserDoc.exists || !targetUserDoc.exists) return;

      final currentUser = UserProfile.fromJson({
        ...?currentUserDoc.data(),
        'id': currentUserDoc.id,
      });
      final targetUser = UserProfile.fromJson({
        ...?targetUserDoc.data(),
        'id': targetUserDoc.id,
      });

      final followRequest = FollowRequest(
        id: requestRef.id,
        requesterId: currentUserId,
        requesterName: currentUser.userName,
        requesterProfilePic: currentUser.profilePic,
        targetId: targetUserId,
        targetName: targetUser.userName,
        targetProfilePic: targetUser.profilePic,
        message: '',
        status: FollowRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await requestRef.set(followRequest.toMap());

      debugPrint('Follow request sent to: $targetUserId');
    } catch (e) {
      debugPrint('Error sending follow request: $e');
      rethrow;
    }
  }

  Future<void> acceptFollowRequest(String requesterId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final requestRef = _firestore
          .collection('follow_requests')
          .doc(currentUserId)
          .collection('requests')
          .doc(requesterId);

      await _firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) return;

        transaction.update(requestRef, {
          'status': FollowRequestStatus.accepted.name,
          'respondedAt': DateTime.now().toIso8601String(),
        });

        await followUser(requesterId);
      });

      debugPrint('Follow request accepted from: $requesterId');
    } catch (e) {
      debugPrint('Error accepting follow request: $e');
      rethrow;
    }
  }

  Future<void> rejectFollowRequest(String requesterId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      await _firestore
          .collection('follow_requests')
          .doc(currentUserId)
          .collection('requests')
          .doc(requesterId)
          .update({
            'status': FollowRequestStatus.rejected.name,
            'respondedAt': DateTime.now().toIso8601String(),
          });

      debugPrint('Follow request rejected from: $requesterId');
    } catch (e) {
      debugPrint('Error rejecting follow request: $e');
      rethrow;
    }
  }

  Future<List<FollowRequest>> getPendingFollowRequests() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final snapshot = await _firestore
          .collection('follow_requests')
          .doc(currentUserId)
          .collection('requests')
          .where('status', isEqualTo: FollowRequestStatus.pending.name)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FollowRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending follow requests: $e');
      return [];
    }
  }

  Stream<List<FollowRequest>> getPendingFollowRequestsStream() {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('follow_requests')
        .doc(currentUserId)
        .collection('requests')
        .where('status', isEqualTo: FollowRequestStatus.pending.name)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FollowRequest.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> removeFollower(String followerId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final batch = _firestore.batch();

      final followerRef = _firestore
          .collection('followers')
          .doc(currentUserId)
          .collection('followers')
          .doc(followerId);

      final followingRef = _firestore
          .collection('following')
          .doc(followerId)
          .collection('following')
          .doc(currentUserId);

      batch.delete(followerRef);
      batch.delete(followingRef);

      await batch.commit();

      await _updateFollowCounts(followerId, currentUserId, false);

      debugPrint('Successfully removed follower: $followerId');
    } catch (e) {
      debugPrint('Error removing follower: $e');
      rethrow;
    }
  }

  Future<List<String>> getMutualFollowers(String userId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      final userFollowing = await _firestore
          .collection('following')
          .doc(userId)
          .collection('following')
          .get();

      final currentUserFollowing = await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .get();

      final userFollowingIds = userFollowing.docs.map((doc) => doc.id).toSet();
      final currentUserFollowingIds = currentUserFollowing.docs
          .map((doc) => doc.id)
          .toSet();

      return userFollowingIds.intersection(currentUserFollowingIds).toList();
    } catch (e) {
      debugPrint('Error getting mutual followers: $e');
      return [];
    }
  }

  Future<void> _updateFollowCounts(
    String followerId,
    String followingId,
    bool isFollowing,
  ) async {
    try {
      final batch = _firestore.batch();
      final followerRef = _firestore.collection('users').doc(followerId);
      final followingRef = _firestore.collection('users').doc(followingId);

      if (isFollowing) {
        batch.update(followerRef, {
          'followingCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.update(followingRef, {
          'followerCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(followerRef, {
          'followingCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.update(followingRef, {
          'followerCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating follow counts: $e');
      rethrow;
    }
  }

  Future<bool> hasPendingFollowRequest(String targetUserId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return false;

      final doc = await _firestore
          .collection('follow_requests')
          .doc(targetUserId)
          .collection('requests')
          .doc(currentUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow request: $e');
      return false;
    }
  }
}
