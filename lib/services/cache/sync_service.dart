import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'profile_cache_service.dart';
import 'post_cache_service.dart';
import 'connectivity_service.dart';
import 'feed_cache_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  SyncService._internal() {
    _listenToConnectivity();
  }

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  void _listenToConnectivity() {
    _connectivitySubscription = ConnectivityService().connectivityStream.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        debugPrint('🔄 [SYNC] Device back online - starting sync...');
        _syncAllData();
      }
    });
  }

  Future<void> _syncAllData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncUserProfile();
      await _syncPosts();
      debugPrint('✅ [SYNC] All data synced successfully');
    } catch (e) {
      debugPrint('❌ [SYNC] Error syncing data: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        await ProfileCacheService.cacheProfile(user.uid, doc.data()!);
        debugPrint('✅ [SYNC] Profile synced for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ [SYNC] Error syncing profile: $e');
    }
  }

  Future<void> _syncPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Sync personalized feed for the current user (server-populated users/{uid}/feed)
      final feedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feed')
          .orderBy('score', descending: true)
          .limit(50)
          .get();

      final feedItems = <Map<String, dynamic>>[];
      final postIdsToFetch = <String>[];

      for (final doc in feedSnap.docs) {
        final data = doc.data();
        feedItems.add({
          'postId': data['postId'] ?? doc.id,
          'score': data['score'] ?? 0,
          'createdAt': data['createdAt'],
        });
        postIdsToFetch.add(data['postId'] ?? doc.id);
      }

      // Cache the feed list locally for instant startup display
      await FeedCacheService.cacheFeedList(
        feedItems,
        accountKey: user.uid,
      );

      // Fetch post documents for any missing posts in local cache
      final posts = <String, Map<String, dynamic>>{};
      for (final pid in postIdsToFetch) {
        if (!PostCacheService.isPostCached(pid, accountKey: user.uid)) {
          try {
            final doc = await FirebaseFirestore.instance.collection('posts').doc(pid).get();
            if (doc.exists) posts[doc.id] = doc.data()!;
          } catch (e) {
            debugPrint('⚠️ [SYNC] Failed to fetch post $pid: $e');
          }
        }
      }

      if (posts.isNotEmpty) {
        await PostCacheService.cachePosts(posts, accountKey: user.uid);
      }

      debugPrint('✅ [SYNC] Feed synced: ${feedItems.length} items, posts fetched: ${posts.length}');
    } catch (e) {
      debugPrint('❌ [SYNC] Error syncing posts: $e');
    }
  }

  Future<void> forceSync() async {
    debugPrint('🔄 [SYNC] Force sync requested...');
    await _syncAllData();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
