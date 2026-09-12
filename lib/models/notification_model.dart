enum NotificationType {
  newFollower,
  newComment,
  newPostFromFollowed,
  postReachMilestone,
  communityViolation,
  temporaryBan,
  postRemoved,
  like,
  share,
  message,
  mention,
  liveStarted,
  liveEnded,
  systemUpdate,
  appealSubmitted,
  jobPendingApproval,
  jobApproved,
  jobRejected,
  jobApplication,
  applicationRejected,
  orderPlaced,
}

class FarmerNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionUserId;
  final String? actionUserName;
  final String? actionUserProfilePic;
  final String? postId;
  final String? postContent;
  final String? commentId;
  final String? commentContent;
  final String? chatId;
  final String? messageId;
  final String? messageContent;
  final bool isRead;
  final bool isPushSent;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  const FarmerNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUserId,
    this.actionUserName,
    this.actionUserProfilePic,
    this.postId,
    this.postContent,
    this.commentId,
    this.commentContent,
    this.chatId,
    this.messageId,
    this.messageContent,
    this.isRead = false,
    this.isPushSent = false,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  /// Manual factory for Firestore/JSON maps
  factory FarmerNotification.fromMap(Map<String, dynamic> map) {
    return FarmerNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: _notificationTypeFromString(map['type']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      actionUserId: map['actionUserId'],
      actionUserName: map['actionUserName'],
      actionUserProfilePic: map['actionUserProfilePic'],
      postId: map['postId'],
      postContent: map['postContent'],
      commentId: map['commentId'],
      commentContent: map['commentContent'],
      chatId: map['chatId'],
      messageId: map['messageId'],
      messageContent: map['messageContent'],
      isRead: map['isRead'] ?? false,
      isPushSent: map['isPushSent'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: map['readAt'] != null
          ? DateTime.tryParse(map['readAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionUserId': actionUserId,
      'actionUserName': actionUserName,
      'actionUserProfilePic': actionUserProfilePic,
      'postId': postId,
      'postContent': postContent,
      'commentId': commentId,
      'commentContent': commentContent,
      'chatId': chatId,
      'messageId': messageId,
      'messageContent': messageContent,
      'isRead': isRead,
      'isPushSent': isPushSent,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  FarmerNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? actionUserId,
    String? actionUserName,
    String? actionUserProfilePic,
    String? postId,
    String? postContent,
    String? commentId,
    String? commentContent,
    String? chatId,
    String? messageId,
    String? messageContent,
    bool? isRead,
    bool? isPushSent,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return FarmerNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUserId: actionUserId ?? this.actionUserId,
      actionUserName: actionUserName ?? this.actionUserName,
      actionUserProfilePic: actionUserProfilePic ?? this.actionUserProfilePic,
      postId: postId ?? this.postId,
      postContent: postContent ?? this.postContent,
      commentId: commentId ?? this.commentId,
      commentContent: commentContent ?? this.commentContent,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      messageContent: messageContent ?? this.messageContent,
      isRead: isRead ?? this.isRead,
      isPushSent: isPushSent ?? this.isPushSent,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  static NotificationType _notificationTypeFromString(String? value) {
    if (value == null) return NotificationType.systemUpdate;
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.systemUpdate,
    );
  }
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newFollower:
        return 'New Follower';
      case NotificationType.newComment:
        return 'New Comment';
      case NotificationType.newPostFromFollowed:
        return 'New Post';
      case NotificationType.postReachMilestone:
        return 'Post Milestone';
      case NotificationType.communityViolation:
        return 'Community Violation';
      case NotificationType.temporaryBan:
        return 'Temporary Ban';
      case NotificationType.postRemoved:
        return 'Post Removed';
      case NotificationType.like:
        return 'Like';
      case NotificationType.share:
        return 'Share';
      case NotificationType.message:
        return 'Message';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.liveStarted:
        return 'Live Started';
      case NotificationType.liveEnded:
        return 'Live Ended';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.appealSubmitted:
        return 'Appeal Submitted';
      case NotificationType.jobPendingApproval:
        return 'Job Pending Approval';
      case NotificationType.jobApproved:
        return 'Job Approved';
      case NotificationType.jobRejected:
        return 'Job Not Approved';
      case NotificationType.jobApplication:
        return 'New Job Application';
      case NotificationType.applicationRejected:
        return 'Application Not Accepted';
      case NotificationType.orderPlaced:
        return 'New Marketplace Order';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.newFollower:
        return '👥';
      case NotificationType.newComment:
        return '💬';
      case NotificationType.newPostFromFollowed:
        return '📝';
      case NotificationType.postReachMilestone:
        return '🎯';
      case NotificationType.communityViolation:
        return '⚠️';
      case NotificationType.temporaryBan:
        return '🚫';
      case NotificationType.postRemoved:
        return '🗑️';
      case NotificationType.like:
        return '❤️';
      case NotificationType.share:
        return '🔄';
      case NotificationType.message:
        return '📨';
      case NotificationType.mention:
        return '@';
      case NotificationType.liveStarted:
        return '🔴';
      case NotificationType.liveEnded:
        return '⏹️';
      case NotificationType.systemUpdate:
        return '🔔';
      case NotificationType.appealSubmitted:
        return '📋';
      case NotificationType.jobPendingApproval:
        return '⏳';
      case NotificationType.jobApproved:
        return '✅';
      case NotificationType.jobRejected:
        return '❌';
      case NotificationType.jobApplication:
        return '📩';
      case NotificationType.applicationRejected:
        return '💼';
      case NotificationType.orderPlaced:
        return '🛍️';
    }
  }
}
