import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/utils/verification_helpers.dart';

import 'farmer_model.dart';
import '../../widgets/optimized_post_card.dart';
import '../../widgets/comment_section.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/ad_banner_widget.dart';
import 'farmer_about_screen.dart';
import '../../services/marketplace/firebase_marketplace_service_impl.dart';
import '../../services/ad_manager.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final FarmerModel? initialFarmer;

  const FarmerProfileScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.initialFarmer,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  bool isLoading = true;
  String? error;
  FarmerModel? _cachedFarmer;
  late final Stream<QuerySnapshot> _pinnedPostsStream;
  late final Stream<QuerySnapshot> _regularPostsStream;
  
  // AdMob integration
  final Map<int, BannerAd> _loadedAds = {};
  final Set<int> _loadingAdSlots = {};
  static const _maxConcurrentAdLoads = 3;
  static String get _adUnitId => AdManager.bannerAdUnitId;
  // First ad on second post (index 1), then space 8-10 posts
  static const _adIntervals = [1, 8, 9, 10];

  @override
  void initState() {
    super.initState();
    print('🔍 [PROFILE_SCREEN] Loading profile for userId: ${widget.userId}, currentUserId: ${widget.currentUserId}');
    // If caller provided an initial typed FarmerModel, use it immediately
    if (widget.initialFarmer != null) {
      _cachedFarmer = widget.initialFarmer;
      isLoading = false;
    }
    // Load cached profile (or overwrite if fresher cache exists)
    _loadCachedProfile();
    // Cache streams so they don't recreate on rebuilds
    // If the current user is viewing their own profile, include all posts
    // (including moderated/ inactive) so the owner can see full data.
    if (widget.userId == widget.currentUserId) {
      _pinnedPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .where('isPinned', isEqualTo: true)
        .orderBy('pinnedAt', descending: true)
        .snapshots();

      _regularPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .orderBy('created_at', descending: true)
        .snapshots();
    } else {
      // When viewing someone else's profile, only show active posts
      _pinnedPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .where('isPinned', isEqualTo: true)
        .where('active', isEqualTo: true)
        .orderBy('pinnedAt', descending: true)
        .snapshots();

      _regularPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: widget.userId)
        .where('active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots();
    }
  }

  @override
  void dispose() {
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    _loadedAds.clear();
    super.dispose();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('profile_${widget.userId}');
      if (cachedJson != null) {
        final cachedData = json.decode(cachedJson) as Map<String, dynamic>;
        setState(() {
          _cachedFarmer = FarmerModel.fromMap(cachedData, widget.userId);
        });
        print('✅ [PROFILE] Loaded cached profile instantly');
      }
    } catch (e) {
      print('❌ [PROFILE] Error loading cached profile: $e');
    }
  }

  /// Convert Firestore data to JSON-serializable format (handles Timestamps)
  Map<String, dynamic> _convertToJsonSafe(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is GeoPoint) {
        result[key] = {'latitude': value.latitude, 'longitude': value.longitude};
      } else if (value is DocumentReference) {
        result[key] = value.path;
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertToJsonSafe(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map<String, dynamic>) return _convertToJsonSafe(item);
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _saveProfileToCache(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonSafeData = _convertToJsonSafe(profileData);
      await prefs.setString('profile_${widget.userId}', json.encode(jsonSafeData));
      print('✅ [PROFILE] Saved profile to cache');
    } catch (e) {
      print('❌ [PROFILE] Error saving profile to cache: $e');
    }
  }

  void _refreshFarmerPosts() {
    // Force rebuild by calling setState which will trigger StreamBuilder to rebuild
    setState(() {});
  }

  // AdMob positioning logic
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
    final firstSlot = _adCountThroughPostIndex(postIndex);
    final slotsToKeep = <int>{};

    for (
      var slot = firstSlot;
      slot < adSlotCount && slotsToKeep.length < 3;
      slot++
    ) {
      slotsToKeep.add(slot);
      _preloadAdForIndex(slot);
    }

    for (final slot in _loadedAds.keys.toList()) {
      if (!slotsToKeep.contains(slot) && (slot - firstSlot).abs() > 3) {
        _loadedAds.remove(slot)?.dispose();
      }
    }
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
          debugPrint('✅ [AdMob Profile] Banner Ad loaded successfully for slot $index (Ad Unit: ${ad.adUnitId})');
          _loadingAdSlots.remove(index);
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loadedAds[index] = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('⚠️ [AdMob Profile] Banner Ad failed to load for slot $index: Code ${error.code} - ${error.message}');
          debugPrint('📱 [AdMob Profile] Domain: ${error.domain} | ResponseInfo: ${error.responseInfo}');
          _loadingAdSlots.remove(index);
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('📱 [AdMob Profile] Banner Ad opened for slot $index'),
        onAdClosed: (ad) => debugPrint('📱 [AdMob Profile] Banner Ad closed for slot $index'),
        onAdImpression: (ad) => debugPrint('📱 [AdMob Profile] Banner Ad impression for slot $index'),
      ),
    );
    debugPrint('📱 [AdMob Profile] Requesting banner ad for slot $index with adUnitId: $_adUnitId');
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        FarmerModel? farmer;
        
        // Use cached profile instantly (like WhatsApp)
        if (_cachedFarmer != null) {
          farmer = _cachedFarmer;
        }
        
        // Update with Firestore data when available
        if (snapshot.hasData && snapshot.data!.exists) {
          final firestoreData = snapshot.data!.data() as Map<String, dynamic>;
          farmer = FarmerModel.fromMap(firestoreData, widget.userId);
          // Save to cache for next time
          _saveProfileToCache(firestoreData);
        }

        if (snapshot.connectionState == ConnectionState.waiting && farmer == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (farmer == null) {
          return const Scaffold(body: Center(child: Text("Profile not found")));
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FarmerProfileHeader(
                  farmer: farmer,
                  currentUserId: widget.currentUserId,
                  onToggleFollow: () {},
                  marketplaceService: FirebaseMarketplaceService.instance,
                ),
              ),

              const SliverToBoxAdapter(child: Divider()),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerAboutScreen(farmer: farmer!),
                        ),
                      );
                    },
                    child: const Text(
                      "About Farmer's Info",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Divider()),

              // 📌 PINNED POSTS SECTION
              StreamBuilder<QuerySnapshot>(
                stream: _pinnedPostsStream,
                builder: (context, snapshot) {
                  debugPrint(
                    '📌 PINNED POSTS BUILD: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, docs=${snapshot.data?.docs.length ?? 0}',
                  );
                  if (snapshot.hasError) {
                    debugPrint('❌ PINNED POSTS ERROR: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  // Handle errors (e.g., missing Firestore index)
                  if (snapshot.hasError) {
                    debugPrint('❌ PINNED POSTS ERROR: ${snapshot.error}');
                    // Print full error to console so user can click the index URL
                    debugPrint(
                      '❌ FULL ERROR DETAILS: ${snapshot.error.toString()}',
                    );
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading pinned: ${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }

                  final pinnedPosts = snapshot.data?.docs ?? [];
                  debugPrint('📌 PINNED POSTS COUNT: ${pinnedPosts.length}');
                  for (var doc in pinnedPosts) {
                    final data = doc.data() as Map<String, dynamic>;
                    debugPrint(
                      '  - Post ${doc.id}: isPinned=${data['isPinned']}, active=${data['active']}, authorId=${data['authorId']}',
                    );
                  }

                  if (pinnedPosts.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                color: Colors.purple.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pinned Posts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${pinnedPosts.length} pinned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...pinnedPosts.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('farmers')
                                .doc(data['authorId'] ?? '')
                                .get(),
                            builder: (context, userSnapshot) {
                              bool isVerified = false;
                              String verificationStatus = '';
                              bool verificationPaid = false;
                              bool paymentExpired = true;

                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                if (userData != null) {
                                  isVerified = userData['isVerified'] == true;
                                  verificationStatus =
                                      userData['verificationStatus'] ?? '';
                                  verificationPaid =
                                      userData['verificationPaid'] == true;
                                  final paidAtRaw = userData['verificationPaidAt'] ?? 
                                      userData['verificationPaidat'];
                                  // Use the same helper function as other screens for consistency
                                  paymentExpired = isVerificationPaymentExpired(paidAtRaw);
                                }
                              }

                              return OptimizedPostCard(
                                key: ValueKey('pinned_${doc.id}'),
                                post: {
                                  'userId': data['authorId'] ?? '',
                                  'authorId': data['authorId'] ?? '',
                                  'authorName': data['authorName'] ?? 'Unknown',
                                  'authorAvatar': data['authorAvatar'] ?? '',
                                  'verified': isVerified,
                                  'verificationStatus': verificationStatus,
                                  'verificationPaid': verificationPaid,
                                  'paymentExpired': paymentExpired,
                                  'content': data['content'] ?? '',
                                  'media': data['media'] ?? [],
                                  'imageUrl': data['imageUrl'] ?? '',
                                  'created_at': data['created_at'] is Timestamp
                                      ? (data['created_at'] as Timestamp)
                                            .toDate()
                                      : DateTime.now(),
                                  'likes': data['likes']?.length ?? 0,
                                  'comments': data['comments']?.length ?? 0,
                                  'reactionsCount':
                                      data['analytics']?['reactionsCount'] ?? 0,
                                  'reactionEmojiCounts':
                                      data['analytics']?['reactionEmojiCounts'] ??
                                      {},
                                  'feelingTag': data['feeling_tag'],
                                  'locationTag': data['location_tag'],
                                  'isLiked':
                                      data['likes']?.contains(
                                        widget.currentUserId,
                                      ) ??
                                      false,
                                  'active': data['active'] ?? true,
                                  'status': data['status'] ?? 'active',
                                  'isPinned': true,
                                  'isBoosted': data['isBoosted'] ?? false,
                                  'boostEndDate': data['boostEndDate'],
                                },
                                postId: doc.id,
                                currentUserId: widget.currentUserId,
                                onLike: () {},
                                onComment: () {
                                  final authorName =
                                      (data['authorName'] as String? ?? '')
                                          .trim()
                                          .isNotEmpty
                                      ? data['authorName']!.trim()
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
                                          backgroundColor:
                                              const Color(0xFF2E7D32),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                        color:
                                                            Color(0xFF2E7D32),
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
                                            postId: doc.id,
                                            currentUserId: widget.currentUserId,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                onShare: () {},
                                showViolationBanners: true,
                                hideStatsForReports: false,
                              );
                            },
                          );
                        }).toList(),
                        const Divider(),
                      ],
                    ),
                  );
                },
              ),

              // REGULAR POSTS - Use cached stream
              StreamBuilder<QuerySnapshot>(
                stream: _regularPostsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Handle Firestore index errors
                  if (snapshot.hasError) {
                    debugPrint('❌ REGULAR POSTS ERROR: ${snapshot.error}');
                    // If index error, try fallback query without orderBy
                    if (snapshot.error.toString().contains(
                          'FAILED_PRECONDITION',
                        ) ||
                        snapshot.error.toString().contains('index')) {
                      return _buildFallbackPostsList();
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text("Error loading posts"),
                            Text(
                              "${snapshot.error}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildPostsList(snapshot.data?.docs ?? []);
                },
              ),

              /// 👇 COMMENTS AS SEPARATE SLIVERS
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return const SizedBox.shrink();
                }, childCount: 0),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fallback for when Firestore index is missing - simple query without orderBy
  Widget _buildFallbackPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildPostsList(snapshot.data?.docs ?? []);
      },
    );
  }

  /// Build the actual posts list with filtering
  Widget _buildPostsList(List<QueryDocumentSnapshot> docs) {
    // Filter: ONLY exclude pinned posts AND posts the farmer themselves deleted
    // For other users viewing the profile, also exclude community hidden posts
    final posts = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isPinned = data['isPinned'] as bool? ?? false;
      final deletedBy = data['deletedBy'] as String?;
      final authorId = data['authorId'] as String?;
      final communityHidden = data['communityHidden'] as bool? ?? false;
      final isOwnProfile = widget.userId == widget.currentUserId;

      // Exclude: pinned posts (they have their own section)
      // Exclude: posts deleted BY THE OWNER themselves
      // Exclude: community hidden posts when viewing other users' profiles
      return !isPinned && 
             deletedBy != authorId && 
             (isOwnProfile || !communityHidden);
    }).toList();

    // Sort by created_at descending (client-side if using fallback)
    posts.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['created_at'] as Timestamp?;
      final bTime = bData['created_at'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No posts yet"),
        ),
      );
    }

    // Schedule ad preloading
    _scheduleAdPreload(0, posts.length);

    final totalItemCount = posts.length + _adCountForPostCount(posts.length);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Check if this index should show an ad
        final adSlot = _adSlotForListIndex(index, posts.length);
        if (adSlot != null) {
          return AdBannerWidget(ad: _loadedAds[adSlot]);
        }

        // Calculate the actual post index
        final adCount = _adCountBeforeListIndex(index, posts.length);
        final postIndex = index - adCount;

        if (postIndex >= posts.length) {
          return const SizedBox.shrink();
        }

        final doc = posts[postIndex];
        final data = doc.data() as Map<String, dynamic>;

        // DEBUG: Log post status for profile
        debugPrint(
          '🔍 PROFILE POST DEBUG: Post ${doc.id} - active=${data['active']}, status="${data['status']}"',
        );

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('farmers')
              .doc(data['authorId'] ?? '')
              .get(),
          builder: (context, userSnapshot) {
            // Get user verification data
            bool isVerified = false;
            String verificationStatus = '';
            bool verificationPaid = false;
            bool paymentExpired = true;

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null) {
                isVerified = userData['isVerified'] == true;
                verificationStatus = userData['verificationStatus'] ?? '';
                verificationPaid = userData['verificationPaid'] == true;

                final paidAtRaw = userData['verificationPaidAt'] ??
                    userData['verificationPaidat'];
                paymentExpired = isVerificationPaymentExpired(paidAtRaw);
              }
            }

            return OptimizedPostCard(
              key: ValueKey(doc.id),
              post: {
                'userId': data['authorId'] ?? '',
                'authorId': data['authorId'] ?? '',
                'authorName': data['authorName'] ?? 'Unknown',
                'authorAvatar': data['authorAvatar'] ?? '',
                'verified': isVerified,
                'verificationStatus': verificationStatus,
                'verificationPaid': verificationPaid,
                'paymentExpired': paymentExpired,
                'content': data['content'] ?? '',
                'media': data['media'] ?? [],
                'imageUrl': data['imageUrl'] ?? '',
                'created_at': data['created_at'] is Timestamp
                    ? (data['created_at'] as Timestamp).toDate()
                    : DateTime.now(),
                'likes': data['likes']?.length ?? 0,
                'comments': data['comments']?.length ?? 0,
                'reactionsCount': data['analytics']?['reactionsCount'] ?? 0,
                'reactionEmojiCounts':
                    data['analytics']?['reactionEmojiCounts'] ?? {},
                'feelingTag': data['feeling_tag'],
                'locationTag': data['location_tag'],
                'isLiked':
                    data['likes']?.contains(widget.currentUserId) ?? false,
                'active': data['active'] ?? true,
                'status': data['status'] ?? 'active',
                'communityHidden': data['communityHidden'] ?? false,
                'community_hidden': data['communityHidden'] ?? false,
                'moderationStatus': data['moderationStatus'] ?? '',
                'moderation_status': data['moderationStatus'] ?? '',
                'is_under_review': data['is_under_review'] ?? false,
                'isUnderReview': data['is_under_review'] ?? false,
                'isPinned': data['isPinned'] ?? false,
                'isBoosted': data['isBoosted'] ?? false,
                'boostEndDate': data['boostEndDate'],
              },
              postId: doc.id,
              currentUserId: widget.currentUserId,
              onLike: () {},
              onComment: () {
                final authorName =
                    (data['authorName'] as String? ?? '').trim().isNotEmpty
                    ? data['authorName']!.trim()
                    : 'Farmer';
                final possessive = authorName.toLowerCase().endsWith('s')
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
                          onPressed: () => Navigator.of(context).pop(),
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
                          postId: doc.id,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
                  ),
                );
              },
              onShare: () {},
              showViolationBanners: true,
              hideStatsForReports: false,
            );
          },
        );
      }, childCount: totalItemCount),
    );
  }
}
