import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/moderation_model.dart';
import '../models/notification_model.dart';
import 'notifications/notification_service.dart';

class ModerationNotificationService {
  // Get current admin user ID for audit trail
  static String? _getCurrentAdminId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      developer.log(
        'Error getting current admin ID: $e',
        name: 'ModerationNotificationService',
      );
      return null;
    }
  }

  static Future<String> _resolveUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return 'Unknown User';
      }

      final data = userDoc.data();
      return (data?['user_name'] ??
              data?['name'] ??
              data?['displayName'] ??
              'Unknown User')
          .toString();
    } catch (e) {
      developer.log(
        '❌ Error resolving user name for $userId: $e',
        name: 'ModerationNotificationService',
      );
      return 'Unknown User';
    }
  }

  // Create notification metadata for tracking
  static Map<String, dynamic> _createNotificationMetadata({
    required String contentOwnerId,
    required String contentId,
    required String contentType,
    required String removalReason,
    required String violationId,
  }) {
    return {
      'contentOwnerId': contentOwnerId,
      'contentId': contentId,
      'contentType': contentType,
      'removalReason': removalReason,
      'violationId': violationId,
      'createdBy': _getCurrentAdminId(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> sendContentRemovalNotification({
    required String contentOwnerId,
    required String contentId,
    required String contentType, // 'post' or 'item'
    required String removalReason,
    required String violationId,
  }) async {
    try {
      final appealId = FirebaseFirestore.instance
          .collection('appeals')
          .doc()
          .id;

      final userName = await _resolveUserName(contentOwnerId);

      // Create an appeal placeholder but DO NOT mark it as already submitted.
      // The user must open the appeal form and submit their statement which
      // will set `appealedAt` / `submittedAt` and `userStatement`.
      await FirebaseFirestore.instance.collection('appeals').doc(appealId).set({
        'id': appealId,
        'userId': contentOwnerId,
        'userName': userName,
        'postId': contentId,
        'violations': [ViolationType.other.name],
        'reason': removalReason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userStatement': null,
        'adminResponse': '',
      });

      await NotificationService().sendNotification(
        userId: contentOwnerId,
        type: NotificationType.communityViolation,
        title: 'Content Removed - Appeal Available',
        body:
            'Your $contentType was removed for: $removalReason\n\nYou can file an appeal within 7 days.',
        postId: contentId,
        additionalData: {
          'appealId': appealId,
          'postId': contentId,
          'contentType': contentType,
          'violationId': violationId,
          'removalReason': removalReason,
          'violations': [ViolationType.other.name],
          'requiresAction': true,
          'actionText': 'Appeal Now',
          'actionScreen': 'appeal_form',
        },
      );

      developer.log(
        '✅ Content removal notification sent to $contentOwnerId with appeal action',
        name: 'ModerationNotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending content removal notification: $e',
        name: 'ModerationNotificationService',
      );
    }
  }

  static Future<void> sendWarningNotification({
    required String userId,
    required String warningType,
    required String message,
  }) async {
    try {
      final notificationData = {
        'type': 'warning',
        'warningType': warningType,
        'title': 'Warning',
        'body': message,
        'read': false,
        'priority': 1, // High priority for first notifications
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'warningType': warningType,
          'message': message,
          'createdBy': _getCurrentAdminId(),
        },
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add(notificationData);

      developer.log(
        '✅ Warning notification sent to $userId',
        name: 'ModerationNotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending warning notification: $e',
        name: 'ModerationNotificationService',
      );
    }
  }

  static Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
            'readBy': _getCurrentAdminId(),
          });

      developer.log(
        '✅ Notification marked as read',
        name: 'ModerationNotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error marking notification as read: $e',
        name: 'ModerationNotificationService',
      );
    }
  }

  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.update({
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
          'readBy': _getCurrentAdminId(),
        });
      }

      developer.log(
        '✅ All notifications marked as read for $userId',
        name: 'ModerationNotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error marking all notifications as read: $e',
        name: 'ModerationNotificationService',
      );
    }
  }

  // Send warning with appeal option
  static Future<void> sendWarningWithAppeal({
    required String userId,
    required String postId,
    required List<ViolationType> violations,
    required String reason,
  }) async {
    developer.log(
      '🚨 sendWarningWithAppeal called for user: $userId, post: $postId',
      name: 'ModerationNotificationService',
    );

    try {
      final userName = await _resolveUserName(userId);

      // Create the appeal record using the same structure the admin dashboard reads.
      final appealId = FirebaseFirestore.instance
          .collection('appeals')
          .doc()
          .id;

      // Create appeal placeholder without marking it as submitted. The user
      // will provide their statement in the appeal form which updates these
      // fields (see `AppealFormScreen`).
      await FirebaseFirestore.instance.collection('appeals').doc(appealId).set({
        'id': appealId,
        'userId': userId,
        'userName': userName,
        'postId': postId,
        'violations': violations.map((v) => v.name).toList(),
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userStatement': null,
        'adminResponse': '',
      });

      developer.log(
        '📧 Attempting to send notification to user $userId',
        name: 'ModerationNotificationService',
      );

      await NotificationService().sendNotification(
        userId: userId,
        type: NotificationType.communityViolation,
        title: 'Content Removed - Appeal Available',
        body:
            'Your content was removed for: ${violations.map((v) => v.name).join(", ")}\n\nYou can file an appeal within 7 days.',
        postId: postId,
        additionalData: {
          'appealId': appealId,
          'postId': postId,
          'violations': violations.map((v) => v.name).toList(),
          'reason': reason,
          'requiresAction': true,
          'actionText': 'Appeal Now',
          'actionScreen': 'appeal_form',
        },
      );

      developer.log(
        '✅ Notification sent successfully to user $userId',
        name: 'ModerationNotificationService',
      );

      developer.log(
        '📧 Warning with appeal sent to user $userId for post $postId',
        name: 'ModerationNotificationService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending warning with appeal: $e',
        name: 'ModerationNotificationService',
      );
    }
  }
}
