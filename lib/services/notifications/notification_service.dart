import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification_model.dart';

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? postId,
    String? commentId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create notification document
      final notification = FarmerNotification(
        id: FirebaseFirestore.instance.collection('notifications').doc().id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        postId: postId,
        commentId: commentId,
        createdAt: DateTime.now(),
        data: additionalData,
      );

      // Save to Firestore
      debugPrint(
        '📧 Creating notification for user: $userId, type: $type, title: $title',
      );
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('✅ Notification saved with ID: ${notification.id}');

      // Show local notification if user is current user
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await _showLocalNotification(title, body, notification.id);
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Show a local notification with sound
  Future<void> _showLocalNotification(
    String title,
    String body,
    String id,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'agribased_notifications',
          'AgriBase Notifications',
          channelDescription: 'Notifications from AgriBase app',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      id: id.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: id,
    );
  }

  /// Stream unread notifications count for real-time badges (regular users)
  Stream<int> streamUnreadCount(String userId) {
    // Prefer subcollection notifications/{userId}/items
    try {
      final ref = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('isRead', isEqualTo: false);
      return ref.snapshots().map((snap) => snap.docs.length);
    } catch (_) {
      final ref = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false);
      return ref.snapshots().map((snap) => snap.docs.length);
    }
  }

  /// Stream unread admin notifications count for real-time badges (admin users)
  Stream<int> streamAdminUnreadCount() {
    // Admin notifications are stored in notifications/admin/items
    try {
      final ref = _firestore
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .where('isRead', isEqualTo: false);
      return ref.snapshots().map((snap) => snap.docs.length);
    } catch (e) {
      debugPrint('Error streaming admin notifications: $e');
      return Stream.value(0);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final unreadNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Send system notification (like maintenance, updates, etc.)
  Future<void> sendSystemNotification({
    required String title,
    required String body,
    List<String>? targetUsers,
    bool sendToAll = false,
  }) async {
    try {
      if (sendToAll) {
        // Send to all users (admin use only)
        final users = await _firestore.collection('users').get();

        for (final userDoc in users.docs) {
          await sendNotification(
            userId: userDoc.id,
            type: NotificationType.systemUpdate,
            title: title,
            body: body,
            additionalData: {'isSystemNotification': true},
          );
        }
      } else if (targetUsers != null) {
        // Send to specific users
        for (final userId in targetUsers) {
          await sendNotification(
            userId: userId,
            type: NotificationType.systemUpdate,
            title: title,
            body: body,
            additionalData: {'isSystemNotification': true},
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending system notification: $e');
    }
  }
}
