import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../controllers/post_controller.dart';

class OptimizedUserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePic;
  final DateTime? updatedAt;

  // Verification fields
  final bool isVerified;
  final String verificationStatus;
  final bool verificationPaid;
  final DateTime? verificationPaidAt;

  const OptimizedUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePic,
    this.updatedAt,
    this.isVerified = false,
    this.verificationStatus = 'none',
    this.verificationPaid = false,
    this.verificationPaidAt,
  });

  factory OptimizedUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return OptimizedUserModel(
      uid: doc.id,
      name: data?['name'] ?? data?['user_name'] ?? '',
      email: data?['email'] ?? '',
      profilePic: data?['profile_pic'],
      updatedAt: data?['updated_at']?.toDate(),
      isVerified: data?['isVerified'] ?? false,
      verificationStatus: data?['verificationStatus'] ?? 'none',
      verificationPaid: data?['verificationPaid'] ?? false,
      verificationPaidAt: data?['verificationPaidAt']?.toDate(),
    );
  }

  /// Helper: should show verification tick (same logic as FarmerModel)
  bool get showTick {
    return isVerified &&
        verificationStatus == "approved" &&
        verificationPaid &&
        !isPaymentExpired;
  }

  /// Helper: check if payment expired
  bool get isPaymentExpired {
    if (verificationPaidAt == null) return true;
    final now = DateTime.now();
    return now.difference(verificationPaidAt!).inDays >=
        30; // Back to 30 days as requested
  }
}

class OptimizedUserCache {
  static final Map<String, OptimizedUserModel> _cache = {};
  static final Map<String, Stream<OptimizedUserModel>> _streams = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(minutes: 5); // 5 minutes TTL for performance
  static const Duration _staleDataThreshold = Duration(minutes: 1); // Refresh if data is older than 1 minute

  /// Get user from cache first, then stream updates
  static OptimizedUserModel? getCachedUser(String uid) {
    final cached = _cache[uid];
    final timestamp = _cacheTimestamps[uid];
    
    // Return null if cache expired
    if (cached == null || timestamp == null) {
      return null;
    }
    
    // Check if cache is still valid
    if (DateTime.now().difference(timestamp) > _cacheTTL) {
      // Cache expired, remove it
      _cache.remove(uid);
      _cacheTimestamps.remove(uid);
      return null;
    }
    
    return cached;
  }
  
  /// Check if cached data is stale (should be refreshed)
  static bool isCacheStale(String uid) {
    final timestamp = _cacheTimestamps[uid];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > _staleDataThreshold;
  }

  /// Update cache instantly with timestamp
  static void updateCache(String uid, OptimizedUserModel user) {
    _cache[uid] = user;
    _cacheTimestamps[uid] = DateTime.now();
    debugPrint('⚡ Cache updated: $uid → ${user.name}');
  }

  /// Get stream with cached data (NO FLICKER)
  static Stream<OptimizedUserModel> userStreamWithCache(String uid) {
    // Guard against empty uid
    if (uid.trim().isEmpty) {
      return Stream.value(OptimizedUserModel(
        uid: uid,
        name: 'Unknown',
        email: '',
      ));
    }

    // Return existing stream if already created
    if (_streams.containsKey(uid)) {
      return _streams[uid]!;
    }

    // Create new stream with cached data
    final stream = FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final user = OptimizedUserModel.fromFirestore(doc);
            updateCache(uid, user);
            return user;
          }
          // Return cached user if doc doesn't exist (offline scenario)
          return _cache[uid] ?? OptimizedUserModel(
            uid: uid,
            name: 'Unknown',
            email: '',
          );
        });

    _streams[uid] = stream;
    return stream;
  }

  /// Get user once with cache fallback
  static Future<OptimizedUserModel?> getUserOnce(String uid) async {
    // Guard against empty uid
    if (uid.trim().isEmpty) {
      return null;
    }

    // Check cache first (even if stale, return it for instant display)
    final cached = getCachedUser(uid);
    if (cached != null) {
      debugPrint('🗂️ Using cached user: $uid');
      
      // If cache is stale, trigger background refresh
      if (isCacheStale(uid)) {
        _refreshUserInBackground(uid);
      }
      
      return cached;
    }

    // Fetch from Firestore
    try {
      debugPrint('📥 Fetching user: $uid');
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();

      if (doc.exists) {
        final user = OptimizedUserModel.fromFirestore(doc);
        updateCache(uid, user);
        return user;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user: $e');
    }

    return null;
  }
  
  /// Refresh user data in background without blocking UI
  static void _refreshUserInBackground(String uid) {
    // Guard against empty uid
    if (uid.trim().isEmpty) {
      return;
    }

    Future.microtask(() async {
      try {
        debugPrint('🔄 Background refresh for user: $uid');
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .get();
        
        if (doc.exists) {
          final user = OptimizedUserModel.fromFirestore(doc);
          updateCache(uid, user);
          debugPrint('✅ Background refresh complete for: $uid');
        }
      } catch (e) {
        debugPrint('⚠️ Background refresh failed for $uid: $e');
      }
    });
  }

  /// Preload users for better performance
  static Future<void> preloadUsers(List<String> uids) async {
    debugPrint('🚀 Preloading ${uids.length} users...');

    // Filter out users that are already cached and not stale
    final uidsToLoad = uids.where((uid) => 
      getCachedUser(uid) == null || isCacheStale(uid)
    ).toList();
    
    if (uidsToLoad.isEmpty) {
      debugPrint('✅ All users already cached and fresh');
      return;
    }

    debugPrint('📥 Loading ${uidsToLoad.length} users from Firestore...');
    final futures = uidsToLoad.map((uid) => getUserOnce(uid)).toList();
    await Future.wait(futures);

    debugPrint('✅ Preloaded ${_cache.length} users');
  }

  /// Clear cache (for testing)
  static void clearCache() {
    _cache.clear();
    _streams.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ Cache cleared');
  }

  /// Clear specific user cache
  static Future<void> clearUserCache(String uid) async {
    _cache.remove(uid);
    _cacheTimestamps.remove(uid);

    // Remove stream for this user
    _streams.remove(uid);

    debugPrint('🗑️ User cache cleared for: $uid');
  }
}

class OptimizedUserService {
  /// Update user profile (name + avatar)
  static Future<void> updateProfile({
    required String uid,
    required String name,
    String? profilePic,
  }) async {
    try {
      debugPrint('🔄 Updating profile: $uid → "$name"');

      final updateData = <String, dynamic>{
        'user_name': name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (profilePic != null && profilePic.isNotEmpty) {
        updateData['profile_pic'] = profilePic;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .update(updateData);

      // 🚀 Smart Cache Update - Update cache immediately for instant UI refresh
      final cachedUser = OptimizedUserCache._cache[uid];
      if (cachedUser != null) {
        final updatedUser = OptimizedUserModel(
          uid: cachedUser.uid,
          name: name,
          email: cachedUser.email,
          profilePic: profilePic ?? cachedUser.profilePic,
          updatedAt: DateTime.now(),
        );
        OptimizedUserCache.updateCache(uid, updatedUser);
      }

      // Update posts authored by this farmer so widgets that render
      // `post['authorAvatar']` directly will reflect the new picture.
      try {
        final postController = PostController();
        await postController.updateFarmerPosts(
          authorId: uid,
          updatedName: name,
          updatedProfilePic: profilePic,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to update farmer posts after profile change: $e');
      }

      debugPrint('✅ Profile updated successfully!');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Get user stream (optimized)
  static Stream<OptimizedUserModel> userStream(String uid) {
    return OptimizedUserCache.userStreamWithCache(uid);
  }

  /// Get user once (optimized)
  static Future<OptimizedUserModel?> getUser(String uid) {
    return OptimizedUserCache.getUserOnce(uid);
  }

  /// Clear specific user cache
  static Future<void> clearUserCache(String uid) async {
    await OptimizedUserCache.clearUserCache(uid);
  }
}
