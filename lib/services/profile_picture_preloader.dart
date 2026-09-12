import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// Service for preloading and caching profile pictures
/// Ensures profile pictures appear instantly without late loading
class ProfilePicturePreloader {
  static final ProfilePicturePreloader _instance = ProfilePicturePreloader._internal();
  factory ProfilePicturePreloader() => _instance;
  ProfilePicturePreloader._internal();

  // Hive box for persistent caching
  Box? _profileCacheBox;
  Box? _imageDataBox;
  bool _isInitialized = false;
  
  // Memory cache for quick access
  final Map<String, ProfileCacheEntry> _memoryCache = {};
  
  // Stream controller for profile updates
  final StreamController<String> _profileUpdateController = StreamController.broadcast();
  Stream<String> get profileUpdates => _profileUpdateController.stream;

  // Preload queue
  final List<String> _preloadQueue = [];
  bool _isPreloading = false;
  
  // Cache configuration
  static const Duration _cacheTTL = Duration(hours: 24);
  static const int _maxCacheSize = 200; // Max profiles to cache
  static const int _maxPreloadBatch = 10; // Batch size for preloading

  /// Initialize the preloader
  Future<void> init() async {
    if (_isInitialized) return;

    _profileCacheBox = Hive.isBoxOpen('profile_picture_meta')
        ? Hive.box('profile_picture_meta')
        : await Hive.openBox('profile_picture_meta');
    _imageDataBox = Hive.isBoxOpen('profile_picture_data')
        ? Hive.box('profile_picture_data')
        : await Hive.openBox('profile_picture_data');
    _isInitialized = true;

    developer.log(
      '✅ ProfilePicturePreloader initialized',
      name: 'ProfilePicturePreloader',
    );
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await init();
  }

  /// Preload profile pictures for a list of user IDs
  /// Call this when loading posts to preload all author profile pictures
  Future<void> preloadProfilePictures(List<String> userIds) async {
    if (userIds.isEmpty) return;

    await _ensureInitialized();

    // Filter out already cached profiles
    final uncachedIds = userIds.where((id) {
      if (_memoryCache.containsKey(id)) {
        final entry = _memoryCache[id]!;
        return DateTime.now().difference(entry.timestamp) > _cacheTTL;
      }
      // Check Hive cache
      final cached = _profileCacheBox?.get(id);
      if (cached == null) return true;
      
      final timestamp = DateTime.tryParse(cached['timestamp'] ?? '');
      if (timestamp == null) return true;
      
      return DateTime.now().difference(timestamp) > _cacheTTL;
    }).toList();

    if (uncachedIds.isEmpty) {
      developer.log(
        '👤 All ${userIds.length} profile pictures already cached',
        name: 'ProfilePicturePreloader',
      );
      return;
    }

    // Add to preload queue
    _preloadQueue.addAll(uncachedIds);
    
    developer.log(
      '⏳ Queueing ${uncachedIds.length} profile pictures for preload',
      name: 'ProfilePicturePreloader',
    );

    // Start preloading if not already running
    if (!_isPreloading) {
      _processPreloadQueue();
    }
  }

  /// Process the preload queue in batches
  Future<void> _processPreloadQueue() async {
    if (_preloadQueue.isEmpty) {
      _isPreloading = false;
      return;
    }

    _isPreloading = true;

    // Take batch from queue
    final batchSize = _preloadQueue.length > _maxPreloadBatch 
        ? _maxPreloadBatch 
        : _preloadQueue.length;
    final batch = _preloadQueue.sublist(0, batchSize);
    _preloadQueue.removeRange(0, batchSize);

    try {
      // Fetch all users in parallel from Firestore
      final futures = batch.map((userId) => _fetchUserData(userId));
      final results = await Future.wait(futures, eagerError: false);

      int successCount = 0;
      for (int i = 0; i < batch.length; i++) {
        final userId = batch[i];
        final data = results[i];
        
        if (data != null && data['profile_pic'] != null) {
          await _cacheProfilePicture(userId, data);
          successCount++;
        }
      }

      developer.log(
        '✅ Preloaded $successCount/${batch.length} profile pictures',
        name: 'ProfilePicturePreloader',
      );
    } catch (e) {
      developer.log(
        '❌ Error preloading batch: $e',
        name: 'ProfilePicturePreloader',
      );
    }

    // Process next batch
    if (_preloadQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _processPreloadQueue();
    } else {
      _isPreloading = false;
    }
  }

  /// Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      // The farmers document is the canonical profile for this app. Posts,
      // comments, and cached users must not override its avatar.
      var doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (doc.exists) {
        return {
          'user_name': doc.data()?['user_name'] ?? doc.data()?['name'] ?? 'Farmer',
          'profile_pic': doc.data()?['profile_pic'] ?? doc.data()?['photoURL'],
          'is_verified': doc.data()?['is_verified'] ?? false,
        };
      }

      // Keep legacy users documents as a fallback for accounts that have not
      // migrated to a farmers profile yet.
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return {
          'user_name': doc.data()?['user_name'] ?? doc.data()?['name'] ?? 'Farmer',
          'profile_pic': doc.data()?['profile_pic'] ?? doc.data()?['photoURL'],
          'is_verified': doc.data()?['is_verified'] ?? false,
        };
      }

      return null;
    } catch (e) {
      developer.log(
        '❌ Error fetching user $userId: $e',
        name: 'ProfilePicturePreloader',
      );
      return null;
    }
  }

  /// Cache a profile picture
  Future<void> _cacheProfilePicture(String userId, Map<String, dynamic> data) async {
    await _ensureInitialized();

    final profileUrl = data['profile_pic'] as String?;
    if (profileUrl == null || profileUrl.isEmpty) return;

    final entry = ProfileCacheEntry(
      userId: userId,
      userName: data['user_name'] ?? 'User',
      // Keep one canonical URL everywhere. Transforming this URL here made
      // posts/reels use a different URL from profile/search screens.
      profileUrl: profileUrl,
      originalUrl: profileUrl,
      isVerified: data['is_verified'] ?? false,
      timestamp: DateTime.now(),
    );

    // Store in memory cache
    _memoryCache[userId] = entry;

    // Store in Hive for persistence
    await _profileCacheBox!.put(userId, {
      'user_name': entry.userName,
      'profile_url': entry.profileUrl,
      'original_url': entry.originalUrl,
      'is_verified': entry.isVerified,
      'timestamp': entry.timestamp.toIso8601String(),
    });

    // Notify listeners
    _profileUpdateController.add(userId);

    // Preload image into CachedNetworkImage cache
    _preloadImageIntoCache(profileUrl);

    // Clean up old entries if cache is too large
    _cleanupOldEntries();
  }

  /// Preload image into CachedNetworkImage's cache
  void _preloadImageIntoCache(String imageUrl) {
    if (imageUrl.isEmpty) return;
    
    // The image will be automatically cached by CachedNetworkImage
    // when it's first displayed, but we can warm up the HTTP cache here
    try {
      precacheImage(
        CachedNetworkImageProvider(imageUrl),
        navigatorKey.currentContext!,
      );
    } catch (e) {
      // Context might not be available, that's ok
    }
  }

  /// Get cached profile data for a user
  ProfileCacheEntry? getCachedProfile(String userId) {
    // Check memory cache first
    if (_memoryCache.containsKey(userId)) {
      final entry = _memoryCache[userId]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheTTL) {
        return entry;
      }
    }

    // Check Hive cache
    final cached = _profileCacheBox?.get(userId);
    if (cached != null) {
      final timestamp = DateTime.tryParse(cached['timestamp'] ?? '');
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheTTL) {
        final entry = ProfileCacheEntry(
          userId: userId,
          userName: cached['user_name'] ?? 'User',
          profileUrl: cached['profile_url'] ?? '',
          originalUrl: cached['original_url'] ?? '',
          isVerified: cached['is_verified'] ?? false,
          timestamp: timestamp,
        );
        // Restore to memory cache
        _memoryCache[userId] = entry;
        return entry;
      }
    }

    return null;
  }

  /// Get profile picture URL for a user (cached or returns default)
  String? getProfilePictureUrl(String userId) {
    final cached = getCachedProfile(userId);
    return cached?.profileUrl;
  }

  /// Get user name for a user (cached or returns default)
  String getUserName(String userId, {String defaultName = 'User'}) {
    final cached = getCachedProfile(userId);
    return cached?.userName ?? defaultName;
  }

  /// Check if user is verified
  bool isUserVerified(String userId) {
    final cached = getCachedProfile(userId);
    return cached?.isVerified ?? false;
  }

  /// Force refresh a profile picture
  Future<void> refreshProfilePicture(String userId) async {
    await _ensureInitialized();

    _memoryCache.remove(userId);
    await _profileCacheBox!.delete(userId);
    
    final data = await _fetchUserData(userId);
    if (data != null) {
      await _cacheProfilePicture(userId, data);
    }
  }

  /// Preload critical assets at app startup
  /// Call this in main.dart before app starts
  Future<void> preloadCriticalAssets() async {
    developer.log(
      '🚀 Preloading critical assets at startup',
      name: 'ProfilePicturePreloader',
    );

    // Preload default avatar
    // Preload verification badge
    // These could be bundled assets rather than network images
  }

  /// Cleanup old cache entries when exceeding max size
  void _cleanupOldEntries() {
    if (_memoryCache.length <= _maxCacheSize) return;

    // Sort by timestamp and remove oldest
    final entries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final toRemove = entries.length - _maxCacheSize;
    for (int i = 0; i < toRemove && i < entries.length; i++) {
      _memoryCache.remove(entries[i].key);
    }

    developer.log(
      '🧹 Cleaned up $toRemove old cache entries',
      name: 'ProfilePicturePreloader',
    );
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await _ensureInitialized();

    _memoryCache.clear();
    await _profileCacheBox!.clear();
    await _imageDataBox!.clear();
    
    developer.log(
      '🗑️ All profile picture caches cleared',
      name: 'ProfilePicturePreloader',
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'hive_cache_size': _profileCacheBox?.length ?? 0,
      'preload_queue_size': _preloadQueue.length,
      'is_preloading': _isPreloading,
    };
  }

  /// Dispose resources
  void dispose() {
    _profileUpdateController.close();
  }
}

/// Global navigator key for precaching images
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Cache entry for a profile
class ProfileCacheEntry {
  final String userId;
  final String userName;
  final String profileUrl;
  final String originalUrl;
  final bool isVerified;
  final DateTime timestamp;

  ProfileCacheEntry({
    required this.userId,
    required this.userName,
    required this.profileUrl,
    required this.originalUrl,
    required this.isVerified,
    required this.timestamp,
  });
}

/// Widget that displays a cached profile picture
/// Uses preloaded data for instant display
class CachedProfilePicture extends StatelessWidget {
  final String userId;
  final String? url;
  final double size;
  final VoidCallback? onTap;

  const CachedProfilePicture({
    super.key,
    required this.userId,
    this.url,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preloader = ProfilePicturePreloader();
    
    // Try to get cached URL
    String? imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      final cached = preloader.getCachedProfile(userId);
      imageUrl = cached?.profileUrl;
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImageProvider(imageUrl)
            : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.person, color: Colors.grey.shade600, size: size * 0.5)
            : null,
      ),
    );
  }
}
