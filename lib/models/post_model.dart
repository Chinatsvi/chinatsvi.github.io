import 'package:cloud_firestore/cloud_firestore.dart';

enum PostStatus { active, deleted, removed }

class PostMedia {
  final String url;
  final String type;

  PostMedia({required this.url, required this.type});

  Map<String, dynamic> toJson() => {'url': url, 'type': type};

  factory PostMedia.fromJson(Map<String, dynamic> json) =>
      PostMedia(url: json['url'] ?? '', type: json['type'] ?? 'image');
}

class PostAnalytics {
  final int viewsCount;
  final int commentsCount;
  final int sharesCount;
  final int reactionsCount;
  final Map<String, int> reactionEmojiCounts;
  final int savesCount;
  final int likesCount;

  PostAnalytics({
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reactionsCount = 0,
    this.reactionEmojiCounts = const {},
    this.savesCount = 0,
    this.likesCount = 0,
  });

  PostAnalytics copyWith({
    int? viewsCount,
    int? commentsCount,
    int? sharesCount,
    int? reactionsCount,
    Map<String, int>? reactionEmojiCounts,
    int? savesCount,
    int? likesCount,
  }) {
    return PostAnalytics(
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      reactionEmojiCounts: reactionEmojiCounts ?? this.reactionEmojiCounts,
      savesCount: savesCount ?? this.savesCount,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'viewsCount': viewsCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'reactionsCount': reactionsCount,
    'reactionEmojiCounts': reactionEmojiCounts,
    'savesCount': savesCount,
    'likesCount': likesCount,
  };

  factory PostAnalytics.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['reactionEmojiCounts'];
    final Map<String, int> parsedCounts = {};

    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          parsedCounts[key] = value;
        } else {
          parsedCounts[key] = int.tryParse(value.toString()) ?? 0;
        }
      }
      parsedCounts.removeWhere((k, v) => v <= 0);
    }

    final rawComments = json['commentsCount'] ??
        json['commentCount'] ??
        json['comments_count'] ??
        json['comments'];

    return PostAnalytics(
      viewsCount: _parseInt(json['viewsCount'] ?? json['views']),
      commentsCount: _parseInt(rawComments),
      sharesCount: _parseInt(json['sharesCount'] ?? json['shares']),
      reactionsCount: _parseInt(json['reactionsCount'] ?? json['reactions']),
      reactionEmojiCounts: parsedCounts,
      savesCount: _parseInt(json['savesCount'] ?? json['saves']),
      likesCount: _parseInt(json['likesCount'] ?? json['likes']),
    );
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String contentType;
  final DateTime createdAt;
  final List<PostMedia> media;
  final List<String> hashtags;
  final PostStatus status;
  final PostAnalytics analytics;
  final List<String> likes;
  final Map<String, String> reactions;
  final List<Map<String, dynamic>> comments;
  final String? groupId;
  final String? groupVisibility;
  final String? feelingTag;
  final String? locationTag;
  final String? repostOf;
  final String caption;
  final int shares;
  final bool active;
  final bool isPinned;
  final DateTime? pinnedAt;
  final bool isBoosted;
  final DateTime? boostEndDate;
  final String? boostObjectiveId;
  final String? boostObjectiveTitle;
  final bool communityHidden;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.contentType,
    required this.createdAt,
    required this.media,
    required this.hashtags,
    required this.status,
    PostAnalytics? analytics,
    required this.likes,
    this.reactions = const {},
    this.comments = const [],
    this.groupId,
    this.groupVisibility,
    this.feelingTag,
    this.locationTag,
    this.repostOf,
    this.caption = '',
    this.shares = 0,
    this.active = true,
    this.isPinned = false,
    this.pinnedAt,
    this.isBoosted = false,
    this.boostEndDate,
    this.boostObjectiveId,
    this.boostObjectiveTitle,
    this.communityHidden = false,
  }) : analytics = analytics ?? PostAnalytics();

  // Backward compatibility getters
  String get userId => authorId;
  String get userName => authorName;
  String get userProfile => authorAvatar;

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? contentType,
    DateTime? createdAt,
    List<PostMedia>? media,
    List<String>? hashtags,
    PostStatus? status,
    PostAnalytics? analytics,
    List<String>? likes,
    Map<String, String>? reactions,
    List<Map<String, dynamic>>? comments,
    String? groupId,
    String? groupVisibility,
    String? feelingTag,
    String? locationTag,
    String? repostOf,
    String? caption,
    int? shares,
    bool? active,
    bool? isPinned,
    DateTime? pinnedAt,
    bool? isBoosted,
    DateTime? boostEndDate,
    String? boostObjectiveId,
    String? boostObjectiveTitle,
    bool? communityHidden,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt ?? this.createdAt,
      media: media ?? List.from(this.media),
      hashtags: hashtags ?? List.from(this.hashtags),
      status: status ?? this.status,
      analytics: analytics ?? this.analytics,
      likes: likes ?? List.from(this.likes),
      reactions: reactions ?? Map.from(this.reactions),
      comments: comments ?? List.from(this.comments),
      groupId: groupId ?? this.groupId,
      groupVisibility: groupVisibility ?? this.groupVisibility,
      feelingTag: feelingTag ?? this.feelingTag,
      locationTag: locationTag ?? this.locationTag,
      repostOf: repostOf ?? this.repostOf,
      caption: caption ?? this.caption,
      shares: shares ?? this.shares,
      active: active ?? this.active,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isBoosted: isBoosted ?? this.isBoosted,
      boostEndDate: boostEndDate ?? this.boostEndDate,
      boostObjectiveId: boostObjectiveId ?? this.boostObjectiveId,
      boostObjectiveTitle: boostObjectiveTitle ?? this.boostObjectiveTitle,
      communityHidden: communityHidden ?? this.communityHidden,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'content': content,
    'content_type': contentType,
    'created_at': Timestamp.fromDate(createdAt),
    'media': media.map((m) => m.toJson()).toList(),
    'hashtags': hashtags,
    'status': status.name,
    'analytics': analytics.toJson(),
    'likes': likes,
    'reactions': reactions,
    'comments': comments,
    'commentsCount': analytics.commentsCount,
    'commentCount': analytics.commentsCount,
    'group_id': groupId,
    'group_visibility': groupVisibility,
    'feeling_tag': feelingTag,
    'location_tag': locationTag,
    'repost_of': repostOf,
    'caption': caption,
    'shares': shares,
    'active': active,
    'isPinned': isPinned,
    'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
    'isBoosted': isBoosted,
    'boostEndDate': boostEndDate != null
        ? Timestamp.fromDate(boostEndDate!)
        : null,
    'boostObjectiveId': boostObjectiveId,
    'boostObjectiveTitle': boostObjectiveTitle,
    'communityHidden': communityHidden,
  };

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData is! Map<String, dynamic>) {
      throw Exception(
        'Invalid data type for post ${doc.id}: Expected Map<String, dynamic> but got ${rawData.runtimeType}',
      );
    }
    return Post._fromData(doc.id, rawData);
  }

  /// Create a Post from a plain Map (used for local cache restores)
  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post._fromData(id, data);
  }

  static Post _fromData(String id, Map<String, dynamic> data) {
    try {
      // Resolve author data with fallbacks for legacy/incorrect keys
      final authorId =
          (data['authorId'] ?? data['userId'] ?? data['author_id'] ?? '')
              as String?;
      final authorName =
          (data['authorName'] ??
                  data['author'] ??
                  data['user_name'] ??
                  data['name'] ??
                  'Unknown')
              as String?;

      // If authorId is missing, continue but set to empty string so admins can still view content
      final resolvedAuthorId = (authorId == null) ? '' : authorId;
      final resolvedAuthorName = (authorName == null || authorName.isEmpty)
          ? 'Unknown'
          : authorName;

      DateTime parsedCreatedAt;
      final rawCreatedAt = data['created_at'] ?? data['createdAt'];
      if (rawCreatedAt is Timestamp) {
        parsedCreatedAt = rawCreatedAt.toDate();
      } else if (rawCreatedAt is String) {
        parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
      } else if (rawCreatedAt is DateTime) {
        parsedCreatedAt = rawCreatedAt;
      } else if (rawCreatedAt is int) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
      } else if (rawCreatedAt is double) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(
          rawCreatedAt.toInt(),
        );
      } else {
        parsedCreatedAt = DateTime.now();
      }

      PostAnalytics analytics;
      try {
        final analyticsData = Map<String, dynamic>.from(
          data['analytics'] ?? {},
        );
        analytics = PostAnalytics.fromJson(analyticsData);
      } catch (e) {
        // Fallback to empty analytics if parsing fails
        analytics = PostAnalytics();
      }

      // Ensure commentsCount is resolved from root or comments list if analytics was 0
      if (analytics.commentsCount == 0) {
        final rootComments = data['commentsCount'] ??
            data['commentCount'] ??
            data['comments_count'];
        int resolvedCount = 0;
        if (rootComments != null) {
          resolvedCount = PostAnalytics._parseInt(rootComments);
        } else if (data['comments'] is int) {
          resolvedCount = data['comments'] as int;
        } else if (data['comments'] is List) {
          resolvedCount = (data['comments'] as List).length;
        }
        if (resolvedCount > 0) {
          analytics = analytics.copyWith(commentsCount: resolvedCount);
        }
      }

      final rawContentType =
          (data['content_type'] ?? data['contentType'] ?? 'text').toString();

      final mediaFromList =
          (data['media'] as List<dynamic>?)
              ?.map((m) => PostMedia.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          <PostMedia>[];

      final legacyMedia = <PostMedia>[];

      final rawImageUrl = data['imageUrl'];
      if (rawImageUrl is String && rawImageUrl.trim().isNotEmpty) {
        legacyMedia.add(PostMedia(url: rawImageUrl.trim(), type: 'image'));
      }

      final rawMediaUrl = data['mediaUrl'];
      if (rawMediaUrl is String && rawMediaUrl.trim().isNotEmpty) {
        legacyMedia.add(PostMedia(url: rawMediaUrl.trim(), type: 'image'));
      }

      final rawMediaUrls = data['mediaUrls'];
      if (rawMediaUrls is List) {
        for (final entry in rawMediaUrls) {
          if (entry is String && entry.trim().isNotEmpty) {
            legacyMedia.add(PostMedia(url: entry.trim(), type: 'image'));
          }
        }
      }

      final effectiveMedia = mediaFromList.isNotEmpty
          ? mediaFromList
          : legacyMedia;
      final effectiveContentType =
          (rawContentType == 'text' && effectiveMedia.isNotEmpty)
          ? effectiveMedia.first.type
          : rawContentType;

      // Parse pinned and boosted fields
      final isPinned = data['isPinned'] as bool? ?? false;
      DateTime? pinnedAt;
      final rawPinnedAt = data['pinnedAt'];
      if (rawPinnedAt is Timestamp) {
        pinnedAt = rawPinnedAt.toDate();
      } else if (rawPinnedAt is String) {
        pinnedAt = DateTime.tryParse(rawPinnedAt);
      } else if (rawPinnedAt is int) {
        pinnedAt = DateTime.fromMillisecondsSinceEpoch(rawPinnedAt);
      } else if (rawPinnedAt is double) {
        pinnedAt = DateTime.fromMillisecondsSinceEpoch(rawPinnedAt.toInt());
      }

      final rawIsBoosted =
          data['isBoosted'] ??
          data['is_boosted'] ??
          data['boosted'] ??
          data['boost'];
      final isBoosted =
          rawIsBoosted == true ||
          (rawIsBoosted is num && rawIsBoosted != 0) ||
          (rawIsBoosted is String &&
              {'true', '1', 'yes'}.contains(rawIsBoosted.toLowerCase().trim()));

      DateTime? boostEndDate;
      final rawBoostEndDate =
          data['boostEndDate'] ??
          data['boost_end_date'] ??
          data['boostExpiresAt'] ??
          data['boost_expires_at'] ??
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
      if (rawBoostEndDate is Timestamp) {
        boostEndDate = rawBoostEndDate.toDate();
      } else if (rawBoostEndDate is DateTime) {
        boostEndDate = rawBoostEndDate;
      } else if (rawBoostEndDate is int) {
        boostEndDate = rawBoostEndDate > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(rawBoostEndDate)
            : DateTime.fromMillisecondsSinceEpoch(rawBoostEndDate * 1000);
      } else if (rawBoostEndDate is double) {
        final intVal = rawBoostEndDate.toInt();
        boostEndDate = intVal > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(intVal)
            : DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      } else if (rawBoostEndDate is Map) {
        final seconds = rawBoostEndDate['_seconds'] ?? rawBoostEndDate['seconds'];
        if (seconds is num) {
          final nanoseconds =
              rawBoostEndDate['_nanoseconds'] ?? rawBoostEndDate['nanoseconds'] ?? 0;
          boostEndDate = Timestamp(
            seconds.toInt(),
            (nanoseconds as num).toInt(),
          ).toDate();
        }
      } else if (rawBoostEndDate is String) {
        boostEndDate = DateTime.tryParse(rawBoostEndDate);
      }

      return Post(
        id: id,
        authorId: resolvedAuthorId,
        authorName: resolvedAuthorName,
        authorAvatar:
            data['authorAvatar'] ??
            data['author_avatar'] ??
            data['userProfile'] ??
            data['authorProfile'] ??
            '',
        content:
            (data['content'] ??
                    data['caption'] ??
                    data['description'] ??
                    data['text'] ??
                    '')
                .toString(),
        contentType: effectiveContentType,
        createdAt: parsedCreatedAt,
        media: effectiveMedia,
        hashtags: List<String>.from(data['hashtags'] ?? []),
        status: PostStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => PostStatus.active,
        ),
        analytics: analytics,
        likes: List<String>.from((data['likes'] ?? []) as List),
        reactions: data['reactions'] is Map<String, dynamic>
            ? Map<String, String>.from(data['reactions'])
            : {},
        comments: data['comments'] is List
            ? List<Map<String, dynamic>>.from(data['comments'])
            : [],
        groupId: data['group_id'],
        groupVisibility: data['group_visibility'],
        feelingTag: data['feeling_tag'],
        locationTag: data['location_tag'],
        repostOf: data['repost_of'],
        caption: data['caption'] ?? '',
        shares: (data['shares'] as int?) ?? 0,
        active: data['active'] as bool? ?? true,
        isPinned: isPinned,
        pinnedAt: pinnedAt,
        isBoosted: isBoosted,
        boostEndDate: boostEndDate,
        boostObjectiveId: data['boostObjectiveId'] ?? data['objectiveId'],
        boostObjectiveTitle:
            data['boostObjectiveTitle'] ?? data['objectiveTitle'],
        communityHidden: data['communityHidden'] as bool? ?? false,
      );
    } catch (e) {
      throw Exception('Failed to parse post $id: $e');
    }
  }

  // Debug method to check status
  void debugStatus() {
    // Debug info removed for performance
  }
}
