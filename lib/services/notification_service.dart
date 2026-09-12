import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../models/user_profile.dart';
import '../models/moderation_model.dart';
import 'build_config_service.dart';
import 'chat_service.dart';
import 'device_capability_service.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;
  final FirebaseMessaging _messaging = FirebaseService.instance.messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  // Using AuthService directly since it has static methods

  Future<void> initialize() async {
    try {
      await _setupLocalNotifications();
      await _requestPermissions();

      if (await DeviceCapabilityService.instance.canUseFirebaseMessaging) {
        await _setupForegroundHandler();
        await _setupBackgroundHandler();
        await _setupTerminatedHandler();
        await _saveFCMToken();
      } else {
        debugPrint('⚠️ Push messaging disabled: Google Play Services unavailable');
      }

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high-importance chat notification channel for Android
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'agribased_chat_channel',
      'AgriBase Chat Messages',
      description: 'Notifications for incoming chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screens
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupForegroundHandler() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _setupBackgroundHandler() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _setupTerminatedHandler() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _updateFCMToken(currentUserId, token);

        _messaging.onTokenRefresh.listen((newToken) {
          _updateFCMToken(currentUserId, newToken);
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _updateFCMToken(String userId, String token) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'fcmToken': token,
        'tokenUpdatedAt': now,
      }, SetOptions(merge: true));

      final farmerRef = _firestore.collection('farmers').doc(userId);
      batch.set(farmerRef, {
        'fcmToken': token,
        'tokenUpdatedAt': now,
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint('✅ Saved FCM token for user $userId to users and farmers collections');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Dispatch chat push notification to recipient via Cloudflare Worker
  Future<void> sendChatPushNotification({
    required String receiverId,
    required String senderName,
    required String content,
    required String chatId,
    required String messageId,
    required String senderId,
  }) async {
    try {
      // 1. Fetch recipient's FCM token from Firestore
      String? fcmToken;
      try {
        final userDoc = await _firestore.collection('users').doc(receiverId).get();
        if (userDoc.exists) {
          fcmToken = userDoc.data()?['fcmToken'] as String?;
        }
      } catch (_) {}

      if (fcmToken == null || fcmToken.isEmpty) {
        try {
          final farmerDoc = await _firestore.collection('farmers').doc(receiverId).get();
          if (farmerDoc.exists) {
            fcmToken = farmerDoc.data()?['fcmToken'] as String?;
          }
        } catch (_) {}
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ Cannot send push: recipient $receiverId has no FCM token registered');
        return;
      }

      // 2. Dispatch to Cloudflare Worker
      final workerBaseUrl = BuildConfigService.moderationWorkerUrl.isNotEmpty
          ? BuildConfigService.moderationWorkerUrl
          : 'https://agribased-moderation.chinatsvieno.workers.dev';
      final cleanUrl = workerBaseUrl.endsWith('/')
          ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
          : workerBaseUrl;
      final endpoint = Uri.parse('$cleanUrl/send-chat-push');

      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': senderName,
          'body': content,
          'data': {
            'type': 'chat_message',
            'chatId': chatId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📨 Chat push dispatch response (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error dispatching chat push notification: $e');
    }
  }

  Future<void> _showChatLocalNotification(String title, String body, String chatId) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agribased_chat_channel',
      'AgriBase Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notifId = chatId.hashCode.abs() % 100000;
    await _localNotifications.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: 'chat:$chatId',
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    final data = message.data;
    if (data['type'] == 'chat_message') {
      final chatId = data['chatId']?.toString();
      final myId = AuthService.currentUserId;
      if (chatId != null && myId != null) {
        ChatService.instance.markMessagesDelivered(chatId, myId);
      }

      final title = message.notification?.title ?? data['senderName']?.toString() ?? 'New Message';
      final body = message.notification?.body ?? data['body']?.toString() ?? 'Sent you a message';
      _showChatLocalNotification(title, body, chatId ?? '');
      return;
    }
    _processMessage(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Received background message: ${message.messageId}');
    _processMessage(message);
  }

  void _handleTerminatedMessage(RemoteMessage message) {
    debugPrint('Received terminated message: ${message.messageId}');
    _processMessage(message);
  }

  void _processMessage(RemoteMessage message) {
    final notificationData = message.data;

    // Play notification sound
    _playNotificationSound();

    if (notificationData.containsKey('type')) {
      final type = notificationData['type'];

      switch (type) {
        case 'new_follower':
          _handleNewFollowerNotification(notificationData);
          break;
        case 'new_comment':
          _handleNewCommentNotification(notificationData);
          break;
        case 'new_post':
          _handleNewPostNotification(notificationData);
          break;
        case 'post_reach':
          _handlePostReachNotification(notificationData);
          break;
        case 'community_violation':
          _handleCommunityViolationNotification(notificationData);
          break;
        case 'temporary_ban':
          _handleTemporaryBanNotification(notificationData);
          break;
        case 'post_removed':
          _handlePostRemovedNotification(notificationData);
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'agribased_channel',
            'AgriBase Notifications',
            channelDescription: 'Notifications from AgriBase app',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'AgriBase',
        body: 'New notification',
        notificationDetails: platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void _handleNewFollowerNotification(Map<String, dynamic> data) {
    debugPrint('New follower notification: $data');
  }

  void _handleNewCommentNotification(Map<String, dynamic> data) {
    debugPrint('New comment notification: $data');
  }

  void _handleNewPostNotification(Map<String, dynamic> data) {
    debugPrint('New post notification: $data');
  }

  void _handlePostReachNotification(Map<String, dynamic> data) {
    debugPrint('Post reach notification: $data');
  }

  void _handleCommunityViolationNotification(Map<String, dynamic> data) {
    debugPrint('Community violation notification: $data');
  }

  void _handleTemporaryBanNotification(Map<String, dynamic> data) {
    debugPrint('Temporary ban notification: $data');
  }

  void _handlePostRemovedNotification(Map<String, dynamic> data) {
    debugPrint('Post removed notification: $data');
  }

  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc()
          .id;

      final notification = FarmerNotification(
        id: notificationId,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data?.map((key, value) => MapEntry(key, value?.toString() ?? '')),
        createdAt: DateTime.now(),
        isRead: false,
      );

      final notificationRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId);

      await notificationRef.set(notification.toMap());

      await _sendPushNotification(userId, title, body, data);
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> _sendPushNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      String? fcmToken;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        fcmToken = userDoc.data()?['fcmToken'] as String?;
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        final farmerDoc = await _firestore.collection('farmers').doc(userId).get();
        if (farmerDoc.exists) {
          fcmToken = farmerDoc.data()?['fcmToken'] as String?;
        }
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ Cannot send push: recipient $userId has no registered FCM token');
        return;
      }

      final workerBaseUrl = BuildConfigService.moderationWorkerUrl.isNotEmpty
          ? BuildConfigService.moderationWorkerUrl
          : 'https://agribased-moderation.chinatsvieno.workers.dev';
      final cleanUrl = workerBaseUrl.endsWith('/')
          ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
          : workerBaseUrl;
      final endpoint = Uri.parse('$cleanUrl/send-push-notification');

      final stringData = data?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ?? {};

      final response = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': stringData,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📨 Push notification dispatch response (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error dispatching push notification: $e');
    }
  }

  Future<void> sendNewFollowerNotification(
    String followerId,
    String followingId,
  ) async {
    try {
      final followerDoc = await _firestore
          .collection('users')
          .doc(followerId)
          .get();
      if (!followerDoc.exists) return;

      final follower = UserProfile.fromJson({
        ...followerDoc.data()!,
        'id': followerDoc.id,
      });

      await sendNotification(
        userId: followingId,
        type: NotificationType.newFollower,
        title: 'New Follower',
        body: '${follower.userName} started following you',
        data: {
          'type': 'new_follower',
          'followerId': followerId,
          'followingId': followingId,
        },
      );
    } catch (e) {
      debugPrint('Error sending new follower notification: $e');
    }
  }

  Future<void> sendNewCommentNotification(
    String postId,
    String commentId,
    String authorId,
    String commenterId,
  ) async {
    try {
      if (authorId == commenterId) return;

      final commenterDoc = await _firestore
          .collection('users')
          .doc(commenterId)
          .get();
      if (!commenterDoc.exists) return;

      final commenter = UserProfile.fromJson({
        ...commenterDoc.data()!,
        'id': commenterDoc.id,
      });
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      String content = 'your post';
      if (postDoc.exists) {
        final postContent = postDoc.data()?['content'] as String?;
        if (postContent != null && postContent.length > 50) {
          content = '${postContent.substring(0, 50)}...';
        } else if (postContent != null) {
          content = postContent;
        }
      }

      await sendNotification(
        userId: authorId,
        type: NotificationType.newComment,
        title: 'New Comment',
        body: '${commenter.userName} commented on $content',
        data: {
          'type': 'new_comment',
          'postId': postId,
          'commentId': commentId,
          'commenterId': commenterId,
        },
      );
    } catch (e) {
      debugPrint('Error sending new comment notification: $e');
    }
  }

  Future<void> sendNewPostNotification(String authorId, String postId) async {
    try {
      final followersSnapshot = await _firestore
          .collection('followers')
          .doc(authorId)
          .collection('followers')
          .get();

      final authorDoc = await _firestore
          .collection('users')
          .doc(authorId)
          .get();
      if (!authorDoc.exists) return;

      final author = UserProfile.fromJson({
        ...authorDoc.data()!,
        'id': authorDoc.id,
      });

      for (final followerDoc in followersSnapshot.docs) {
        final followerId = followerDoc.id;

        await sendNotification(
          userId: followerId,
          type: NotificationType.newPostFromFollowed,
          title: 'New Post',
          body: '${author.userName} posted something new',
          data: {'type': 'new_post', 'postId': postId, 'authorId': authorId},
        );
      }
    } catch (e) {
      debugPrint('Error sending new post notification: $e');
    }
  }

  Future<void> sendPostReachNotification(String postId, int reach) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final authorId = postDoc.data()?['authorId'] as String?;
      if (authorId == null) return;

      String milestone = '';
      if (reach >= 10000) {
        milestone = '10K+';
      } else if (reach >= 5000) {
        milestone = '5K+';
      } else if (reach >= 1000) {
        milestone = '1K+';
      } else if (reach >= 500) {
        milestone = '500+';
      } else if (reach >= 100) {
        milestone = '100+';
      } else {
        return;
      }

      await sendNotification(
        userId: authorId,
        type: NotificationType.postReachMilestone,
        title: 'Post Reach Milestone',
        body: 'Your post has reached $milestone views',
        data: {
          'type': 'post_reach',
          'postId': postId,
          'reach': reach,
          'milestone': milestone,
        },
      );
    } catch (e) {
      debugPrint('Error sending post reach notification: $e');
    }
  }

  Future<void> sendCommunityViolationNotification(
    String userId,
    String postId,
    ViolationType violationType,
  ) async {
    try {
      String violationMessage = '';
      switch (violationType) {
        case ViolationType.nudity:
          violationMessage = 'inappropriate content';
          break;
        case ViolationType.prohibitedGoods:
          violationMessage = 'prohibited goods';
          break;
        case ViolationType.harassment:
          violationMessage = 'harassment';
          break;
        case ViolationType.sexualContent:
          violationMessage = 'sexual content';
          break;
        case ViolationType.abuse:
          violationMessage = 'abuse';
          break;
        case ViolationType.threats:
          violationMessage = 'threats';
          break;
        case ViolationType.spam:
          violationMessage = 'spam';
          break;
        case ViolationType.hateSpeech:
          violationMessage = 'hate speech';
          break;
        case ViolationType.violence:
          violationMessage = 'violent content';
          break;
        case ViolationType.misinformation:
          violationMessage = 'misinformation';
          break;
        case ViolationType.copyright:
          violationMessage = 'copyright infringement';
          break;
        case ViolationType.other:
          violationMessage = 'community guidelines violation';
          break;
      }

      await sendNotification(
        userId: userId,
        type: NotificationType.communityViolation,
        title: 'Community Guidelines Violation',
        body: 'Your post was removed for $violationMessage',
        data: {
          'type': 'community_violation',
          'postId': postId,
          'violationType': violationType.name,
        },
      );
    } catch (e) {
      debugPrint('Error sending community violation notification: $e');
    }
  }

  Future<void> sendTemporaryBanNotification(
    String userId,
    DateTime banUntil,
    int violationCount,
  ) async {
    try {
      final duration = banUntil.difference(DateTime.now());
      String durationText = '';

      if (duration.inDays >= 1) {
        durationText =
            '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
      } else if (duration.inHours >= 1) {
        durationText =
            '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
      } else {
        durationText =
            '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
      }

      await sendNotification(
        userId: userId,
        type: NotificationType.temporaryBan,
        title: 'Account Suspended',
        body:
            'Your account has been suspended for $durationText due to repeated violations',
        data: {
          'type': 'temporary_ban',
          'banUntil': banUntil.toIso8601String(),
          'violationCount': violationCount,
        },
      );
    } catch (e) {
      debugPrint('Error sending temporary ban notification: $e');
    }
  }

  Future<void> sendPostRemovedNotification(
    String userId,
    String postId,
    String reason,
  ) async {
    try {
      await sendNotification(
        userId: userId,
        type: NotificationType.postRemoved,
        title: 'Post Removed',
        body: 'Your post was removed: $reason',
        data: {'type': 'post_removed', 'postId': postId, 'reason': reason},
      );
    } catch (e) {
      debugPrint('Error sending post removed notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': DateTime.now()});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final unreadSnapshot = await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true, 'readAt': DateTime.now()});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .get();

      final batch = _firestore.batch();

      for (final doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  Future<List<FarmerNotification>> getNotifications({
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool? unreadOnly,
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return [];

      Query query = _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .orderBy('createdAt', descending: true);

      if (unreadOnly == true) {
        query = query.where('isRead', isEqualTo: false);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) =>
                FarmerNotification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting unread notifications count: $e');
      return 0;
    }
  }

  Stream<List<FarmerNotification>> getNotificationsStream({
    int limit = 20,
    bool? unreadOnly,
  }) {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return Stream.value([]);

    Query query = _firestore
        .collection('notifications')
        .doc(currentUserId)
        .collection('items')
        .orderBy('createdAt', descending: true);

    if (unreadOnly == true) {
      query = query.where('isRead', isEqualTo: false);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                FarmerNotification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Stream<int> getUnreadNotificationsCountStream() {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .doc(currentUserId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> updateNotificationPreferences({
    bool? newFollower,
    bool? newComment,
    bool? newPost,
    bool? postReach,
    bool? communityViolation,
    bool? temporaryBan,
    bool? postRemoved,
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final preferences = <String, dynamic>{};
      if (newFollower != null) preferences['newFollower'] = newFollower;
      if (newComment != null) preferences['newComment'] = newComment;
      if (newPost != null) preferences['newPost'] = newPost;
      if (postReach != null) preferences['postReach'] = postReach;
      if (communityViolation != null) {
        preferences['communityViolation'] = communityViolation;
      }
      if (temporaryBan != null) preferences['temporaryBan'] = temporaryBan;
      if (postRemoved != null) preferences['postRemoved'] = postRemoved;

      await _firestore.collection('users').doc(currentUserId).update({
        'notificationPreferences': preferences,
      });
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return {};

      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (!doc.exists) return {};

      final preferences =
          doc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      if (preferences == null) return {};

      return preferences.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {};
    }
  }
}
