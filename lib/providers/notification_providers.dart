import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../services/notifications/notification_service.dart';

// Auth controller provider - renamed to test for conflicts
final authControllerProviderMain = Provider<AuthController>(
  (ref) => AuthController(),
);

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// Chat unread count provider with Family
final chatUnreadCountProvider = StreamProvider.family<int, String>((
  ref,
  currentUserId,
) {
  if (currentUserId.isEmpty) return const Stream.empty();

  final chatStream = FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .snapshots();

  return chatStream.map((snapshot) {
    int count = 0;
    for (var doc in snapshot.docs) {
      final unreadMap = doc.get('unreadCount') as Map<String, dynamic>? ?? {};
      count += (unreadMap[currentUserId] ?? 0) as int;
    }
    return count;
  });
});

// Message notifications count provider (for bottom bar)
final messageNotificationsCountProvider = StreamProvider<int>((ref) {
  final currentUserId = ref.watch(authControllerProviderMain).currentUser?.uid;
  if (currentUserId == null) return const Stream.empty().map((_) => 0);

  final messageNotifStream = FirebaseFirestore.instance
      .collection('notifications')
      .doc(currentUserId)
      .collection('items')
      .where('type', isEqualTo: 'message')
      .where('isRead', isEqualTo: false)
      .snapshots();

  return messageNotifStream.map((snapshot) => snapshot.docs.length);
});

// General notifications count provider (for app bar - excludes messages)
final generalNotificationsCountProvider = StreamProvider<int>((ref) {
  final currentUserId = ref.watch(authControllerProviderMain).currentUser?.uid;
  if (currentUserId == null) return const Stream.empty().map((_) => 0);

  final notifStream = FirebaseFirestore.instance
      .collection('notifications')
      .doc(currentUserId)
      .collection('items')
      .where('type', isNotEqualTo: 'message')
      .where('isRead', isEqualTo: false)
      .snapshots();

  return notifStream.map((snapshot) => snapshot.docs.length);
});

// Moderation appeals count provider (for admin users)
final moderationAppealsCountProvider = StreamProvider<int>((ref) {
  final currentUserId = ref.watch(authControllerProviderMain).currentUser?.uid;
  if (currentUserId == null) return const Stream.empty().map((_) => 0);

  // Only admins should see appeals count
  // You might want to add a check here for admin role

  final appealsStream = FirebaseFirestore.instance
      .collection('moderation_appeals')
      .where('status', isEqualTo: 'pending')
      .snapshots();

  return appealsStream.map((snapshot) => snapshot.docs.length);
});

// Total notifications unread count provider (legacy - for backward compatibility)
final notificationsUnreadCountProvider = StreamProvider<int>((ref) {
  final currentUserId = ref.watch(authControllerProviderMain).currentUser?.uid;
  if (currentUserId == null) return const Stream.empty().map((_) => 0);

  final notifStream = FirebaseFirestore.instance
      .collection('notifications')
      .doc(currentUserId)
      .collection('items')
      .where('isRead', isEqualTo: false)
      .snapshots();

  return notifStream.map((snapshot) => snapshot.docs.length);
});
