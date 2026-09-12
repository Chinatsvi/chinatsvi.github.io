import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/services/moderation_service.dart';
import 'package:agribased/widgets/safe_network_image.dart';
import 'package:agribased/models/post_model.dart';
import 'package:agribased/models/moderation_model.dart';

class ReportPostPage extends StatefulWidget {
  final Post post;
  const ReportPostPage({super.key, required this.post});

  @override
  State<ReportPostPage> createState() => _ReportPostPageState();
}

class _ReportPostPageState extends State<ReportPostPage> {
  String _reason = 'Inappropriate';
  final _notesCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in to report posts');
      return;
    }

    // Validate reporter credibility
    final reporterValid = await _validateReporter(user.uid);
    if (!reporterValid) {
      _showError('Unable to validate report. Please contact support.');
      return;
    }

    setState(() => _sending = true);

    try {
      // Map report reason to violation type
      final violationType = _mapReasonToViolationType(_reason);

      // Get reporter information
      final reporterDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();

      if (!reporterDoc.exists) {
        _showError('Unable to get reporter information');
        return;
      }

      final reporterData = reporterDoc.data()!;
      final reporterName = reporterData['user_name'] ?? 'Anonymous';
      final reporterProfilePic = reporterData['profile_pic'];

      // Generate report ID for notification
      final reportId = FirebaseFirestore.instance
          .collection('moderation_reports')
          .doc()
          .id;

      // Create violation report through moderation service
      await ModerationService.reportContent(
        postId: widget.post.id,
        postAuthorId: widget.post.authorId,
        postAuthorName: widget.post.authorName,
        violationType: violationType,
        description: '${_reason}: ${_notesCtrl.text.trim()}',
        reporterId: user.uid,
        reporterName: reporterName,
        reporterProfilePic: reporterProfilePic,
        reportedContent: widget.post.content,
        reportedContentType: 'post',
        reportedMediaUrls: widget.post.media.map((m) => m.url).toList(),
      );

      // Create notification for admins about new report
      await _createAdminNotification(reportId, user.uid, reporterName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted successfully. Our team will review it.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Validate reporter credibility before accepting report
  Future<bool> _validateReporter(String reporterId) async {
    try {
      // Check if reporter exists and is not banned
      final reporterDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(reporterId)
          .get();

      if (!reporterDoc.exists) return false;

      final reporterData = reporterDoc.data();
      if (reporterData == null) return false;

      // Check if reporter is banned
      final isBanned = await ModerationService.isUserBanned(reporterId);
      if (isBanned) return false;

      // Check if reporter is active
      final isActive = reporterData['active'] ?? true;
      if (!isActive) return false;

      // Check if reporter has too many false reports (optional validation)
      final falseReports = await _checkFalseReports(reporterId);
      if (falseReports > 5) return false; // Threshold for false reports

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check number of false reports by this user (optional validation)
  Future<int> _checkFalseReports(String reporterId) async {
    try {
      final reports = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('status', isEqualTo: 'false_report')
          .count()
          .get();

      return reports.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Map report reason to violation type
  ViolationType _mapReasonToViolationType(String reason) {
    switch (reason) {
      case 'Inappropriate':
        return ViolationType.harassment;
      case 'Hate Speech':
        return ViolationType.hateSpeech;
      case 'Spam':
        return ViolationType.spam;
      case 'Misinformation':
        return ViolationType.misinformation;
      case 'Violence':
        return ViolationType.violence;
      case 'Other':
      default:
        return ViolationType.other;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Post'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Show post being reported
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporting Post by ${widget.post.authorName}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Show media preview if available
                  if (widget.post.media.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: PageView.builder(
                        itemCount: widget.post.media.length,
                        itemBuilder: (context, idx) {
                          final url = widget.post.media[idx].url;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SafeNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Text(
                      widget.post.content,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _reason,
              items: [
                'Inappropriate',
                'Hate Speech',
                'Spam',
                'Misinformation',
                'Violence',
                'Other',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _reason = v ?? _reason),
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (optional)',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _sendReport,
              child: _sending
                  ? const CircularProgressIndicator()
                  : const Text('Send Report'),
            ),
          ],
        ),
      ),
    );
  }

  // Create notification for admins about new report
  Future<void> _createAdminNotification(
    String reportId,
    String userId,
    String userName,
  ) async {
    try {
      // Create admin notification using the correct structure
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin') // Special admin user ID
          .collection('user_notifications')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🚨 New Report Submitted',
        'body':
            '$userName has reported a post for violating community guidelines. Please review in the moderation dashboard.',
        'type': 'admin_report_notification',
        'relatedType': 'report',
        'relatedId': reportId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'high',
        'actionUrl':
            '/moderation_dashboard?tab=reports', // Navigate to reports tab
        'metadata': {
          'reportId': reportId,
          'postId': widget.post.id,
          'postAuthorName': widget.post.authorName,
          'reportReason': _reason,
          'submittedBy': userId,
        },
      });

      debugPrint('🔔 Admin notification created for report: $reportId');
    } catch (e) {
      debugPrint('❌ Failed to create admin notification: $e');
      // Don't fail the report submission if notification fails
    }
  }
}
