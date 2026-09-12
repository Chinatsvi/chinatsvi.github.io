// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViolationReport _$ViolationReportFromJson(Map<String, dynamic> json) =>
    ViolationReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      reporterProfilePic: json['reporterProfilePic'] as String?,
      reportedUserId: json['reportedUserId'] as String?,
      reportedUserName: json['reportedUserName'] as String?,
      reportedPostId: json['reportedPostId'] as String?,
      reportedCommentId: json['reportedCommentId'] as String?,
      violationType: $enumDecode(_$ViolationTypeEnumMap, json['violationType']),
      description: json['description'] as String,
      evidenceUrls:
          (json['evidenceUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status:
          $enumDecodeNullable(_$ModerationStatusEnumMap, json['status']) ??
          ModerationStatus.pending,
      moderatorId: json['moderatorId'] as String?,
      moderatorName: json['moderatorName'] as String?,
      actionTaken: $enumDecodeNullable(
        _$ModerationActionEnumMap,
        json['actionTaken'],
      ),
      actionReason: json['actionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
    );

Map<String, dynamic> _$ViolationReportToJson(ViolationReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'reporterName': instance.reporterName,
      'reporterProfilePic': instance.reporterProfilePic,
      'reportedUserId': instance.reportedUserId,
      'reportedUserName': instance.reportedUserName,
      'reportedPostId': instance.reportedPostId,
      'reportedCommentId': instance.reportedCommentId,
      'violationType': _$ViolationTypeEnumMap[instance.violationType]!,
      'description': instance.description,
      'evidenceUrls': instance.evidenceUrls,
      'status': _$ModerationStatusEnumMap[instance.status]!,
      'moderatorId': instance.moderatorId,
      'moderatorName': instance.moderatorName,
      'actionTaken': _$ModerationActionEnumMap[instance.actionTaken],
      'actionReason': instance.actionReason,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
    };

const _$ViolationTypeEnumMap = {
  ViolationType.nudity: 'nudity',
  ViolationType.prohibitedGoods: 'prohibitedGoods',
  ViolationType.harassment: 'harassment',
  ViolationType.sexualContent: 'sexualContent',
  ViolationType.abuse: 'abuse',
  ViolationType.threats: 'threats',
  ViolationType.spam: 'spam',
  ViolationType.misinformation: 'misinformation',
  ViolationType.hateSpeech: 'hateSpeech',
  ViolationType.violence: 'violence',
  ViolationType.copyright: 'copyright',
  ViolationType.other: 'other',
};

const _$ModerationStatusEnumMap = {
  ModerationStatus.pending: 'pending',
  ModerationStatus.reviewed: 'reviewed',
  ModerationStatus.resolved: 'resolved',
  ModerationStatus.appealed: 'appealed',
};

const _$ModerationActionEnumMap = {
  ModerationAction.warning: 'warning',
  ModerationAction.temporaryBan24h: 'temporaryBan24h',
  ModerationAction.temporaryBan7d: 'temporaryBan7d',
  ModerationAction.temporaryBan30d: 'temporaryBan30d',
  ModerationAction.permanentBan: 'permanentBan',
  ModerationAction.contentRemoval: 'contentRemoval',
};

UserBan _$UserBanFromJson(Map<String, dynamic> json) => UserBan(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  userProfilePic: json['userProfilePic'] as String?,
  banType: $enumDecode(_$ModerationActionEnumMap, json['banType']),
  reason: json['reason'] as String,
  banStartsAt: DateTime.parse(json['banStartsAt'] as String),
  banEndsAt: json['banEndsAt'] == null
      ? null
      : DateTime.parse(json['banEndsAt'] as String),
  isPermanent: json['isPermanent'] as bool? ?? false,
  isActive: json['isActive'] as bool? ?? true,
  moderatorId: json['moderatorId'] as String,
  moderatorName: json['moderatorName'] as String,
  violationCount: (json['violationCount'] as num?)?.toInt() ?? 0,
  previousViolations:
      (json['previousViolations'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ViolationTypeEnumMap, e))
          .toList() ??
      const [],
  appealStatus:
      $enumDecodeNullable(_$ModerationStatusEnumMap, json['appealStatus']) ??
      ModerationStatus.pending,
  appealReason: json['appealReason'] as String?,
  appealedAt: json['appealedAt'] == null
      ? null
      : DateTime.parse(json['appealedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserBanToJson(UserBan instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'userProfilePic': instance.userProfilePic,
  'banType': _$ModerationActionEnumMap[instance.banType]!,
  'reason': instance.reason,
  'banStartsAt': instance.banStartsAt.toIso8601String(),
  'banEndsAt': instance.banEndsAt?.toIso8601String(),
  'isPermanent': instance.isPermanent,
  'isActive': instance.isActive,
  'moderatorId': instance.moderatorId,
  'moderatorName': instance.moderatorName,
  'violationCount': instance.violationCount,
  'previousViolations': instance.previousViolations
      .map((e) => _$ViolationTypeEnumMap[e]!)
      .toList(),
  'appealStatus': _$ModerationStatusEnumMap[instance.appealStatus]!,
  'appealReason': instance.appealReason,
  'appealedAt': instance.appealedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};
