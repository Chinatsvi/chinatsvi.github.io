import 'package:json_annotation/json_annotation.dart';

part 'moderation_model.g.dart';

/// Enums
enum ViolationType {
  nudity,
  prohibitedGoods,
  harassment,
  sexualContent,
  abuse,
  threats,
  spam,
  misinformation,
  hateSpeech,
  violence,
  copyright,
  other,
}

enum ModerationAction {
  warning,
  temporaryBan24h,
  temporaryBan7d,
  temporaryBan30d,
  permanentBan,
  contentRemoval,
}

enum ModerationStatus { pending, reviewed, resolved, appealed }

/// Violation Report
@JsonSerializable()
class ViolationReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? reporterProfilePic;
  final String? reportedUserId;
  final String? reportedUserName;
  final String? reportedPostId;
  final String? reportedCommentId;
  final ViolationType violationType;
  final String description;
  final List<String> evidenceUrls;
  final ModerationStatus status;
  final String? moderatorId;
  final String? moderatorName;
  final ModerationAction? actionTaken;
  final String? actionReason;
  // Content fields for admin review
  final String? reportedContent;
  final String? reportedContentType; // 'post', 'comment', 'reply'
  final List<String>? reportedMediaUrls;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;

  const ViolationReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reporterProfilePic,
    this.reportedUserId,
    this.reportedUserName,
    this.reportedPostId,
    this.reportedCommentId,
    required this.violationType,
    required this.description,
    this.evidenceUrls = const [],
    this.status = ModerationStatus.pending,
    this.moderatorId,
    this.moderatorName,
    this.actionTaken,
    this.actionReason,
    this.reportedContent,
    this.reportedContentType,
    this.reportedMediaUrls,
    required this.createdAt,
    this.reviewedAt,
    this.resolvedAt,
  });

  factory ViolationReport.fromJson(Map<String, dynamic> json) =>
      _$ViolationReportFromJson(json);

  Map<String, dynamic> toJson() => _$ViolationReportToJson(this);

  ViolationReport copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? reporterProfilePic,
    String? reportedUserId,
    String? reportedUserName,
    String? reportedPostId,
    String? reportedCommentId,
    ViolationType? violationType,
    String? description,
    List<String>? evidenceUrls,
    ModerationStatus? status,
    String? moderatorId,
    String? moderatorName,
    ModerationAction? actionTaken,
    String? actionReason,
    String? reportedContent,
    String? reportedContentType,
    List<String>? reportedMediaUrls,
    DateTime? createdAt,
    DateTime? reviewedAt,
    DateTime? resolvedAt,
  }) {
    return ViolationReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterProfilePic: reporterProfilePic ?? this.reporterProfilePic,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reportedPostId: reportedPostId ?? this.reportedPostId,
      reportedCommentId: reportedCommentId ?? this.reportedCommentId,
      violationType: violationType ?? this.violationType,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      status: status ?? this.status,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      actionTaken: actionTaken ?? this.actionTaken,
      actionReason: actionReason ?? this.actionReason,
      reportedContent: reportedContent ?? this.reportedContent,
      reportedContentType: reportedContentType ?? this.reportedContentType,
      reportedMediaUrls: reportedMediaUrls ?? this.reportedMediaUrls,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViolationReport &&
        other.id == id &&
        other.reporterId == reporterId &&
        other.reporterName == reporterName &&
        other.reporterProfilePic == reporterProfilePic &&
        other.reportedUserId == reportedUserId &&
        other.reportedUserName == reportedUserName &&
        other.reportedPostId == reportedPostId &&
        other.reportedCommentId == reportedCommentId &&
        other.violationType == violationType &&
        other.description == description &&
        other.evidenceUrls == evidenceUrls &&
        other.status == status &&
        other.moderatorId == moderatorId &&
        other.moderatorName == moderatorName &&
        other.actionTaken == actionTaken &&
        other.actionReason == actionReason &&
        other.createdAt == createdAt &&
        other.reviewedAt == reviewedAt &&
        other.resolvedAt == resolvedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reporterId,
      reporterName,
      reporterProfilePic,
      reportedUserId,
      reportedUserName,
      reportedPostId,
      reportedCommentId,
      violationType,
      description,
      evidenceUrls,
      status,
      moderatorId,
      moderatorName,
      actionTaken,
      actionReason,
      createdAt,
      reviewedAt,
      resolvedAt,
    );
  }

  @override
  String toString() {
    return 'ViolationReport(id: $id, reporterId: $reporterId, reporterName: $reporterName, reporterProfilePic: $reporterProfilePic, reportedUserId: $reportedUserId, reportedUserName: $reportedUserName, reportedPostId: $reportedPostId, reportedCommentId: $reportedCommentId, violationType: $violationType, description: $description, evidenceUrls: $evidenceUrls, status: $status, moderatorId: $moderatorId, moderatorName: $moderatorName, actionTaken: $actionTaken, actionReason: $actionReason, createdAt: $createdAt, reviewedAt: $reviewedAt, resolvedAt: $resolvedAt)';
  }
}

/// User Ban
@JsonSerializable()
class UserBan {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final ModerationAction banType;
  final String reason;
  final DateTime banStartsAt;
  final DateTime? banEndsAt;
  final bool isPermanent;
  final bool isActive;
  final String moderatorId;
  final String moderatorName;
  final int violationCount;
  final List<ViolationType> previousViolations;
  final ModerationStatus appealStatus;
  final String? appealReason;
  final DateTime? appealedAt;
  final DateTime createdAt;

  const UserBan({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.banType,
    required this.reason,
    required this.banStartsAt,
    this.banEndsAt,
    this.isPermanent = false,
    this.isActive = true,
    required this.moderatorId,
    required this.moderatorName,
    this.violationCount = 0,
    this.previousViolations = const [],
    this.appealStatus = ModerationStatus.pending,
    this.appealReason,
    this.appealedAt,
    required this.createdAt,
  });

  factory UserBan.fromJson(Map<String, dynamic> json) =>
      _$UserBanFromJson(json);

  Map<String, dynamic> toJson() => _$UserBanToJson(this);

  UserBan copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    ModerationAction? banType,
    String? reason,
    DateTime? banStartsAt,
    DateTime? banEndsAt,
    bool? isPermanent,
    bool? isActive,
    String? moderatorId,
    String? moderatorName,
    int? violationCount,
    List<ViolationType>? previousViolations,
    ModerationStatus? appealStatus,
    String? appealReason,
    DateTime? appealedAt,
    DateTime? createdAt,
  }) {
    return UserBan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      banType: banType ?? this.banType,
      reason: reason ?? this.reason,
      banStartsAt: banStartsAt ?? this.banStartsAt,
      banEndsAt: banEndsAt ?? this.banEndsAt,
      isPermanent: isPermanent ?? this.isPermanent,
      isActive: isActive ?? this.isActive,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      violationCount: violationCount ?? this.violationCount,
      previousViolations: previousViolations ?? this.previousViolations,
      appealStatus: appealStatus ?? this.appealStatus,
      appealReason: appealReason ?? this.appealReason,
      appealedAt: appealedAt ?? this.appealedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBan &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.userProfilePic == userProfilePic &&
        other.banType == banType &&
        other.reason == reason &&
        other.banStartsAt == banStartsAt &&
        other.banEndsAt == banEndsAt &&
        other.isPermanent == isPermanent &&
        other.isActive == isActive &&
        other.moderatorId == moderatorId &&
        other.moderatorName == moderatorName &&
        other.violationCount == violationCount &&
        other.previousViolations == previousViolations &&
        other.appealStatus == appealStatus &&
        other.appealReason == appealReason &&
        other.appealedAt == appealedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userName,
      userProfilePic,
      banType,
      reason,
      banStartsAt,
      banEndsAt,
      isPermanent,
      isActive,
      moderatorId,
      moderatorName,
      violationCount,
      previousViolations,
      appealStatus,
      appealReason,
      appealedAt,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'UserBan(id: $id, userId: $userId, userName: $userName, userProfilePic: $userProfilePic, banType: $banType, reason: $reason, banStartsAt: $banStartsAt, banEndsAt: $banEndsAt, isPermanent: $isPermanent, isActive: $isActive, moderatorId: $moderatorId, moderatorName: $moderatorName, violationCount: $violationCount, previousViolations: $previousViolations, appealStatus: $appealStatus, appealReason: $appealReason, appealedAt: $appealedAt, createdAt: $createdAt)';
  }
}
