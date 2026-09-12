import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/utils/verification_helpers.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, Map<String, dynamic>> participantsInfo;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantsInfo,
    required this.lastMessage,
    required this.lastMessageAt,
    Map<String, int>? unreadCount,
  }) : unreadCount = unreadCount ?? {for (final p in participants) p: 0};

  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantsInfo: (data['participantsInfo'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: (data['unreadCount'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantsInfo': participantsInfo,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
    };
  }

  /// ✅ Helper: should show tick for a given participant
  bool showTickFor(String userId) {
    final info = participantsInfo[userId];
    if (info == null) return false;

    final isVerified = info['isVerified'] == true;
    final verificationStatus = info['verificationStatus'] as String?;
    final verificationPaid = info['verificationPaid'] == true;
    final verificationPaidAt = info['verificationPaidAt'] is Timestamp
      ? (info['verificationPaidAt'] as Timestamp).toDate()
      : (info['verificationPaidat'] is Timestamp
        ? (info['verificationPaidat'] as Timestamp).toDate()
        : null);

    return isVerified &&
        verificationStatus == "approved" &&
        verificationPaid &&
        !isVerificationPaymentExpired(verificationPaidAt);
  }
}
