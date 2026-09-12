import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityAlertsScreen extends StatelessWidget {
  const CommunityAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const currentUserId = 'user_001'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Alerts'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reactions')
            .where('user_id', isEqualTo: currentUserId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                'No alerts yet.\nStay tuned for updates!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (_, i) {
              final alert = alerts[i].data() as Map<String, dynamic>;
              final type = alert['type'] ?? 'unknown';
              final postId = alert['post_id'] ?? 'N/A';
              final timestamp = alert['created_at'] as Timestamp?;
              final time = timestamp != null
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                  : 'Unknown time';

              return ListTile(
                leading: Icon(
                  type == 'like'
                      ? Icons.favorite
                      : type == 'comment'
                      ? Icons.chat_bubble
                      : Icons.share,
                  color: Colors.green,
                ),
                title: Text('You received a $type on post $postId'),
                subtitle: Text(time),
              );
            },
          );
        },
      ),
    );
  }
}
