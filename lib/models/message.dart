import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String mediaUrl;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.mediaUrl,
    required this.sentAt,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    final rawSentAt = data['sent_at'] ?? data['timestamp'] ?? data['createdAt'] ?? data['sentAt'];
    DateTime sentAt;
    if (rawSentAt is Timestamp) {
      sentAt = rawSentAt.toDate();
    } else if (rawSentAt is String) {
      sentAt = DateTime.tryParse(rawSentAt) ?? DateTime.now();
    } else {
      sentAt = DateTime.now();
    }

    String textContent = '';
    if (data['text'] is String) {
      textContent = data['text'];
    } else if (data['content'] is String) {
      textContent = data['content'];
    }

    return Message(
      id: id,
      senderId: data['sender_id'] ?? data['senderId'] ?? '',
      receiverId: data['receiver_id'] ?? data['receiverId'] ?? '',
      text: textContent,
      mediaUrl: data['media_url'] ?? data['mediaUrl'] ?? '',
      sentAt: sentAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'senderId': senderId,
      'receiver_id': receiverId,
      'receiverId': receiverId,
      'text': text,
      'content': text,
      'media_url': mediaUrl,
      'mediaUrl': mediaUrl,
      'sent_at': Timestamp.fromDate(sentAt),
      'timestamp': Timestamp.fromDate(sentAt),
      'createdAt': Timestamp.fromDate(sentAt),
    };
  }
}
