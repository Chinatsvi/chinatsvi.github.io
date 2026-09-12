import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import 'package:agribased/services/optimized_user_service.dart';
import 'package:agribased/services/verification_cache_service.dart';
import 'package:agribased/widgets/full_screen_image_viewer.dart';
import 'package:agribased/screens/profile/farmer_profile_screen.dart';
import 'package:agribased/widgets/stable_follow_button.dart';
import 'package:agribased/widgets/collapsible_post.dart';
import 'package:agribased/widgets/post_stats_row.dart';
import 'package:agribased/widgets/user_info_display.dart';
import 'package:agribased/models/post_model.dart';
import 'package:agribased/screens/community/report_post_page.dart';
import 'package:agribased/screens/location_screen.dart';
import 'package:agribased/screens/post/edit_post_screen.dart';
import 'package:agribased/screens/post/post_analytics_screen.dart';
import 'package:agribased/screens/post/boost_objective_page.dart';
import 'package:agribased/screens/marketplace/item_details_page.dart';
import 'package:agribased/services/marketplace/cart_service.dart';
import 'package:agribased/screens/marketplace/cart_screen.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/firebase_marketplace_service.dart';
import 'package:agribased/widgets/comment_section.dart';
import 'package:agribased/app/utils/formatters.dart';

class OptimizedPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final String currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onRefreshPost;
  final bool showStats;
  final bool showViolationBanners;
  final bool hideStatsForReports;

  const OptimizedPostCard({
    super.key,
    required this.post,
    required this.postId,
    required this.currentUserId,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onDelete,
    this.onEdit,
    this.onRefreshPost,
    this.showStats = true,
    this.showViolationBanners = true,
    this.hideStatsForReports = false,
  });

  /// Public method to clear profile cache for a specific user
  /// Delegates to OptimizedUserCache for centralized cache management
  static void clearProfileCache(String userId) {
    OptimizedUserCache.clearUserCache(userId);
  }

  /// Public method to clear ALL profile cache
  /// Delegates to OptimizedUserCache for centralized cache management
  static void clearAllProfileCache() {
    OptimizedUserCache.clearCache();
  }

  @override
  State<OptimizedPostCard> createState() => _OptimizedPostCardState();
}

Map<String, dynamic> resolveMarketplaceCartPayload(
  Map<String, dynamic> post, {
  required String marketplaceId,
  required String primaryImage,
}) {
  final embedded = post['marketplaceItem'] is Map
      ? Map<String, dynamic>.from(post['marketplaceItem'] as Map)
      : <String, dynamic>{};

  final title =
      (embedded['title'] ?? post['title'] ?? post['authorName'] ?? 'Item')
          .toString();
  final price = embedded['price'] ?? post['price'] ?? 0;
  final currency =
      (embedded['currencySymbol'] ??
              embedded['currency'] ??
              post['currencySymbol'] ??
              post['currency'] ??
              'ZAR')
          .toString();
  final sellerId =
      (embedded['sellerId'] ?? post['sellerId'] ?? post['authorId'] ?? '')
          .toString();

  return {
    'itemId': marketplaceId,
    'sellerId': sellerId,
    'title': title,
    'price': price is num
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0.0,
    'image': primaryImage,
    'quantity': 1,
    'currencySymbol': currency,
    'currency': currency,
    'addedAt': DateTime.now().toIso8601String(),
  };
}

class _OptimizedPostCardState extends State<OptimizedPostCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Track which posts we've already counted a view for this session
  static final Set<String> _viewedInSession = {};

  bool _hasActiveReports = false;
  final Map<int, VideoPlayerController> _videoControllers = {};
  late String _primaryMediaUrl;
  late bool _isModerated;
  late bool _shouldShowStatsFinal;

  bool _computeIsModerated() {
    final String status = (widget.post['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String moderationStatus =
        (widget.post['moderationStatus'] ??
                widget.post['moderation_status'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
    final bool communityHidden =
        widget.post['communityHidden'] == true ||
        widget.post['community_hidden'] == true;
    final bool isUnderReview =
        widget.post['is_under_review'] == true ||
        widget.post['isUnderReview'] == true;

    return communityHidden ||
        isUnderReview ||
        moderationStatus == 'pending_review' ||
        moderationStatus == 'violation_detected' ||
        moderationStatus == 'violation_confirmed' ||
        status == 'deleted' ||
        status == 'removed' ||
        status == 'banned' ||
        status == 'inactive' ||
        status == 'suspended';
  }

  bool _isConfirmedViolation() {
    final String status = (widget.post['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String moderationStatus =
        (widget.post['moderationStatus'] ??
                widget.post['moderation_status'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

    return moderationStatus == 'violation_confirmed' ||
        moderationStatus == 'removed' ||
        status == 'deleted' ||
        status == 'removed' ||
        status == 'banned' ||
        status == 'inactive' ||
        status == 'suspended';
  }

  bool _isPendingReview() {
    final String moderationStatus =
        (widget.post['moderationStatus'] ??
                widget.post['moderation_status'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
    final bool communityHidden =
        widget.post['communityHidden'] == true ||
        widget.post['community_hidden'] == true;
    final bool isUnderReview =
        widget.post['is_under_review'] == true ||
        widget.post['isUnderReview'] == true;

    return (communityHidden ||
            isUnderReview ||
            _hasActiveReports ||
            moderationStatus == 'pending_review' ||
            moderationStatus == 'violation_detected') &&
        !_isConfirmedViolation();
  }

  List<Map<String, String>> _getAllMediaItems() {
    final List<Map<String, String>> mediaItems = [];

    // Check media array first (new format)
    final dynamic rawMedia = widget.post['media'];

    if (rawMedia is List && rawMedia.isNotEmpty) {
      for (int i = 0; i < rawMedia.length; i++) {
        final item = rawMedia[i];
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final url = map['url'] ?? map['downloadUrl'] ?? map['publicUrl'];
          final type = map['type'] ?? 'image';

          // Include processing videos (empty URL) to show processing message
          if (type == 'video') {
            mediaItems.add({
              'url': url?.toString() ?? '',
              'type': type.toString(),
            });
          } else if (url is String &&
              url.trim().isNotEmpty &&
              url.startsWith('http')) {
            mediaItems.add({'url': url.trim(), 'type': type.toString()});
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final trimmedUrl = item.trim();
          mediaItems.add({'url': trimmedUrl, 'type': 'image'});
        }
      }
    } else if (rawMedia is Map) {
      final map = Map<String, dynamic>.from(rawMedia);
      final url = map['url'] ?? map['downloadUrl'] ?? map['publicUrl'];
      final type = map['type'] ?? 'image';
      if (type == 'video') {
        mediaItems.add({'url': url?.toString() ?? '', 'type': type.toString()});
      } else if (url is String &&
          url.trim().isNotEmpty &&
          url.startsWith('http')) {
        mediaItems.add({'url': url.trim(), 'type': type.toString()});
      }
    }

    // Fallback to legacy single image fields
    if (mediaItems.isEmpty) {
      final imageUrl = widget.post['imageUrl']?.toString();
      if (imageUrl != null &&
          imageUrl.trim().isNotEmpty &&
          imageUrl.startsWith('http')) {
        mediaItems.add({'url': imageUrl.trim(), 'type': 'image'});
      }

      final mediaUrl = widget.post['mediaUrl']?.toString();
      if (mediaUrl != null &&
          mediaUrl.trim().isNotEmpty &&
          mediaUrl.startsWith('http')) {
        mediaItems.add({'url': mediaUrl.trim(), 'type': 'image'});
      }
    }

    // If still empty, check embedded marketplace/item data often included in boosted items
    if (mediaItems.isEmpty) {
      final dynamic marketplaceEmbedded =
          widget.post['marketplaceItem'] ??
          widget.post['item'] ??
          widget.post['product'];
      if (marketplaceEmbedded is Map) {
        final images =
            marketplaceEmbedded['images'] ??
            marketplaceEmbedded['imagesUrl'] ??
            marketplaceEmbedded['imageUrls'];
        if (images is List && images.isNotEmpty) {
          for (final img in images) {
            if (img is String && img.startsWith('http')) {
              mediaItems.add({'url': img, 'type': 'image'});
            } else if (img is Map) {
              final url = img['url'] ?? img['image'];
              if (url is String && url.startsWith('http')) {
                mediaItems.add({'url': url, 'type': 'image'});
              }
            }
          }
        }
      }

      // Direct images field common in some posts
      final dynamic directImages =
          widget.post['images'] ??
          widget.post['itemImages'] ??
          widget.post['marketplaceImages'];
      if (directImages is List &&
          directImages.isNotEmpty &&
          mediaItems.isEmpty) {
        for (final img in directImages) {
          if (img is String && img.startsWith('http')) {
            mediaItems.add({'url': img, 'type': 'image'});
          }
        }
      }
    }

    return mediaItems;
  }

  String _getPrimaryMediaUrl() {
    // Check all possible media URL fields for file:// URLs and reject them
    final List<String> potentialUrls = [];

    // Collect all possible URLs
    final dynamic rawMedia = widget.post['media'];
    if (rawMedia is List && rawMedia.isNotEmpty) {
      final first = rawMedia.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        final url = map['url'] ?? map['downloadUrl'] ?? map['publicUrl'];
        if (url is String && url.trim().isNotEmpty) {
          potentialUrls.add(url.trim());
        }
      }
    }

    final dynamic rawImageUrl = widget.post['imageUrl'];
    if (rawImageUrl is String && rawImageUrl.trim().isNotEmpty) {
      potentialUrls.add(rawImageUrl.trim());
    }

    final dynamic rawMediaUrl = widget.post['mediaUrl'];
    if (rawMediaUrl is String && rawMediaUrl.trim().isNotEmpty) {
      potentialUrls.add(rawMediaUrl.trim());
    }

    final dynamic rawMediaUrls =
        widget.post['mediaUrls'] ?? widget.post['imageUrls'];
    if (rawMediaUrls is List && rawMediaUrls.isNotEmpty) {
      for (final entry in rawMediaUrls) {
        if (entry is String && entry.trim().isNotEmpty) {
          potentialUrls.add(entry.trim());
        }
      }
    }

    // Check each URL - reject any file:// URLs
    for (final url in potentialUrls) {
      if (url.startsWith('http')) {
        return url;
      }
    }

    // If still no URL found, check embedded marketplace/item data (consistent with _getAllMediaItems)
    final dynamic marketplaceEmbedded =
        widget.post['marketplaceItem'] ??
        widget.post['item'] ??
        widget.post['product'];
    if (marketplaceEmbedded is Map) {
      final images =
          marketplaceEmbedded['images'] ??
          marketplaceEmbedded['imagesUrl'] ??
          marketplaceEmbedded['imageUrls'];
      if (images is List && images.isNotEmpty) {
        for (final img in images) {
          if (img is String && img.startsWith('http')) {
            return img;
          } else if (img is Map) {
            final url = img['url'] ?? img['image'];
            if (url is String && url.startsWith('http')) {
              return url;
            }
          }
        }
      }
    }

    // Check direct images fields (consistent with _getAllMediaItems)
    final dynamic directImages =
        widget.post['images'] ??
        widget.post['itemImages'] ??
        widget.post['marketplaceImages'];
    if (directImages is List && directImages.isNotEmpty) {
      for (final img in directImages) {
        if (img is String && img.startsWith('http')) {
          return img;
        }
      }
    }

    return '';
  }

  bool _hasVisibleContent() {
    final content = widget.post['content']?.toString().trim();
    final hasContent = content != null && content.isNotEmpty;
    final mediaItems = _getAllMediaItems();
    return hasContent || mediaItems.isNotEmpty;
  }

  Widget _verificationTickWidget() {
    final authorId = (widget.post['userId'] ?? widget.post['authorId'] ?? '')
        .toString()
        .trim();
    if (authorId.isEmpty) return const SizedBox.shrink();

    final bool activeTick = _hasStoredActiveVerification() ||
        VerificationCacheService().isVerified(authorId);

    return activeTick ? _buildVerificationTick() : const SizedBox.shrink();
  }

  bool _hasStoredActiveVerification() {
    final status = (widget.post['verificationStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return widget.post['verified'] == true &&
        widget.post['verificationPaid'] == true &&
        widget.post['paymentExpired'] != true &&
        status == 'approved';
  }

  /// Build the verification tick widget
  Widget _buildVerificationTick() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Image.asset(
        'assets/icon/verification_tick.png',
        width: 22,
        height: 22,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.verified, size: 22, color: Colors.blue);
        },
      ),
    );
  }

  Map<String, int> _parseReactionEmojiCounts(dynamic raw) {
    final Map<String, int> parsed = {};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          parsed[key] = value;
        } else {
          parsed[key] = int.tryParse(value.toString()) ?? 0;
        }
      }
      parsed.removeWhere((k, v) => v <= 0);
    }
    return parsed;
  }

  void _checkForActiveReports() {
    final dynamic reportsValue =
        widget.post['activeReports'] ??
        widget.post['reports'] ??
        widget.post['reportsCount'];
    if (reportsValue is bool) {
      _hasActiveReports = reportsValue;
    } else if (reportsValue is num) {
      _hasActiveReports = reportsValue > 0;
    } else if (reportsValue is String) {
      _hasActiveReports =
          int.tryParse(reportsValue) != null && int.parse(reportsValue) > 0;
    } else {
      _hasActiveReports = false;
    }
  }

  Timer? _viewRecordTimer;

  @override
  void initState() {
    super.initState();
    _primaryMediaUrl = _getPrimaryMediaUrl();
    _isModerated = _computeIsModerated();
    _shouldShowStatsFinal = widget.showStats;

    // Always check for active reports to show banners
    _checkForActiveReports();

    // Defer recording view until user pauses on this post to avoid saturating I/O on fast fling
    _viewRecordTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _recordViewIfNeeded();
      }
    });
  }

  Future<void> _recordViewIfNeeded() async {
    if (_viewedInSession.contains(widget.postId)) return;
    _viewedInSession.add(widget.postId);

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'views': FieldValue.increment(1),
            'analytics.viewsCount': FieldValue.increment(1),
          });

      final boostSnapshot = await FirebaseFirestore.instance
          .collection('post_boosts')
          .where('postId', isEqualTo: widget.postId)
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();
      for (final boostDoc in boostSnapshot.docs) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(boostDoc.reference);
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return;

          final expiresAt = data['expiresAt'];
          if (expiresAt is Timestamp &&
              !expiresAt.toDate().isAfter(DateTime.now())) {
            return;
          }
          final budget =
              (data['impressionBudget'] ?? data['reach'] ?? 5000) as num;
          final delivered = (data['impressionsDelivered'] ?? 0) as num;
          if (delivered < budget) {
            transaction.update(boostDoc.reference, {
              'impressionsDelivered': FieldValue.increment(1),
            });
          }
        });
      }
    } catch (_) {
      // Silently ignore view recording errors
    }
  }

  void _initVideoControllerForIndex(int index, String url) {
    if (_videoControllers.containsKey(index) || url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoControllers[index] = controller;

    controller.addListener(() {
      if (mounted && controller.value.hasError) {
        setState(() {});
      }
    });

    controller.initialize().then((_) {
      if (mounted) {
        try {
          controller.setLooping(true);
        } catch (_) {}
        setState(() {});
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
  }

  @override
  void didUpdateWidget(OptimizedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.post, widget.post) ||
        oldWidget.showStats != widget.showStats) {
      _primaryMediaUrl = _getPrimaryMediaUrl();
      _isModerated = _computeIsModerated();
      _shouldShowStatsFinal = widget.showStats;
      _checkForActiveReports();
      if (oldWidget.post['media'] != widget.post['media']) {
        _disposeVideoControllers();
      }
    }
  }

  @override
  void dispose() {
    _viewRecordTimer?.cancel();
    _disposeVideoControllers();
    super.dispose();
  }

  String _getTimeWithColor() {
    // Check if post is boosted. Accept multiple possible key names to be
    // tolerant of different sources (boostEndDate, boostExpiresAt, etc.)
    final bool isBoosted =
        (widget.post['isBoosted'] == true) ||
        (widget.post['is_boosted'] == true);

    final dynamic rawBoost =
        widget.post['boostEndDate'] ??
        widget.post['boost_end_date'] ??
        widget.post['boostExpiresAt'] ??
        widget.post['boost_expires_at'] ??
        widget.post['boostEnd'] ??
        widget.post['boost_end'];

    if (isBoosted && rawBoost != null) {
      DateTime expiryTime;
      if (rawBoost is Timestamp) {
        expiryTime = rawBoost.toDate();
      } else if (rawBoost is DateTime) {
        expiryTime = rawBoost;
      } else if (rawBoost is String) {
        expiryTime = DateTime.tryParse(rawBoost) ?? DateTime.now();
      } else {
        expiryTime = DateTime.now();
      }

      // Debug: log raw boost value and parsed expiry
      debugPrint(
        '🔍 BOOST DEBUG for post ${widget.postId}: rawBoost=$rawBoost, expiry=$expiryTime',
      );

      // Check if boost is still active
      if (DateTime.now().isBefore(expiryTime)) {
        return 'Featured Post';
      }
    }

    // Show normal time for non-boosted or expired boost posts
    final timestamp = widget.post['created_at'] ?? widget.post['createdAt'];
    if (timestamp == null) return 'Just now';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primaryMediaUrl = _primaryMediaUrl;
    final bool isModerated = _isModerated;
    final bool isConfirmedViolation = _isConfirmedViolation();
    final bool isPendingReview = _isPendingReview();
    final bool shouldShowStatsFinal = _shouldShowStatsFinal;
    final bool hasVisibleContent = _hasVisibleContent();

    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CONTENT REMOVED BANNER (show for confirmed removals)
          if (isConfirmedViolation && widget.showViolationBanners)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Content removed due to community guidelines violation',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    'Interactions disabled for removed content',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),

          /// PENDING REPORTS BANNER (show while the report is under review)
          if (isPendingReview && widget.showViolationBanners)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending_actions,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Content under review for community guidelines',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserProfileImage(
                  userId:
                      widget.post['userId'] ?? widget.post['authorId'] ?? '',
                  radius: 20,
                  initialImageUrl:
                      widget.post['authorAvatar']?.toString() ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FarmerProfileScreen(
                          userId:
                              widget.post['userId'] ??
                              widget.post['authorId'] ??
                              '',
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: UserNameDisplay(
                              userId:
                                  widget.post['userId'] ??
                                  widget.post['authorId'] ??
                                  '',
                              initialName:
                                  widget.post['authorName']?.toString() ??
                                  'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Simple verification tick that always works
                          _verificationTickWidget(),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getTimeWithColor(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Location
                          if (widget.post['locationTag']?.isNotEmpty ==
                              true) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to location page
                                  _navigateToLocationPage();
                                },
                                child: Text(
                                  widget.post['locationTag'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          // Feeling
                          if (widget.post['feelingTag']?.isNotEmpty ==
                              true) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showFeelingDialog,
                                child: Text(
                                  'feeling ${widget.post['feelingTag']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Follow Button (only for non-owners)
                if (widget.post['userId'] != widget.currentUserId &&
                    widget.post['authorId'] != widget.currentUserId)
                  StableFollowButton(
                    currentUserId: widget.currentUserId,
                    targetUserId:
                        widget.post['userId'] ?? widget.post['authorId'] ?? '',
                  ),

                // More Options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  iconSize: 20,
                  onSelected: (value) {
                    switch (value) {
                      case 'analytics':
                        _navigateToAnalyticsScreen();
                        break;
                      case 'boost':
                        _navigateToBoostScreen();
                        break;
                      case 'edit':
                        _navigateToEditScreen();
                        break;
                      case 'delete':
                        _showDeleteDialog();
                        break;
                      case 'pin':
                        _togglePinPost(true);
                        break;
                      case 'unpin':
                        _togglePinPost(false);
                        break;
                      case 'report':
                        _navigateToReportScreen();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> items = [];

                    // Analytics (only for post owners)
                    if (widget.post['userId'] == widget.currentUserId ||
                        widget.post['authorId'] == widget.currentUserId) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'analytics',
                          child: Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Post Analytics'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Boost Post (only for post owners)
                    if (widget.post['userId'] == widget.currentUserId ||
                        widget.post['authorId'] == widget.currentUserId) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'boost',
                          child: Row(
                            children: [
                              Icon(Icons.rocket_launch, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Boost Post'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Edit (only for post owners)
                    if (widget.post['userId'] == widget.currentUserId ||
                        widget.post['authorId'] == widget.currentUserId) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Edit Post'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Delete (only for post owners)
                    if (widget.post['userId'] == widget.currentUserId ||
                        widget.post['authorId'] == widget.currentUserId) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Pin/Unpin (only for post owners)
                    if (widget.post['userId'] == widget.currentUserId ||
                        widget.post['authorId'] == widget.currentUserId) {
                      final isPinned = widget.post['isPinned'] == true;
                      items.add(
                        PopupMenuItem<String>(
                          value: isPinned ? 'unpin' : 'pin',
                          child: Row(
                            children: [
                              Icon(
                                isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Text(isPinned ? 'Unpin Post' : 'Pin Post'),
                            ],
                          ),
                        ),
                      );
                    }

                    // Report Post (for all users except post owner)
                    if (widget.post['userId'] != widget.currentUserId &&
                        widget.post['authorId'] != widget.currentUserId) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Report Post'),
                            ],
                          ),
                        ),
                      );
                    }

                    return items;
                  },
                ),
              ],
            ),
          ),

          /// CONTENT
          if (!hasVisibleContent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                'No visible content is available for this post. Approve or reject the boost request based on the post metadata.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          if (hasVisibleContent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  /// POST CONTENT SECTION
                  CollapsiblePost(
                    // Sanitize content to avoid literal markdown markers like **
                    content: (widget.post['content'] ?? '')
                        .toString()
                        .replaceAll('**', ''),
                    maxLines: 4, // Collapse posts at four lines
                    textStyle: TextStyle(
                      fontSize: 15,
                      color: isModerated ? Colors.grey.shade600 : Colors.black,
                      height: 1.4,
                    ),
                    actionStyle: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    expandText: 'Read more...',
                    collapseText: 'Show less',
                  ),
                ],
              ),
            ),

          /// IMAGES - Multiple images support with GridView
          _buildImageGrid(),

          /// ACTIONS/STATS
          if (shouldShowStatsFinal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: AbsorbPointer(
                absorbing: isModerated,
                child: Opacity(
                  opacity: isModerated ? 0.5 : 1.0,
                  child: Column(
                    children: [
                      if (widget.postId.startsWith('marketplace_'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.post['price'] != null ||
                                widget.post['marketplaceItem'] is Map)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _buildMarketplacePriceText(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final navigator = Navigator.of(context);
                                      try {
                                        final marketplaceId =
                                            _extractMarketplaceIdFromPost();
                                        final cartService = CartService();
                                        final currentUser =
                                            widget.currentUserId;

                                        if (marketplaceId.isEmpty) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Item not found'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final String postOwnerId =
                                            (widget.post['authorId'] ??
                                            widget.post['userId'] ??
                                            '');
                                        final bool isOwner =
                                            postOwnerId == widget.currentUserId;
                                        if (isOwner) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('Opening cart'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                          navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) => CartScreen(),
                                            ),
                                          );
                                          return;
                                        }

                                        final canonicalItem =
                                            await _loadMarketplaceItemForCart(
                                              marketplaceId,
                                            );
                                        final cartSource = canonicalItem.isEmpty
                                            ? widget.post
                                            : {
                                                ...widget.post,
                                                'marketplaceItem':
                                                    canonicalItem,
                                              };

                                        await cartService.addToCart(
                                          resolveMarketplaceCartPayload(
                                            cartSource,
                                            marketplaceId: marketplaceId,
                                            primaryImage: _getPrimaryMediaUrl(),
                                          ),
                                          currentUser,
                                        );

                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Item added to cart'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        navigator.push(
                                          MaterialPageRoute(
                                            builder: (_) => CartScreen(),
                                          ),
                                        );
                                      } catch (e) {
                                        developer.log(
                                          'Error adding marketplace item to cart: $e',
                                          name: 'OptimizedPostCard',
                                        );
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 18,
                                    ),
                                    label: const Text('Add to Cart'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _navigateToMarketplaceItem(),
                                    icon: const Icon(
                                      Icons.shopping_bag,
                                      size: 18,
                                    ),
                                    label: const Text('View Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        PostStatsRow(
                          postId: widget.postId,
                          farmerName:
                              widget.post['authorName'] ??
                              widget.post['authorName'] ??
                              'Unknown',
                          currentUserId: widget.currentUserId,
                          isOwner:
                              widget.post['authorId'] == widget.currentUserId,
                          postText: widget.post['content'] ?? '',
                          onToggleComments: () {
                            final authorName =
                                (widget.post['authorName'] ??
                                        widget.post['authorName'] ??
                                        'Farmer')
                                    .trim();
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
                                      postId: widget.postId,
                                      currentUserId: widget.currentUserId,
                                    ),
                                  ),
                                ),
                              ),
                            ).then((_) {
                              widget.onRefreshPost?.call();
                            });
                          },
                          onRefreshPost: widget.onRefreshPost,
                          post: Post(
                            id: widget.postId,
                            authorId: widget.post['authorId'] ?? '',
                            authorName: widget.post['authorName'] ?? '',
                            authorAvatar: widget.post['authorAvatar'] ?? '',
                            content: widget.post['content'] ?? '',
                            contentType: primaryMediaUrl.isNotEmpty
                                ? 'image'
                                : 'text',
                            createdAt:
                                widget.post['created_at'] ?? DateTime.now(),
                            media: primaryMediaUrl.isNotEmpty
                                ? [
                                    PostMedia(
                                      url: primaryMediaUrl,
                                      type: 'image',
                                    ),
                                  ]
                                : [],
                            hashtags: [],
                            status: PostStatus.active,
                            analytics: PostAnalytics(
                              likesCount: widget.post['likes'] is int
                                  ? widget.post['likes']
                                  : int.tryParse(widget.post['likes']?.toString() ?? '') ?? 0,
                              commentsCount: widget.post['commentsCount'] is int
                                  ? widget.post['commentsCount']
                                  : widget.post['comments'] is int
                                      ? widget.post['comments']
                                      : (widget.post['comments'] is List)
                                          ? (widget.post['comments'] as List).length
                                          : int.tryParse(widget.post['commentsCount']?.toString() ?? widget.post['comments']?.toString() ?? '') ?? 0,
                              reactionsCount: widget.post['reactionsCount'] is int
                                  ? widget.post['reactionsCount']
                                  : int.tryParse(widget.post['reactionsCount']?.toString() ?? '') ?? 0,
                              reactionEmojiCounts: _parseReactionEmojiCounts(
                                widget.post['reactionEmojiCounts'],
                              ),
                            ),
                            likes: widget.post['likes'] is List
                                ? List<String>.from(widget.post['likes'] ?? [])
                                : widget.post['likesList'] is List
                                    ? List<String>.from(widget.post['likesList'] ?? [])
                                    : [],
                            reactions: widget.post['reactions'] is Map
                                ? Map<String, String>.from(
                                    widget.post['reactions'] ?? {},
                                  )
                                : {},
                            comments: widget.post['comments'] is List
                                ? List<Map<String, dynamic>>.from(
                                    widget.post['comments'] ?? [],
                                  )
                                : widget.post['commentsList'] is List
                                    ? List<Map<String, dynamic>>.from(
                                        widget.post['commentsList'] ?? [],
                                      )
                                    : [],
                            groupId: null,
                            groupVisibility: null,
                            feelingTag: widget.post['feelingTag'],
                            locationTag: widget.post['locationTag'],
                            repostOf: null,
                            caption: widget.post['content'] ?? '',
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Divider
                      Container(height: 1, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToAnalyticsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostAnalyticsScreen(postId: widget.postId, post: widget.post),
      ),
    );
  }

  void _navigateToBoostScreen() {
    // Create Post object from the widget data
    final post = Post(
      id: widget.postId,
      authorId: widget.post['authorId'] ?? '',
      authorName: widget.post['authorName'] ?? '',
      authorAvatar: widget.post['authorAvatar'] ?? '',
      content: widget.post['content'] ?? '',
      contentType: widget.post['contentType'] ?? 'text',
      createdAt: widget.post['createdAt']?.toDate() ?? DateTime.now(),
      media:
          (widget.post['media'] as List<dynamic>?)
              ?.map(
                (m) =>
                    PostMedia(url: m['url'] ?? '', type: m['type'] ?? 'image'),
              )
              .toList() ??
          [],
      hashtags: [],
      status: PostStatus.active,
      likes: [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BoostObjectivePage(post: post)),
    );
  }

  void _navigateToEditScreen() {
    // Create a Post object from the widget data
    final post = Post(
      id: widget.postId,
      authorId: widget.post['authorId'] ?? '',
      authorName: widget.post['authorName'] ?? '',
      authorAvatar: widget.post['authorAvatar'] ?? '',
      content: widget.post['content'] ?? '',
      contentType: 'text',
      createdAt: widget.post['created_at'] is DateTime
          ? widget.post['created_at'] as DateTime
          : DateTime.now(),
      media: [],
      hashtags: [],
      status: PostStatus.active,
      likes: [],
      caption: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostScreen(postId: widget.postId, post: post),
      ),
    );
  }

  void _showFeelingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feeling'),
          content: Text(
            'feeling ${widget.post['feelingTag']}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLocationPage() {
    final location = widget.post['locationTag'];
    if (location != null && location.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationScreen(locationName: location),
        ),
      );
    }
  }

  void _navigateToReportScreen() {
    // Create a Post object from the widget data
    final post = Post(
      id: widget.postId,
      authorId: widget.post['authorId'] ?? '',
      authorName: widget.post['authorName'] ?? '',
      authorAvatar: widget.post['authorAvatar'] ?? '',
      content: widget.post['content'] ?? '',
      contentType: 'text',
      createdAt: widget.post['created_at'] is DateTime
          ? widget.post['created_at'] as DateTime
          : DateTime.now(),
      media: [],
      hashtags: [],
      status: PostStatus.active,
      likes: [],
      caption: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportPostPage(post: post)),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                if (!mounted) return;

                final messenger = ScaffoldMessenger.of(context);

                try {
                  // Show loading indicator
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Deleting post...')),
                  );

                  // Delete the post from Firestore
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .delete();

                  // Call the callback if provided
                  widget.onDelete?.call();

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error deleting post: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _togglePinPost(bool pin) async {
    try {
      final authorId = widget.post['authorId'] ?? '';

      if (pin && authorId.isNotEmpty) {
        // First, find and unpin any existing pinned posts from this author
        final existingPinned = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: authorId)
            .where('isPinned', isEqualTo: true)
            .get();

        // Unpin all existing pinned posts (should be max 1, but loop to be safe)
        for (final doc in existingPinned.docs) {
          if (doc.id != widget.postId) {
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(doc.id)
                .update({'isPinned': false, 'pinnedAt': null});
          }
        }
      }

      // Now pin/unpin the current post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'isPinned': pin,
            'pinnedAt': pin ? FieldValue.serverTimestamp() : null,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pin ? '📌 Post pinned to profile' : '📍 Post unpinned',
            ),
            backgroundColor: pin ? Colors.purple : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToMarketplaceItem() async {
    final marketplaceId = _extractMarketplaceIdFromPost();

    developer.log(
      '🛒 Fetching marketplace item: $marketplaceId',
      name: 'OptimizedPostCard',
    );

    if (marketplaceId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Try common collection names in order of likelihood
      final collectionsToTry = [
        'Marketplace',
        'marketplace',
        'marketplaces',
        'marketplace_items',
        'items',
      ];
      DocumentSnapshot? found;

      for (final col in collectionsToTry) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(col)
              .doc(marketplaceId)
              .get();
          if (doc.exists) {
            found = doc;
            developer.log(
              'Found marketplace doc in collection: $col',
              name: 'OptimizedPostCard',
            );
            break;
          }
        } catch (e) {
          developer.log(
            'Error checking collection $col: $e',
            name: 'OptimizedPostCard',
          );
        }
      }

      // If not found by id, try to search by common fields stored in the post
      if (found == null) {
        final candidates = [
          'marketplaceId',
          'itemId',
          'marketplace_item_id',
          'item_id',
        ];
        for (final field in candidates) {
          final idFromPost = widget.post[field];
          if (idFromPost is String && idFromPost.isNotEmpty) {
            for (final col in collectionsToTry) {
              try {
                final doc = await FirebaseFirestore.instance
                    .collection(col)
                    .doc(idFromPost)
                    .get();
                if (doc.exists) {
                  found = doc;
                  developer.log(
                    'Found marketplace doc by post field $field in $col',
                    name: 'OptimizedPostCard',
                  );
                  break;
                }
              } catch (e) {
                developer.log(
                  'Error checking collection $col for idFromPost $idFromPost: $e',
                  name: 'OptimizedPostCard',
                );
              }
            }
          }
          if (found != null) break;
        }
      }

      // If still not found, attempt to build from embedded post data
      if (found == null && widget.post['marketplaceItem'] is Map) {
        final embedded = Map<String, dynamic>.from(
          widget.post['marketplaceItem'],
        );
        final item = MarketplaceItem.fromMap(embedded);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailsPage(
                item: item,
                marketplaceService: FirebaseMarketplaceService.instance,
              ),
            ),
          );
        }
        return;
      }

      if (found == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final item = MarketplaceItem.fromFirestore(found);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailsPage(
              item: item,
              marketplaceService: FirebaseMarketplaceService.instance,
            ),
          ),
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error navigating to marketplace item: $e',
        name: 'OptimizedPostCard',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _buildMarketplacePriceText() {
    final embedded = widget.post['marketplaceItem'] is Map
        ? Map<String, dynamic>.from(widget.post['marketplaceItem'] as Map)
        : <String, dynamic>{};

    final rawPrice = embedded['price'] ?? widget.post['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
    final currency =
        (embedded['currencySymbol'] ??
                embedded['currency'] ??
                widget.post['currencySymbol'] ??
                widget.post['currency'] ??
                'ZAR')
            .toString();
    final negotiable =
        embedded['negotiable'] ?? widget.post['negotiable'] ?? false;
    final formattedPrice = Formatter.formatMarketplacePrice(
      price,
      negotiable: negotiable,
      symbol: currency,
    );
    return 'Cost: $formattedPrice';
  }

  Future<Map<String, dynamic>> _loadMarketplaceItemForCart(
    String marketplaceId,
  ) async {
    for (final collectionName in ['Marketplace', 'marketplace']) {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(marketplaceId)
          .get();
      if (snapshot.exists) {
        return snapshot.data() ?? <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  String _extractMarketplaceIdFromPost() {
    // Prefer explicit postId format marketplace_<id>
    if (widget.postId.startsWith('marketplace_')) {
      return widget.postId.replaceFirst('marketplace_', '');
    }

    final candidates = [
      widget.post['marketplaceId'],
      widget.post['itemId'],
      widget.post['marketplace_item_id'],
      widget.post['item_id'],
      widget.post['id'],
    ];

    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }

    return '';
  }

  // Build media grid for multiple images and videos
  Widget _buildImageGrid() {
    final mediaItems = _getAllMediaItems();

    if (mediaItems.isEmpty) return const SizedBox.shrink();

    // Check if there are any videos
    final hasVideo = mediaItems.any((item) => item['type'] == 'video');

    // If there's a video, show only the first item (single display)
    if (hasVideo) {
      final firstItem = mediaItems.first;
      if (firstItem['type'] == 'video') {
        // Full phone width video with better ratio
        final double screenWidth = MediaQuery.of(context).size.width;
        const double videoHeight = 600;

        // Check if this is a processing video (empty URL)
        if (firstItem['url']!.isEmpty) {
          return Container(
            width: screenWidth,
            height: videoHeight,
            color: Colors.black,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call, size: 70, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Video is processing...',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You\'ll see the video here soon',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Container(
          width: screenWidth,
          height: videoHeight,
          child: _buildVideoPlayer(0, firstItem['url']!),
        );
      } else {
        // First item is image, show it normally
        return Container(
          width: double.infinity,
          height: 300,
          child: GestureDetector(
            onTap: () => _openFullScreenViewer([firstItem['url']!], 0),
            child: Hero(
              tag: 'post_${widget.postId}_${widget.hashCode}_0',
              child: CachedNetworkImage(
                imageUrl: firstItem['url']!,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                cacheKey: 'post_single_${widget.postId}_${firstItem['url']}',
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // No videos - show images in grid
    final imageItems = mediaItems
        .where((item) => item['type'] == 'image')
        .toList();

    // Single image - full phone width with limited max height
    if (imageItems.length == 1) {
      final item = imageItems.first;
      final screenWidth = MediaQuery.of(context).size.width;
      final maxHeight = screenWidth * 1.2; // Limit max height (120% of width)

      return Container(
        width: screenWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.grey.shade200,
        child: GestureDetector(
          onTap: () => _openFullScreenViewer([item['url']!], 0),
          child: Hero(
            tag: 'post_${widget.postId}_${widget.hashCode}_0',
            child: CachedNetworkImage(
              imageUrl: item['url']!,
              fit: BoxFit.cover,
              width: screenWidth,
              memCacheWidth: 1200,
              cacheKey: 'post_single_${widget.postId}_${item['url']}',
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (context, url) =>
                  Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Multiple images - use GridView
    return Container(
      height: _getGridHeight(imageItems.length),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(imageItems.length),
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: _getAspectRatio(imageItems.length),
        ),
        itemCount: imageItems.length,
        itemBuilder: (context, index) {
          final item = imageItems[index];
          return GestureDetector(
            onTap: () => _openFullScreenViewer(
              imageItems.map((m) => m['url']!).toList(),
              index,
            ),
            child: Hero(
              tag: 'post_${widget.postId}_${widget.hashCode}_$index',
              child: CachedNetworkImage(
                imageUrl: item['url']!,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                cacheKey: 'post_grid_${widget.postId}_${item['url']}_$index',
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade300),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build video player widget with lazy initialization
  Widget _buildVideoPlayer(int index, String url) {
    final controller = _videoControllers[index];
    final double screenWidth = MediaQuery.of(context).size.width;
    const double videoHeight = 600;

    if (controller == null) {
      _initVideoControllerForIndex(index, url);
      return Container(
        width: screenWidth,
        height: videoHeight,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      );
    }

    if (!controller.value.isInitialized) {
      return Container(
        width: screenWidth,
        height: videoHeight,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      );
    }

    // Check for video errors
    if (controller.value.hasError) {
      return Container(
        width: screenWidth,
        height: videoHeight,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Video failed to load',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                controller.initialize().then((_) {
                  if (mounted) setState(() {});
                });
              },
              child: const Text(
                'Tap to retry',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: screenWidth,
      height: videoHeight,
      color: Colors.black,
      child: Stack(
        children: [
          SizedBox(
            width: screenWidth,
            height: videoHeight,
            child: VideoPlayer(controller),
          ),
          if (!controller.value.isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () async {
                try {
                  if (!controller.value.isInitialized || controller.value.hasError) {
                    return;
                  }

                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }

                  if (mounted) {
                    setState(() {});
                  }
                } catch (_) {}
              },
            ),
          ),
        ],
      ),
    );
  }

  // Open full-screen image viewer
  void _openFullScreenViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
              heroTag: 'post_${widget.postId}_${widget.hashCode}',
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Helper methods for grid layout - INCREASED SIZES
  int _getCrossAxisCount(int imageCount) {
    if (imageCount == 2) return 2;
    if (imageCount == 3) return 3;
    if (imageCount == 4) return 2; // 2x2 for 4 images
    return 2; // For 5+ images, use 2 columns
  }

  double _getAspectRatio(int imageCount) {
    if (imageCount == 2) return 0.9;
    if (imageCount == 3) return 0.9;
    if (imageCount == 4) return 0.9; // Slightly taller for bigger look
    return 0.9; // For 5+ images
  }

  double _getGridHeight(int imageCount) {
    if (imageCount <= 0) {
      return 300; // Minimum fallback height
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= 0 || !screenWidth.isFinite) {
      return 300;
    }

    if (imageCount == 1) return screenWidth * 0.5; // Single image - half width
    if (imageCount == 2) return screenWidth * 0.5; // 2 rows of half width
    if (imageCount == 3) return screenWidth * 0.33; // 1 row of 3 columns
    if (imageCount == 4) return screenWidth; // 2 rows of 2 columns
    if (imageCount == 5) return screenWidth * 0.66; // 2 rows (3+2)
    if (imageCount == 6) return screenWidth * 0.66; // 3 rows of 2 columns

    final calculatedHeight = screenWidth * ((imageCount / 2).ceil() * 0.5);

    if (!calculatedHeight.isFinite) {
      return 300;
    }

    return calculatedHeight;
  }
}
