import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'diagnosis_chat_screen.dart';
import 'previous_chats_screen.dart';
import '../../services/analytics_service.dart';

class ImageDiagnosisScreen extends StatelessWidget {
  const ImageDiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sender = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriBase Farmer Comm.'),
        backgroundColor: Colors.green[700],
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'previous') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PreviousChatsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'previous',
                child: Text('View Previous Chats'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/icon/chinatsvi.png'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chinatsvi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              '🩺 Diagnose Crop or Livestock Issues',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Send a photo, file, or message describing your problem. Our system will help you identify possible causes and solutions.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ================= START CHAT =================
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Start Diagnosis Chat'),
              onPressed: () async {
                final chatId = const Uuid().v4();

                // ✅ Save chat session directly in Firestore
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .set({
                      'chat_id': chatId,
                      'sender': sender,
                      'type': 'diagnosis',
                      'timestamp': FieldValue.serverTimestamp(),
                      'last_message': '',
                      'title': '',
                    });

                // ✅ Analytics
                AnalyticsService.instance.logEvent(
                  'diagnosis_chat_started',
                  parameters: {'chatId': chatId, 'sender': sender},
                );

                // ✅ Navigate to chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DiagnosisChatScreen(chatId: chatId, sender: sender),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
