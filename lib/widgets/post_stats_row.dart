import 'dart:async';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart'; // for Clipboard

import '../models/post_model.dart'; // Import Post model

class PostStatsRow extends StatefulWidget {
  final String postId;
  final String? farmerName;
  final String currentUserId;
  final bool isOwner;
  final String postText;
  final VoidCallback onToggleComments;
  final Post post;
  final VoidCallback? onRefreshPost;

  const PostStatsRow({
    super.key,
    required this.postId,
    required this.farmerName,
    required this.currentUserId,
    required this.isOwner,
    required this.postText,
    required this.onToggleComments,
    required this.post,
    this.onRefreshPost,
  });

  @override
  State<PostStatsRow> createState() => _PostStatsRowState();
}

class _PostStatsRowState extends State<PostStatsRow> {
  bool _showEmojiPicker = false;

  int? _optimisticReactionsCount;
  Map<String, int>? _optimisticReactionEmojiCounts;
  bool _optimisticUserEmojiOverridden = false;
  String? _optimisticUserEmoji;
  Timer? _optimisticClearTimer;

  // Add optimistic copy count
  int? _optimisticCopyCount;
  Timer? _optimisticCopyClearTimer;

  // 🔒 FIX: lock row height - increased to prevent overflow
  static const double _rowHeight = 90;

  static const Map<String, String> _reactionAssetByEmoji = {
    '👍': 'assets/reactions/like.png',
    '❤️': 'assets/reactions/love.png',
    '😂': 'assets/reactions/haha.png',
    '😮': 'assets/reactions/wow.png',
    '😢': 'assets/reactions/sad.png',
  };

  Widget _buildReactionAssetIcon(String emoji, {double size = 14}) {
    final assetPath = _reactionAssetByEmoji[emoji];
    if (assetPath == null) {
      return Text(emoji, style: TextStyle(fontSize: size));
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: 128,
      cacheHeight: 128,
      filterQuality: FilterQuality.high,
    );
  }

  Widget _buildReactionIconsStack(List<String> emojis) {
    final shown = emojis.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    const double iconSize = 22;
    const double overlap = 10;
    final width = iconSize + (shown.length - 1) * overlap;

    return SizedBox(
      width: width,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(iconSize / 2),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: _buildReactionAssetIcon(shown[i], size: 19),
              ),
            ),
        ],
      ),
    );
  }

  void _scheduleOptimisticClear() {
    _optimisticClearTimer?.cancel();
    _optimisticCopyClearTimer?.cancel();
    _optimisticClearTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _optimisticReactionsCount = null;
        _optimisticReactionEmojiCounts = null;
        _optimisticUserEmojiOverridden = false;
        _optimisticUserEmoji = null;
        _optimisticCopyCount = null;
      });
    });
  }

  void _applyOptimisticAddCopy() {
    final baseCount = _optimisticCopyCount ?? 0;
    _optimisticCopyCount = baseCount + 1;
    _scheduleOptimisticClear();
  }

  int _coerceInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> _parseAnalyticsMap(dynamic rawAnalytics) {
    if (rawAnalytics is Map) {
      return Map<String, dynamic>.from(rawAnalytics);
    }
    return {};
  }

  Map<String, int> _parseEmojiCounts(dynamic rawCounts) {
    final emojiCounts = <String, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key.toString();
        final parsedValue = _coerceInt(entry.value);
        if (parsedValue > 0) {
          emojiCounts[key] = parsedValue;
        }
      }
    }
    return emojiCounts;
  }

  Map<String, dynamic> _buildAnalyticsPayload({
    required Map<String, dynamic> analytics,
    required int reactionsCount,
    required Map<String, int> emojiCounts,
    int? sharesCount,
  }) {
    final updatedAnalytics = <String, dynamic>{...analytics};
    updatedAnalytics['reactionsCount'] = reactionsCount;
    updatedAnalytics['reactionEmojiCounts'] = emojiCounts;
    if (sharesCount != null) {
      updatedAnalytics['sharesCount'] = sharesCount;
    }
    return updatedAnalytics;
  }

  void _applyOptimisticAddReaction(String emoji) {
    final baseCount =
        _optimisticReactionsCount ?? widget.post.analytics.reactionsCount;
    final baseMap = Map<String, int>.from(
      _optimisticReactionEmojiCounts ??
          widget.post.analytics.reactionEmojiCounts,
    );

    baseMap[emoji] = (baseMap[emoji] ?? 0) + 1;
    baseMap.removeWhere((k, v) => v <= 0);

    _optimisticReactionsCount = baseCount + 1;
    _optimisticReactionEmojiCounts = baseMap;
    _optimisticUserEmojiOverridden = true;
    _optimisticUserEmoji = emoji;

    _scheduleOptimisticClear();
  }

  void _applyOptimisticRemoveReaction(String? emoji) {
    final baseCount =
        _optimisticReactionsCount ?? widget.post.analytics.reactionsCount;
    final baseMap = Map<String, int>.from(
      _optimisticReactionEmojiCounts ??
          widget.post.analytics.reactionEmojiCounts,
    );

    if (emoji != null) {
      final current = baseMap[emoji] ?? 0;
      final next = current - 1;
      if (next <= 0) {
        baseMap.remove(emoji);
      } else {
        baseMap[emoji] = next;
      }
    }
    baseMap.removeWhere((k, v) => v <= 0);

    _optimisticReactionsCount = baseCount > 0 ? baseCount - 1 : 0;
    _optimisticReactionEmojiCounts = baseMap;
    _optimisticUserEmojiOverridden = true;
    _optimisticUserEmoji = null;

    _scheduleOptimisticClear();
  }

  @override
  void didUpdateWidget(covariant PostStatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only clear optimistic state if the actual data matches what we expected
    final optimisticCount = _optimisticReactionsCount;
    final optimisticEmojiCounts = _optimisticReactionEmojiCounts;

    if (optimisticCount != null && optimisticEmojiCounts != null) {
      final currentCount = widget.post.analytics.reactionsCount;
      final currentCounts = widget.post.analytics.reactionEmojiCounts;

      // Check if both count and emoji distribution match
      if (currentCount == optimisticCount &&
          _mapsEqual(currentCounts, optimisticEmojiCounts)) {
        _optimisticClearTimer?.cancel();
        setState(() {
          _optimisticReactionsCount = null;
          _optimisticReactionEmojiCounts = null;
          _optimisticUserEmojiOverridden = false;
          _optimisticUserEmoji = null;
        });
      }
    }
  }

  /// Helper to compare two maps for equality
  bool _mapsEqual(Map<String, int>? map1, Map<String, int>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final entry in map1.entries) {
      if (map2[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _optimisticClearTimer?.cancel();
    super.dispose();
  }

  Future<void> _setReaction(String emoji) async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final reactionRef = postRef
        .collection('reactions')
        .doc(widget.currentUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final postData = postDoc.data() ?? {};
      final analytics = _parseAnalyticsMap(postData['analytics']);
      final emojiCounts = _parseEmojiCounts(analytics['reactionEmojiCounts']);
      int reactionsCount = _coerceInt(analytics['reactionsCount']);

      final reactionDoc = await transaction.get(reactionRef);
      final existingData = reactionDoc.data();
      final oldEmoji = existingData?['type'] as String?;

      if (reactionDoc.exists) {
        if (oldEmoji != emoji) {
          transaction.set(reactionRef, {
            'type': emoji,
            'created_at': Timestamp.now(),
          }, SetOptions(merge: true));

          if (oldEmoji != null) {
            final current = emojiCounts[oldEmoji] ?? 0;
            final next = current - 1;
            if (next <= 0) {
              emojiCounts.remove(oldEmoji);
            } else {
              emojiCounts[oldEmoji] = next;
            }
          } else {
            reactionsCount = reactionsCount > 0 ? reactionsCount : 0;
            reactionsCount += 1;
          }

          emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
        }
      } else {
        transaction.set(reactionRef, {
          'type': emoji,
          'created_at': Timestamp.now(),
        }, SetOptions(merge: true));

        reactionsCount += 1;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }

      emojiCounts.removeWhere((k, v) => v <= 0);
      if (reactionsCount < 0) reactionsCount = 0;

      transaction.update(postRef, {
        'analytics': _buildAnalyticsPayload(
          analytics: analytics,
          reactionsCount: reactionsCount,
          emojiCounts: emojiCounts,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    widget.onRefreshPost?.call();
  }

  Future<void> _removeReaction() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final reactionRef = postRef
        .collection('reactions')
        .doc(widget.currentUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final reactionDoc = await transaction.get(reactionRef);
      if (!reactionDoc.exists) return;

      final reactionData = reactionDoc.data() ?? {};
      final oldEmoji = reactionData['type'] as String?;

      final postData = postDoc.data() ?? {};
      final analytics = _parseAnalyticsMap(postData['analytics']);
      final emojiCounts = _parseEmojiCounts(analytics['reactionEmojiCounts']);
      int reactionsCount = _coerceInt(analytics['reactionsCount']);

      transaction.delete(reactionRef);

      reactionsCount = reactionsCount > 0 ? reactionsCount - 1 : 0;
      if (oldEmoji != null) {
        final current = emojiCounts[oldEmoji] ?? 0;
        final next = current - 1;
        if (next <= 0) {
          emojiCounts.remove(oldEmoji);
        } else {
          emojiCounts[oldEmoji] = next;
        }
      }

      emojiCounts.removeWhere((k, v) => v <= 0);

      transaction.update(postRef, {
        'analytics': _buildAnalyticsPayload(
          analytics: analytics,
          reactionsCount: reactionsCount,
          emojiCounts: emojiCounts,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    widget.onRefreshPost?.call();
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        final postData = snapshot.data?.data();
        final analytics = _parseAnalyticsMap(postData?['analytics']);
        final liveReactionsCount = _coerceInt(
          analytics['reactionsCount'],
          fallback: widget.post.analytics.reactionsCount,
        );
        final liveEmojiCounts = (snapshot.hasData && analytics.containsKey('reactionEmojiCounts'))
            ? _parseEmojiCounts(analytics['reactionEmojiCounts'])
            : widget.post.analytics.reactionEmojiCounts;
        final liveShareCount = _coerceInt(
          postData?['shares'],
          fallback: widget.post.shares,
        );
        final rawComments = postData?['comments'];
        final liveCommentsCount = _coerceInt(
          analytics['commentsCount'] ??
              analytics['commentCount'] ??
              postData?['commentsCount'] ??
              postData?['commentCount'] ??
              (rawComments is int
                  ? rawComments
                  : (rawComments is List ? rawComments.length : null)),
          fallback: widget.post.analytics.commentsCount > 0
              ? widget.post.analytics.commentsCount
              : widget.post.comments.length,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _reactionButton(
                    count: _optimisticReactionsCount ?? liveReactionsCount,
                    emojiCounts:
                        _optimisticReactionEmojiCounts ?? liveEmojiCounts,
                  ),
                  _commentButton(count: liveCommentsCount),
                  _copyButton(displayCount: _optimisticCopyCount ?? liveShareCount),
                ],
              ),
            ),

            if (_showEmojiPicker)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["👍", "❤️", "😂", "😮", "😢"].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _showEmojiPicker = false;
                          _applyOptimisticAddReaction(emoji);
                        });
                        _setReaction(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  /// =========================
  /// SUB-WIDGETS (KEY FIX)
  /// =========================

  Widget _reactionButton({
    required int count,
    required Map<String, int> emojiCounts,
  }) {
    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmojis = sortedEmojis.take(3).map((e) => e.key).toList();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('reactions')
          .doc(widget.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final userEmojiFromDb = data?['type'] as String?;
        final fallbackUserEmoji = widget.post.reactions[widget.currentUserId] ??
            (widget.post.likes.contains(widget.currentUserId) ? '❤️' : null);
        final userEmoji = _optimisticUserEmojiOverridden
            ? _optimisticUserEmoji
            : (userEmojiFromDb ?? fallbackUserEmoji);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              child: count > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReactionIconsStack(topEmojis),
                        const SizedBox(width: 3),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            IconButton(
              icon: Icon(
                userEmoji == null ? Icons.favorite_border : Icons.favorite,
                color: userEmoji == null ? Colors.grey : Colors.red,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () {
                if (userEmoji != null) {
                  setState(() {
                    _applyOptimisticRemoveReaction(userEmoji);
                  });
                  _removeReaction();
                } else {
                  setState(() {
                    _applyOptimisticAddReaction('❤️');
                  });
                  _setReaction('❤️');
                }
              },
              onLongPress: () {
                _toggleEmojiPicker();
              },
              iconSize: 26,
            ),
          ],
        );
      },
    );
  }

  Widget _commentButton({required int count}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Center(
            child: count > 0
                ? Text(
                    '$count ${count == 1 ? 'comment' : 'comments'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: widget.onToggleComments,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          iconSize: 26,
        ),
      ],
    );
  }

  Widget _copyButton({required int displayCount}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Center(
            child: Text(
              displayCount > 0
                  ? '$displayCount ${displayCount == 1 ? 'copy' : 'copies'}'
                  : 'copy',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () async {
            final copyRef = FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('copies')
                .doc(widget.currentUserId);

            // Always copy to clipboard first
            await Clipboard.setData(ClipboardData(text: widget.postText));

            // Check if user has already copied
            final copyDoc = await copyRef.get();
            final isFirstCopy = !copyDoc.exists;

            try {
              // Only increment count on first copy
              if (isFirstCopy) {
                setState(() {
                  _applyOptimisticAddCopy();
                });

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final postRef = FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId);
                  final postDoc = await transaction.get(postRef);
                  if (!postDoc.exists) return;

                  final postData = postDoc.data() ?? {};
                  final analytics = _parseAnalyticsMap(postData['analytics']);
                  final currentShares = _coerceInt(postData['shares']);
                  final currentSharesCount = _coerceInt(analytics['sharesCount']);

                  // Mark this user as having copied the post
                  transaction.set(copyRef, {
                    'userId': widget.currentUserId,
                    'copiedAt': Timestamp.now(),
                  }, SetOptions(merge: true));

                  // Increment both shares and analytics.sharesCount
                  transaction.update(postRef, {
                    'shares': currentShares + 1,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'analytics': _buildAnalyticsPayload(
                      analytics: analytics,
                      reactionsCount: _coerceInt(analytics['reactionsCount']),
                      emojiCounts: _parseEmojiCounts(analytics['reactionEmojiCounts']),
                      sharesCount: currentSharesCount + 1,
                    ),
                  });
                });

                widget.onRefreshPost?.call();
              }

              // Show success message for every copy (whether first or repeat)
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFirstCopy ? 'Post copied and saved!' : 'Post copied!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          iconSize: 26,
        ),
      ],
    );
  }
}
