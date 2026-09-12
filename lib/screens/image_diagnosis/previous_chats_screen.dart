import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diagnosis_chat_screen.dart';

class PreviousChatsScreen extends StatefulWidget {
  const PreviousChatsScreen({super.key});

  @override
  State<PreviousChatsScreen> createState() => _PreviousChatsScreenState();
}

class _PreviousChatsScreenState extends State<PreviousChatsScreen> {
  Future<void> _deleteGhostChatsOlderThanSevenDays() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('sender', isEqualTo: uid)
        .get();

    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] != 'diagnosis') continue;

      final title = (data['title'] as String? ?? '').trim();
      final lastMessage = (data['last_message'] as String? ?? '').trim();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      final isGhost = title.isEmpty && lastMessage.isEmpty;
      if (isGhost && timestamp != null && timestamp.isBefore(cutoff)) {
        await doc.reference.delete();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _deleteGhostChatsOlderThanSevenDays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Diagnosis Chats'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(
              'sender',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
            )
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No previous AI chats found.'));
          }

          final diagnosisDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['type'] != 'diagnosis') return false;

            final title = (data['title'] as String? ?? '').trim();
            final lastMessage = (data['last_message'] as String? ?? '').trim();
            if (title.isEmpty && lastMessage.isEmpty) return false;

            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            if (timestamp != null &&
                timestamp.isBefore(
                  DateTime.now().subtract(const Duration(days: 7)),
                ) &&
                (title.isEmpty || lastMessage.isEmpty)) {
              return false;
            }

            return true;
          }).toList();

          if (diagnosisDocs.isEmpty) {
            return const Center(child: Text('No previous AI chats found.'));
          }

          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: diagnosisDocs.length,
            itemBuilder: (context, index) {
              final data = diagnosisDocs[index].data() as Map<String, dynamic>;
              final chatId = data['chat_id'] as String? ?? '';
              final storedTitle = data['title'] as String? ?? '';
              final lastMessage = data['last_message'] as String? ?? '';
              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final displaySubtitle = storedTitle.isNotEmpty
                  ? storedTitle
                  : lastMessage.isNotEmpty
                  ? lastMessage
                  : 'Start a new diagnosis';

              if (chatId.isEmpty) {
                return const SizedBox.shrink();
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/icon/chinatsvi.png'),
                ),
                title: const Text(
                  'Chinatsvi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} '
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onLongPress: () async {
                  if (chatId.isEmpty) return;

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete chat?'),
                      content: const Text(
                        'This will permanently delete this diagnosis chat.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final messagesRef = FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages');
                  final messagesSnapshot = await messagesRef.get();
                  for (var doc in messagesSnapshot.docs) {
                    await doc.reference.delete();
                  }

                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .delete();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat deleted')),
                    );
                  }
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiagnosisChatScreen(
                        chatId: chatId,
                        sender: FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}