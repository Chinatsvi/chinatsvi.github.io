class Follow {
  final String id;
  final String followerId;
  final String followerName;
  final String? followerProfilePic;
  final String followingId;
  final String followingName;
  final String? followingProfilePic;
  final DateTime createdAt;

  const Follow({
    required this.id,
    required this.followerId,
    required this.followerName,
    this.followerProfilePic,
    required this.followingId,
    required this.followingName,
    this.followingProfilePic,
    required this.createdAt,
  });

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      id: map['id'] ?? '',
      followerId: map['followerId'] ?? '',
      followerName: map['followerName'] ?? '',
      followerProfilePic: map['followerProfilePic'],
      followingId: map['followingId'] ?? '',
      followingName: map['followingName'] ?? '',
      followingProfilePic: map['followingProfilePic'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'followerId': followerId,
      'followerName': followerName,
      'followerProfilePic': followerProfilePic,
      'followingId': followingId,
      'followingName': followingName,
      'followingProfilePic': followingProfilePic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Follow copyWith({
    String? id,
    String? followerId,
    String? followerName,
    String? followerProfilePic,
    String? followingId,
    String? followingName,
    String? followingProfilePic,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followerName: followerName ?? this.followerName,
      followerProfilePic: followerProfilePic ?? this.followerProfilePic,
      followingId: followingId ?? this.followingId,
      followingName: followingName ?? this.followingName,
      followingProfilePic: followingProfilePic ?? this.followingProfilePic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FollowRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterProfilePic;
  final String targetId;
  final String targetName;
  final String? targetProfilePic;
  final String message;
  final FollowRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FollowRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterProfilePic,
    required this.targetId,
    required this.targetName,
    this.targetProfilePic,
    this.message = '',
    this.status = FollowRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory FollowRequest.fromMap(Map<String, dynamic> map) {
    return FollowRequest(
      id: map['id'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterProfilePic: map['requesterProfilePic'],
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      targetProfilePic: map['targetProfilePic'],
      message: map['message'] ?? '',
      status: _statusFromString(map['status']),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      respondedAt: map['respondedAt'] is DateTime
          ? map['respondedAt']
          : DateTime.tryParse(map['respondedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterProfilePic': requesterProfilePic,
      'targetId': targetId,
      'targetName': targetName,
      'targetProfilePic': targetProfilePic,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  FollowRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterProfilePic,
    String? targetId,
    String? targetName,
    String? targetProfilePic,
    String? message,
    FollowRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FollowRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterProfilePic: requesterProfilePic ?? this.requesterProfilePic,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetProfilePic: targetProfilePic ?? this.targetProfilePic,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  static FollowRequestStatus _statusFromString(String? status) {
    switch (status) {
      case 'accepted':
        return FollowRequestStatus.accepted;
      case 'rejected':
        return FollowRequestStatus.rejected;
      default:
        return FollowRequestStatus.pending;
    }
  }
}

enum FollowRequestStatus { pending, accepted, rejected }

extension FollowRequestStatusExtension on FollowRequestStatus {
  String get displayName {
    switch (this) {
      case FollowRequestStatus.pending:
        return 'Pending';
      case FollowRequestStatus.accepted:
        return 'Accepted';
      case FollowRequestStatus.rejected:
        return 'Rejected';
    }
  }
}