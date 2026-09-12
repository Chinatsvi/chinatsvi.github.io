import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String contentType; // 'text', 'image', or 'voice'
  final String contentUrl;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.contentType,
    required this.contentUrl,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      contentType: data['content_type'] ?? 'text',
      contentUrl: data['content_url'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content_type': contentType,
      'content_url': contentUrl,
      'timestamp': timestamp,
      'is_read': isRead,
    };
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _getChatId(String a, String b) {
    return a.hashCode <= b.hashCode ? '${a}_$b' : '${b}_$a';
  }

  void _showDeleteMessageDialog(String messageId, Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _firestore
                      .collection('messages')
                      .doc(_getChatId(_auth.currentUser!.uid, widget.peerId))
                      .collection('chats')
                      .doc(messageId)
                      .delete();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting message: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage({
    required String senderId,
    required String receiverId,
    required String contentType,
    required String contentUrl,
  }) async {
    final chatId = _getChatId(senderId, receiverId);

    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        .add({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content_type': contentType,
          'content_url': contentUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'is_read': false,
        });

    // Update the chat metadata
    await _firestore.collection('chats').doc(chatId).set({
      'last_message': contentUrl.length > 30
          ? '${contentUrl.substring(0, 30)}...'
          : contentUrl,
      'last_message_time': FieldValue.serverTimestamp(),
      'participants': [senderId, receiverId],
      'sender_id': senderId,
      'receiver_id': receiverId,
    }, SetOptions(merge: true));
  }

  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _sendMessage(
      senderId: _auth.currentUser!.uid,
      receiverId: widget.peerId,
      contentType: 'text',
      contentUrl: text,
    );
    _controller.clear();
  }

  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final url = await _uploadFile(
        File(picked.path),
        'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await _sendMessage(
        senderId: _auth.currentUser!.uid,
        receiverId: widget.peerId,
        contentType: 'image',
        contentUrl: url,
      );
    }
  }

  Future<void> _toggleRecord() async {
    if (!_isRecording) {
      final dir = await getTemporaryDirectory();
      _recordPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: _recordPath);
    } else {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final url = await _uploadFile(
          File(path),
          'voice_notes/${DateTime.now().millisecondsSinceEpoch}.aac',
        );
        await _sendMessage(
          senderId: _auth.currentUser!.uid,
          receiverId: widget.peerId,
          contentType: 'voice',
          contentUrl: url,
        );
      }
    }
    setState(() => _isRecording = !_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .doc(_getChatId(userId, widget.peerId))
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i].data() as Map<String, dynamic>;
                    final isMe = msg['sender_id'] == userId;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onDoubleTap: isMe
                            ? () =>
                                  _showDeleteMessageDialog(messages[i].id, msg)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.green.shade300
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _buildMessageContent(msg),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> msg) {
    switch (msg['content_type']) {
      case 'text':
        return Text(msg['content_url']);
      case 'image':
        return Image.network(msg['content_url'], width: 180);
      case 'voice':
        return const Icon(Icons.mic, color: Colors.red);
      default:
        return const Text('[Unsupported message]');
    }
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? Colors.red : Colors.black,
            ),
            onPressed: _toggleRecord,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendText),
        ],
      ),
    );
  }
}
