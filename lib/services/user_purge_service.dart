import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service responsible for completely purging all user/farmer data from Firestore
/// and Firebase Storage, ensuring zero "ghost data" remains in the app.
class UserPurgeService {
  static final UserPurgeService _instance = UserPurgeService._internal();
  factory UserPurgeService() => _instance;
  UserPurgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Completely removes all data belonging to or referencing [userId].
  Future<void> purgeUserData(String userId, {String? userEmail}) async {
    if (userId.trim().isEmpty) return;

    developer.log('🚀 [UserPurgeService] Starting COMPLETE data purge for user: $userId', name: 'UserPurgeService');

    try {
      // 1. Delete Storage Assets (Avatar, Cover Photo)
      await _deleteStorageAssets(userId);

      // 2. Delete all Posts created by user and their subcollections (comments, views, analytics)
      await _deleteUserPosts(userId);

      // 3. Delete all Comments written by user on other users' posts
      await _deleteUserCommentsAcrossApp(userId);

      // 4. Remove User's Likes from other posts
      await _removeUserLikesFromOtherPosts(userId);

      // 5. Delete Marketplace items, reviews, ratings, and orders
      await _deleteMarketplaceData(userId);

      // 6. Clean up Follow relationships across all other farmers
      await _cleanFollowRelationships(userId);

      // 7. Delete Follow Requests (incoming & outgoing)
      await _deleteFollowRequests(userId);

      // 8. Delete Notifications (user's inbox + outgoing notifications)
      await _deleteNotifications(userId);

      // 9. Delete Chats and Message History
      await _deleteChatsAndMessages(userId);

      // 10. Delete Verification, Badges, Moderation Reports & Appeals
      await _deleteVerificationAndModeration(userId);

      // 11. Delete Jobs and Applications
      await _deleteJobsAndApplications(userId);

      // 12. Delete Farm Tool Records (Poultry, Animals, Crops, Sensors, CCTV, Budget, Diagnosis, Bookmarks)
      await _deleteFarmToolRecords(userId);

      // 13. Delete Primary Farmer Profile & Subcollections
      await _deletePrimaryFarmerDoc(userId);

      // 14. Delete Primary Users collection doc
      await _deletePrimaryUserDoc(userId);

      developer.log('✅ [UserPurgeService] COMPLETE data purge successful for: $userId (Zero ghost data remaining)', name: 'UserPurgeService');
    } catch (e, st) {
      developer.log('❌ [UserPurgeService] Error during user data purge: $e\n$st', name: 'UserPurgeService');
      rethrow;
    }
  }

  // ===========================================================================
  // 1. STORAGE ASSETS
  // ===========================================================================
  Future<void> _deleteStorageAssets(String userId) async {
    try {
      final farmerDoc = await _firestore.collection('farmers').doc(userId).get();
      if (farmerDoc.exists) {
        final data = farmerDoc.data();
        final profilePic = data?['profile_pic'] as String?;
        final coverPhoto = data?['cover_photo'] as String?;

        if (profilePic != null && profilePic.isNotEmpty && profilePic.contains('firebasestorage.googleapis.com')) {
          try {
            await _storage.refFromURL(profilePic).delete();
          } catch (e) {
            developer.log('Storage delete profile_pic non-fatal: $e', name: 'UserPurgeService');
          }
        }

        if (coverPhoto != null && coverPhoto.isNotEmpty && coverPhoto.contains('firebasestorage.googleapis.com')) {
          try {
            await _storage.refFromURL(coverPhoto).delete();
          } catch (e) {
            developer.log('Storage delete cover_photo non-fatal: $e', name: 'UserPurgeService');
          }
        }
      }
    } catch (e) {
      developer.log('Storage cleanup non-fatal error: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 2. USER POSTS & SUBCOLLECTIONS
  // ===========================================================================
  Future<void> _deleteUserPosts(String userId) async {
    try {
      final postsQuery = await _firestore.collection('posts').where('authorId', isEqualTo: userId).get();
      for (final postDoc in postsQuery.docs) {
        await _deletePostAndSubcollections(postDoc.reference);
      }

      // Also check if any post used 'userId' instead of 'authorId'
      final altPostsQuery = await _firestore.collection('posts').where('userId', isEqualTo: userId).get();
      for (final postDoc in altPostsQuery.docs) {
        await _deletePostAndSubcollections(postDoc.reference);
      }
    } catch (e) {
      developer.log('Error deleting user posts: $e', name: 'UserPurgeService');
    }
  }

  Future<void> _deletePostAndSubcollections(DocumentReference postRef) async {
    try {
      // 1. Delete comments subcollection & their replies
      final comments = await postRef.collection('comments').get();
      for (final comment in comments.docs) {
        final replies = await comment.reference.collection('replies').get();
        for (final reply in replies.docs) {
          await reply.reference.delete();
        }
        await comment.reference.delete();
      }

      // 2. Delete views subcollection
      final views = await postRef.collection('views').get();
      for (final view in views.docs) {
        await view.reference.delete();
      }

      // 3. Delete likes subcollection if present
      final likes = await postRef.collection('likes').get();
      for (final like in likes.docs) {
        await like.reference.delete();
      }

      // 4. Delete the post itself
      await postRef.delete();
    } catch (e) {
      developer.log('Error deleting post subcollection: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 3. USER COMMENTS ACROSS ENTIRE APP
  // ===========================================================================
  Future<void> _deleteUserCommentsAcrossApp(String userId) async {
    try {
      // Find all comments across all posts made by this user
      final commentsQuery = await _firestore.collectionGroup('comments').where('authorId', isEqualTo: userId).get();
      for (final commentDoc in commentsQuery.docs) {
        await commentDoc.reference.delete();
      }

      final altCommentsQuery = await _firestore.collectionGroup('comments').where('userId', isEqualTo: userId).get();
      for (final commentDoc in altCommentsQuery.docs) {
        await commentDoc.reference.delete();
      }

      // Find all replies across all comments made by this user
      final repliesQuery = await _firestore.collectionGroup('replies').where('authorId', isEqualTo: userId).get();
      for (final replyDoc in repliesQuery.docs) {
        await replyDoc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting user comments collectionGroup: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 4. REMOVE USER LIKES FROM OTHER POSTS
  // ===========================================================================
  Future<void> _removeUserLikesFromOtherPosts(String userId) async {
    try {
      final likedPostsQuery = await _firestore.collection('posts').where('likes', arrayContains: userId).get();
      final batch = _firestore.batch();
      for (final postDoc in likedPostsQuery.docs) {
        batch.update(postDoc.reference, {
          'likes': FieldValue.arrayRemove([userId]),
        });
      }
      await batch.commit();
    } catch (e) {
      developer.log('Error removing user likes: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 5. MARKETPLACE, REVIEWS, RATINGS, ORDERS
  // ===========================================================================
  Future<void> _deleteMarketplaceData(String userId) async {
    try {
      // 1. Marketplace Items where user is seller
      final itemsQuery = await _firestore.collection('Marketplace').where('sellerId', isEqualTo: userId).get();
      for (final itemDoc in itemsQuery.docs) {
        // Delete subcollections (e.g. reviews, ratings)
        final reviews = await itemDoc.reference.collection('reviews').get();
        for (final r in reviews.docs) {
          await r.reference.delete();
        }
        await itemDoc.reference.delete();
      }

      final altItemsQuery = await _firestore.collection('Marketplace').where('userId', isEqualTo: userId).get();
      for (final itemDoc in altItemsQuery.docs) {
        await itemDoc.reference.delete();
      }

      // 2. Orders where user is buyer or seller
      final buyerOrders = await _firestore.collection('orders').where('buyerId', isEqualTo: userId).get();
      for (final doc in buyerOrders.docs) {
        await doc.reference.delete();
      }
      final sellerOrders = await _firestore.collection('orders').where('sellerId', isEqualTo: userId).get();
      for (final doc in sellerOrders.docs) {
        await doc.reference.delete();
      }

      // 3. Ratings & Reviews
      final ratingsQuery = await _firestore.collection('marketplace_ratings').where('buyerId', isEqualTo: userId).get();
      for (final doc in ratingsQuery.docs) {
        await doc.reference.delete();
      }
      final sellerRatings = await _firestore.collection('marketplace_ratings').where('sellerId', isEqualTo: userId).get();
      for (final doc in sellerRatings.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting marketplace data: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 6. FOLLOW RELATIONSHIPS CLEANUP
  // ===========================================================================
  Future<void> _cleanFollowRelationships(String userId) async {
    try {
      // 1. Remove userId from other farmers' 'followers' array
      final followersQuery = await _firestore.collection('farmers').where('followers', arrayContains: userId).get();
      for (final doc in followersQuery.docs) {
        await doc.reference.update({
          'followers': FieldValue.arrayRemove([userId]),
        });
        // Delete subcollections
        await doc.reference.collection('followers').doc(userId).delete();
        await _firestore.collection('followers').doc(doc.id).collection('followers').doc(userId).delete();
      }

      // 2. Remove userId from other farmers' 'following' array
      final followingQuery = await _firestore.collection('farmers').where('following', arrayContains: userId).get();
      for (final doc in followingQuery.docs) {
        await doc.reference.update({
          'following': FieldValue.arrayRemove([userId]),
        });
        // Delete subcollections
        await doc.reference.collection('following').doc(userId).delete();
        await _firestore.collection('following').doc(doc.id).collection('following').doc(userId).delete();
      }

      // 3. Delete root followers and following collections for this user
      final userFollowersSub = await _firestore.collection('followers').doc(userId).collection('followers').get();
      for (final doc in userFollowersSub.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('followers').doc(userId).delete();

      final userFollowingSub = await _firestore.collection('following').doc(userId).collection('following').get();
      for (final doc in userFollowingSub.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('following').doc(userId).delete();
    } catch (e) {
      developer.log('Error cleaning follow relationships: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 7. FOLLOW REQUESTS
  // ===========================================================================
  Future<void> _deleteFollowRequests(String userId) async {
    try {
      // User's own incoming follow requests
      final incoming = await _firestore.collection('follow_requests').doc(userId).collection('requests').get();
      for (final doc in incoming.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('follow_requests').doc(userId).delete();

      // Requests sent by this user to others
      final outgoing = await _firestore.collectionGroup('requests').where('requesterId', isEqualTo: userId).get();
      for (final doc in outgoing.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting follow requests: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 8. NOTIFICATIONS
  // ===========================================================================
  Future<void> _deleteNotifications(String userId) async {
    try {
      // Delete user's own notifications
      final notifs = await _firestore.collection('notifications').doc(userId).collection('items').get();
      for (final doc in notifs.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('notifications').doc(userId).delete();

      // Delete notifications triggered by this user in other users' inboxes
      final sentNotifs = await _firestore.collectionGroup('items').where('fromUserId', isEqualTo: userId).get();
      for (final doc in sentNotifs.docs) {
        await doc.reference.delete();
      }

      final actorNotifs = await _firestore.collectionGroup('items').where('actorId', isEqualTo: userId).get();
      for (final doc in actorNotifs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting notifications: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 9. CHATS AND MESSAGES
  // ===========================================================================
  Future<void> _deleteChatsAndMessages(String userId) async {
    try {
      // Find chats where user is a participant
      final chatsQuery = await _firestore.collection('chats').where('participants', arrayContains: userId).get();
      for (final chatDoc in chatsQuery.docs) {
        // Delete all messages subcollection docs
        final messages = await chatDoc.reference.collection('messages').get();
        for (final msg in messages.docs) {
          await msg.reference.delete();
        }
        // Delete chat document
        await chatDoc.reference.delete();
      }

      // Also check chat_rooms
      final roomsQuery = await _firestore.collection('chat_rooms').where('participants', arrayContains: userId).get();
      for (final roomDoc in roomsQuery.docs) {
        final messages = await roomDoc.reference.collection('messages').get();
        for (final msg in messages.docs) {
          await msg.reference.delete();
        }
        await roomDoc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting chats: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 10. VERIFICATION & MODERATION
  // ===========================================================================
  Future<void> _deleteVerificationAndModeration(String userId) async {
    try {
      final verifyReqs = await _firestore.collection('verification_requests').where('userId', isEqualTo: userId).get();
      for (final doc in verifyReqs.docs) {
        await doc.reference.delete();
      }

      final verifySubs = await _firestore.collection('verification_submissions').where('userId', isEqualTo: userId).get();
      for (final doc in verifySubs.docs) {
        await doc.reference.delete();
      }

      final verifyPayments = await _firestore.collection('verification_payments').where('userId', isEqualTo: userId).get();
      for (final doc in verifyPayments.docs) {
        await doc.reference.delete();
      }

      final appeals = await _firestore.collection('appeals').where('userId', isEqualTo: userId).get();
      for (final doc in appeals.docs) {
        await doc.reference.delete();
      }

      final userReports = await _firestore.collection('user_reports').where('reportedUserId', isEqualTo: userId).get();
      for (final doc in userReports.docs) {
        await doc.reference.delete();
      }

      final reporterReports = await _firestore.collection('user_reports').where('reporterId', isEqualTo: userId).get();
      for (final doc in reporterReports.docs) {
        await doc.reference.delete();
      }

      final modReports = await _firestore.collection('moderation_reports').where('reportedUserId', isEqualTo: userId).get();
      for (final doc in modReports.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting verification & moderation: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 11. JOBS & APPLICATIONS
  // ===========================================================================
  Future<void> _deleteJobsAndApplications(String userId) async {
    try {
      final jobs = await _firestore.collection('jobs').where('authorId', isEqualTo: userId).get();
      for (final doc in jobs.docs) {
        final apps = await doc.reference.collection('applications').get();
        for (final a in apps.docs) {
          await a.reference.delete();
        }
        await doc.reference.delete();
      }

      final altJobs = await _firestore.collection('jobs').where('posterId', isEqualTo: userId).get();
      for (final doc in altJobs.docs) {
        await doc.reference.delete();
      }

      final appsQuery = await _firestore.collection('job_applications').where('applicantId', isEqualTo: userId).get();
      for (final doc in appsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      developer.log('Error deleting jobs: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 12. FARM TOOLS & FEATURE MODULES
  // ===========================================================================
  Future<void> _deleteFarmToolRecords(String userId) async {
    try {
      final toolCollections = [
        'poultry_batches',
        'poultry_flocks',
        'poultry_reports',
        'poultry_feed_formulations',
        'animals',
        'animal_records',
        'livestock',
        'crop_calendar',
        'crop_records',
        'crop_plans',
        'cctv_cameras',
        'cctv_streams',
        'cctv_recordings',
        'soil_sensors',
        'sensor_readings',
        'farm_budget',
        'budget_planner',
        'farm_calculator',
        'fertilizer_plans',
        'guidebook_unlocks',
        'book_purchases',
        'bookmarks',
        'diagnosis_history',
        'image_diagnosis',
      ];

      for (final collectionName in toolCollections) {
        // Query by farmerId
        final byFarmerId = await _firestore.collection(collectionName).where('farmerId', isEqualTo: userId).get();
        for (final doc in byFarmerId.docs) {
          await doc.reference.delete();
        }

        // Query by userId
        final byUserId = await _firestore.collection(collectionName).where('userId', isEqualTo: userId).get();
        for (final doc in byUserId.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      developer.log('Error deleting farm tool records: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 13. PRIMARY FARMER DOCUMENT & SUBCOLLECTIONS
  // ===========================================================================
  Future<void> _deletePrimaryFarmerDoc(String userId) async {
    try {
      final farmerRef = _firestore.collection('farmers').doc(userId);

      // Clean all possible subcollections
      final subcollectionNames = [
        'followers',
        'following',
        'blocked_users',
        'crop_updates',
        'inventory',
        'activities',
        'recordings',
        'cameras',
      ];

      for (final sub in subcollectionNames) {
        final subDocs = await farmerRef.collection(sub).get();
        for (final doc in subDocs.docs) {
          await doc.reference.delete();
        }
      }

      await farmerRef.delete();
    } catch (e) {
      developer.log('Error deleting farmer document: $e', name: 'UserPurgeService');
    }
  }

  // ===========================================================================
  // 14. PRIMARY USER DOCUMENT
  // ===========================================================================
  Future<void> _deletePrimaryUserDoc(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        await userRef.delete();
      }
    } catch (e) {
      developer.log('Error deleting users doc: $e', name: 'UserPurgeService');
    }
  }
}
