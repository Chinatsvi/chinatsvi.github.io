import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

// Import the step screens
import 'location_form_screen.dart';
import 'document_upload_screen.dart';
import 'selfie_check_screen.dart';

class VerificationRequestScreen extends StatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  State<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  bool loading = false;

  bool locationDone = false;
  bool documentsDone = false;
  bool selfieDone = false;

  Future<void> submitRequest() async {
    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();
      final farmerData = farmerDoc.data();
      final farmerName =
          farmerData?['user_name'] ?? farmerData?['name'] ?? 'Unknown Farmer';

      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        'verificationStatus': 'pending',
        'verificationRequestedAt': FieldValue.serverTimestamp(),
      });

      // 🔔 Send notification to admin
      await _sendAdminNotification(uid, farmerName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Submitted, waiting for approval')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// 🔔 Send notification to admin about new verification request
  Future<void> _sendAdminNotification(
    String farmerId,
    String farmerName,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🆕 New Verification Request',
        'body':
            '$farmerName has submitted a verification request and is waiting for your approval.',
        'type': 'admin_verification_request',
        'relatedType': 'verification',
        'farmerId': farmerId,
        'farmerName': farmerName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Review Request',
        'actionScreen': 'admin_verification',
      });

      developer.log(
        '🔔 Admin notification sent for verification request: $farmerId',
        name: 'VerificationRequest',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending admin notification: $e',
        name: 'VerificationRequest',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allStepsDone = locationDone && documentsDone && selfieDone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Request'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Follow the steps below to apply for verification. '
              'Once all steps are complete, you can submit for approval.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _stepTile(
              title: "Fill Location Address",
              done: locationDone,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationFormScreen()),
                );
                if (result == true) setState(() => locationDone = true);
              },
            ),
            _stepTile(
              title: "Upload Documents",
              done: documentsDone,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentUploadScreen(),
                  ),
                );
                if (result == true) setState(() => documentsDone = true);
              },
            ),
            _stepTile(
              title: "Selfie / Video Check",
              done: selfieDone,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SelfieCheckScreen()),
                );
                if (result == true) setState(() => selfieDone = true);
              },
            ),

            const Spacer(),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: allStepsDone ? submitRequest : null,
                      child: const Text('Submit for Review'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile({
    required String title,
    required bool done,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      trailing: !done
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: onTap,
              child: const Text("Complete"),
            )
          : const Text("Done", style: TextStyle(color: Colors.green)),
    );
  }
}
