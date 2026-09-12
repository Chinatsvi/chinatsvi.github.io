import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/follow_model.dart';
import '../models/farm_type.dart';
import 'firebase_service.dart';
import 'follow_service.dart';
import 'storage_router_service.dart';
import 'user_name_update_service.dart';
import 'user_purge_service.dart';
import 'smart_moderation_service.dart';

class ProfileService {
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();

  ProfileService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseStorage _storage = FirebaseService.instance.storage;
  // Using AuthService directly since it has static methods
  final FollowService _follow = FollowService.instance;

  // -----------------------------------------------------------
  // UPDATE PROFILE
  // -----------------------------------------------------------
  Future<void> updateProfile({
    required String userId,
    String? userName,
    String? bio,
    String? location,
    String? work,
    String? education,
    FarmType? farmType,
    List<String>? crops,
    String? profilePicUrl,
    String? coverPhotoUrl,
    String? website,
    String? phoneNumber,
    bool? isPrivate,
    bool? showEmail,
    bool? showPhone,
  }) async {
    try {
      // Get current profile data to check if name or avatar changed
      final currentDoc = await _firestore
          .collection('farmers')
          .doc(userId)
          .get();
      final currentData = currentDoc.data() ?? {};
      final currentName = currentData['user_name'] ?? '';
      final currentAvatar = currentData['profile_pic'] ?? '';

      final updates = <String, dynamic>{};

      if (userName != null) updates['user_name'] = userName;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (work != null) updates['work'] = work;
      if (education != null) updates['education'] = education;
      if (farmType != null) updates['farmType'] = farmType.name;
      if (crops != null) updates['crops'] = crops;
      if (profilePicUrl != null) updates['profile_pic'] = profilePicUrl;
      if (coverPhotoUrl != null) updates['cover_photo'] = coverPhotoUrl;
      if (website != null) updates['website'] = website;
      if (phoneNumber != null) updates['phone'] = phoneNumber;
      if (isPrivate != null) updates['isPrivate'] = isPrivate;
      if (showEmail != null) updates['showEmail'] = showEmail;
      if (showPhone != null) updates['showPhone'] = showPhone;

      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('farmers').doc(userId).update(updates);

      debugPrint('Profile updated for farmer: $userId');

      // Check if name or avatar changed and update across all posts/comments
      final nameChanged = userName != null && currentName != userName;
      final avatarChanged =
          profilePicUrl != null && currentAvatar != profilePicUrl;

      if (kDebugMode) {
        print('🔄 ProfileService Update Debug:');
        print('  - Current Name: $currentName');
        print('  - New Name: $userName');
        print('  - Name Changed: $nameChanged');
        print('  - Current Avatar: $currentAvatar');
        print('  - New Avatar: $profilePicUrl');
        print('  - Avatar Changed: $avatarChanged');
        print('  - User ID: $userId');
      }

      if (nameChanged || avatarChanged) {
        try {
          if (kDebugMode) {
            print('🚀 ProfileService: Starting background update service...');
          }
          // Run in background without blocking UI
          UserNameUpdateService.instance.updateUserNameAcrossAllPosts(
            userId,
            userName ?? currentName,
            newAvatar: avatarChanged ? profilePicUrl : null,
          );

          if (kDebugMode) {
            print(
              '✅ ProfileService: Background update service started successfully',
            );
          }
        } catch (e) {
          // Don't fail the profile update if name update fails
          if (kDebugMode) {
            print('❌ ProfileService: Failed to update name across posts: $e');
          }
          debugPrint('Warning: Failed to update name across posts: $e');
        }
      } else {
        if (kDebugMode) {
          print(
            'ℹ️ ProfileService: No name/avatar changes detected, skipping background update',
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // GET PROFILE
  // -----------------------------------------------------------
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('farmers').doc(userId).get();
      if (!doc.exists) return null;

      return UserProfile.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore.collection('farmers').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return UserProfile.fromJson({...snapshot.data()!, 'id': snapshot.id});
    });
  }

  // -----------------------------------------------------------
  // PROFILE PICTURES & COVER PHOTOS
  // -----------------------------------------------------------
  Future<String> uploadProfilePicture(String userId, File filePath) async {
    try {
      final downloadUrl = await StorageRouterService.instance
          .uploadProfilePicture(file: filePath, userId: userId);

      await _firestore.collection('farmers').doc(userId).update({
        'profile_pic': downloadUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _moderateProfileMedia(userId, downloadUrl, isProfile: true);

      debugPrint('Profile picture uploaded for farmer: $userId');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  Future<String> uploadCoverPhoto(String userId, File filePath) async {
    try {
      final downloadUrl = await StorageRouterService.instance.uploadCoverPhoto(
        file: filePath,
        userId: userId,
      );

      await _firestore.collection('farmers').doc(userId).update({
        'cover_photo': downloadUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _moderateProfileMedia(userId, downloadUrl, isProfile: false);

      debugPrint('Cover photo uploaded for farmer: $userId');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      rethrow;
    }
  }

  void _moderateProfileMedia(String userId, String imageUrl, {required bool isProfile}) {
    Future.microtask(() async {
      try {
        final doc = await _firestore.collection('farmers').doc(userId).get();
        final userName = (doc.data()?['user_name'] ?? 'Farmer').toString();
        await SmartModerationService.moderateContent(
          content: isProfile ? 'Profile picture upload' : 'Cover photo upload',
          postId: '${userId}_${isProfile ? "profile_pic" : "cover_photo"}',
          userId: userId,
          userName: userName,
          contentType: isProfile ? 'profile_picture' : 'cover_photo',
          imageUrl: imageUrl,
        );
      } catch (e) {
        debugPrint('Error in background profile media moderation: $e');
      }
    });
  }

  Future<void> deleteProfilePicture(String userId) async {
    try {
      final userDoc = await _firestore.collection('farmers').doc(userId).get();
      if (!userDoc.exists) return;

      final profilePicUrl = userDoc.data()?['profile_pic'] as String?;
      if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(profilePicUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting profile picture from storage: $e');
        }
      }

      await _firestore.collection('farmers').doc(userId).update({
        'profile_pic': '',
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Profile picture deleted for farmer: $userId');
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      rethrow;
    }
  }

  Future<void> deleteCoverPhoto(String userId) async {
    try {
      final userDoc = await _firestore.collection('farmers').doc(userId).get();
      if (!userDoc.exists) return;

      final coverPhotoUrl = userDoc.data()?['cover_photo'] as String?;
      if (coverPhotoUrl != null && coverPhotoUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(coverPhotoUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting cover photo from storage: $e');
        }
      }

      await _firestore.collection('farmers').doc(userId).update({
        'cover_photo': '',
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Cover photo deleted for farmer: $userId');
    } catch (e) {
      debugPrint('Error deleting cover photo: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // SEARCH & FILTER FARMERS
  // -----------------------------------------------------------
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('farmers')
          .where('user_name', isGreaterThanOrEqualTo: query)
          .where('user_name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error searching farmers: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getFarmersByLocation(
    String location, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .where('location', isEqualTo: location)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting farmers by location: $e');
      return [];
    }
  }

  Future<List<UserProfile>> getFarmersByFarmType(
    FarmType farmType, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .where('farmType', isEqualTo: farmType.name)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting farmers by farm type: $e');
      return [];
    }
  }

  // -----------------------------------------------------------
  // FOLLOW REQUESTS & MUTUALS
  // -----------------------------------------------------------
  Future<List<FollowRequest>> getPendingFollowRequests() async {
    return await _follow.getPendingFollowRequests();
  }

  Stream<List<FollowRequest>> getPendingFollowRequestsStream() {
    return _follow.getPendingFollowRequestsStream();
  }

  Future<void> removeFollower(String followerId) async {
    await _follow.removeFollower(followerId);
  }

  Future<void> unfollowUser(String targetUserId) async {
    await _follow.unfollowUser(targetUserId);
  }

  Future<List<UserProfile>> getMutualFollowers(String userId) async {
    final mutualIds = await _follow.getMutualFollowers(userId);
    if (mutualIds.isEmpty) return [];

    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: mutualIds)
        .get();

    return usersSnapshot.docs
        .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<bool> hasPendingFollowRequest(String targetUserId) async {
    return await _follow.hasPendingFollowRequest(targetUserId);
  }

  // -----------------------------------------------------------
  // PRIVACY SETTINGS
  // -----------------------------------------------------------
  Future<void> updatePrivacySettings({
    required String userId,
    bool? isPrivate,
    bool? showEmail,
    bool? showPhone,
    bool? allowFollowRequests,
    bool? allowDirectMessages,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isPrivate != null) updates['isPrivate'] = isPrivate;
      if (showEmail != null) updates['showEmail'] = showEmail;
      if (showPhone != null) updates['showPhone'] = showPhone;
      if (allowFollowRequests != null) {
        updates['allowFollowRequests'] = allowFollowRequests;
      }
      if (allowDirectMessages != null) {
        updates['allowDirectMessages'] = allowDirectMessages;
      }

      updates['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('farmers').doc(userId).update(updates);

      debugPrint('Privacy settings updated for farmer: $userId');
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // NOTIFICATION SETTINGS
  // -----------------------------------------------------------
  Future<void> updateNotificationSettings({
    required String userId,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? newFollowerNotifications,
    bool? newCommentNotifications,
    bool? newPostNotifications,
    bool? messageNotifications,
  }) async {
    try {
      final updates = <String, dynamic>{
        'notificationSettings': {
          'emailNotifications': ?emailNotifications,
          'pushNotifications': ?pushNotifications,
          'newFollowerNotifications': ?newFollowerNotifications,
          'newCommentNotifications': ?newCommentNotifications,
          'newPostNotifications': ?newPostNotifications,
          'messageNotifications': ?messageNotifications,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('farmers').doc(userId).update(updates);

      debugPrint('Notification settings updated for farmer: $userId');
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // BLOCKING
  // -----------------------------------------------------------
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .set({
            'blockedUserId': blockedUserId,
            'blockedAt': FieldValue.serverTimestamp(),
          });

      await unfollowUser(blockedUserId);

      debugPrint('User blocked: $blockedUserId');
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('blocked_users')
          .doc(blockedUserId)
          .delete();

      debugPrint('User unblocked: $blockedUserId');
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  Future<List<UserProfile>> getBlockedUsers(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('blocked_users')
          .limit(limit)
          .get();

      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      if (blockedUserIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('farmers')
          .where(FieldPath.documentId, whereIn: blockedUserIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  Future<bool> isBlocked(String userId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // -----------------------------------------------------------
  // REPORTING
  // -----------------------------------------------------------
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final reportRef = _firestore.collection('user_reports').doc();

      await reportRef.set({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('User reported: $reportedUserId');
    } catch (e) {
      debugPrint('Error reporting user: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------
  // ACCOUNT STATUS
  // -----------------------------------------------------------
  Future<void> deactivateAccount(String userId) async {
    try {
      await _firestore.collection('farmers').doc(userId).update({
        'isDeactivated': true,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Account deactivated: $userId');
    } catch (e) {
      debugPrint('Error deactivating account: $e');
      rethrow;
    }
  }

  Future<void> reactivateAccount(String userId) async {
    try {
      await _firestore.collection('farmers').doc(userId).update({
        'isDeactivated': false,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Account reactivated: $userId');
    } catch (e) {
      debugPrint('Error reactivating account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(String userId) async {
    try {
      await UserPurgeService().purgeUserData(userId);
      debugPrint('Account deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}
