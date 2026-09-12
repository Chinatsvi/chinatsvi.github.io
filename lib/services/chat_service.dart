import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

enum MessageType { text, image, video, audio, document }

class ChatService {
  // ---------------- SINGLETON ----------------
  static ChatService? _instance;
  static ChatService get instance => _instance ??= ChatService._();
  ChatService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  /// 🔑 STABLE, DETERMINISTIC CHAT ID
  String _getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ---------------- CREATE OR GET CHAT ----------------
  Future<ChatModel> createChat(String otherUserId) async {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    if (currentUserId == otherUserId) {
      throw Exception('Cannot chat with yourself');
    }

    final chatId = _getChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    if (chatDoc.exists) {
      return ChatModel.fromFirestore(chatDoc);
    }

    // Fetch farmer profiles
    final me =
        await _firestore.collection('farmers').doc(currentUserId).get();
    final other =
        await _firestore.collection('farmers').doc(otherUserId).get();

    if (!me.exists || !other.exists) {
      throw Exception('User profile missing');
    }

    final now = DateTime.now();

    final chat = ChatModel(
      id: chatId,
      participants: [currentUserId, otherUserId],
      participantsInfo: {
        currentUserId: {
          'id': currentUserId,
          'name': me['user_name'] ?? 'Farmer',
          'photo': me['profile_pic'] ?? '',
          'lastSeen': now.toIso8601String(),
        },
        otherUserId: {
          'id': otherUserId,
          'name': other['user_name'] ?? 'Farmer',
          'photo': other['profile_pic'] ?? '',
          'lastSeen': null,
        },
      },
      lastMessage: '',
      lastMessageAt: now,
      unreadCount: {
        currentUserId: 0,
        otherUserId: 0,
      },
    );

    await chatRef.set(chat.toJson());
    return chat;
  }

  // ---------------- SEND MESSAGE ----------------
  Future<void> sendMessage({
    required String otherUserId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final chatId = _getChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    String senderName = 'Farmer';
    try {
      final me = await _firestore.collection('farmers').doc(currentUserId).get();
      if (me.exists) {
        senderName = me.data()?['user_name'] ?? senderName;
      }
    } catch (_) {}

    await _firestore.runTransaction((tx) async {
      tx.set(messageRef, {
        'id': messageRef.id,
        'senderId': currentUserId,
        'senderName': senderName,
        'receiverId': otherUserId,
        'text': content,
        'content': content,
        'type': type.name,
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'isRead': false,
        'read': false,
      });

      tx.set(
        chatRef,
        {
          'participants': [currentUserId, otherUserId],
          'lastMessage': content,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': {
            otherUserId: FieldValue.increment(1),
          },
        },
        SetOptions(merge: true),
      );
    });

    // 🚀 Instantly dispatch push notification to recipient via Cloudflare Worker
    try {
      NotificationService.instance.sendChatPushNotification(
        receiverId: otherUserId,
        senderName: senderName,
        content: content,
        chatId: chatId,
        messageId: messageRef.id,
        senderId: currentUserId,
      );
    } catch (e) {
      debugPrint('⚠️ Error triggering push notification: $e');
    }
  }

  // ---------------- MARK DELIVERED ----------------
  Future<void> markMessagesDelivered(String chatId, String receiverId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status', isEqualTo: 'sent')
          .get();

      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      var count = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['senderId'] != receiverId) {
          batch.update(doc.reference, {
            'status': 'delivered',
            'deliveredAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages delivered: $e');
    }
  }

  // ---------------- MARK READ ----------------
  Future<void> markMessagesRead(String chatId, String readerId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // Reset unread count for current user
      await chatRef.set({
        'unreadCount': {readerId: 0},
      }, SetOptions(merge: true));

      final unreadQuery = await chatRef
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadQuery.docs.isEmpty) return;

      final batch = _firestore.batch();
      var count = 0;
      for (final doc in unreadQuery.docs) {
        final data = doc.data();
        if (data['senderId'] != readerId) {
          batch.update(doc.reference, {
            'status': 'read',
            'isRead': true,
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages read: $e');
    }
  }

  // ---------------- UPDATE USER PRESENCE ----------------
  Future<void> updateChatPresence(String chatId, String userId, {required bool inChat}) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('chats').doc(chatId).set({
        'presence': {
          userId: {
            'inChat': inChat,
            'lastSeen': now,
          }
        },
        'participantsInfo': {
          userId: {
            'inChat': inChat,
            'lastSeen': now,
          }
        }
      }, SetOptions(merge: true));

      // Also update farmers collection lastSeen
      await _firestore.collection('farmers').doc(userId).set({
        'lastSeen': now,
        'isOnline': inChat,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  // ---------------- INBOX STREAM ----------------
  Stream<QuerySnapshot> inboxStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  // ---------------- UPLOAD MEDIA ----------------
  Future<String> uploadChatMedia(
    String chatId,
    String fileName,
    Uint8List data,
    MessageType mediaType,
  ) async {
    final ref = FirebaseService.instance.chatMediaRef(chatId, fileName);
    return FirebaseService.instance.uploadFile(ref, data);
  }

  // ---------------- SAVE CHAT SESSION (FIXED) ----------------
  /// ⚠️ REQUIRED by image_diagnosis_screen & diagnosis_chat_screen
  static Future<void> saveChatSession({
    required String chatId,
    required String sender,
    required DateTime timestamp,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(chatId)
          .set({
        'chatId': chatId,
        'sender': sender,
        'lastActive': Timestamp.fromDate(timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving chat session: $e');
    }
  }
}
