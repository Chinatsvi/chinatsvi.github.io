import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/profile_picture_preloader.dart';
import '../services/cloudinary_optimizer.dart';
import '../models/post_model.dart';

/// Service for preloading critical assets at app startup
/// Ensures offline-first behavior and instant loading of key UI elements
class AssetPreloader {
  static final AssetPreloader _instance = AssetPreloader._internal();
  factory AssetPreloader() => _instance;
  AssetPreloader._internal();

  // Progress tracking
  final StreamController<double> _progressController = StreamController.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Preload status
  bool _isPreloading = false;
  bool get isPreloading => _isPreloading;

  // Critical assets cache
  late Box _criticalAssetsBox;
  
  // Cached bundle assets
  final Map<String, AssetImage> _bundleAssetCache = {};

  /// Initialize the preloader
  Future<void> init() async {
    _criticalAssetsBox = await Hive.openBox('critical_assets_cache');
    developer.log(
      '✅ AssetPreloader initialized',
      name: 'AssetPreloader',
    );
  }

  /// Preload all critical assets at app startup
  /// Call this before running the app
  Future<void> preloadCriticalAssets() async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      developer.log(
        '🚀 Starting critical asset preloading...',
        name: 'AssetPreloader',
      );

      final steps = 5;
      var currentStep = 0;

      // Step 1: Preload bundle assets (icons, logos)
      await _preloadBundleAssets();
      currentStep++;
      _progressController.add(currentStep / steps);

      // Step 2: Initialize profile picture preloader
      await ProfilePicturePreloader().init();
      currentStep++;
      _progressController.add(currentStep / steps);

      // Step 3: Preload current user's profile
      await _preloadCurrentUserProfile();
      currentStep++;
      _progressController.add(currentStep / steps);

      // Step 4: Preload verification badge and other icons
      await _preloadVerificationAssets();
      currentStep++;
      _progressController.add(currentStep / steps);

      // Step 5: Preload feed posts for offline access
      await _preloadFeedPosts();
      currentStep++;
      _progressController.add(currentStep / steps);

      developer.log(
        '✅ Critical asset preloading complete!',
        name: 'AssetPreloader',
      );
    } catch (e) {
      developer.log(
        '❌ Error during asset preloading: $e',
        name: 'AssetPreloader',
      );
    } finally {
      _isPreloading = false;
      _progressController.add(1.0);
    }
  }

  /// Preload bundle assets (icons, logos bundled with app)
  Future<void> _preloadBundleAssets() async {
    final criticalAssets = [
      'assets/icon/verification_tick.png',
      'assets/logo/app_logo.png',
      'assets/images/default_avatar.png',
      'assets/images/default_cover.png',
    ];

    for (final asset in criticalAssets) {
      try {
        await rootBundle.load(asset);
        _bundleAssetCache[asset] = AssetImage(asset);
        developer.log(
          '📦 Preloaded bundle asset: $asset',
          name: 'AssetPreloader',
        );
      } catch (e) {
        // Asset might not exist, skip
        developer.log(
          '⚠️ Bundle asset not found: $asset',
          name: 'AssetPreloader',
        );
      }
    }
  }

  /// Preload current user's profile for instant display
  Future<void> _preloadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log(
        '👤 No current user, skipping profile preload',
        name: 'AssetPreloader',
      );
      return;
    }

    try {
      // Queue for preloading
      await ProfilePicturePreloader().preloadProfilePictures([user.uid]);
      
      // Fetch and cache user data
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        await _criticalAssetsBox.put('current_user', {
          'uid': user.uid,
          'name': data['user_name'] ?? data['name'] ?? 'User',
          'email': data['email'] ?? user.email ?? '',
          'profile_pic': data['profile_pic'] ?? data['photoURL'] ?? '',
          'cached_at': DateTime.now().toIso8601String(),
        });

        developer.log(
          '👤 Preloaded current user profile: ${user.uid}',
          name: 'AssetPreloader',
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error preloading current user: $e',
        name: 'AssetPreloader',
      );
    }
  }

  /// Preload verification badge and other critical network assets
  Future<void> _preloadVerificationAssets() async {
    // Preload Cloudinary optimized verification badge if available
    // This could be a remote URL that needs caching
    final verificationBadgeUrl = _criticalAssetsBox.get('verification_badge_url');
    
    if (verificationBadgeUrl != null) {
      try {
        final optimizedUrl = CloudinaryOptimizer.getOptimizedImageUrl(
          originalUrl: verificationBadgeUrl,
          width: 100,
          quality: 'auto:good',
        );
        
        // Preload into image cache
        await precacheImage(
          CachedNetworkImageProvider(optimizedUrl),
          navigatorKey.currentContext!,
        );
      } catch (e) {
        developer.log(
          '⚠️ Could not preload verification badge: $e',
          name: 'AssetPreloader',
        );
      }
    }
  }

  /// Preload recent feed posts for offline access
  Future<void> _preloadFeedPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      
      // Cache posts locally
      final postsData = posts.map((post) => {
        'id': post.id,
        'authorId': post.authorId,
        'authorName': post.authorName,
        'authorAvatar': post.authorAvatar,
        'content': post.content,
        'contentType': post.contentType,
        'media': post.media.map((m) => {'url': m.url, 'type': m.type}).toList(),
        'createdAt': post.createdAt.toIso8601String(),
        'likes': post.likes,
        'commentCount': post.comments.length,
      }).toList();

      await _criticalAssetsBox.put('cached_feed_posts', postsData);
      await _criticalAssetsBox.put('feed_cached_at', DateTime.now().toIso8601String());

      // Preload profile pictures for all post authors
      final authorIds = posts.map((p) => p.authorId).toSet().toList();
      await ProfilePicturePreloader().preloadProfilePictures(authorIds);

      developer.log(
        '📰 Preloaded ${posts.length} feed posts for offline access',
        name: 'AssetPreloader',
      );
    } catch (e) {
      developer.log(
        '❌ Error preloading feed posts: $e',
        name: 'AssetPreloader',
      );
    }
  }

  /// Get cached feed posts for offline display
  List<Map<String, dynamic>>? getCachedFeedPosts() {
    try {
      final cachedAt = _criticalAssetsBox.get('feed_cached_at');
      if (cachedAt == null) return null;

      final cacheTime = DateTime.tryParse(cachedAt);
      if (cacheTime == null) return null;

      // Cache valid for 1 hour
      if (DateTime.now().difference(cacheTime) > const Duration(hours: 1)) {
        return null;
      }

      return _criticalAssetsBox.get('cached_feed_posts')?.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Get cached current user data
  Map<String, dynamic>? getCachedCurrentUser() {
    try {
      return _criticalAssetsBox.get('current_user')?.cast<String, dynamic>();
    } catch (e) {
      return null;
    }
  }

  /// Get a preloaded bundle asset
  AssetImage? getBundleAsset(String assetPath) {
    return _bundleAssetCache[assetPath];
  }

  /// Clear all cached assets
  Future<void> clearAllCaches() async {
    await _criticalAssetsBox.clear();
    _bundleAssetCache.clear();
    developer.log(
      '🗑️ All critical asset caches cleared',
      name: 'AssetPreloader',
    );
  }

  /// Get preloader statistics
  Map<String, dynamic> getStats() {
    return {
      'is_preloading': _isPreloading,
      'bundle_assets_cached': _bundleAssetCache.length,
      'hive_cache_size': _criticalAssetsBox.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Global navigator key for precaching images
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Preloader widget that shows a loading screen while assets are being preloaded
class PreloaderScreen extends StatefulWidget {
  final Widget child;

  const PreloaderScreen({
    super.key,
    required this.child,
  });

  @override
  State<PreloaderScreen> createState() => _PreloaderScreenState();
}

class _PreloaderScreenState extends State<PreloaderScreen> {
  double _progress = 0.0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startPreloading();
  }

  Future<void> _startPreloading() async {
    // Listen to progress
    AssetPreloader().progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          if (progress >= 1.0) {
            _isComplete = true;
          }
        });
      }
    });

    // Start preloading
    await AssetPreloader().preloadCriticalAssets();
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/icon/verification_tick.png',
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.agriculture,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Loading text
            const Text(
              'AgriBased',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading your farming community...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            
            // Progress bar
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
