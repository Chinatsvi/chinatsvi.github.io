import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppealFormScreen extends StatefulWidget {
  final String appealId;
  final String postId;
  final String reason;
  final List<String> violations;

  const AppealFormScreen({
    super.key,
    required this.appealId,
    required this.postId,
    required this.reason,
    required this.violations,
  });

  @override
  State<AppealFormScreen> createState() => _AppealFormScreenState();
}

class _AppealFormScreenState extends State<AppealFormScreen> {
  final _statementController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Don't create appeal record here - only create when user submits
    debugPrint('📝 Appeal form opened, waiting for user submission');
  }

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    if (_statementController.text.trim().isEmpty) {
      _showMessage('Please provide your statement for the appeal');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();

      final userName =
          userDoc.data()?['user_name'] ??
          userDoc.data()?['name'] ??
          userDoc.data()?['displayName'] ??
          'Unknown User';

      // Check if appeal already exists for this post and user
      final existingAppeal = await FirebaseFirestore.instance
          .collection('appeals')
          .where('postId', isEqualTo: widget.postId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      String appealId;

      if (existingAppeal.docs.isNotEmpty) {
        // Update existing appeal
        appealId = existingAppeal.docs.first.id;
        await FirebaseFirestore.instance
            .collection('appeals')
            .doc(appealId)
            .update({
              'userStatement': _statementController.text.trim(),
              'userName': userName,
              'submittedAt': DateTime.now().toIso8601String(),
              'appealedAt': FieldValue.serverTimestamp(),
              'status': 'pending',
              'violations': widget.violations,
              'reason': widget.reason,
            });
        debugPrint('📝 Updated existing appeal: $appealId');
      } else {
        // Create new appeal record
        appealId = FirebaseFirestore.instance.collection('appeals').doc().id;
        await FirebaseFirestore.instance
            .collection('appeals')
            .doc(appealId)
            .set({
              'id': appealId,
              'userId': user.uid,
              'userName': userName,
              'postId': widget.postId,
              'violations': widget.violations,
              'reason': widget.reason,
              'status': 'pending',
              'createdAt': DateTime.now().toIso8601String(),
              'userStatement': _statementController.text.trim(),
              'submittedAt': DateTime.now().toIso8601String(),
              'appealedAt': FieldValue.serverTimestamp(),
              'adminResponse': '',
            });
        debugPrint('📝 Created new appeal: $appealId');
      }

      _showMessage('Appeal submitted successfully');

      // Create notification for admins (does not use context)
      await _createAdminNotification(appealId, user.uid);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Error submitting appeal: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Create notification for admins about new appeal
  Future<void> _createAdminNotification(String appealId, String userId) async {
    try {
      // Get user info for notification
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      final userName =
          userDoc.data()?['user_name'] ??
          userDoc.data()?['name'] ??
          userDoc.data()?['displayName'] ??
          'Unknown User';

      // Create admin notification using the correct structure
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin') // Special admin user ID
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'userId': 'admin',
        'title': '🚨 New Appeal Submitted',
        'body':
            '$userName has submitted an appeal for post ${widget.postId}. Please review in the moderation dashboard.',
        'type': 'admin_appeal_notification',
        'relatedType': 'appeal',
        'relatedId': appealId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'postId': widget.postId,
        'appealId': appealId,
        'submittedBy': userId,
      });

      debugPrint('🔔 Admin notification created for appeal: $appealId');
    } catch (e) {
      debugPrint('❌ Failed to create admin notification: $e');
      // Don't fail the appeal submission if notification fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Appeal'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Report Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Original Report:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Post ID: ${widget.postId}'),
                  Text('Violations: ${widget.violations.join(', ')}'),
                  Text('Reason: ${widget.reason}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // User Appeal Form
            const Text(
              'Your Appeal Statement:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _statementController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText:
                    'Please explain why you believe this content should not have been removed...',
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Submitting false information in your appeal may result in additional penalties. Please be honest and thorough in your explanation.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Appeal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
