import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app/utils/formatters.dart';
import '../models/post_model.dart';
import '../models/marketplace/marketplace_item_model.dart';
import '../cache/feed_cache.dart';
import '../services/verification_cache_service.dart';
import '../services/cache/post_cache_service.dart';
import '../services/cache/feed_cache_service.dart';
import '../services/moderation_service.dart';
import '../services/profile_picture_preloader.dart';
import '../services/farmer_reputation_service.dart';
import 'post_controller.dart';
import '../services/marketplace_boost_service.dart';

/// Feed modes supported by the app
enum FeedMode { mixed, random, personalized, popularity }

DateTime? _parseBoostExpiry(Map<String, dynamic> data) {
  final rawBoostEnd =
      data['boostExpiresAt'] ??
      data['boostEndDate'] ??
      data['boost_expires_at'] ??
      data['boost_end_date'] ??
      data['expiresAt'] ??
      data['expires_at'] ??
      data['endDate'] ??
      data['end_date'] ??
      data['boostExpireDate'] ??
      data['boost_expire_date'] ??
      data['boostEnd'] ??
      data['boost_end'] ??
      data['expiryDate'] ??
      data['expiry_date'];

  return parseExpiryDateTime(rawBoostEnd);
}

DateTime? parseExpiryDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) {
    if (raw > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    return null;
  }
  if (raw is double) {
    final intVal = raw.toInt();
    if (intVal > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal);
    } else if (intVal > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
    }
    return null;
  }
  if (raw is Map) {
    final seconds = raw['_seconds'] ?? raw['seconds'];
    if (seconds is num) {
      final nanoseconds =
          raw['_nanoseconds'] ?? raw['nanoseconds'] ?? 0;
      return Timestamp(
        seconds.toInt(),
        (nanoseconds as num).toInt(),
      ).toDate();
    }
    return null;
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;

    // Pattern 1: "15 January 2025 at 12:00:00 UTC+2"
    final match1 = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\s+at\s+(\d{2}:\d{2}:\d{2})\s+UTC([+-]\d{1,2})$',
    ).firstMatch(trimmed);
    if (match1 != null) {
      final day = int.parse(match1.group(1)!);
      final month = _monthFromName(match1.group(2)!);
      final year = int.parse(match1.group(3)!);
      final timeParts =
          match1.group(4)!.split(':').map(int.parse).toList();
      final offset = int.parse(match1.group(5)!);
      if (month != null && timeParts.length == 3) {
        return DateTime.utc(
          year,
          month,
          day,
          timeParts[0],
          timeParts[1],
          timeParts[2],
        ).subtract(Duration(hours: offset));
      }
    }

    // Pattern 2: "January 15, 2025" or "January 15 2025"
    final match2 = RegExp(
      r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})$',
    ).firstMatch(trimmed);
    if (match2 != null) {
      final month = _monthFromName(match2.group(1)!);
      final day = int.parse(match2.group(2)!);
      final year = int.parse(match2.group(3)!);
      if (month != null) {
        return DateTime(year, month, day, 23, 59, 59);
      }
    }

    // Pattern 3: "15 January 2025"
    final match3 = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$',
    ).firstMatch(trimmed);
    if (match3 != null) {
      final day = int.parse(match3.group(1)!);
      final month = _monthFromName(match3.group(2)!);
      final year = int.parse(match3.group(3)!);
      if (month != null) {
        return DateTime(year, month, day, 23, 59, 59);
      }
    }
  }
  return null;
}

int? _monthFromName(String name) {
  switch (name.toLowerCase()) {
    case 'january':
    case 'jan':
      return 1;
    case 'february':
    case 'feb':
      return 2;
    case 'march':
    case 'mar':
      return 3;
    case 'april':
    case 'apr':
      return 4;
    case 'may':
      return 5;
    case 'june':
    case 'jun':
      return 6;
    case 'july':
    case 'jul':
      return 7;
    case 'august':
    case 'aug':
      return 8;
    case 'september':
    case 'sep':
    case 'sept':
      return 9;
    case 'october':
    case 'oct':
      return 10;
    case 'november':
    case 'nov':
      return 11;
    case 'december':
    case 'dec':
      return 12;
    default:
      return null;
  }
}

bool isMarketplacePost(Post post) {
  return post.id.startsWith('marketplace_') ||
      post.contentType == 'marketplace' ||
      post.hashtags.any((h) => h.toLowerCase() == 'marketplace') ||
      post.content.trim().startsWith('🛒');
}

DateTime? resolveBoostExpiry(Map<String, dynamic> data) {
  final explicit = _parseBoostExpiry(data);
  if (explicit != null) return explicit;

  final rawBoostDays =
      data['boostDays'] ?? data['days'] ?? data['durationDays'];
  final boostDays = rawBoostDays is num
      ? rawBoostDays.toInt()
      : (rawBoostDays is String ? int.tryParse(rawBoostDays) : null);

  if (boostDays != null && boostDays > 0) {
    final rawStarted = data['paidAt'] ??
        data['paymentDate'] ??
        data['payment_date'] ??
        data['activatedAt'] ??
        data['boostStartedAt'] ??
        data['boostCreatedAt'] ??
        data['startDate'] ??
        data['boostUpdatedAt'] ??
        data['updatedAt'] ??
        data['createdAt'];

    final startedAtDate = parseExpiryDateTime(rawStarted);
    if (startedAtDate != null) {
      return startedAtDate.add(Duration(days: boostDays));
    }
  }

  return null;
}

bool hasActiveBoost(Map<String, dynamic> data, {DateTime? now}) {
  final status = data['status']?.toString().toLowerCase().trim();
  if (status == 'sold' || status == 'removed') {
    return false;
  }

  final currentTime = now ?? DateTime.now();
  final rawBoosted =
      data['isBoosted'] ??
      data['is_boosted'] ??
      data['boosted'] ??
      data['boost'];
  final isBoosted =
      rawBoosted == true ||
      (rawBoosted is num && rawBoosted != 0) ||
      (rawBoosted is String &&
          {'true', '1', 'yes'}.contains(rawBoosted.toLowerCase().trim()));

  if (!isBoosted) return false;

  final boostEndDate = resolveBoostExpiry(data);
  if (boostEndDate != null) {
    return boostEndDate.isAfter(currentTime);
  }

  return false;
}

Post? convertMarketplaceItemToPostForFeedData(
  Map<String, dynamic> data, {
  required String documentId,
}) {
  try {
    final status = data['status']?.toString().toLowerCase().trim();
    if (status == 'sold' || status == 'removed') {
      return null;
    }

    final now = DateTime.now();
    if (!hasActiveBoost(data, now: now)) {
      return null;
    }

    final boostEndDate = resolveBoostExpiry(data);
    if (boostEndDate == null || !boostEndDate.isAfter(now)) {
      return null;
    }

    DateTime createdAt;
    final rawCreatedAt = data['createdAt'] ?? data['created_at'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is int) {
      createdAt = rawCreatedAt > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(rawCreatedAt)
          : DateTime.fromMillisecondsSinceEpoch(rawCreatedAt * 1000);
    } else {
      createdAt = DateTime.now();
    }

    final marketplaceItem = MarketplaceItem.fromMap(data);
    final media = marketplaceItem.images
        .map((url) => PostMedia(url: url, type: 'image'))
        .toList();

    final title = marketplaceItem.title;
    final description = marketplaceItem.description;
    final price = marketplaceItem.price;
    final category = marketplaceItem.category;
    final negotiable = marketplaceItem.negotiable;

    final resolvedCurrencySymbol =
        (data['currencySymbol'] ??
                data['currency'] ??
                data['currencyCode'] ??
                '')
            .toString()
            .trim();
    final priceLabel = Formatter.formatMarketplacePrice(
      price,
      negotiable: negotiable,
      symbol: resolvedCurrencySymbol.isNotEmpty
          ? resolvedCurrencySymbol
          : 'ZAR',
    );
    final content =
        '🛒 **$title**\n\n$description\n\n💰 Price: $priceLabel\n📂 Category: $category\n💵 Cost: $priceLabel';

    String sellerId = '';
    String sellerName = 'Unknown Seller';
    String sellerAvatar = '';

    final sellerRaw = data['seller'] ?? data['owner'];
    if (sellerRaw is Map<String, dynamic>) {
      sellerId =
          sellerRaw['id'] ??
          sellerRaw['userId'] ??
          sellerRaw['uid'] ??
          sellerRaw['sellerId'] ??
          '';
      sellerName =
          sellerRaw['name'] ??
          sellerRaw['user_name'] ??
          sellerRaw['sellerName'] ??
          sellerName;
      sellerAvatar =
          sellerRaw['avatar'] ??
          sellerRaw['profile_pic'] ??
          sellerRaw['profileImage'] ??
          sellerAvatar;
    } else {
      sellerId = data['sellerId'] ?? data['userId'] ?? data['ownerId'] ?? '';
      sellerName =
          data['sellerName'] ??
          data['user_name'] ??
          data['ownerName'] ??
          sellerName;
      sellerAvatar = data['sellerAvatar'] ?? data['profile_pic'] ?? '';
    }

    return Post(
      id: 'marketplace_$documentId',
      authorId: sellerId,
      authorName: sellerName,
      authorAvatar: sellerAvatar,
      content: content,
      contentType: 'marketplace',
      createdAt: createdAt,
      media: media,
      hashtags: ['marketplace', category.toLowerCase().replaceAll(' ', '')],
      status: PostStatus.active,
      analytics: PostAnalytics(),
      likes: [],
      reactions: const {},
      comments: [],
      locationTag: data['locationTag'],
      caption: title,
      isBoosted: true,
      boostEndDate: boostEndDate,
      active: true,
    );
  } catch (e) {
    developer.log(
      '❌ Error converting marketplace item $documentId to post: $e',
      name: 'FeedController',
    );
    return null;
  }
}

class FeedController {
  final PostController _postController;
  final VerificationCacheService _verificationCache =
      VerificationCacheService();

  Box<dynamic>? get _cacheBox {
    if (Hive.isBoxOpen('feed_cache')) {
      return Hive.box<dynamic>('feed_cache');
    }
    return null;
  }

  /// Salt used to vary the random placement of boosted posts.
  int get _feedShuffleSalt {
    final cacheBox = _cacheBox;
    if (cacheBox == null) {
      return DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    }

    try {
      final accountKey = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final saltKey = 'feed_shuffle_salt_$accountKey';
      final existing = cacheBox.get(saltKey);
      if (existing is int) return existing;
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      cacheBox.put(saltKey, seed);
      return seed;
    } catch (_) {
      return DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    }
  }

  int _stableFeedHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    return hash;
  }

  double _accountFeedJitter(String postId) {
    final accountKey = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final dayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final hash = _stableFeedHash('$accountKey:$dayKey:$postId');
    return (hash % 3500) / 100.0;
  }

  void _shuffleForAccount(List<Post> posts) {
    if (posts.length < 2) return;
    posts.shuffle(Random());
  }

  /// Feed mode settings persisted in Hive
  /// 0 = mixed (default), 1 = random, 2 = personalized, 3 = popularity
  FeedMode _feedMode = FeedMode.mixed;

  /// Feed state
  final List<Post> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isFetching = false;
  bool _loading = true;
  final int _pageSize = 10;

  /// Stream controllers
  final StreamController<List<Post>>
  _postsController = StreamController<List<Post>>.broadcast(
    onListen: () {
      // Re-emit the current cached feed when a listener attaches.
      // This prevents the UI from waiting on Firebase if cache data already exists.
      if (_instance._posts.isNotEmpty) {
        _instance._postsController.add(List.from(_instance._posts));
      }
    },
  );
  final StreamController<bool> _newPostsController =
      StreamController.broadcast();

  bool _hasLocalCache = false;
  final List<Post> _pendingNewPosts = [];

  // Singleton pattern
  static final FeedController _instance = FeedController._internal();
  factory FeedController() => _instance;
  FeedController._internal() : _postController = PostController() {
    _restoreFromHive();
    _preloadFarmers();
  }

  /// Set the feed mode and persist it
  void setFeedMode(FeedMode mode) {
    _feedMode = mode;
    try {
      final cacheBox = _cacheBox;
      cacheBox?.put('feed_mode', mode.index);
    } catch (e) {
      developer.log(
        '⚠️ Failed to persist feed_mode: $e',
        name: 'FeedController',
      );
    }
  }

  FeedMode get feedMode => _feedMode;

  Stream<List<Post>> get postsStream => _postsController.stream;
  Stream<bool> get newPostsAvailableStream => _newPostsController.stream;
  bool get isInitialLoading => _loading;
  bool get hasLocalCache => _hasLocalCache;
  List<Post> get cachedPosts => List.unmodifiable(_posts);

  // Expose verification cache for PostCard
  bool isUserVerified(String userId) => _verificationCache.isVerified(userId);
  Map<String, dynamic> getUserData(String userId) =>
      _verificationCache.getUserData(userId);

  // Backward compatibility method
  Map<String, dynamic> getFarmerData(String userId) =>
      _verificationCache.getUserData(userId);

  /// Create a new post - allows all posts immediately, moderation runs in background
  Future<String> createPost({
    required String content,
    String contentType = 'text',
    List<PostMedia> media = const [],
    List<String> hashtags = const [],
    String groupId = '',
    String groupVisibility = 'public',
    String feelingTag = '',
    String locationTag = '',
    String caption = '',
  }) async {
    try {
      developer.log('📝 Creating new post', name: 'FeedController');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      developer.log('👤 Current user UID: ${user.uid}', name: 'FeedController');

      // Get user data from verification cache
      final userData = _verificationCache.getUserData(user.uid);
      if (userData.isEmpty) {
        // If not in cache, fetch from Firestore
        await _verificationCache.fetchMissingUsers([user.uid]);
      }

      final farmer = _verificationCache.getUserData(user.uid);
      final authorName = farmer['user_name'] ?? user.displayName ?? 'Farmer';
      final authorAvatar = farmer['profile_pic'] ?? user.photoURL ?? '';

      // DEBUG: Log user data
      developer.log(
        '🔧 FEED CREATE: farmer data keys=${farmer.keys.toList()}',
        name: 'FeedController',
      );
      developer.log(
        '🔧 FEED CREATE: user_name="${farmer['user_name']}", profile_pic="${farmer['profile_pic']}"',
        name: 'FeedController',
      );
      developer.log(
        '🔧 FEED CREATE: authorName="$authorName", authorAvatar="$authorAvatar"',
        name: 'FeedController',
      );

      final id = FirebaseFirestore.instance.collection('posts').doc().id;
      developer.log('🆔 Generated post ID: $id', name: 'FeedController');

      final post = Post(
        id: id,
        authorId: user.uid,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        contentType: contentType,
        createdAt: DateTime.now(),
        media: media,
        hashtags: hashtags,
        status: PostStatus.active, // Explicitly set to active
        analytics: PostAnalytics(),
        likes: [],
        reactions: const {},
        groupId: groupId,
        groupVisibility: groupVisibility,
        feelingTag: feelingTag,
        locationTag: locationTag,
        caption: caption,
        active: true, // Explicitly set to active
      );

      await _postController.createPost(post: post);
      developer.log(
        '✅ Post successfully saved to Firestore',
        name: 'FeedController',
      );

      // Add post to local feed immediately with proper ID
      final createdPost = post.copyWith(id: id);
      _posts.insert(0, createdPost);
      _postsController.add(List.from(_posts));
      developer.log(
        '📢 Post added to local feed. Total posts: ${_posts.length}',
        name: 'FeedController',
      );

      // 🔍 BACKGROUND AI MODERATION - Run after post creation to hide from feed if violations found
      // This is non-blocking - post creation is not blocked by moderation
      final mediaUrls = media
          .map((m) => m.url)
          .where((url) => url.isNotEmpty)
          .toList();
      unawaited(
        _runBackgroundModeration(
          id,
          content,
          user.uid,
          authorName,
          authorAvatar,
          mediaUrls.isNotEmpty ? mediaUrls : null,
        ),
      );

      developer.log(
        '✅ Post created successfully with ID: $id',
        name: 'FeedController',
      );

      return id;
    } catch (e) {
      developer.log('❌ Error creating post: $e', name: 'FeedController');
      rethrow;
    }
  }

  /// Get all post IDs that have active (pending) reports - EXCLUDE FROM FEED
  Future<Set<String>> _getReportedPostIds() async {
    try {
      final reportsSnap = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('status', isEqualTo: 'pending')
          .where('reportedPostId', isNotEqualTo: null)
          .get();

      final reportedPostIds = <String>{};
      for (final report in reportsSnap.docs) {
        final postId = report['reportedPostId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          reportedPostIds.add(postId);
        }
      }

      developer.log(
        '🚫 Found ${reportedPostIds.length} posts with pending reports',
        name: 'FeedController',
      );
      return reportedPostIds;
    } catch (e) {
      developer.log(
        '⚠️ Error fetching reported post IDs: $e',
        name: 'FeedController',
      );
      return {}; // Return empty set if there's an error
    }
  }

  /// Fetch posts with filtering - ONLY ACTIVE POSTS (excluding reported ones)
  /// Fetch posts with ranking: Pinned → Boosted → Verified → Trending → Recent
  Future<void> fetchPosts() async {
    if (_isFetching) return; // Guard against concurrent fetches
    _isFetching = true;

    developer.log('🚀 fetchPosts() STARTED', name: 'FeedController');
    final Stopwatch fetchStopwatch = Stopwatch()..start();

    try {
      // Get post IDs with active reports to exclude them
      final reportedPostIds = await _getReportedPostIds();
      developer.log(
        '🚫 Reported posts to exclude: ${reportedPostIds.length}',
        name: 'FeedController',
      );

      // ⚡ OPTIMIZED: Skip debug query, go straight to main queries
      // Prepare queries. We intentionally fetch a wider set of boosted items and
      // filter for active expiration client-side so a specific boosted marketplace
      // item is not missed by a small, arbitrary Firestore result set.
      Future<QuerySnapshot> getBoostedPosts() async {
        final postsCollection = FirebaseFirestore.instance.collection('posts');
        final snapshot = await postsCollection
            .where('isBoosted', isEqualTo: true)
            .limit(50)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot;
        }

        // Fallback for legacy field names.
        return await postsCollection
            .where('is_boosted', isEqualTo: true)
            .limit(50)
            .get();
      }

      Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getMarketplaceBoosts() async {
        final marketplaceDocs =
            <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

        for (final collectionName in ['Marketplace', 'marketplace']) {
          final collection = FirebaseFirestore.instance.collection(
            collectionName,
          );
          try {
            // Read documents with isBoosted == true
            final snapshot1 = await collection
                .where('isBoosted', isEqualTo: true)
                .get();
            for (final doc in snapshot1.docs) {
              if (hasActiveBoost(doc.data())) {
                marketplaceDocs['$collectionName:${doc.id}'] = doc;
              }
            }

            // Read documents with is_boosted == true
            final snapshot2 = await collection
                .where('is_boosted', isEqualTo: true)
                .get();
            for (final doc in snapshot2.docs) {
              if (hasActiveBoost(doc.data())) {
                marketplaceDocs['$collectionName:${doc.id}'] = doc;
              }
            }

            developer.log(
              '🛒 $collectionName: active boosts count = '
              '${marketplaceDocs.keys.where((key) => key.startsWith('$collectionName:')).length}',
              name: 'FeedController',
            );
          } catch (e) {
            developer.log(
              '⚠️ Marketplace scan failed for $collectionName: $e',
              name: 'FeedController',
            );
          }
        }

        return marketplaceDocs.values.toList();
      }

      // ⚡ PARALLEL QUERIES: Run all at once for speed
      final postsQuery = FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get();

      final results = await Future.wait<Object>([
        postsQuery,
        getBoostedPosts(),
        getMarketplaceBoosts(),
      ]);

      final regularSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final boostedSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final marketplaceDocs =
          results[2] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      developer.log('✅ Main query succeeded', name: 'FeedController');

      final activeBoostedDocs = boostedSnap.docs.where((doc) {
        final data = doc.data();
        return hasActiveBoost(data);
      }).toList();

      final activeMarketplaceDocs = marketplaceDocs.where((doc) {
        final data = doc.data();
        return hasActiveBoost(data);
      }).toList();

      developer.log(
        '🔍 Feed queries: ${activeBoostedDocs.length} active boosted docs, ${activeMarketplaceDocs.length} active marketplace docs, ${regularSnap.docs.length} regular docs',
        name: 'FeedController',
      );

      // Combine and parse all posts
      final allDocs = [...activeBoostedDocs, ...regularSnap.docs];

      // Remove duplicates (a post could be both pinned and boosted)
      final uniqueDocs = <String, DocumentSnapshot>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      int parsedCount = 0;
      int filteredCount = 0;
      final posts = uniqueDocs.values
          .map((doc) {
            try {
              final post = Post.fromFirestore(doc);
              parsedCount++;
              return post;
            } catch (e) {
              developer.log(
                '❌ Error parsing post ${doc.id}: $e',
                name: 'FeedController',
              );
              return null;
            }
          })
          .where((post) => post != null)
          .cast<Post>()
          .where((post) {
            final isGood =
                _isGoodPost(post) && !reportedPostIds.contains(post.id);
            if (!isGood) {
              filteredCount++;
            }
            return isGood;
          })
          .toList();

      developer.log(
        '📊 PARSING RESULT: $parsedCount posts parsed, ${posts.length} passed filter, $filteredCount filtered out',
        name: 'FeedController',
      );

      // Convert boosted marketplace items to posts and ensure expired ones are excluded.
      final marketplacePosts = activeMarketplaceDocs
          .map((doc) => convertMarketplaceItemToPostForFeed(doc))
          .where((post) => post != null)
          .cast<Post>()
          .where(_isGoodPost)
          .toList();

      developer.log(
        '🛒 Converted ${marketplacePosts.length} marketplace items to posts',
        name: 'FeedController',
      );

      // Combine all posts (marketplace items get high priority via isBoosted flag)
      final allPosts = [...marketplacePosts, ...posts];

      // Sort posts by ranking score (mode-aware)
      final rankedPosts = await _rankPosts(allPosts, mode: _feedMode);

      // Trigger background cleanup of expired boosts in Firestore
      unawaited(MarketplaceBoostService.instance.cleanupExpiredBoosts());

      // ⚡ CACHE-FIRST OPTIMIZATION: Only clear posts if we don't have cached data
      // This prevents the skeleton loader from re-appearing when we already have posts on screen
      if (!_hasLocalCache && _posts.isEmpty) {
        // First-ever load: no cache exists, safe to clear (it's already empty anyway)
        _posts.clear();
        _posts.addAll(rankedPosts);
      } else {
        // First sanitize _posts to remove expired marketplace items or deleted posts
        _posts.removeWhere((p) => !_isGoodPost(p));

        // Ensure any marketplace posts not present in active marketplace batch are removed
        final activeMarketplaceIds = marketplacePosts.map((p) => p.id).toSet();
        _posts.removeWhere((p) =>
            isMarketplacePost(p) &&
            !activeMarketplaceIds.contains(p.id));

        // Keep each existing row in place and update only matching records.
        // New records are appended here; silent refresh handles new-top-post
        // delivery separately so the current viewport does not jump.
        final freshById = {for (final post in rankedPosts) post.id: post};
        for (var index = 0; index < _posts.length; index++) {
          final freshPost = freshById[_posts[index].id];
          if (freshPost != null) _posts[index] = freshPost;
        }
        final existingIds = _posts.map((p) => p.id).toSet();
        _posts.addAll(
          rankedPosts.where((post) => !existingIds.contains(post.id)),
        );
      }

      // Store last doc for pagination (use last regular post)
      if (regularSnap.docs.isNotEmpty) {
        _lastDoc = regularSnap.docs.last;
      }

      _postsController.add(List.from(_posts));

      // Preload profile pictures and verification data in the background
      final authorIds = rankedPosts.map((p) => p.authorId).toSet().toList();
      ProfilePicturePreloader().preloadProfilePictures(authorIds);
      if (authorIds.isNotEmpty) {
        unawaited(_verificationCache.fetchMissingUsers(authorIds));
      }

      developer.log(
        '✅ Fetched and ranked ${rankedPosts.length} posts (including ${marketplacePosts.length} marketplace items)',
        name: 'FeedController',
      );

      // Cache posts locally so next app launch shows them instantly.
      // Awaited directly so the write completes before this function returns.
      try {
        final cacheMap = <String, Map<String, dynamic>>{};
        for (final p in _posts) {
          cacheMap[p.id] = p.toFirestoreMap();
        }
        await PostCacheService.cachePosts(
          cacheMap,
          accountKey: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        );
        developer.log(
          '💾 Cached ${cacheMap.length} posts to local post cache',
          name: 'FeedController',
        );
      } catch (e) {
        developer.log('⚠️ Failed to cache posts: $e', name: 'FeedController');
      }

      developer.log(
        '⏱ fetchPosts total time: ${fetchStopwatch.elapsedMilliseconds} ms',
        name: 'FeedController',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error fetching posts: $e',
        name: 'FeedController',
        error: e,
        stackTrace: stackTrace,
      );
      // Still update the UI to stop loading
      _postsController.add(List.from(_posts));
    } finally {
      _isFetching = false;
      _loading = false;
    }
  }

  /// Fetch initial posts - respects cache-first pattern
  /// If cache exists and is recent, use it without forcing network fetch
  Future<void> fetchInitialPosts() async {
    // If we have cached posts from startup, use them and refresh quietly in background
    if (_hasLocalCache && _posts.isNotEmpty) {
      _posts.removeWhere((p) => !_isGoodPost(p));
      _shuffleForAccount(_posts);
      _postsController.add(List.from(_posts));
      developer.log(
        '✅ INSTANT: Using ${_posts.length} cached posts (skip network)',
        name: 'FeedController',
      );
      // Emit cached posts immediately
      _postsController.add(List.from(_posts));
      // Refresh in background without disrupting UI
      unawaited(_refreshFeedInBackground());
      return;
    }

    // No cache: do full network fetch
    await fetchPosts();
  }

  /// Automatically merge newly detected posts into the visible feed.
  /// This keeps the feed continuous and avoids the stale "new posts" banner UX.
  void autoMergeIncomingPosts(List<Post> incomingPosts) {
    if (incomingPosts.isEmpty) return;

    final existingIds = _posts.map((p) => p.id).toSet();
    final uniqueIncoming = incomingPosts
        .where((post) => !existingIds.contains(post.id))
        .toList();

    if (uniqueIncoming.isEmpty) return;

    _pendingNewPosts.clear();
    _newPostsController.add(false);
    _posts.insertAll(0, uniqueIncoming);
    _postsController.add(List.from(_posts));

    developer.log(
      '📬 Auto-merged ${uniqueIncoming.length} new posts into the visible feed',
      name: 'FeedController',
    );
  }

  /// Backward compatibility helper for screens that still trigger a manual merge.
  Future<void> applyPendingNewPosts() async {
    if (_pendingNewPosts.isNotEmpty) {
      autoMergeIncomingPosts(_pendingNewPosts);
      _pendingNewPosts.clear();
    }

    try {
      final cacheMap = <String, Map<String, dynamic>>{};
      for (final post in _posts) {
        cacheMap[post.id] = post.toFirestoreMap();
      }
      await PostCacheService.cachePosts(
        cacheMap,
        accountKey: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      );
      developer.log(
        '💾 Cached ${cacheMap.length} posts after applying pending new posts',
        name: 'FeedController',
      );
    } catch (e) {
      developer.log(
        '⚠️ Failed to cache posts after applying pending new posts: $e',
        name: 'FeedController',
      );
    }
  }

  /// Convert a marketplace item to a Post for feed display
  Post? convertMarketplaceItemToPostForFeed(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return convertMarketplaceItemToPostForFeedData(data, documentId: doc.id);
  }

  /// Rank posts with distributed boosted posts
  /// Boosted posts appear every N posts (e.g., positions 0, 8, 16) instead of all at top
  /// Note: Posts with expired boosts lose their boosted priority and are ranked as regular posts
  /// (they're not excluded from the feed, just treated as normal posts in ranking)
  Future<List<Post>> _rankPosts(
    List<Post> posts, {
    FeedMode mode = FeedMode.mixed,
  }) async {
    try {
      final now = DateTime.now();

      // Ensure all posts pass basic hygiene; exclude expired marketplace posts immediately
      posts = posts.where(_isGoodPost).toList();

      // Get verification data for all authors (useful for personalized/mixed modes)
      final authorIds = posts.map((p) => p.authorId).toSet().toList();
      await _verificationCache.fetchMissingUsers(authorIds);

      // Separate boosted and regular posts
      // KEY: Posts that are both pinned AND boosted must have active boost (not expired)
      // Posts with expired boosts fall back to regular post ranking (unless they are marketplace items)
      final boostedPosts = posts.where((post) {
        return post.isBoosted &&
            post.boostEndDate != null &&
            post.boostEndDate!.isAfter(now);
      }).toList();

      // Objective targeting uses the app's existing follow graph. If the
      // graph cannot be read, keep the post eligible rather than hiding it.
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && boostedPosts.isNotEmpty) {
        try {
          final followingSnapshot = await FirebaseFirestore.instance
              .collection('following')
              .doc(currentUserId)
              .collection('following')
              .get();
          final followedAuthorIds = followingSnapshot.docs
              .map((doc) => doc.id)
              .toSet();

          boostedPosts.removeWhere((post) {
            if (post.boostObjectiveId == null ||
                post.authorId == currentUserId) {
              return false;
            }
            final followsAuthor = followedAuthorIds.contains(post.authorId);
            final objectiveTargetsFollowers =
                post.boostObjectiveId == 'engagement';
            return objectiveTargetsFollowers != followsAuthor;
          });
        } catch (e) {
          developer.log(
            '⚠️ Objective targeting unavailable; retaining boosted posts: $e',
            name: 'FeedController',
          );
        }
      }

      // Regular posts include: non-boosted posts, boosted community posts with expired boosts,
      // and pinned posts without active boosts.
      // NOTE: Marketplace items MUST NEVER be treated as regular posts in the community feed.
      final regularPosts = posts.where((post) {
        if (isMarketplacePost(post)) return false;

        return !post.isBoosted ||
            post.boostEndDate == null ||
            !post.boostEndDate!.isAfter(now);
      }).toList();

      final visibilityMultipliers = await _getVisibilityMultipliers(posts);

      // Sort boosted posts by urgency (ending soon first)
      final rankedBoosted = boostedPosts.map((post) {
        double score = 0;
        final hoursUntilEnd = post.boostEndDate!.difference(now).inHours;
        final visibilityMultiplier =
            visibilityMultipliers[post.authorId] ?? 1.0;
        score +=
            (168 - hoursUntilEnd.clamp(0, 168)) *
            2 *
            visibilityMultiplier; // Max 336 points
        return MapEntry(post, score);
      }).toList();
      rankedBoosted.sort((a, b) => b.value.compareTo(a.value));

      // MODE: RANDOM -> shuffle regular posts and then distribute boosted posts evenly
      if (mode == FeedMode.random) {
        // Shuffle regular posts to create randomness
        regularPosts.shuffle();
        final result = <Post>[];
        final boostedList = rankedBoosted.map((e) => e.key).toList();
        final regularList = regularPosts;

        // Start with regular posts
        result.addAll(regularList);

        // Insert each boosted post at a random position, never at index 0,
        // and avoid placing boosted posts adjacent to each other.
        final rng = _feedShuffleSalt ^ DateTime.now().microsecondsSinceEpoch;
        final random = Random(rng);
        for (final boosted in boostedList) {
          if (result.isEmpty) {
            result.add(boosted);
            continue;
          }

          bool placed = false;
          // Try random positions first, but skip indices adjacent to other boosted posts
          for (int attempt = 0; attempt < 20; attempt++) {
            final insertIndex =
                random.nextInt(result.length) + 1; // 1..result.length
            final leftIsBoosted =
                insertIndex - 1 >= 0 &&
                result[insertIndex - 1].isBoosted == true;
            final rightIsBoosted =
                insertIndex < result.length &&
                result[insertIndex].isBoosted == true;
            if (!leftIsBoosted && !rightIsBoosted) {
              result.insert(insertIndex, boosted);
              placed = true;
              break;
            }
          }

          // Fallback: scan for a safe slot
          if (!placed) {
            for (int i = 1; i <= result.length; i++) {
              final leftIsBoosted =
                  i - 1 >= 0 && result[i - 1].isBoosted == true;
              final rightIsBoosted =
                  i < result.length && result[i].isBoosted == true;
              if (!leftIsBoosted && !rightIsBoosted) {
                result.insert(i, boosted);
                placed = true;
                break;
              }
            }
          }

          // If still not placed (rare), append at end
          if (!placed) result.add(boosted);
        }

        // Ensure first post is not a boosted/featured post
        if (result.isNotEmpty && result.first.isBoosted == true) {
          final firstRegularIndex = result.indexWhere(
            (p) => p.isBoosted != true,
          );
          if (firstRegularIndex > 0) {
            final boostedPost = result.removeAt(0);
            final regularPost = result.removeAt(firstRegularIndex - 1);
            result.insert(0, regularPost);
            result.insert(firstRegularIndex, boostedPost);
          }
        }

        return result;
      }

      // MODE: PERSONALIZED -> boost posts that match user interests
      List<String> userInterests = [];
      if (mode == FeedMode.personalized) {
        userInterests = await _getCurrentUserInterests();
        developer.log(
          '🔎 Personalized interests for ranking: $userInterests',
          name: 'FeedController',
        );
      }

      // MODE: POPULARITY -> rely primarily on engagement score (less recency/verification bias)
      final rankedRegular = regularPosts.map((post) {
        double score = 0;

        final engagementScore = _calculateEngagementScore(post);
        final visibilityMultiplier =
            visibilityMultipliers[post.authorId] ?? 1.0;

        if (mode == FeedMode.popularity) {
          // Popularity mode: emphasize engagement
          score =
              engagementScore *
              10 *
              visibilityMultiplier; // scale up to separate values
          // Small recency tie-breaker
          final hoursSinceCreated = now.difference(post.createdAt).inHours;
          score += (hoursSinceCreated < 168)
              ? (168 - hoursSinceCreated) * 0.1
              : 0;
          return MapEntry(post, score);
        }

        // Default/mixed/personalized scoring (existing logic)
        final userData = _verificationCache.getUserData(post.authorId);
        final isVerified = userData['isVerified'] == true;
        final verificationStatus = userData['verificationStatus'] ?? '';
        final verificationPaid = userData['verificationPaid'] == true;

        if (isVerified &&
            verificationStatus == 'approved' &&
            verificationPaid) {
          score += 200;
        }

        score += engagementScore * visibilityMultiplier; // trending score

        // Personalization boost when interests match hashtags or content
        if (mode == FeedMode.personalized && userInterests.isNotEmpty) {
          final postTags = <String>{}
            ..addAll(post.hashtags.map((h) => h.toLowerCase()))
            ..addAll(post.content.toLowerCase().split(RegExp(r"\W+")));
          final matches = userInterests
              .where((i) => postTags.contains(i.toLowerCase()))
              .toList();
          if (matches.isNotEmpty) {
            score += 150; // strong boost for interest match
          }
        }

        // Recency bonus (up to 100 points for posts from last 24 hours)
        final hoursSinceCreated = now.difference(post.createdAt).inHours;
        if (hoursSinceCreated < 24) {
          score += (24 - hoursSinceCreated) * 4;
        } else if (hoursSinceCreated < 168) {
          score += (168 - hoursSinceCreated) * 0.5;
        }

        // Age penalties for old posts
        if (hoursSinceCreated > 168) {
          final weeksOld = (hoursSinceCreated / 168).floor();
          score -= (weeksOld * 10).clamp(0, 100);
        }
        if (hoursSinceCreated > 720) {
          final monthsOld = (hoursSinceCreated / 720).floor();
          score -= (monthsOld * 20).clamp(0, 200);
        }
        if (hoursSinceCreated > 2160) {
          score -= 500;
        }

        // Keep the broad ranking signals, but vary close results per account
        // so every user does not receive the identical feed sequence.
        score += _accountFeedJitter(post.id);

        return MapEntry(post, score);
      }).toList();

      // Sort regular posts by score
      rankedRegular.sort((a, b) => b.value.compareTo(a.value));

      // Insert boosted posts at random positions among ranked regular posts
      final result = <Post>[];
      final boostedList = rankedBoosted.map((e) => e.key).toList();
      final regularList = rankedRegular.map((e) => e.key).toList();

      // Start with the ordered regular posts
      result.addAll(regularList);
      _shuffleForAccount(result);

      // Use a per-installation salt combined with time so different phones
      // produce different random orders and the ordering still changes over time.
      final rng = _feedShuffleSalt ^ DateTime.now().microsecondsSinceEpoch;
      final random = Random(rng);

      for (final boosted in boostedList) {
        if (result.isEmpty) {
          result.add(boosted);
          continue;
        }

        bool placed = false;
        for (int attempt = 0; attempt < 20; attempt++) {
          final insertIndex =
              random.nextInt(result.length) + 1; // 1..result.length
          final leftIsBoosted =
              insertIndex - 1 >= 0 && result[insertIndex - 1].isBoosted == true;
          final rightIsBoosted =
              insertIndex < result.length &&
              result[insertIndex].isBoosted == true;
          if (!leftIsBoosted && !rightIsBoosted) {
            result.insert(insertIndex, boosted);
            placed = true;
            break;
          }
        }

        if (!placed) {
          for (int i = 1; i <= result.length; i++) {
            final leftIsBoosted = i - 1 >= 0 && result[i - 1].isBoosted == true;
            final rightIsBoosted =
                i < result.length && result[i].isBoosted == true;
            if (!leftIsBoosted && !rightIsBoosted) {
              result.insert(i, boosted);
              placed = true;
              break;
            }
          }
        }

        if (!placed) result.add(boosted);
      }

      // Ensure first post is not boosted
      if (result.isNotEmpty && result.first.isBoosted == true) {
        final firstRegularIndex = result.indexWhere((p) => p.isBoosted != true);
        if (firstRegularIndex > 0) {
          final boostedPost = result.removeAt(0);
          final regularPost = result.removeAt(firstRegularIndex - 1);
          result.insert(0, regularPost);
          result.insert(firstRegularIndex, boostedPost);
        }
      }

      developer.log(
        '📊 Randomly inserted ${boostedList.length} boosted posts among ${regularList.length} regular posts. Total: ${result.length}',
        name: 'FeedController',
      );

      return result;
    } catch (e) {
      developer.log('❌ Error ranking posts: $e', name: 'FeedController');
      return posts;
    }
  }

  /// Get the current user's interests from their farmer profile (if any)
  Future<List<String>> _getCurrentUserInterests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final raw = data['interests'] ?? data['topics'] ?? data['followedTopics'];
      if (raw is List) {
        return raw
            .map((e) => e.toString().toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (raw is String) {
        return raw
            .split(',')
            .map((e) => e.toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      developer.log(
        '⚠️ Failed to fetch current user interests: $e',
        name: 'FeedController',
      );
      return [];
    }
  }

  Future<Map<String, double>> _getVisibilityMultipliers(
    List<Post> posts,
  ) async {
    final authorIds = posts.map((post) => post.authorId).toSet().toList();
    if (authorIds.isEmpty) return {};

    final futures = authorIds.map((authorId) async {
      final status = await FarmerReputationService.getFarmerStatus(authorId);
      return MapEntry(
        authorId,
        FarmerReputationService.getVisibilityMultiplierForStatus(status),
      );
    }).toList();

    final entries = await Future.wait(futures);
    return {for (final entry in entries) entry.key: entry.value};
  }

  /// Calculate engagement score for trending
  double _calculateEngagementScore(Post post) {
    double score = 0;

    // Likes (1 point each, max 100)
    final likesCount = post.analytics.likesCount;
    score += likesCount.clamp(0, 100).toDouble();

    // Comments (3 points each, max 150)
    final commentsCount = post.analytics.commentsCount;
    score += (commentsCount * 3).clamp(0, 150).toDouble();

    // Reactions (2 points each, max 50)
    final reactionsCount = post.analytics.reactionsCount;
    score += (reactionsCount * 2).clamp(0, 50).toDouble();

    // Shares (5 points each, max 100)
    final sharesCount = post.analytics.sharesCount;
    score += (sharesCount * 5).clamp(0, 100).toDouble();

    // Views (0.01 points each, max 50)
    final viewsCount = post.analytics.viewsCount;
    score += (viewsCount * 0.01).clamp(0, 50).toDouble();

    return score;
  }

  /// Fetch more posts (pagination) - ONLY ACTIVE POSTS (excluding reported ones)
  /// KEY FIX: Do NOT re-rank existing posts to prevent feed jumping
  /// New posts are ranked independently and appended, keeping visible posts stable
  Future<void> fetchMorePosts() async {
    if (!_hasMore || _isFetching || _lastDoc == null) return;
    _isFetching = true;

    try {
      // Get post IDs with active reports to exclude them
      final reportedPostIds = await _getReportedPostIds();

      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      if (snap.docs.isEmpty) {
        _hasMore = false;
        _isFetching = false;
        return;
      }

      final posts = snap.docs
          .map((doc) {
            try {
              final post = Post.fromFirestore(doc);
              return post;
            } catch (e) {
              developer.log(
                '❌ Error parsing post ${doc.id}: $e',
                name: 'FeedController',
              );
              return null;
            }
          })
          .where((post) => post != null)
          .cast<Post>()
          .where(
            (post) => _isGoodPost(post) && !reportedPostIds.contains(post.id),
          )
          .toList();

      // 🔑 SMOOTH SCROLL FIX: Rank only new posts, append to end
      // This keeps visible posts stable - no jumping during scroll
      final rankedNewPosts = await _rankPosts(posts, mode: _feedMode);
      _posts.addAll(rankedNewPosts);

      _lastDoc = snap.docs.last;
      _postsController.add(List.from(_posts));

      // Preload profile pictures and verification data for new post authors
      final authorIds = rankedNewPosts.map((p) => p.authorId).toSet().toList();
      ProfilePicturePreloader().preloadProfilePictures(authorIds);
      if (authorIds.isNotEmpty) {
        unawaited(_verificationCache.fetchMissingUsers(authorIds));
      }

      developer.log(
        '✅ Fetched and ranked ${rankedNewPosts.length} more posts',
        name: 'FeedController',
      );
    } catch (e) {
      developer.log('❌ Error fetching more posts: $e', name: 'FeedController');
    } finally {
      _isFetching = false;
    }
  }

  /// Refresh posts (clear and fetch again) - ONLY ACTIVE POSTS
  Future<void> refreshPosts() async {
    _lastDoc = null;
    _hasMore = true;
    if (_pendingNewPosts.isNotEmpty) {
      await applyPendingNewPosts();
    }

    if (_hasLocalCache && _posts.isNotEmpty) {
      // Keep visible feed stable; fetch new posts in background and buffer updates.
      await silentBackgroundRefresh();
      return;
    }

    await fetchPosts();
  }

  bool get hasPendingNewPosts => _pendingNewPosts.isNotEmpty;
  int get pendingNewPostCount => _pendingNewPosts.length;

  /// Silent background refresh - updates feed without disrupting visible posts
  /// Uses a "pull-to-refresh" style update that doesn't jump existing content
  /// This allows new posts to appear naturally without feed jumping
  Future<void> silentBackgroundRefresh() async {
    if (_isFetching) return; // Don't pile up refresh requests
    _isFetching = true;

    try {
      developer.log(
        '🔄 Silent background refresh started (no UI disruption)',
        name: 'FeedController',
      );

      // Get fresh data from Firestore without clearing existing posts
      final reportedPostIds = await _getReportedPostIds();

      // Fetch the latest posts (without pagination anchor)
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(_pageSize * 2) // Fetch double to include boosted items
          .get();

      // Keep pagination aligned with the active-post query. Without this,
      // cached launches have visible posts but no cursor for the next page.
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
      }

      // Parse new posts
      final newPosts = snap.docs
          .map((doc) {
            try {
              return Post.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((post) => post != null)
          .cast<Post>()
          .where(
            (post) => _isGoodPost(post) && !reportedPostIds.contains(post.id),
          )
          .toList();

      final marketplaceDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final collectionName in ['Marketplace', 'marketplace']) {
        try {
          final marketplaceSnap = await FirebaseFirestore.instance
              .collection(collectionName)
              .where('isBoosted', isEqualTo: true)
              .get();
          marketplaceDocs.addAll(
            marketplaceSnap.docs.where((doc) => hasActiveBoost(doc.data())),
          );
        } catch (e) {
          developer.log(
            '⚠️ Silent marketplace refresh failed for $collectionName: $e',
            name: 'FeedController',
          );
        }
      }

      final marketplacePosts = marketplaceDocs
          .map(convertMarketplaceItemToPostForFeed)
          .whereType<Post>()
          .where(_isGoodPost)
          .where((post) => !reportedPostIds.contains(post.id))
          .toList();

      // Clean up any expired posts or marketplace items from current feed
      final initialCount = _posts.length;
      _posts.removeWhere((p) => !_isGoodPost(p));
      final activeMarketplaceIds = marketplacePosts.map((p) => p.id).toSet();
      _posts.removeWhere((p) =>
          isMarketplacePost(p) &&
          !activeMarketplaceIds.contains(p.id));

      if (_posts.length != initialCount) {
        _postsController.add(List.from(_posts));
      }

      // Check for new posts not already in feed
      final existingPostIds = _posts.map((p) => p.id).toSet();
      final actuallyNewPosts = [
        ...newPosts,
        ...marketplacePosts,
      ].where((p) => !existingPostIds.contains(p.id)).toList();

      if (actuallyNewPosts.isNotEmpty) {
        final rankedNew = await _rankPosts(actuallyNewPosts, mode: _feedMode);
        final pendingIds = _pendingNewPosts.map((p) => p.id).toSet();
        final newPendingPosts = rankedNew
            .where((post) => !pendingIds.contains(post.id))
            .toList();

        if (newPendingPosts.isNotEmpty) {
          _pendingNewPosts.addAll(newPendingPosts);
          _newPostsController.add(true);
          developer.log(
            '📬 Silent refresh: queued ${newPendingPosts.length} new posts without moving the feed',
            name: 'FeedController',
          );
        }
      }
    } catch (e) {
      developer.log(
        '⚠️ Silent refresh failed (non-blocking): $e',
        name: 'FeedController',
      );
    } finally {
      _isFetching = false;
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final post = _posts[postIndex];
      final updatedPost = post.copyWith(
        likes: post.likes.contains(userId)
            ? post.likes.where((id) => id != userId).toList()
            : [...post.likes, userId],
      );

      _posts[postIndex] = updatedPost;
      _postsController.add(List.from(_posts));

      // Update in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': updatedPost.likes,
      });

      developer.log('✅ Toggled like for post $postId', name: 'FeedController');
    } catch (e) {
      developer.log('❌ Error toggling like: $e', name: 'FeedController');
    }
  }

  /// Refresh a single post (for post card updates)
  Future<void> refreshSinglePost(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!doc.exists) return;

      final post = Post.fromFirestore(doc);
      final postIndex = _posts.indexWhere((p) => p.id == postId);

      if (postIndex != -1) {
        _posts[postIndex] = post;
        _postsController.add(List.from(_posts));
        developer.log(
          '✅ Refreshed single post $postId',
          name: 'FeedController',
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error refreshing single post: $e',
        name: 'FeedController',
      );
    }
  }

  /// Preload verification data (for search screen compatibility)
  Future<void> preloadVerificationData() async {
    try {
      // Preload verification data for better UX
      developer.log('🔄 Preloading verification data', name: 'FeedController');
      // Implementation can be added as needed
    } catch (e) {
      developer.log(
        '❌ Error preloading verification data: $e',
        name: 'FeedController',
      );
    }
  }

  /// Preload farmer data for better UX
  void _preloadFarmers() {
    // Preload verification data for better performance
    // Use fetchMissingUsers with empty list as a preload trigger
    _verificationCache.fetchMissingUsers([]);
  }

  /// Restore from Hive cache without blocking the first frame.
  /// 🔧 IMPROVED: Better error handling, multiple fallback sources, and offline detection
  void _restoreFromHive() {
    try {
      developer.log(
        '🔄 [OFFLINE] Starting cache restoration for offline support...',
        name: 'FeedController',
      );

      final accountKey = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final cachedMap = PostCacheService.getAllCachedPosts(
        accountKey: accountKey,
      );

      developer.log(
        '📦 Hive restore: found ${cachedMap.length} cached post entries',
        name: 'FeedController',
      );

      final entries = cachedMap.entries.toList()..shuffle(Random());
      final restoredPosts = <Post>[];

      // TIER 1: Load posts from primary cache (PostCacheService)
      if (entries.isNotEmpty) {
        const initialBatchSize = 10;

        for (final entry in entries) {
          try {
            final post = Post.fromMap(entry.key, entry.value);
            if (_isGoodPost(post)) {
              restoredPosts.add(post);
              if (restoredPosts.length >= initialBatchSize) break;
            } else {
              unawaited(PostCacheService.clearPost(entry.key, accountKey: accountKey));
            }
          } catch (err) {
            developer.log(
              '❌ Failed to parse cached post ${entry.key}: $err',
              name: 'FeedController',
            );
          }
        }

        developer.log(
          '📦 Hive restore: parsed ${restoredPosts.length} initial cached posts from primary cache',
          name: 'FeedController',
        );

        if (restoredPosts.isNotEmpty) {
          _posts.addAll(restoredPosts);
          _hasLocalCache = true;
          _postsController.add(List.from(_posts));
          _loading = false;
          developer.log(
            '✅ INSTANT: Restored ${restoredPosts.length} cached posts for first paint (OFFLINE MODE)',
            name: 'FeedController',
          );
          _restoreFeedMode();

          unawaited(_refreshFeedInBackground());
          return;
        }
      }

      // TIER 2: Load from FeedCacheService if primary cache is empty
      developer.log(
        '📋 Primary cache empty, checking feed list cache...',
        name: 'FeedController',
      );

      final feedList = FeedCacheService.getFeedList(accountKey: accountKey);
      developer.log(
        '📦 FeedCache restore: found ${feedList.length} feed list entries',
        name: 'FeedController',
      );

      for (final item in feedList) {
        final postId = item['postId']?.toString();
        if (postId == null || postId.isEmpty) continue;

        final cachedData = PostCacheService.getCachedPost(
          postId,
          accountKey: accountKey,
        );
        if (cachedData == null) {
          developer.log(
            '⚠️ Post $postId in feed list but not found in cache',
            name: 'FeedController',
          );
          continue;
        }

        try {
          final post = Post.fromMap(postId, cachedData);
          if (_isGoodPost(post)) {
            restoredPosts.add(post);
          } else {
            unawaited(FeedCacheService.removeFeedItem(postId, accountKey: accountKey));
            unawaited(PostCacheService.clearPost(postId, accountKey: accountKey));
          }
        } catch (err) {
          developer.log(
            '❌ Failed to parse feed list cached post $postId: $err',
            name: 'FeedController',
          );
        }
      }

      developer.log(
        '📦 FeedCache restore: loaded ${restoredPosts.length} posts from feed list',
        name: 'FeedController',
      );

      if (restoredPosts.isNotEmpty) {
        _shuffleForAccount(restoredPosts);
        _posts.addAll(restoredPosts);
        _hasLocalCache = true;
        _postsController.add(List.from(_posts));
        _loading = false;
        developer.log(
          '✅ INSTANT: Restored ${restoredPosts.length} cached posts from feed list (OFFLINE MODE)',
          name: 'FeedController',
        );
        _restoreFeedMode();
        unawaited(_refreshFeedInBackground());
        return;
      }

      // TIER 3: Fallback to legacy cache if higher tiers are empty
      developer.log(
        '📚 Feed list empty, checking legacy cache...',
        name: 'FeedController',
      );

      _restoreFeedMode();

      if (_posts.isEmpty) {
        final legacyFeedPosts = FeedCache.loadPosts(accountKey: accountKey);
        final validLegacy = legacyFeedPosts.where(_isGoodPost).toList();
        if (validLegacy.isNotEmpty) {
          _posts.addAll(validLegacy);
          _hasLocalCache = true;
          _postsController.add(List.from(_posts));
          _loading = false;
          developer.log(
            '✅ Legacy fallback: Restored ${validLegacy.length} posts from feed_posts box (OFFLINE MODE)',
            name: 'FeedController',
          );
          unawaited(_refreshFeedInBackground());
          return;
        }
      }

      // No cache found - will load from Firestore when online
      if (cachedMap.isNotEmpty) {
        developer.log(
          '⚠️ Hive cache entries exist (${cachedMap.length}), but no valid cached posts were restored. Cache may be corrupted.',
          name: 'FeedController',
        );
      } else {
        developer.log(
          '⚠️ No cache found at all. This is first app launch or cache was cleared. Will load from Firestore when online.',
          name: 'FeedController',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error restoring from Hive: $e\nStacktrace: $stackTrace',
        name: 'FeedController',
      );
    } finally {
      if (!_hasLocalCache) {
        _loading = false;
        _postsController.add(List.from(_posts));
      }
    }
  }

  void _restoreFeedMode() {
    try {
      final cacheBox = _cacheBox;
      if (cacheBox == null) return;
      final modeIndex = cacheBox.get('feed_mode');
      if (modeIndex is int &&
          modeIndex >= 0 &&
          modeIndex < FeedMode.values.length) {
        _feedMode = FeedMode.values[modeIndex];
        developer.log(
          '🔁 Restored feed mode: $_feedMode',
          name: 'FeedController',
        );
      }
    } catch (e) {
      developer.log(
        '⚠️ Failed to restore feed mode: $e',
        name: 'FeedController',
      );
    }
  }

  /// Refresh feed in background WITHOUT blocking UI
  /// Uses silent refresh to detect new posts and prepend them naturally
  /// This prevents feed jumping and provides Facebook-like smooth updates
  Future<void> _refreshFeedInBackground() async {
    try {
      developer.log(
        '🔄 Background refresh started (silent mode - no disruption)',
        name: 'FeedController',
      );

      // Wait a brief moment to let UI settle
      await Future.delayed(const Duration(milliseconds: 500));

      // Use silent refresh instead of full re-fetch
      // This detects new posts and adds them without clearing existing feed
      await silentBackgroundRefresh();
      developer.log('✅ Background refresh completed', name: 'FeedController');
    } catch (e) {
      developer.log(
        '⚠️ Background refresh failed (non-blocking): $e',
        name: 'FeedController',
      );
      // Don't throw - background refresh should not affect user experience
    }
  }

  /// Quick fix: Migrate ALL posts to active=true (EMERGENCY FIX)
  Future<void> emergencyFixAllPosts() async {
    try {
      developer.log(
        '🚨 EMERGENCY: Activating ALL posts...',
        name: 'FeedController',
      );

      final allPosts = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int updated = 0;

      for (final doc in allPosts.docs) {
        batch.update(doc.reference, {'active': true, 'status': 'active'});
        updated++;
      }

      await batch.commit();
      developer.log(
        '✅ EMERGENCY COMPLETE: $updated posts set to active=true',
        name: 'FeedController',
      );

      // Refresh feed immediately
      await refreshPosts();
    } catch (e) {
      developer.log('❌ Emergency fix failed: $e', name: 'FeedController');
    }
  }

  /// Basic harmful content check as fallback
  bool _basicHarmfulContentCheck(String prompt) {
    if (prompt.trim().isEmpty) return false;

    final normalizedPrompt = prompt.toLowerCase().trim();

    // Expanded harmful patterns with better coverage
    final harmfulPatterns = [
      // Hacking / cybercrime
      RegExp(
        r'\b(how\s+to\s+hack|hack\s+into|bypass\s+security|steal\s+password|phishing\s+attack|create\s+backdoor|sql\s+injection|ddos\s+attack|crack\s+password)\b',
        caseSensitive: false,
      ),

      // Fraud / scams
      RegExp(
        r'\b(how\s+to\s+scam|credit\s+card\s+fraud|bank\s+fraud|steal\s+money|fake\s+identity|identity\s+theft|pyramid\s+scheme|ponzi\s+scheme)\b',
        caseSensitive: false,
      ),

      // Malware creation
      RegExp(
        r'\b(create\s+virus|make\s+malware|spread\s+ransomware|write\s+trojan|develop\s+spyware|create\s+keylogger|malicious\s+software)\b',
        caseSensitive: false,
      ),

      // Violence instructions
      RegExp(
        r'\b(how\s+to\s+kill|how\s+to\s+make\s+bomb|terrorist\s+attack|make\s+weapon|explosive\s+recipe|shoot\s+people|mass\s+violence)\b',
        caseSensitive: false,
      ),

      // Illegal drugs production
      RegExp(
        r'\b(make\s+meth|produce\s+cocaine|drug\s+trafficking|synthesize\s+drugs|illegal\s+drug\s+manufacturing|drug\s+lab)\b',
        caseSensitive: false,
      ),

      // Self-harm
      RegExp(
        r'\b(how\s+to\s+commit\s+suicide|self\s+harm|kill\s+myself|end\s+my\s+life)\b',
        caseSensitive: false,
      ),

      // Hate speech
      RegExp(
        r'\b(hate\s+speech|racial\s+slur|discriminate|genocide|ethnic\s+cleansing)\b',
        caseSensitive: false,
      ),
    ];

    // Check each pattern
    for (final pattern in harmfulPatterns) {
      if (pattern.hasMatch(normalizedPrompt)) {
        return true;
      }
    }

    return false;
  }

  /// 🔍 BACKGROUND MODERATION - Run after post creation
  /// Hides post from community feed if violations found, but keeps it on user's profile
  Future<void> _runBackgroundModeration(
    String postId,
    String content,
    String userId,
    String userName,
    String authorProfilePic,
    List<String>? mediaUrls,
  ) async {
    try {
      developer.log(
        '🔍 Starting background AI moderation for post $postId',
        name: 'FeedController',
      );

      final moderationPassed = await ModerationService.checkContent(
        text: content,
        postId: postId,
        userId: userId,
      );

      if (moderationPassed) {
        developer.log(
          '✅ Post $postId passed moderation',
          name: 'FeedController',
        );
        return;
      }

      developer.log(
        '🚫 Post $postId flagged by moderation - hiding from community feed',
        name: 'FeedController',
      );

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'communityHidden': true,
        'moderationStatus': 'violation_detected',
        'moderatedAt': FieldValue.serverTimestamp(),
      });

      _posts.removeWhere((p) => p.id == postId);
      _postsController.add(List.from(_posts));

      developer.log(
        '✅ Post $postId hidden from community feed (still visible on profile)',
        name: 'FeedController',
      );
    } catch (e) {
      developer.log(
        '❌ Background AI moderation error for post $postId: $e',
        name: 'FeedController',
      );
      // Don't throw - background moderation should not affect user experience
    }
  }

  /// Check if a post is good (client-side filtering)
  bool _isGoodPost(Post post) {
    // Filter out posts explicitly marked as inactive
    if (post.active == false) {
      developer.log(
        '❌ Post ${post.id} is BAD (active=false)',
        name: 'FeedController',
      );
      return false;
    }

    // 🚫 Filter out posts hidden by moderation (still visible on profile)
    if (post.communityHidden == true) {
      developer.log(
        '❌ Post ${post.id} is BAD (communityHidden=true - moderation violation)',
        name: 'FeedController',
      );
      return false;
    }

    // Filter out bad posts by status
    final status = post.status.name.toLowerCase();

    developer.log(
      '🔍 _isGoodPost checking: postId=${post.id}, status="$status"',
      name: 'FeedController',
    );
    developer.log(
      '🔍 POST FILTER DEBUG: postId=${post.id}, content="${post.content}"',
      name: 'FeedController',
    );
    developer.log(
      '🔍 POST FILTER DEBUG: media count=${post.media.length}, media types=${post.media.map((m) => m.type).toList()}',
      name: 'FeedController',
    );

    // Posts with empty status are considered good, but need to be activated
    if (status.isEmpty) {
      developer.log(
        '✅ Post ${post.id} is GOOD (empty status)',
        name: 'FeedController',
      );
      return true; // Empty status = good post
    }

    if (status == 'deleted' ||
        status == 'removed' ||
        status == 'banned' ||
        status == 'inactive' ||
        status == 'suspended') {
      developer.log(
        '❌ Post ${post.id} is BAD (status: $status)',
        name: 'FeedController',
      );
      return false;
    }

    // Filter empty or very short content (but allow video posts)
    if (post.content.trim().isEmpty || post.content.trim().length < 3) {
      // Check if this is a video post - allow short content for videos
      final hasVideo = post.media.any((media) => media.type == 'video');

      if (hasVideo) {
        developer.log(
          '✅ Post ${post.id} is GOOD (video post with short content: "${post.content}")',
          name: 'FeedController',
        );
        return true; // Allow video posts with short content
      }

      developer.log(
        '❌ Post ${post.id} is BAD (empty/short content: "${post.content}")',
        name: 'FeedController',
      );
      return false;
    }

    // Check for harmful content (basic check only - async AI moderation happens during post creation)
    if (_basicHarmfulContentCheck(post.content)) {
      developer.log(
        '❌ Post ${post.id} is BAD (harmful content)',
        name: 'FeedController',
      );
      return false;
    }

    // Exclude marketplace-origin posts whose boost is not active or has expired.
    // Marketplace items MUST NEVER appear in the community feed unless they have an active paid boost.
    final now = DateTime.now();
    if (isMarketplacePost(post)) {
      if (post.isBoosted != true ||
          post.boostEndDate == null ||
          !post.boostEndDate!.isAfter(now)) {
        developer.log(
          '❌ Post ${post.id} is BAD (marketplace boost expired or not active)',
          name: 'FeedController',
        );
        return false;
      }
    }

    developer.log('✅ Post ${post.id} is GOOD', name: 'FeedController');
    // Otherwise, it's a good post
    return true;
  }

  /// SUPER EMERGENCY FIX - Call this if nothing else works
  /// Only activates posts that are NOT reported, removed, or deleted
  Future<void> superEmergencyFix() async {
    try {
      developer.log(
        '🚨 SUPER EMERGENCY: Activating safe posts only',
        name: 'FeedController',
      );

      // 1. Get post IDs with active reports to exclude them
      final reportedPostIds = await _getReportedPostIds();
      developer.log(
        '🚫 Excluding ${reportedPostIds.length} reported posts',
        name: 'FeedController',
      );

      // 2. Get ALL posts
      final allPosts = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      developer.log(
        '📊 Found ${allPosts.docs.length} total posts',
        name: 'FeedController',
      );

      // 3. Filter and update only safe posts
      final batch = FirebaseFirestore.instance.batch();
      int updated = 0;
      int skipped = 0;

      for (final doc in allPosts.docs) {
        final data = doc.data();
        final status = (data['status'] as String? ?? '').toLowerCase();
        final postId = doc.id;

        // Skip reported posts
        if (reportedPostIds.contains(postId)) {
          skipped++;
          continue;
        }

        // Skip posts with bad statuses
        if (status == 'deleted' ||
            status == 'removed' ||
            status == 'banned' ||
            status == 'suspended') {
          skipped++;
          continue;
        }

        // Only activate safe posts
        batch.update(doc.reference, {'active': true, 'status': 'active'});
        updated++;
      }

      // 4. Commit
      await batch.commit();
      developer.log(
        '✅ $updated posts activated, $skipped posts skipped (reported/bad status)',
        name: 'FeedController',
      );

      // 5. Clear local cache and refresh
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;

      // 6. Wait a moment then fetch
      await Future.delayed(const Duration(seconds: 1));
      developer.log('🔄 About to call fetchPosts()...', name: 'FeedController');
      await fetchPosts();

      developer.log(
        '🔄 Feed refreshed after emergency fix. Local posts count: ${_posts.length}',
        name: 'FeedController',
      );

      // 7. Force UI update
      _postsController.add(List.from(_posts));
      developer.log(
        '📢 UI updated with ${_posts.length} posts',
        name: 'FeedController',
      );
    } catch (e) {
      developer.log('❌ Super emergency fix failed: $e', name: 'FeedController');
    }
  }

  /// Dispose resources
  void dispose() {
    _postsController.close();
    _newPostsController.close();
  }
}
