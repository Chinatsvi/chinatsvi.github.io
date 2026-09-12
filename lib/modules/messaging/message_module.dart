import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MessagingModule {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String contentType, // 'text', 'image', 'voice'
    required String contentUrl,
  }) async {
    final message = {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content_type': contentType,
      'content_url': contentUrl,
      'created_at': Timestamp.now(),
      'seen': false,
    };

    await _firestore.collection('messages').add(message);

    // Optionally: store chat summary for inbox view
    final chatId = _getChatId(senderId, receiverId);
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'last_message': contentType == 'text' ? contentUrl : '[Media message]',
      'updated_at': Timestamp.now(),
    });
  }

  static String _getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
  }

  static Stream<QuerySnapshot> getMessages(String userId, String peerId) {
    return _firestore
        .collection('messages')
        .where('sender_id', whereIn: [userId, peerId])
        .where('receiver_id', whereIn: [userId, peerId])
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  static Future<void> markAsSeen(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({'seen': true});
  }

  static Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .snapshots();
  }

  // 🔽 Upload media to Firebase Storage
  static Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}