import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorProfilePic;
  final String content;
  final String? parentId;
  final int repliesCount;
  final int likesCount;
  final bool isLiked;
  final bool isFlagged;
  final String? flaggedReason;
  final CommentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ Verification fields
  final bool isVerified;
  final String? verificationStatus;
  final bool verificationPaid;
  final DateTime? verificationPaidAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorProfilePic,
    required this.content,
    this.parentId,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.isFlagged = false,
    this.flaggedReason,
    this.status = CommentStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.verificationStatus,
    this.verificationPaid = false,
    this.verificationPaidAt,
  });

  /// JSON serialization
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorProfilePic: json['authorProfilePic'] as String?,
      content: json['content'] as String,
      parentId: json['parentId'] as String?,
      repliesCount: (json['repliesCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isFlagged: json['isFlagged'] as bool? ?? false,
      flaggedReason: json['flaggedReason'] as String?,
      status: CommentStatusX.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      verificationStatus: json['verificationStatus'] as String?,
      verificationPaid: json['verificationPaid'] as bool? ?? false,
        verificationPaidAt: json['verificationPaidAt'] != null
          ? DateTime.parse(json['verificationPaidAt'] as String)
          : (json['verificationPaidat'] != null
            ? DateTime.parse(json['verificationPaidat'] as String)
            : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfilePic': authorProfilePic,
      'content': content,
      'parentId': parentId,
      'repliesCount': repliesCount,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isFlagged': isFlagged,
      'flaggedReason': flaggedReason,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationPaid': verificationPaid,
      if (verificationPaidAt != null)
        'verificationPaidAt': verificationPaidAt!.toIso8601String(),
    };
  }

  /// Firestore factory
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['user_id'] ?? '',
      authorName: data['user_name'] ?? '',
      authorProfilePic: data['user_profile'],
      content: data['content'] ?? data['text'] ?? '',
      parentId: data['parentId'],
      repliesCount: (data['repliesCount'] as num?)?.toInt() ?? 0,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: data['isLiked'] ?? false,
      isFlagged: data['isFlagged'] ?? false,
      flaggedReason: data['flaggedReason'],
      status: CommentStatusX.fromString(data['status']),
      createdAt: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      verificationStatus: data['verificationStatus'],
      verificationPaid: data['verificationPaid'] ?? false,
        verificationPaidAt: (data['verificationPaidAt'] is Timestamp)
          ? (data['verificationPaidAt'] as Timestamp).toDate()
          : (data['verificationPaidat'] is Timestamp)
            ? (data['verificationPaidat'] as Timestamp).toDate()
            : null,
    );
  }

  /// Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'user_id': authorId,
      'user_name': authorName,
      'user_profile': authorProfilePic ?? '',
      'content': content,
      'parentId': parentId,
      'repliesCount': repliesCount,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isFlagged': isFlagged,
      'flaggedReason': flaggedReason,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'verificationPaid': verificationPaid,
      if (verificationPaidAt != null)
        'verificationPaidAt': Timestamp.fromDate(verificationPaidAt!),
    };
  }

  /// ✅ Helper: should show tick
  bool get showTick {
    return isVerified &&
        verificationStatus == "approved" &&
        verificationPaid &&
        !isPaymentExpired;
  }

  /// ✅ Helper: check if payment expired
  bool get isPaymentExpired {
    if (verificationPaidAt == null) return true;
    final now = DateTime.now();
    return now.difference(verificationPaidAt!).inDays >= 30;
  }
}

enum CommentStatus { active, flagged, removed, pending }

extension CommentStatusX on CommentStatus {
  static CommentStatus fromString(String? status) {
    if (status == null) return CommentStatus.active;
    return CommentStatus.values.firstWhere(
      (e) => e.toString() == 'CommentStatus.$status',
      orElse: () => CommentStatus.active,
    );
  }
}