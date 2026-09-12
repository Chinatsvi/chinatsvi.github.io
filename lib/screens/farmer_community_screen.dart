import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:agribased/controllers/feed_controller.dart';
import 'package:agribased/controllers/auth_controller.dart';
import 'package:agribased/services/auth_state_storage.dart';
import 'package:agribased/services/marketplace/firebase_marketplace_service.dart';
import 'package:agribased/models/post_model.dart';

import 'package:agribased/widgets/optimized_post_card.dart';
import 'package:agribased/widgets/comment_section.dart';
import 'package:agribased/widgets/post_creation_widget.dart';
import 'package:agribased/widgets/skeleton_loader.dart';
import 'package:agribased/widgets/ad_banner_widget.dart';
import 'package:agribased/utils/verification_helpers.dart';

import 'package:agribased/screens/search_screen.dart';

import 'dashboard_tool_screen.dart';
import 'marketplace/marketplace_home_page.dart';
import 'profile/farmer_profile_screen.dart';
import 'chat/privacy_settings_screen.dart';
import 'chat/chat_list_screen.dart';
import 'package:agribased/screens/auth/about_agribase_screen.dart';
import 'package:agribased/screens/notifications/notifications_screen.dart';
import 'package:agribased/screens/academy/academy_screen.dart';
import 'package:agribased/screens/admin/academy/academy_manager_screen.dart';
import 'package:agribased/services/notifications/notification_service.dart';
import 'package:agribased/services/cache/connectivity_service.dart';
import 'package:agribased/services/cache/profile_cache_service.dart';
import 'package:agribased/services/secure_auth_service.dart';
import 'package:agribased/services/ad_manager.dart';

bool shouldUseCachedFeed({
  required bool hasCachedPosts,
  required bool hasLocalCache,
}) {
  return hasCachedPosts || hasLocalCache;
}

bool shouldShowSkeletonLoader({
  required bool isLoadingProfile,
  required bool hasCachedPosts,
  required bool hasLocalCache,
  required bool isInitialLoading,
}) {
  return isLoadingProfile &&
      !hasCachedPosts &&
      !hasLocalCache &&
      isInitialLoading;
}

class FarmerCommunityScreen extends StatefulWidget {
  const FarmerCommunityScreen({super.key});

  @override
  State<FarmerCommunityScreen> createState() => _FarmerCommunityScreenState();
}

class _FarmerCommunityScreenState extends State<FarmerCommunityScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  String? currentUserId;
  final FeedController _feedController = FeedController();
  bool _isAdmin = false;
  StreamSubscription<bool>? _connectivitySub;
  final Map<int, BannerAd> _loadedAds = {};
  final Set<int> _loadingAdSlots = {};
  static const _maxConcurrentAdLoads = 3;
  static String get _adUnitId => AdManager.bannerAdUnitId;
  static const _adIntervals = [3, 8, 9, 10];

  bool get _hasCachedFeed =>
      _feedController.cachedPosts.isNotEmpty || _feedController.hasLocalCache;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load cached profile quickly for a smoother UX
    _loadCachedProfile();

    // Listen to Firebase auth state changes to load when Firebase restores
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        print('✅ [COMMUNITY] Firebase auth state changed, user: ${user.uid}');
        final userChanged = currentUserId != null && currentUserId != user.uid;
        setState(() {
          currentUserId = user.uid;
          _profileExists = true;
          if (userChanged) {
            currentUserName = null;
            currentUserProfilePic = null;
          }
        });
        _loadUserProfile();
        _feedController.fetchInitialPosts();
      } else if (user == null && mounted) {
        // Don't clear immediately - may be temporary null during reconnection
        // Only clear if we have no cached user data at all
        if (currentUserId == null) {
          setState(() {
            _profileExists = false;
          });
        }
        // If currentUserId is already set (from cache), keep it alive
        // Firebase will reconnect automatically when internet stabilizes
      }
    });

    // 🔥 CRITICAL: Listen to connectivity changes for auto-login when internet returns
    final connectivityService = ConnectivityService();
    connectivityService.startListening();
    _connectivitySub = connectivityService.connectivityStream.listen((
      isOnline,
    ) async {
      if (isOnline && mounted) {
        print(
          '🌐 [COMMUNITY] Internet restored! Checking if auto-login needed...',
        );

        if (FirebaseAuth.instance.currentUser == null &&
            currentUserId != null) {
          print(
            '🔄 [COMMUNITY] Firebase auth is null, attempting auto-login...',
          );
          final secureAuth = SecureAuthService();
          final user = await secureAuth.autoLogin();
          if (user != null) {
            print('✅ [COMMUNITY] Auto-login successful! User: ${user.uid}');
            // authStateChanges listener will handle the rest
          } else {
            print('❌ [COMMUNITY] Auto-login failed');
          }
        } else if (FirebaseAuth.instance.currentUser != null) {
          print(
            '🔄 [COMMUNITY] Internet restored and user is signed in. Refreshing feed silently.',
          );
          unawaited(_feedController.silentBackgroundRefresh());
        }
      }
    });

    // Run optional cleanup after first frame. Do not clear the cached feed on startup.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check admin status only. Do not run superEmergencyFix() here.
      await _checkAdminStatus();
    });
  }

  @override
  void dispose() {
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    _loadedAds.clear();
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      if (_feedController.hasLocalCache &&
          _feedController.cachedPosts.isNotEmpty) {
        print('🔄 [COMMUNITY] App resumed, performing silent feed refresh');
        unawaited(_feedController.silentBackgroundRefresh());
      }
    }
  }

  /// Check if current user is admin
  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      final isAdmin = doc.exists && doc.data()?['role'] == 'admin';
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
      debugPrint('🔐 Admin status: $isAdmin');
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
    }
  }

  Future<void> _loadPosts() async {
    // Try Firebase first
    User? user = FirebaseAuth.instance.currentUser;

    // If Firebase is ready, use it immediately
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
        _profileExists = true; // Profile exists if we have user ID
      });
      unawaited(_loadUserProfile());
      await _feedController.fetchInitialPosts();
      return;
    }

    // Fallback: try to get cached user ID from SharedPreferences
    final storage = AuthStateStorage();
    await storage.init();
    final cachedUid = await storage.getLastUid();
    if (cachedUid != null) {
      print('✅ [COMMUNITY] Using cached user ID: $cachedUid');
      setState(() {
        currentUserId = cachedUid;
        _profileExists = true; // Profile exists if we have user ID
      });
      // Try to load profile from cache
      final cached = await storage.getCachedProfile();
      if (cached != null) {
        setState(() {
          currentUserName = cached['user_name'] ?? 'Farmer';
          currentUserProfilePic = cached['profile_pic'] ?? '';
        });
      }
      _feedController.fetchInitialPosts();
      return;
    }

    print('❌ [COMMUNITY] No user ID found anywhere');

    // Ensure cached feed is attempted even when no user ID is available.
    // This lets the app show locally cached posts instantly when offline.
    try {
      await _feedController.fetchInitialPosts();
    } catch (e) {
      print('⚠️ [COMMUNITY] Failed to load cached posts: $e');
    }
  }

  final FirebaseMarketplaceService _marketplaceService =
      FirebaseMarketplaceService.instance;
  final AuthController _authController = AuthController();

  String? currentUserName;
  String? currentUserProfilePic;

  bool _isLoadingProfile = true;
  bool _profileExists = false;

  Future<void> _loadUserProfile() async {
    // Use currentUserId (from cache or auth) instead of _authController.currentUser
    // which may be null during internet reconnection
    final userId = currentUserId ?? _authController.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(userId)
        .get();

    if (!mounted) return;
    if (currentUserId != userId ||
        FirebaseAuth.instance.currentUser?.uid != userId) {
      return;
    }

    setState(() {
      currentUserId = userId;
      if (doc.exists) {
        final data = doc.data()!;
        currentUserName = data['user_name'] ?? 'Farmer';
        currentUserProfilePic = data['profile_pic'] ?? '';
        _profileExists = true;
      } else {
        _profileExists = false;
      }
      _isLoadingProfile = false;
    });

    // Cache minimal profile securely for optimistic startup next time
    try {
      final storage = AuthStateStorage();
      await storage.saveCachedProfile(
        uid: userId,
        userName: currentUserName,
        profilePic: currentUserProfilePic,
      );
    } catch (_) {
      // ignore cache errors
    }

    // 🔥 Cache FULL profile to Hive for dashboard/tools offline support
    if (doc.exists) {
      try {
        await ProfileCacheService.cacheProfile(userId, doc.data()!);
        print('✅ [COMMUNITY] Cached full profile to Hive for offline use');
      } catch (e) {
        print('⚠️ [COMMUNITY] Failed to cache full profile: $e');
      }
    }
  }

  Future<void> _loadCachedProfile() async {
    try {
      final authenticatedUser =
          FirebaseAuth.instance.currentUser ??
          await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
      final storage = AuthStateStorage();
      await storage.init();
      final cached = await storage.getCachedProfile();
      if (cached != null && mounted) {
        final authenticatedUid = authenticatedUser?.uid;
        final cachedUid = cached['uid'];
        if (authenticatedUid == null || cachedUid != authenticatedUid) {
          return;
        }
        setState(() {
          currentUserId = cached['uid'];
          currentUserName = (cached['user_name']?.isNotEmpty ?? false)
              ? cached['user_name']
              : currentUserName;
          currentUserProfilePic = (cached['profile_pic']?.isNotEmpty ?? false)
              ? cached['profile_pic']
              : currentUserProfilePic;
          _profileExists = true;
          _isLoadingProfile = false;
        });
        _feedController.fetchInitialPosts();
      } else {
        // No full cache - try to get just the user ID
        final fallbackUid = await storage.getLastUid();
        if (fallbackUid != null && mounted) {
          setState(() {
            currentUserId = fallbackUid;
            _profileExists = true; // Profile exists if we have user ID
            _isLoadingProfile = false;
          });
          // Try to load full profile from Firestore
          _loadProfileFromFirestore();
        } else if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted && _isLoadingProfile) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Load profile from Firestore when we have user ID but no cache
  Future<void> _loadProfileFromFirestore() async {
    if (currentUserId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUserId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          currentUserName = data['user_name'] ?? data['name'] ?? 'Farmer';
          currentUserProfilePic =
              data['profile_pic'] ?? data['profile_image_url'];
          _profileExists = true;
        });
        // Save to cache for next time
        final storage = AuthStateStorage();
        await storage.saveCachedProfile(
          uid: currentUserId!,
          userName: currentUserName,
          profilePic: currentUserProfilePic,
        );
      }
    } catch (e) {
      // Silently handle errors
      print('Error loading profile from Firestore: $e');
    }
  }

  // Preload images for next post to appear instantly while scrolling
  void _preloadPostImages(BuildContext context, Post post) {
    // Preload post media images
    for (final media in post.media) {
      if (media.type == 'image') {
        final provider = CachedNetworkImageProvider(media.url);
        precacheImage(provider, context).catchError((e) {
          // Silently handle preload errors
        });
      }
    }

    // Preload profile picture
    if (post.authorAvatar.isNotEmpty) {
      final provider = CachedNetworkImageProvider(post.authorAvatar);
      precacheImage(provider, context).catchError((e) {
        // Silently handle preload errors
      });
    }
  }

  Widget _buildHomeTab() {
    // 🔑 ONE decision point, made synchronously, before anything else
    final bool hasCache = shouldUseCachedFeed(
      hasCachedPosts: _feedController.cachedPosts.isNotEmpty,
      hasLocalCache: _feedController.hasLocalCache,
    );
    final bool isLoadingPosts = _feedController.isInitialLoading;

    debugPrint(
      '🏠🏠🏠 hasCache=$hasCache count=${_feedController.cachedPosts.length} isLoading=$isLoadingPosts isLoadingProfile=$_isLoadingProfile',
    );

    // Show loading state with offline indicator only when we truly do not have any cached feed.
    if (shouldShowSkeletonLoader(
      isLoadingProfile: _isLoadingProfile,
      hasCachedPosts: _feedController.cachedPosts.isNotEmpty,
      hasLocalCache: _feedController.hasLocalCache,
      isInitialLoading: isLoadingPosts,
    )) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PostSkeleton(),
              PostSkeleton(),
              PostSkeleton(),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Loading offline feed...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_profileExists && !hasCache) {
      return const Center(
        child: Text(
          "Your farmer profile is missing.\nFeed cannot load.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              GestureDetector(
                onTap: currentUserId == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerProfileScreen(
                            userId: currentUserId!,
                            currentUserId: currentUserId!,
                          ),
                        ),
                      ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      currentUserProfilePic != null &&
                          currentUserProfilePic!.isNotEmpty
                      ? NetworkImage(currentUserProfilePic!)
                      : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: currentUserId == null
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                              ),
                              child: PostCreationWidget(
                                userId: currentUserId!,
                                communityName: 'Farmers Community',
                              ),
                            ),
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Share your farming advice?",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: hasCache
              ? _buildFeedList(_feedController.cachedPosts)
              : _buildLiveFeed(),
        ),
      ],
    );
  }

  // Renders the actual scrollable post list — used for BOTH cached and live data
  Widget _buildFeedList(List<Post> initialPosts) {
    return StreamBuilder<List<Post>>(
      stream: _feedController.postsStream,
      initialData: initialPosts,
      builder: (context, snapshot) {
        final posts = (snapshot.data?.isNotEmpty ?? false)
            ? snapshot.data!
            : initialPosts;

        if (posts.isEmpty) {
          return const SizedBox.shrink(); // never show "No posts yet" text
        }

        return _buildPostListView(posts);
      },
    );
  }

  // Used ONLY when there was no cache at all — first-ever app open or offline with no cache
  Widget _buildLiveFeed() {
    return StreamBuilder<List<Post>>(
      stream: _feedController.postsStream,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          // 📱 OFFLINE CHECK: Show appropriate message based on connectivity
          return FutureBuilder<bool>(
            future: _checkConnectivity(),
            builder: (context, connSnapshot) {
              final isOnline = connSnapshot.data ?? true;

              if (!isOnline) {
                // User is offline with NO cached posts
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Internet Connection',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No cached posts available. Connect to the internet to load the community feed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // User is online but no posts loaded yet - show skeleton loaders
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: 5,
                itemBuilder: (_, __) => const PostSkeleton(),
              );
            },
          );
        }

        return _buildPostListView(posts);
      },
    );
  }

  /// Check current connectivity status
  Future<bool> _checkConnectivity() async {
    final connectivityService = ConnectivityService();
    return connectivityService.isOnline;
  }

  // Shared ListView builder used by both cached and live flows
  Widget _buildPostListView(List<Post> posts) {
    if (posts.isEmpty) return const SizedBox.shrink();

    final visiblePosts = posts.toList();
    _scheduleAdPreload(0, visiblePosts.length);

    return StreamBuilder<bool>(
      stream: _feedController.newPostsAvailableStream,
      builder: (context, newPostsSnapshot) {
        final showNewPostsBanner =
            newPostsSnapshot.data == true ||
            _feedController.hasPendingNewPosts;

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification) {
                  final estimatedPostIndex = (n.metrics.pixels / 280).floor();
                  _preloadAdsForPostIndex(estimatedPostIndex, visiblePosts.length);
                }
                final max = n.metrics.maxScrollExtent;
                final pos = n.metrics.pixels;
                final shouldPrefetch = (max - pos) < 800;

                if (shouldPrefetch) {
                  unawaited(_feedController.fetchMorePosts());
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  await _feedController.refreshPosts();
                },
                child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              cacheExtent: 1200.0,
              itemCount:
                  visiblePosts.length +
                  _adCountForPostCount(visiblePosts.length),
              itemBuilder: (context, index) {
                final adSlot = _adSlotForListIndex(index, visiblePosts.length);
                if (adSlot != null) {
                  return AdBannerWidget(ad: _loadedAds[adSlot]);
                }

                final adCount = _adCountBeforeListIndex(
                  index,
                  visiblePosts.length,
                );
                final postIndex = index - adCount;

                if (postIndex >= visiblePosts.length) {
                  return const SizedBox.shrink();
                }

                final post = visiblePosts[postIndex];

                if (postIndex == visiblePosts.length - 2) {
                  _preloadPostImages(context, visiblePosts[postIndex + 1]);
                }

                final userData = _feedController.getUserData(post.authorId);
                final isVerified =
                    userData['isVerified'] == true ||
                    _feedController.isUserVerified(post.authorId);
                final verificationStatus =
                    (userData['verificationStatus'] ?? '').toString();
                final verificationPaid = userData['verificationPaid'] == true;
                final paidAtRaw =
                    userData['verificationPaidAt'] ??
                    userData['verificationPaidat'];
                bool paymentExpired = true;
                paymentExpired = isVerificationPaymentExpired(paidAtRaw);

                final bool isActiveBoost =
                    post.isBoosted &&
                    post.boostEndDate != null &&
                    post.boostEndDate!.isAfter(DateTime.now());
                final userId = currentUserId ?? '';

                return OptimizedPostCard(
                  key: ValueKey(post.id),
                  post: {
                    'userId': post.authorId,
                    'authorId': post.authorId,
                    'authorName': post.authorName,
                    'authorAvatar': post.authorAvatar,
                    'isBoosted': isActiveBoost,
                    'boostEndDate': post.boostEndDate,
                    'verified': isVerified,
                    'verificationStatus': verificationStatus,
                    'verificationPaid': verificationPaid,
                    'paymentExpired': paymentExpired,
                    'content': post.content,
                    'media': post.media.map((m) => m.toJson()).toList(),
                    'created_at': post.createdAt,
                    'likes': post.analytics.likesCount,
                    'likesList': post.likes,
                    'comments': post.analytics.commentsCount > 0
                        ? post.analytics.commentsCount
                        : post.comments.length,
                    'commentsCount': post.analytics.commentsCount > 0
                        ? post.analytics.commentsCount
                        : post.comments.length,
                    'commentsList': post.comments,
                    'reactionsCount': post.analytics.reactionsCount,
                    'reactionEmojiCounts': post.analytics.reactionEmojiCounts,
                    'reactions': post.reactions,
                    'feelingTag': post.feelingTag,
                    'locationTag': post.locationTag,
                    'isLiked': post.likes.contains(userId),
                    'isPinned': post.isPinned,
                    'active': post.active,
                    'status': post.status.name,
                  },
                  postId: post.id,
                  currentUserId: userId,
                  onLike: currentUserId == null
                      ? null
                      : () {
                          _feedController.toggleLike(post.id, userId);
                        },
                  onComment: currentUserId == null
                      ? null
                      : () {
                          final authorName = post.authorName.trim().isNotEmpty
                              ? post.authorName.trim()
                              : 'Farmer';
                          final possessive =
                              authorName.toLowerCase().endsWith('s')
                              ? "$authorName' post"
                              : "$authorName's post";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  elevation: 0.5,
                                  leading: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Comment $possessive',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.eco_rounded,
                                        color: Color(0xFF81C784),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                      ),
                                      onSelected: (value) {},
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'refresh',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.refresh,
                                                size: 18,
                                                color: Color(0xFF2E7D32),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Refresh'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                body: SingleChildScrollView(
                                  child: CommentSection(
                                    postId: post.id,
                                    currentUserId: userId,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                  onShare: currentUserId == null ? null : () {},
                  onDelete: () {},
                  onEdit: () {},
                  onRefreshPost: () {
                    _feedController.refreshSinglePost(post.id);
                  },
                  showViolationBanners: false,
                  showStats: true,
                );
              },
                ),
              ),
            ),
            if (showNewPostsBanner)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await _feedController.applyPendingNewPosts();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/reactions/new_posts.png',
                          height: 52,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _scheduleAdPreload(int postIndex, int postCount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadAdsForPostIndex(postIndex, postCount);
      }
    });
  }

  void _preloadAdsForPostIndex(int postIndex, int postCount) {
    if (!AdManager.instance.adsEnabled || postCount < _adIntervals.first) {
      return;
    }

    final adSlotCount = _adCountForPostCount(postCount);
    final currentSlot = _adCountThroughPostIndex(postIndex);
    final slotsToKeep = <int>{};

    // Preload surrounding slots bidirectionally (past slots for upward scroll, forward for downward)
    final minSlot = (currentSlot - 2).clamp(0, adSlotCount);
    final maxSlot = (currentSlot + 3).clamp(0, adSlotCount);

    for (var slot = minSlot; slot < maxSlot; slot++) {
      slotsToKeep.add(slot);
      _preloadAdForIndex(slot);
    }

    // Only dispose ads far outside the active viewport neighborhood
    for (final slot in _loadedAds.keys.toList()) {
      if (!slotsToKeep.contains(slot) && (slot - currentSlot).abs() > 6) {
        _loadedAds.remove(slot)?.dispose();
      }
    }
  }

  int _adPositionForSlot(int slot) {
    var postPosition = 0;
    for (var currentSlot = 0; currentSlot <= slot; currentSlot++) {
      postPosition += _adIntervals[currentSlot % _adIntervals.length];
    }
    return postPosition;
  }

  int _adCountForPostCount(int postCount) {
    var count = 0;
    while (_adPositionForSlot(count) <= postCount) {
      count++;
    }
    return count;
  }

  int _adCountThroughPostIndex(int postIndex) {
    var count = 0;
    while (_adPositionForSlot(count) <= postIndex) {
      count++;
    }
    return count;
  }

  int? _adSlotForListIndex(int listIndex, int postCount) {
    final adSlotCount = _adCountForPostCount(postCount);
    for (var slot = 0; slot < adSlotCount; slot++) {
      final adListIndex = _adPositionForSlot(slot) + slot;
      if (adListIndex == listIndex) return slot;
      if (adListIndex > listIndex) break;
    }
    return null;
  }

  int _adCountBeforeListIndex(int listIndex, int postCount) {
    final adSlotCount = _adCountForPostCount(postCount);
    var count = 0;
    for (var slot = 0; slot < adSlotCount; slot++) {
      if (_adPositionForSlot(slot) + slot < listIndex) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> _preloadAdForIndex(int index) async {
    if (_loadedAds.containsKey(index) ||
        _loadingAdSlots.contains(index) ||
        _loadingAdSlots.length >= _maxConcurrentAdLoads) {
      return;
    }

    _loadingAdSlots.add(index);
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          Orientation.portrait,
          width,
        );

    if (size == null || !mounted) {
      _loadingAdSlots.remove(index);
      return;
    }

    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ [AdMob] Banner Ad loaded successfully for slot $index (Ad Unit: ${ad.adUnitId})');
          _loadingAdSlots.remove(index);
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loadedAds[index] = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('⚠️ [AdMob] Banner Ad failed to load for slot $index: Code ${error.code} - ${error.message}');
          debugPrint('📱 [AdMob] Domain: ${error.domain} | ResponseInfo: ${error.responseInfo}');
          _loadingAdSlots.remove(index);
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('📱 [AdMob] Banner Ad opened for slot $index'),
        onAdClosed: (ad) => debugPrint('📱 [AdMob] Banner Ad closed for slot $index'),
        onAdImpression: (ad) => debugPrint('📱 [AdMob] Banner Ad impression for slot $index'),
      ),
    );
    debugPrint('📱 [AdMob] Requesting banner ad for slot $index with adUnitId: $_adUnitId');
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isAdmin ? 'Admin Dashboard' : 'Farmers Community'),
        centerTitle: true,
        backgroundColor: _isAdmin
            ? Colors.purple.shade700
            : Colors.green.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: currentUserId == null ? Colors.grey.shade300 : null,
            ),
            onPressed: currentUserId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SearchScreen(currentUserId: currentUserId!),
                      ),
                    );
                  },
          ),
          // Notifications icon with live unread count badge
          StreamBuilder<int>(
            stream: _isAdmin
                ? NotificationService().streamAdminUnreadCount()
                : NotificationService().streamUnreadCount(
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications,
                      color: _isAdmin ? Colors.purple.shade100 : null,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isAdmin ? Colors.purple : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'about') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutAgriBaseScreen(),
                  ),
                );
              } else if (value == 'privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen(),
                  ),
                );
              } else if (value == 'academy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AcademyScreen(),
                  ),
                );
              } else if (value == 'admin_academy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AcademyManagerScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: 'academy',
                  child: Text('🎓 Farming Academy'),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: Text('🌱 About AgriBase'),
                ),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Text('🔒 Privacy & Settings'),
                ),
              ];

              if (_isAdmin) {
                items.add(
                  const PopupMenuItem(
                    value: 'admin_academy',
                    child: Text('🎓 Academy Manager'),
                  ),
                );
              }

              return items;
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildHomeTab(), // 0 Home
          currentUserId != null
              ? ChatListScreen(currentUserId: currentUserId!)
              : const Center(child: Text('Chat unavailable until sign in.')),
          const DashboardToolScreen(), // 2 Tools
          MarketplaceHomePage(
            marketplaceService: _marketplaceService,
          ), // 3 Market
          currentUserId != null
              ? FarmerProfileScreen(
                  userId: currentUserId!,
                  currentUserId: currentUserId!,
                )
              : const Center(child: Text('Profile unavailable until sign in.')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: currentUserId == null
            ? (i) {
                if (i == 0) return;
              }
            : (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: currentUserId == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: currentUserId)
                        .snapshots(),
              builder: (context, snapshot) {
                var unreadCount = 0;
                for (final doc in snapshot.data?.docs ?? []) {
                  final unreadMap = doc.data()['unreadCount'];
                  if (unreadMap is Map) {
                    final unread = unreadMap[currentUserId] ?? 0;
                    unreadCount += unread is num ? unread.toInt() : 0;
                  }
                }

                final iconColor = currentIndex == 1
                    ? Colors.green
                    : Colors.grey[600];
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 24, color: iconColor),
                    if (unreadCount > 0)
                      Positioned(
                        right: -10,
                        top: -8,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
