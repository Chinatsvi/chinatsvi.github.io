import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/moderation_model.dart';
import '../models/notification_model.dart';
import 'ai_content_moderation_service.dart';
import 'moderation_notification_service.dart';
import 'farmer_reputation_service.dart';
import 'farmer_status_scheduler.dart';
import 'notifications/notification_service.dart';

class ModerationService {
  static const String _reportsCollection = 'moderation_reports';
  static const String _bansCollection = 'user_bans';
  static const String _warningsCollection = 'user_warnings';

  // Get current moderator/admin user info for audit trail
  static Map<String, String> getCurrentModeratorInfo() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return {
          'id': user.uid,
          'name': user.displayName ?? 'Anonymous Moderator',
          'email': user.email ?? '',
        };
      }
    } catch (e) {
      developer.log(
        'Error getting current moderator info: $e',
        name: 'ModerationService',
      );
    }
    return {'id': 'system', 'name': 'System Moderator', 'email': ''};
  }

  // Auto-detect moderator info for system actions
  static Map<String, String> _getModeratorInfo({
    String? customModeratorId,
    String? customModeratorName,
  }) {
    if (customModeratorId != null && customModeratorName != null) {
      return {
        'id': customModeratorId,
        'name': customModeratorName,
        'email': '',
      };
    }
    return getCurrentModeratorInfo();
  }

  // Check content for violations
  static Future<bool> checkContent({
    required String text,
    required String postId,
    required String userId,
    String contentType = 'post',
    List<String>? mediaUrls,
    String? imageUrl,
  }) async {
    developer.log(
      '🔍 Starting moderation check for $contentType $postId by user $userId',
      name: 'ModerationService',
    );

    // Try AI moderation first
    final aiResult = await AIContentModerationService.moderateContent(
      text,
      contentType: contentType,
      mediaUrls: mediaUrls,
      imageUrl: imageUrl,
    );

    List<ViolationType> violations = [];
    if (aiResult.isFlagged) {
      for (final category in aiResult.categories.keys) {
        final catLower = category.toLowerCase();
        if (catLower.contains('sexual') || catLower.contains('nude') || catLower.contains('nudity')) {
          violations.add(ViolationType.sexualContent);
        } else if (catLower.contains('drug') || catLower.contains('prohibited') || catLower.contains('goods')) {
          violations.add(ViolationType.prohibitedGoods);
        } else if (catLower.contains('hate')) {
          violations.add(ViolationType.hateSpeech);
        } else if (catLower.contains('violence')) {
          violations.add(ViolationType.violence);
        } else if (catLower.contains('spam')) {
          violations.add(ViolationType.spam);
        } else if (catLower.contains('harass') || catLower.contains('abuse')) {
          violations.add(ViolationType.harassment);
        } else {
          violations.add(ViolationType.other);
        }
      }
      if (violations.isEmpty) {
        violations.add(ViolationType.other);
      }
    } else {
      // Fallback rule scan
      violations = _detectViolations(text);
    }

    developer.log(
      '🔍 Detected violations: $violations',
      name: 'ModerationService',
    );

    if (violations.isNotEmpty) {
      // Create violation report
      final reportId = await _createViolationReport(
        postId: postId,
        userId: userId,
        violations: violations,
        text: text,
        contentType: contentType,
        mediaUrls: mediaUrls ?? (imageUrl != null ? [imageUrl] : null),
        isAutoDetected: true,
      );

      developer.log(
        '🚨 Content violations detected: $violations',
        name: 'ModerationService',
      );

      developer.log(
        '🚫 Auto-takedown triggered for violations ($contentType)',
        name: 'ModerationService',
      );

      if (contentType == 'marketplace') {
        await removeMarketplaceItem(
          postId,
          reason: 'Auto-detected violation: ${violations.map((v) => v.name).join(", ")}',
          violationId: reportId,
        );
      } else if (contentType == 'profile_picture') {
        await removeProfilePicture(
          userId,
          reason: 'Auto-detected violation: ${violations.map((v) => v.name).join(", ")}',
          violationId: reportId,
        );
      } else if (contentType == 'cover_photo') {
        await removeCoverPhoto(
          userId,
          reason: 'Auto-detected violation: ${violations.map((v) => v.name).join(", ")}',
          violationId: reportId,
        );
      } else if (contentType == 'comment') {
        await removeComment(
          postId,
          reason: 'Auto-detected violation: ${violations.map((v) => v.name).join(", ")}',
          violationId: reportId,
        );
      } else {
        await removeContent(
          postId,
          reason: 'Auto-detected violation: ${violations.map((v) => v.name).join(", ")}',
          violationId: reportId,
        );
      }

      // Send warning
      await issueWarning(
        userId: userId,
        userName: 'User',
        reason: 'Content violation ($contentType): ${violations.map((v) => v.name).join(", ")}',
      );

      // Send notification with appeal button
      await ModerationNotificationService.sendWarningWithAppeal(
        userId: userId,
        postId: postId,
        violations: violations,
        reason: violations.map((v) => v.name).join(", "),
      );

      // Update user reputation
      await FarmerReputationService.onModerationAction(userId);
      await FarmerReputationService.updateFarmerStatus(userId);

      return false;
    }

    developer.log(
      '✅ No violations detected, content allowed',
      name: 'ModerationService',
    );
    return true;
  }

  /// Detect violations in text with precise word boundaries & agricultural awareness
  static List<ViolationType> detectViolations(String text) => _detectViolations(text);

  static List<ViolationType> _detectViolations(String text) {
    final lowerText = text.toLowerCase();
    final violations = <ViolationType>[];

    // Explicit sexual content (strictly whole words / explicit terms only)
    final sexualRegex = RegExp(
      r'\b(porn|porno|pornography|xxx|nsfw|nude|nudes|nudity|naked|genitals|masturbat\w*|erotic|blowjob|handjob|dildo|vagina|penis)\b',
      caseSensitive: false,
    );
    if (sexualRegex.hasMatch(lowerText)) {
      violations.add(ViolationType.sexualContent);
      developer.log('🔍 DEBUG Explicit sexual violation', name: 'ModerationService');
    }

    // Illicit hard drugs (explicit street narcotics, strictly separated from agricultural chemicals & weeds)
    final hardDrugsRegex = RegExp(
      r'\b(cocaine|heroin|crystal meth|methamphetamine|fentanyl|crack cocaine)\b',
      caseSensitive: false,
    );
    if (hardDrugsRegex.hasMatch(lowerText)) {
      violations.add(ViolationType.prohibitedGoods);
      developer.log('🔍 DEBUG Illicit drug violation', name: 'ModerationService');
    }

    // Hate speech detection
    final hateRegex = RegExp(
      r'\b(white supremacy|kill all \w+|death to \w+|genocide|nazi)\b',
      caseSensitive: false,
    );
    if (hateRegex.hasMatch(lowerText)) {
      violations.add(ViolationType.hateSpeech);
      developer.log('🔍 DEBUG Hate speech violation', name: 'ModerationService');
    }

    // Spam detection - skip if farming context
    final isFarming = _isFarmingContext(lowerText);
    if (!isFarming) {
      final spamRegex = RegExp(
        r'\b(free money giveaway|send btc get double|ponzi scheme|crypto investment guarantee)\b',
        caseSensitive: false,
      );
      if (spamRegex.hasMatch(lowerText)) {
        violations.add(ViolationType.spam);
        developer.log('🔍 DEBUG Spam violation', name: 'ModerationService');
      }
    }

    return violations;
  }

  // Create violation report
  static Future<String> _createViolationReport({
    required String postId,
    required String userId,
    required List<ViolationType> violations,
    required String text,
    String contentType = 'post',
    List<String>? mediaUrls,
    required bool isAutoDetected,
  }) async {
    final report = ViolationReport(
      id: FirebaseFirestore.instance.collection(_reportsCollection).doc().id,
      reporterId: 'system',
      reporterName: 'Auto-Moderation',
      reportedUserId: userId,
      reportedPostId: postId,
      violationType: violations.isNotEmpty ? violations.first : ViolationType.other,
      reportedContentType: contentType,
      reportedContent: text,
      reportedMediaUrls: mediaUrls,
      description:
          'Auto-detected violations ($contentType): ${violations.map((v) => v.name).join(", ")}\nContent: "$text"',
      status: ModerationStatus.resolved,
      actionTaken: ModerationAction.contentRemoval,
      actionReason: 'Auto-detected violations: ${violations.map((v) => v.name).join(", ")}',
      createdAt: DateTime.now(),
      resolvedAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(report.id)
        .set(report.toJson());

    return report.id;
  }

  // Report content manually
  static Future<void> reportContent({
    required String postId,
    required String postAuthorId,
    required String postAuthorName,
    required ViolationType violationType,
    required String description,
    String? reporterId,
    String? reporterName,
    String? reporterProfilePic,
    String? reportedContent,
    String? reportedContentType,
    List<String>? reportedMediaUrls,
  }) async {
    // Get current user info if not provided
    final moderatorInfo = reporterId != null && reporterName != null
        ? {'id': reporterId, 'name': reporterName, 'email': ''}
        : getCurrentModeratorInfo();

    // If content is not provided, fetch it from the post
    String? content = reportedContent;
    String? contentType = reportedContentType;
    List<String>? mediaUrls = reportedMediaUrls;

    if (content == null && postId.isNotEmpty) {
      try {
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          final postData = postDoc.data()!;
          content = postData['content'] ?? '';
          contentType = 'post';

          // Extract media URLs if present
          if (postData['media'] != null && postData['media'] is List) {
            mediaUrls = (postData['media'] as List)
                .map((m) => m['url'] as String? ?? '')
                .where((url) => url.isNotEmpty)
                .toList();
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching post content: $e',
          name: 'ModerationService',
        );
      }
    }

    final report = ViolationReport(
      id: FirebaseFirestore.instance.collection(_reportsCollection).doc().id,
      reporterId: moderatorInfo['id']!,
      reporterName: moderatorInfo['name']!,
      reporterProfilePic: reporterProfilePic,
      reportedUserId: postAuthorId,
      reportedUserName: postAuthorName,
      reportedPostId: postId,
      violationType: violationType,
      description: description,
      status: ModerationStatus.pending,
      reportedContent: content,
      reportedContentType: contentType,
      reportedMediaUrls: mediaUrls,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(report.id)
        .set(report.toJson());

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({
          'communityHidden': true,
          'moderationStatus': 'pending_review',
          'is_under_review': true,
          'review_timestamp': FieldValue.serverTimestamp(),
          'active': true,
        });

    if (postAuthorId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: postAuthorId,
        type: NotificationType.communityViolation,
        title: 'Post Under Review',
        body:
            'Your post has been reported and is hidden from other users while moderators review it.',
        postId: postId,
        additionalData: {
          'requiresAction': false,
          'postId': postId,
          'contentType': 'post',
          'reviewStatus': 'pending_review',
        },
      );
    }

    developer.log(
      '📝 Content reported: ${report.id} by ${moderatorInfo['name']}',
      name: 'ModerationService',
    );

    // Send notification to all admins about the new report
    await _sendAdminReportNotification(report);
  }

  // Send notification to all admins about new content report
  static Future<void> _sendAdminReportNotification(
    ViolationReport report,
  ) async {
    try {
      // Get all admin users
      final adminUsers = await FirebaseFirestore.instance
          .collection('farmers')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminUsers.docs.isEmpty) {
        developer.log(
          '⚠️ No admin users found to send notification',
          name: 'ModerationService',
        );
        return;
      }

      // Create notification data
      final notificationData = {
        'type': 'admin_report_notification',
        'reportId': report.id,
        'reportType': 'content',
        'violationType': report.violationType.name,
        'reportedUserId': report.reportedUserId,
        'reportedUserName': report.reportedUserName,
        'reporterId': report.reporterId,
        'reporterName': report.reporterName,
        'reportedPostId': report.reportedPostId,
        'description': report.description,
        'reportedMediaUrls': report.reportedMediaUrls ?? [],
        'title': 'New Content Report',
        'body':
            'New ${report.violationType.name} report by ${report.reporterName}',
        'isRead': false,
        'priority': 2, // High priority for admin notifications
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'contentType': 'post',
          'reportId': report.id,
          'reportedMediaUrls': report.reportedMediaUrls ?? [],
        },
      };

      // Send notification to admin collection (centralized admin notifications)
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .add(notificationData);

      developer.log(
        '📧 Admin notification sent for report ${report.id}',
        name: 'ModerationService',
      );

      developer.log(
        '✅ Admin notifications sent for new content report: ${report.id}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending admin notifications for report ${report.id}: $e',
        name: 'ModerationService',
      );
    }
  }

  // Report comment or reply
  static Future<void> reportComment({
    required String postId,
    required String commentId,
    required String commentAuthorId,
    required String commentAuthorName,
    required ViolationType violationType,
    required String description,
    String? reporterId,
    String? reporterName,
    String? reporterProfilePic,
    String? reportedContent,
    String? reportedContentType, // 'comment' or 'reply'
  }) async {
    // Get current user info if not provided
    final moderatorInfo = reporterId != null && reporterName != null
        ? {'id': reporterId, 'name': reporterName, 'email': ''}
        : getCurrentModeratorInfo();

    // If content is not provided, fetch it from the comment
    String? content = reportedContent;
    String? contentType = reportedContentType ?? 'comment';

    if (content == null && commentId.isNotEmpty) {
      try {
        final commentDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .get();

        if (commentDoc.exists) {
          final commentData = commentDoc.data()!;
          content = commentData['content'] ?? '';

          // Check if this is a reply
          if (commentData['parentId'] != null) {
            contentType = 'reply';
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching comment content: $e',
          name: 'ModerationService',
        );
      }
    }

    final report = ViolationReport(
      id: FirebaseFirestore.instance.collection(_reportsCollection).doc().id,
      reporterId: moderatorInfo['id']!,
      reporterName: moderatorInfo['name']!,
      reporterProfilePic: reporterProfilePic,
      reportedUserId: commentAuthorId,
      reportedUserName: commentAuthorName,
      reportedPostId: postId,
      reportedCommentId: commentId,
      violationType: violationType,
      description: description,
      status: ModerationStatus.pending,
      reportedContent: content,
      reportedContentType: contentType,
      reportedMediaUrls: null, // Comments typically don't have media
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(report.id)
        .set(report.toJson());

    developer.log(
      '📝 Comment reported: ${report.id} by ${moderatorInfo['name']}',
      name: 'ModerationService',
    );

    // Send notification to all admins about the new comment report
    await _sendAdminCommentReportNotification(report);
  }

  // Send notification to all admins about new comment report
  static Future<void> _sendAdminCommentReportNotification(
    ViolationReport report,
  ) async {
    try {
      // Get all admin users
      final adminUsers = await FirebaseFirestore.instance
          .collection('farmers')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminUsers.docs.isEmpty) {
        developer.log(
          '⚠️ No admin users found to send notification',
          name: 'ModerationService',
        );
        return;
      }

      // Create notification data
      final notificationData = {
        'type': 'admin_report_notification',
        'reportId': report.id,
        'reportType': 'comment',
        'violationType': report.violationType.name,
        'reportedUserId': report.reportedUserId,
        'reportedUserName': report.reportedUserName,
        'reporterId': report.reporterId,
        'reporterName': report.reporterName,
        'reportedPostId': report.reportedPostId,
        'reportedCommentId': report.reportedCommentId,
        'description': report.description,
        'title': 'New Comment Report',
        'body':
            'New ${report.violationType.name} ${report.reportedContentType} report by ${report.reporterName}',
        'isRead': false,
        'priority': 2, // High priority for admin notifications
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'contentType': report.reportedContentType ?? 'comment',
          'reportId': report.id,
        },
      };

      // Send notification to admin collection (centralized admin notifications)
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .add(notificationData);

      developer.log(
        '📧 Admin notification sent for comment report ${report.id}',
        name: 'ModerationService',
      );

      developer.log(
        '✅ Admin notifications sent for new comment report: ${report.id}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending admin notifications for comment report ${report.id}: $e',
        name: 'ModerationService',
      );
    }
  }

  // Get user's violation count
  static Future<int> getUserViolationCount(String userId) async {
    final reports = await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .where('reportedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'resolved')
        .get();

    return reports.docs.length;
  }

  // Check if user should be warned
  static Future<bool> shouldWarnUser(String userId) async {
    final violationCount = await getUserViolationCount(userId);
    return violationCount >= 1 && violationCount < 3;
  }

  // Check if user should be banned
  static Future<bool> shouldBanUser(String userId) async {
    final violationCount = await getUserViolationCount(userId);
    return violationCount >= 3;
  }

  // Issue warning to user
  static Future<void> issueWarning({
    required String userId,
    required String userName,
    required String reason,
    String? moderatorId,
    String? moderatorName,
  }) async {
    final moderatorInfo = _getModeratorInfo(
      customModeratorId: moderatorId,
      customModeratorName: moderatorName,
    );

    final warningId = FirebaseFirestore.instance
        .collection(_warningsCollection)
        .doc()
        .id;

    await FirebaseFirestore.instance
        .collection(_warningsCollection)
        .doc(warningId)
        .set({
          'id': warningId,
          'userId': userId,
          'userName': userName,
          'reason': reason,
          'moderatorId': moderatorInfo['id'],
          'moderatorName': moderatorInfo['name'],
          'moderatorEmail': moderatorInfo['email'],
          'issuedAt': DateTime.now().toIso8601String(),
          'isActive': true,
        });

    developer.log(
      '⚠️ Warning issued to user $userId by ${moderatorInfo['name']}: $reason',
      name: 'ModerationService',
    );
  }

  // Ban user
  static Future<void> banUser({
    required String userId,
    required String userName,
    required String? userProfilePic,
    required ModerationAction banType,
    required String reason,
    String? moderatorId,
    String? moderatorName,
  }) async {
    final moderatorInfo = _getModeratorInfo(
      customModeratorId: moderatorId,
      customModeratorName: moderatorName,
    );

    final banId = FirebaseFirestore.instance
        .collection(_bansCollection)
        .doc()
        .id;
    final now = DateTime.now();

    DateTime? banEndsAt;
    bool isPermanent = false;

    switch (banType) {
      case ModerationAction.temporaryBan24h:
        banEndsAt = now.add(const Duration(hours: 24));
        break;
      case ModerationAction.temporaryBan7d:
        banEndsAt = now.add(const Duration(days: 7));
        break;
      case ModerationAction.temporaryBan30d:
        banEndsAt = now.add(const Duration(days: 30));
        break;
      case ModerationAction.permanentBan:
        isPermanent = true;
        break;
      default:
        banEndsAt = now.add(const Duration(hours: 24));
    }

    final ban = UserBan(
      id: banId,
      userId: userId,
      userName: userName,
      userProfilePic: userProfilePic,
      banType: banType,
      reason: reason,
      banStartsAt: now,
      banEndsAt: banEndsAt,
      isPermanent: isPermanent,
      isActive: true,
      moderatorId: moderatorInfo['id']!,
      moderatorName: moderatorInfo['name']!,
      violationCount: await getUserViolationCount(userId),
      createdAt: now,
    );

    await FirebaseFirestore.instance
        .collection(_bansCollection)
        .doc(banId)
        .set(ban.toJson());

    // Update user profile to reflect ban
    await FirebaseFirestore.instance.collection('farmers').doc(userId).update({
      'isBanned': true,
      'banReason': reason,
      'banEndsAt': banEndsAt?.toIso8601String(),
      'isPermanentBan': isPermanent,
      'bannedBy': moderatorInfo['name'],
      'bannedByEmail': moderatorInfo['email'],
    });

    developer.log(
      '🚫 User banned: $userId by ${moderatorInfo['name']} - $reason',
      name: 'ModerationService',
    );
  }

  // Restore content after an admin review overturns a moderation decision
  static Map<String, dynamic> buildContentRestorationUpdate({
    String? reason,
  }) {
    return {
      'active': true,
      'status': 'active',
      'communityHidden': false,
      'moderationStatus': 'restored',
      'moderatedAt': FieldValue.serverTimestamp(),
      'is_visible': true,
      'is_under_review': false,
      'review_timestamp': FieldValue.serverTimestamp(),
      'is_removed': false,
      'removalReason': null,
      'removal_reason': null,
      'removedAt': FieldValue.delete(),
      'removal_timestamp': FieldValue.delete(),
      'reviewNote': reason ?? 'Restored by admin review',
    };
  }

  static Future<void> restoreContent(
    String postId, {
    String? reason,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update(buildContentRestorationUpdate(reason: reason));

      developer.log(
        '♻️ Post $postId restored after admin review',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error restoring content: $e', name: 'ModerationService');
    }
  }

  // Remove content
  static Future<void> removeContent(
    String postId, {
    String? reason,
    String? violationId,
  }) async {
    try {
      // Get post details before removing
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final postAuthorId = postData['authorId'] as String?;

      if (postAuthorId == null) return;

      // Update post status
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'active': false,
        'status': 'deleted',
        'removedAt': DateTime.now().toIso8601String(),
        'removalReason': reason ?? 'Community guidelines violation',
        'communityHidden': true,
        'moderationStatus': 'violation_detected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'is_visible': false,
        'is_under_review': false,
        'is_removed': true,
        'removal_reason': reason ?? 'Community guidelines violation',
        'removal_timestamp': FieldValue.serverTimestamp(),
      });

      await ModerationNotificationService.sendContentRemovalNotification(
        contentOwnerId: postAuthorId,
        contentId: postId,
        contentType: 'post',
        removalReason: reason ?? 'Community guidelines violation',
        violationId: violationId ?? postId,
      );

      developer.log(
        '🗑️ Post $postId removed and appeal notification sent to $postAuthorId by ${getCurrentModeratorInfo()['name']}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error removing content: $e', name: 'ModerationService');
    }
  }

  // Remove comment specifically
  static Future<void> removeComment(
    String commentId, {
    String? postId,
    String? reason,
    String? violationId,
  }) async {
    try {
      // Try to find which post this comment belongs to if not provided
      String targetPostId = postId ?? '';

      if (postId == null) {
        // Search through all posts to find the comment
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .get();

        for (final postDoc in postsSnapshot.docs) {
          final commentDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postDoc.id)
              .collection('comments')
              .doc(commentId)
              .get();

          if (commentDoc.exists) {
            targetPostId = postDoc.id;
            break;
          }
        }
      }

      if (targetPostId.isEmpty) {
        developer.log(
          '❌ Could not find post for comment $commentId',
          name: 'ModerationService',
        );
        return;
      }

      // Get comment details before removing
      final commentDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(targetPostId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) return;

      final commentData = commentDoc.data()!;
      final commentAuthorId =
          commentData['userId'] as String? ??
          commentData['authorId'] as String?;

      if (commentAuthorId == null) return;

      // Delete the comment
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(targetPostId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count on post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(targetPostId)
          .update({'analytics.commentsCount': FieldValue.increment(-1)});

      developer.log(
        '🗑️ Comment $commentId removed from post $targetPostId by ${getCurrentModeratorInfo()['name']}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error removing comment: $e', name: 'ModerationService');
    }
  }

  // Remove Marketplace listing specifically
  static Future<void> removeMarketplaceItem(
    String itemId, {
    String? reason,
    String? violationId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('Marketplace').doc(itemId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final sellerId = data['sellerId'] as String?;

      await docRef.update({
        'status': 'removed',
        'active': false,
        'communityHidden': true,
        'moderationStatus': 'violation_detected',
        'is_visible': false,
        'is_removed': true,
        'removalReason': reason ?? 'Community guidelines violation',
        'removal_reason': reason ?? 'Community guidelines violation',
        'moderatedAt': FieldValue.serverTimestamp(),
        'removal_timestamp': FieldValue.serverTimestamp(),
      });

      if (sellerId != null && sellerId.isNotEmpty) {
        await ModerationNotificationService.sendContentRemovalNotification(
          contentOwnerId: sellerId,
          contentId: itemId,
          contentType: 'marketplace',
          removalReason: reason ?? 'Community guidelines violation',
          violationId: violationId ?? itemId,
        );
      }

      developer.log(
        '🗑️ Marketplace listing $itemId removed by ${getCurrentModeratorInfo()['name']}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error removing marketplace item: $e', name: 'ModerationService');
    }
  }

  // Restore Marketplace listing
  static Future<void> restoreMarketplaceItem(
    String itemId, {
    String? reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('Marketplace').doc(itemId).update({
        'status': 'active',
        'active': true,
        'communityHidden': false,
        'moderationStatus': 'restored',
        'is_visible': true,
        'is_under_review': false,
        'is_removed': false,
        'removalReason': null,
        'removal_reason': null,
        'moderatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        '♻️ Marketplace listing $itemId restored',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error restoring marketplace item: $e', name: 'ModerationService');
    }
  }

  // Remove Profile Picture specifically
  static Future<void> removeProfilePicture(
    String userId, {
    String? reason,
    String? violationId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('farmers').doc(userId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      await docRef.update({
        'profile_pic': '',
        'moderatedProfilePicAt': FieldValue.serverTimestamp(),
        'profilePicRemovalReason': reason ?? 'Profile picture violated community safety guidelines',
      });

      await ModerationNotificationService.sendContentRemovalNotification(
        contentOwnerId: userId,
        contentId: userId,
        contentType: 'profile_picture',
        removalReason: reason ?? 'Profile picture violated community safety guidelines',
        violationId: violationId ?? userId,
      );

      developer.log(
        '🗑️ Profile picture removed for user $userId by ${getCurrentModeratorInfo()['name']}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error removing profile picture: $e', name: 'ModerationService');
    }
  }

  // Remove Cover Photo specifically
  static Future<void> removeCoverPhoto(
    String userId, {
    String? reason,
    String? violationId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('farmers').doc(userId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      await docRef.update({
        'cover_photo': '',
        'moderatedCoverPhotoAt': FieldValue.serverTimestamp(),
        'coverPhotoRemovalReason': reason ?? 'Cover photo violated community safety guidelines',
      });

      await ModerationNotificationService.sendContentRemovalNotification(
        contentOwnerId: userId,
        contentId: userId,
        contentType: 'cover_photo',
        removalReason: reason ?? 'Cover photo violated community safety guidelines',
        violationId: violationId ?? userId,
      );

      developer.log(
        '🗑️ Cover photo removed for user $userId by ${getCurrentModeratorInfo()['name']}',
        name: 'ModerationService',
      );
    } catch (e) {
      developer.log('❌ Error removing cover photo: $e', name: 'ModerationService');
    }
  }

  // Check if user is currently banned
  static Future<bool> isUserBanned(String userId) async {
    final banQuery = await FirebaseFirestore.instance
        .collection(_bansCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (banQuery.docs.isEmpty) return false;

    final ban = UserBan.fromJson(banQuery.docs.first.data());

    // Check if temporary ban has expired
    if (!ban.isPermanent && ban.banEndsAt != null) {
      if (DateTime.now().isAfter(ban.banEndsAt!)) {
        // Ban expired, reactivate user
        await reactivateUser(userId);
        return false;
      }
    }

    return true;
  }

  // Reactivate user after ban expires
  static Future<void> reactivateUser(String userId) async {
    await FirebaseFirestore.instance
        .collection(_bansCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get()
        .then((snapshot) {
          for (final doc in snapshot.docs) {
            doc.reference.update({'isActive': false});
          }
        });

    await FirebaseFirestore.instance.collection('farmers').doc(userId).update({
      'isBanned': false,
      'banReason': null,
      'banEndsAt': null,
      'isPermanentBan': false,
    });

    developer.log('✅ User reactivated: $userId', name: 'ModerationService');
  }

  // Get pending reports for admin
  static Stream<QuerySnapshot> getPendingReports() {
    return FirebaseFirestore.instance
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Handle moderation action
  static Future<void> handleModerationAction({
    required String reportId,
    required ModerationAction action,
    required String moderatorId,
    required String moderatorName,
    String? actionReason,
  }) async {
    final reportDoc = await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(reportId)
        .get();

    if (!reportDoc.exists) return;

    final report = ViolationReport.fromJson(reportDoc.data()!);

    // Update report status
    await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(reportId)
        .update({
          'status': 'resolved',
          'actionTaken': action.name,
          'actionReason': actionReason,
          'moderatorId': moderatorId,
          'moderatorName': moderatorName,
          'reviewedAt': DateTime.now().toIso8601String(),
          'resolvedAt': DateTime.now().toIso8601String(),
        });

    // Execute action
    switch (action) {
      case ModerationAction.warning:
        if (report.reportedUserId != null) {
          await issueWarning(
            userId: report.reportedUserId!,
            userName: report.reportedUserName ?? 'Unknown',
            reason: actionReason ?? 'Community guideline violation',
            moderatorId: moderatorId,
            moderatorName: moderatorName,
          );

          // Send notification to user about warning
          await ModerationNotificationService.sendWarningNotification(
            userId: report.reportedUserId!,
            warningType: 'manual_warning',
            message:
                'You have received a warning from community moderators: ${actionReason ?? "Community guideline violation"}',
          );
        }
        break;

      case ModerationAction.contentRemoval:
        if (report.reportedPostId != null) {
          await removeContent(
            report.reportedPostId!,
            reason: actionReason ?? 'Community guideline violation',
            violationId: reportId,
          );

          // Send a structured appeal notification so the owner sees the
          // appeal action immediately after their content is removed.
          await ModerationNotificationService.sendContentRemovalNotification(
            contentOwnerId: report.reportedUserId!,
            contentId: report.reportedPostId!,
            contentType: 'post',
            removalReason: actionReason ?? 'Community guideline violation',
            violationId: reportId,
          );
        }
        break;

      case ModerationAction.temporaryBan24h:
      case ModerationAction.temporaryBan7d:
      case ModerationAction.temporaryBan30d:
      case ModerationAction.permanentBan:
        if (report.reportedUserId != null) {
          await banUser(
            userId: report.reportedUserId!,
            userName: report.reportedUserName ?? 'Unknown',
            userProfilePic: null,
            banType: action,
            reason: actionReason ?? 'Repeated violations',
            moderatorId: moderatorId,
            moderatorName: moderatorName,
          );

          // Send notification to user about ban
          String banTypeText = action.name
              .replaceAll('temporaryBan', 'temporarily banned')
              .replaceAll('permanentBan', 'permanently banned');
          await ModerationNotificationService.sendWarningNotification(
            userId: report.reportedUserId!,
            warningType: 'ban',
            message:
                'Your account has been $banTypeText: ${actionReason ?? "Repeated violations"}',
          );
        }
        break;
    }

    developer.log(
      '⚖️ Moderation action executed: $action for report $reportId by $moderatorName',
      name: 'ModerationService',
    );

    // Update farmer reputation after moderation action
    if (report.reportedUserId != null) {
      await FarmerReputationService.onModerationAction(report.reportedUserId!);

      // Schedule automatic status check for recovery
      await FarmerStatusScheduler.resetStatusSchedule(report.reportedUserId!);
    }
  }

  // Check if text is clearly about farming
  static bool _isFarmingContext(String text) {
    final farmingKeywords = [
      'farm',
      'crop',
      'plant',
      'seed',
      'harvest',
      'soil',
      'water',
      'fertilizer',
      'pest',
      'weed',
      'tractor',
      'livestock',
      'cattle',
      'chicken',
      'poultry',
      'maize',
      'corn',
      'wheat',
      'rice',
      'vegetable',
      'fruit',
      'organic',
      'irrigation',
      'drought',
      'rain',
      'weather',
      'season',
      'planting',
      'growing',
      'yield',
      'agriculture',
      'farming',
      'farmer',
      'field',
      'barn',
      'silo',
    ];

    int farmingMatches = 0;
    for (final keyword in farmingKeywords) {
      if (text.contains(keyword)) {
        farmingMatches++;
      }
    }

    // DEBUG: Log farming context detection
    developer.log(
      '🔍 DEBUG Farming context: text="$text", matches=$farmingMatches, isFarming=${farmingMatches >= 2}',
      name: 'ModerationService',
    );

    // If 2+ farming keywords found, consider it farming context
    return farmingMatches >= 2;
  }
}
