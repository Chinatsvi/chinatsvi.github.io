import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/moderation_model.dart';
import 'ai_content_moderation_service.dart';
import 'farmer_reputation_service.dart';
import 'moderation_service.dart';

/// Smart Moderation Service
/// Uses AI moderation first, then falls back to keyword filtering
/// Only auto-takes down high-confidence violations
/// Allows user reporting and admin review
class SmartModerationService {
  static const String _reportsCollection = 'moderation_reports';
  static const String _flaggedContentCollection = 'flagged_content';
  static const String _userReportsCollection = 'user_reports';

  // Confidence thresholds
  static const double _highConfidenceThreshold = 0.65;
  static const double _moderateConfidenceThreshold = 0.4;

  /// Main moderation function - AI first, then fallback
  /// Returns:
  /// - true: content is allowed
  /// - false: content was auto-removed (high confidence violation)
  /// - null: content flagged for admin review (moderate confidence)
  static Future<bool?> moderateContent({
    required String content,
    required String postId,
    required String userId,
    required String userName,
    String? authorProfilePic,
    String contentType = 'post',
    List<String>? mediaUrls,
    String? imageUrl,
  }) async {
    developer.log(
      '🔄 Starting smart moderation for $contentType $postId',
      name: 'SmartModeration',
    );

    final effectiveMedia = <String>[
      if (imageUrl != null && imageUrl.trim().isNotEmpty) imageUrl.trim(),
      if (mediaUrls != null)
        ...mediaUrls.where((u) => u.trim().isNotEmpty).map((u) => u.trim()),
    ];

    if (content.trim().isEmpty && effectiveMedia.isEmpty) {
      developer.log('✅ Empty content, allowing', name: 'SmartModeration');
      return true;
    }

    try {
      // Step 1: Try AI moderation first
      final aiResult = await AIContentModerationService.moderateContent(
        content,
        contentType: contentType,
        mediaUrls: effectiveMedia,
      );

      developer.log(
        '🤖 AI Result - Flagged: ${aiResult.isFlagged}, Scores: ${aiResult.confidenceScores}',
        name: 'SmartModeration',
      );

      if (!aiResult.isFlagged) {
        developer.log(
          '✅ AI approved content, allowing',
          name: 'SmartModeration',
        );
        return true;
      }

      // Get highest confidence score
      final maxConfidence = aiResult.confidenceScores.values.isEmpty
          ? 0.0
          : aiResult.confidenceScores.values.reduce((a, b) => a > b ? a : b);

      developer.log(
        '📊 Max confidence: $maxConfidence',
        name: 'SmartModeration',
      );

      // Step 2: High confidence violation - auto-remove
      if (maxConfidence > _highConfidenceThreshold) {
        developer.log(
          '🚫 High confidence violation (${maxConfidence.toStringAsFixed(2)}), auto-removing',
          name: 'SmartModeration',
        );

        final sexualConfidence = aiResult.getConfidence('sexual') ??
            aiResult.getConfidence('sexualContent') ??
            0.0;
        final sexualFlagged = aiResult.categories['sexual'] == true ||
            aiResult.categories['sexualContent'] == true;

        // If sexual was flagged but confidence isn't high enough, escalate
        // to admin review instead of auto-removal.
        if (sexualFlagged && sexualConfidence < 0.85) {
          developer.log(
            '⚠️ Sexual category flagged but confidence below threshold (${sexualConfidence.toStringAsFixed(2)}), sending for review instead of auto-remove',
            name: 'SmartModeration',
          );

          await _flagContentForReview(
            postId: postId,
            userId: userId,
            userName: userName,
            authorProfilePic: authorProfilePic,
            contentType: contentType,
            content: content,
            violationCategories: aiResult.categories,
            confidenceScores: aiResult.confidenceScores,
            reason: aiResult.reason,
            mediaUrls: effectiveMedia,
          );

          return null; // Flagged for review
        }

        await _autoRemoveContent(
          postId: postId,
          userId: userId,
          userName: userName,
          contentType: contentType,
          violations: aiResult.categories,
          reason: 'High confidence violation: ${aiResult.reason}',
          maxConfidence: maxConfidence,
        );

        return false;
      }

      // Step 3: Moderate confidence - flag for admin review
      if (maxConfidence > _moderateConfidenceThreshold) {
        developer.log(
          '⚠️ Moderate confidence violation (${maxConfidence.toStringAsFixed(2)}), flagging for review',
          name: 'SmartModeration',
        );

        await _flagContentForReview(
          postId: postId,
          userId: userId,
          userName: userName,
          authorProfilePic: authorProfilePic,
          contentType: contentType,
          content: content,
          violationCategories: aiResult.categories,
          confidenceScores: aiResult.confidenceScores,
          reason: aiResult.reason,
          mediaUrls: effectiveMedia,
        );

        return null; // Flagged, not decided yet
      }

      // Step 4: Low confidence - allow but log for analysis
      developer.log(
        '✅ Low confidence, allowing content (confidence: ${maxConfidence.toStringAsFixed(2)})',
        name: 'SmartModeration',
      );

      return true;
    } catch (e) {
      developer.log(
        '❌ Moderation error: $e, falling back to safe keyword filter',
        name: 'SmartModeration',
      );

      // Fallback to conservative keyword filtering
      return _conservativeKeywordFilter(
        content,
        postId,
        userId,
        userName,
        contentType: contentType,
      );
    }
  }

  /// Conservative keyword filter as fallback
  /// Only catches severe, unambiguous violations
  static Future<bool?> _conservativeKeywordFilter(
    String content,
    String postId,
    String userId,
    String userName, {
    String contentType = 'post',
  }) async {
    final lowerText = content.toLowerCase();

    // Only catch severe, unambiguous violations
    final severeKeywords = [
      'child abuse',
      'csam',
      'white supremacy',
      'free money giveaway',
    ];

    for (final keyword in severeKeywords) {
      if (lowerText.contains(keyword)) {
        developer.log(
          '🚫 Severe keyword detected: $keyword, auto-removing',
          name: 'SmartModeration',
        );

        await _autoRemoveContent(
          postId: postId,
          userId: userId,
          userName: userName,
          contentType: contentType,
          violations: {'severe_violation': true},
          reason: 'Severe violation detected',
          maxConfidence: 1.0,
        );

        return false;
      }
    }

    developer.log(
      '✅ Fallback filter passed, allowing content',
      name: 'SmartModeration',
    );
    return true;
  }

  /// Map string violation categories to appropriate ViolationType enum
  static ViolationType _resolveViolationType(Map<String, bool> violations) {
    if (violations['sexualContent'] == true ||
        violations['sexual'] == true ||
        violations['nudity'] == true) {
      return ViolationType.sexualContent;
    }
    if (violations['prohibitedGoods'] == true ||
        violations['drugs'] == true) {
      return ViolationType.prohibitedGoods;
    }
    if (violations['violence'] == true) {
      return ViolationType.violence;
    }
    if (violations['hateSpeech'] == true ||
        violations['hate'] == true) {
      return ViolationType.hateSpeech;
    }
    if (violations['spam'] == true) {
      return ViolationType.spam;
    }
    if (violations['harassment'] == true ||
        violations['abuse'] == true) {
      return ViolationType.harassment;
    }
    if (violations['misinformation'] == true) {
      return ViolationType.misinformation;
    }
    return ViolationType.other;
  }

  /// Auto-remove content (for high confidence violations only)
  static Future<void> _autoRemoveContent({
    required String postId,
    required String userId,
    required String userName,
    required String contentType,
    required Map<String, bool> violations,
    required String reason,
    required double maxConfidence,
  }) async {
    try {
      final violationType = _resolveViolationType(violations);

      // Create a violation report
      final report = ViolationReport(
        id: FirebaseFirestore.instance.collection(_reportsCollection).doc().id,
        reporterId: 'system_ai',
        reporterName: 'AI Moderation System',
        reportedUserId: userId,
        reportedUserName: userName,
        reportedPostId: postId,
        violationType: violationType,
        description:
            'Auto-removed by AI moderation ($contentType). Violations: ${violations.keys.join(", ")}\nConfidence: ${maxConfidence.toStringAsFixed(2)}\nReason: $reason',
        status: ModerationStatus.resolved,
        reportedContentType: contentType,
        actionTaken: ModerationAction.contentRemoval,
        actionReason: reason,
        createdAt: DateTime.now(),
        resolvedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .doc(report.id)
          .set(report.toJson());

      // Auto-remove based on content type
      if (contentType == 'marketplace') {
        await ModerationService.removeMarketplaceItem(
          postId,
          reason: reason,
          violationId: report.id,
        );
      } else if (contentType == 'profile_picture') {
        await ModerationService.removeProfilePicture(
          userId,
          reason: reason,
          violationId: report.id,
        );
      } else if (contentType == 'cover_photo') {
        await ModerationService.removeCoverPhoto(
          userId,
          reason: reason,
          violationId: report.id,
        );
      } else if (contentType == 'comment') {
        await ModerationService.removeComment(
          postId,
          reason: reason,
          violationId: report.id,
        );
      } else {
        await ModerationService.removeContent(
          postId,
          reason: reason,
          violationId: report.id,
        );
      }

      await ModerationService.issueWarning(
        userId: userId,
        userName: userName.isNotEmpty ? userName : 'User',
        reason: 'Auto-removed by AI moderation ($contentType): $reason',
      );

      await FarmerReputationService.onModerationAction(userId);
      await FarmerReputationService.updateFarmerStatus(userId);

      developer.log(
        '✅ $contentType auto-removed, reported, and author penalized',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log(
        '❌ Error auto-removing $contentType: $e',
        name: 'SmartModeration',
      );
    }
  }

  /// Flag content for admin review
  static Future<void> _flagContentForReview({
    required String postId,
    required String userId,
    required String userName,
    required String? authorProfilePic,
    required String contentType,
    required String content,
    required Map<String, bool> violationCategories,
    required Map<String, double> confidenceScores,
    required String reason,
    required List<String>? mediaUrls,
  }) async {
    try {
      // Create flagged content document
      await FirebaseFirestore.instance
          .collection(_flaggedContentCollection)
          .doc(postId)
          .set({
            'post_id': postId,
            'user_id': userId,
            'user_name': userName,
            'author_profile_pic': authorProfilePic,
            'content_type': contentType,
            'content': content,
            'media_urls': mediaUrls ?? [],
            'violations': violationCategories,
            'confidence_scores': confidenceScores,
            'reason': reason,
            'flagged_at': FieldValue.serverTimestamp(),
            'status': 'pending_review', // pending_review, approved, removed
            'admin_notes': '',
          });

      // Hide content based on contentType
      if (contentType == 'marketplace') {
        await FirebaseFirestore.instance
            .collection('Marketplace')
            .doc(postId)
            .update({
              'is_visible': false,
              'communityHidden': true,
              'is_under_review': true,
              'review_timestamp': FieldValue.serverTimestamp(),
            })
            .catchError((_) {});
      } else if (contentType == 'post') {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
              'is_visible': false,
              'communityHidden': true,
              'is_under_review': true,
              'review_timestamp': FieldValue.serverTimestamp(),
            })
            .catchError((_) {});
      }

      developer.log(
        '✅ Content ($contentType) flagged for admin review and hidden',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log('❌ Error flagging content: $e', name: 'SmartModeration');
    }
  }

  /// User reports a post
  static Future<void> reportPost({
    required String postId,
    required String postAuthorId,
    required String postAuthorName,
    required String reportReason,
    required String description,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        developer.log('❌ Not authenticated', name: 'SmartModeration');
        return;
      }

      // Get reporter info
      final reporterDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUser.uid)
          .get();

      final reporterName = reporterDoc.data()?['user_name'] ?? 'Anonymous';
      final reporterProfilePic = reporterDoc.data()?['profile_pic'];

      // Create user report
      final reportId = FirebaseFirestore.instance
          .collection(_userReportsCollection)
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection(_userReportsCollection)
          .doc(reportId)
          .set({
            'report_id': reportId,
            'post_id': postId,
            'post_author_id': postAuthorId,
            'post_author_name': postAuthorName,
            'reporter_id': currentUser.uid,
            'reporter_name': reporterName,
            'reporter_profile_pic': reporterProfilePic,
            'report_reason': reportReason,
            'description': description,
            'status': 'pending',
            'created_at': FieldValue.serverTimestamp(),
            'reviewed_at': null,
            'admin_notes': '',
          });

      // Hide reported post from feed immediately until admin reviews
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
            'is_visible': false,
            'is_under_review': true,
            'review_timestamp': FieldValue.serverTimestamp(),
          })
          .catchError((e) {
            developer.log(
              'Note: Could not hide post: $e',
              name: 'SmartModeration',
            );
            // Don't throw - report still created
          });

      developer.log(
        '✅ User report created and post hidden: $reportId',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log(
        '❌ Error creating user report: $e',
        name: 'SmartModeration',
      );
    }
  }

  /// Appeal a removed post (admin review)
  static Future<void> appealRemoval({
    required String postId,
    required String reason,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Find the moderation report for this post
      final reports = await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .where('reported_post_id', isEqualTo: postId)
          .limit(1)
          .get();

      if (reports.docs.isEmpty) return;

      final reportId = reports.docs.first.id;

      // Update report status to appealed
      await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .doc(reportId)
          .update({
            'status': ModerationStatus.appealed.toString().split('.').last,
            'appeal_reason': reason,
            'appeal_timestamp': FieldValue.serverTimestamp(),
          });

      developer.log(
        '✅ Appeal submitted for post $postId',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log('❌ Error submitting appeal: $e', name: 'SmartModeration');
    }
  }

  /// Get user reports for admin dashboard
  static Stream<QuerySnapshot> getPendingReports() {
    return FirebaseFirestore.instance
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Get flagged content for admin review
  static Stream<QuerySnapshot> getFlaggedContent() {
    return FirebaseFirestore.instance
        .collection(_flaggedContentCollection)
        .where('status', isEqualTo: 'pending_review')
        .orderBy('flagged_at', descending: true)
        .snapshots();
  }

  /// Admin approves flagged content
  static Future<void> approveFlaggedContent({
    required String postId,
    required String adminNotes,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_flaggedContentCollection)
          .doc(postId)
          .update({
            'status': 'approved',
            'admin_notes': adminNotes,
            'reviewed_at': FieldValue.serverTimestamp(),
          });

      // Restore the post's visibility and clear moderation flags after approval
      await ModerationService.restoreContent(
        postId,
        reason: adminNotes.isNotEmpty ? adminNotes : 'Approved by admin',
      );

      developer.log(
        '✅ Content approved by admin and made visible in feed',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log('❌ Error approving content: $e', name: 'SmartModeration');
    }
  }

  /// Admin removes flagged content
  static Future<void> removeFlaggedContent({
    required String postId,
    required String removalReason,
    required String adminNotes,
    String? userId,
  }) async {
    try {
      // Update flagged content status
      await FirebaseFirestore.instance
          .collection(_flaggedContentCollection)
          .doc(postId)
          .update({
            'status': 'removed',
            'admin_notes': adminNotes,
            'reviewed_at': FieldValue.serverTimestamp(),
          });

      // Update the post to mark it as removed and hidden
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'is_removed': true,
        'is_visible': false,
        'is_under_review': false,
        'removal_reason': removalReason,
        'removal_timestamp': FieldValue.serverTimestamp(),
      });

      if (userId != null && userId.isNotEmpty) {
        await FarmerReputationService.onModerationAction(userId);
      }

      developer.log(
        '✅ Content removed by admin and hidden from feed',
        name: 'SmartModeration',
      );
    } catch (e) {
      developer.log('❌ Error removing content: $e', name: 'SmartModeration');
    }
  }

  /// Get moderation statistics
  static Future<Map<String, dynamic>> getModerationStats() async {
    try {
      final reportsCount = await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .count()
          .get();

      final flaggedCount = await FirebaseFirestore.instance
          .collection(_flaggedContentCollection)
          .count()
          .get();

      final userReportsCount = await FirebaseFirestore.instance
          .collection(_userReportsCollection)
          .count()
          .get();

      return {
        'total_reports': reportsCount.count,
        'flagged_content': flaggedCount.count,
        'user_reports': userReportsCount.count,
      };
    } catch (e) {
      developer.log('❌ Error getting stats: $e', name: 'SmartModeration');
      return {};
    }
  }
}
