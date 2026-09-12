import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';
import '../../services/chat_service.dart';
import 'package:agribased/utils/verification_helpers.dart';
import 'package:agribased/widgets/user_info_display.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String get myId => widget.currentUserId;

  /// Delete a chat conversation
  Future<void> _deleteChat(String chatId) async {
    try {
      // Delete the chat document
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();

      // Delete all messages in the chat subcollection
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmationDialog(
    String chatId,
    String userName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete the chat with $userName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteChat(chatId);
    }
  }

  /// ✅ Compute tick logic from userInfo map
  Widget _buildVerificationBadge(Map<String, dynamic>? userInfo) {
    if (userInfo == null) return const SizedBox.shrink();

    final isVerified = userInfo['isVerified'] == true;
    final status = userInfo['verificationStatus'] ?? '';
    final paid = userInfo['verificationPaid'] == true;
    final paidRaw = userInfo['verificationPaidAt'] ?? userInfo['verificationPaidat'];

    final isPaymentExpired = isVerificationPaymentExpired(paidRaw);

    final showTick =
        isVerified && status == "approved" && paid && !isPaymentExpired;

    return showTick
        ? Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Image.asset(
              'assets/icon/verification_tick.png',
              width: 20,
              height: 20,
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (myId.isEmpty) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: myId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading chats:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Auto-mark incoming messages across inbox chats as delivered
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final unread = (data['unreadCount'] as Map<String, dynamic>?)?[myId] ?? 0;
          if (unread > 0) {
            ChatService.instance.markMessagesDelivered(doc.id, myId);
          }
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final participants = List<String>.from(data['participants'] ?? []);

            if (participants.length < 2) {
              return const SizedBox.shrink();
            }

            final otherUserId = participants.firstWhere(
              (id) => id != myId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) {
              return const SizedBox.shrink();
            }

            final lastMessage = data['lastMessage'] ?? '';

            final Timestamp? ts = data['lastMessageAt'];
            final DateTime? time = ts?.toDate();

            final unread =
                (data['unreadCount'] as Map<String, dynamic>?)?[myId] ?? 0;

            // ✅ Special handling for system messages
            final leading = otherUserId == 'system'
                ? const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.verified, color: Colors.white),
                  )
                : UserProfileImage(
                    userId: otherUserId,
                    radius: 20,
                  );

            final title = otherUserId == 'system'
                ? const Text(
                    'AgriBase System',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('farmers')
                        .doc(otherUserId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>? ??
                          {};
                      final userName = userData['user_name'] ?? 'User';

                      return Row(
                        children: [
                          Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          _buildVerificationBadge(userData),
                        ],
                      );
                    },
                  );

            return ListTile(
              key: ValueKey(doc.id),
              leading: leading,
              title: title,
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: unread > 0
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        unread > 9 ? '9+' : unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Text(
                      time != null ? DateFormat('HH:mm').format(time) : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(otherUserId: otherUserId),
                  ),
                );
              },
              onLongPress: () async {
                String userName = 'User';
                if (otherUserId != 'system') {
                  try {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('farmers')
                        .doc(otherUserId)
                        .get();
                    final userData = userDoc.data();
                    userName = userData?['user_name'] ?? 'User';
                  } catch (e) {
                    // Use default name if there's an error
                  }
                } else {
                  userName = 'AgriBase System';
                }

                await _showDeleteConfirmationDialog(doc.id, userName);
              },
            );
          },
        );
      },
    );
  }
}
