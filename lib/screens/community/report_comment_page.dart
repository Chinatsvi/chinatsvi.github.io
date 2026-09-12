import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/services/moderation_service.dart';
import 'package:agribased/models/moderation_model.dart';

class ReportCommentPage extends StatefulWidget {
  final String commentId;
  final String commentContent;
  final String commentAuthorId;
  final String commentAuthorName;
  final String postId;

  const ReportCommentPage({
    super.key,
    required this.commentId,
    required this.commentContent,
    required this.commentAuthorId,
    required this.commentAuthorName,
    required this.postId,
  });

  @override
  State<ReportCommentPage> createState() => _ReportCommentPageState();
}

class _ReportCommentPageState extends State<ReportCommentPage> {
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
      _showError('You must be logged in to report comments');
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
      await ModerationService.reportComment(
        postId: widget.postId,
        commentId: widget.commentId,
        commentAuthorId: widget.commentAuthorId,
        commentAuthorName: widget.commentAuthorName,
        violationType: violationType,
        description: 'Comment: $_reason: ${_notesCtrl.text.trim()}',
        reporterId: user.uid,
        reporterName: reporterName,
        reporterProfilePic: reporterProfilePic,
        reportedContent: widget.commentContent,
        reportedContentType: 'comment',
      );

      // Create notification for admins about new comment report
      await _createAdminNotification(
        reportId,
        user.uid,
        reporterName,
        'comment',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Comment report submitted successfully. Our team will review it.',
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
        title: const Text('Report Comment'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Show comment being reported
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
                    'Reporting Comment by ${widget.commentAuthorName}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.commentContent,
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

  // Create notification for admins about new comment report
  Future<void> _createAdminNotification(
    String reportId,
    String userId,
    String userName,
    String contentType,
  ) async {
    try {
      // Check if this is actually a reply by looking at the comment data
      String actualContentType = contentType;
      String commentId = widget.commentId;

      try {
        final commentDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(widget.commentId)
            .get();

        if (commentDoc.exists) {
          final commentData = commentDoc.data()!;
          if (commentData['parentId'] != null) {
            actualContentType = 'reply';
          }
        }
      } catch (e) {
        debugPrint('Could not determine if comment is a reply: $e');
      }

      // Create admin notification using the correct structure
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin') // Special admin user ID
          .collection('user_notifications')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🚨 New $actualContentType Report Submitted',
        'body':
            '$userName has reported a $actualContentType for violating community guidelines. Please review in the moderation dashboard.',
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
          'postId': widget.postId,
          'commentId': commentId,
          'commentAuthorName': widget.commentAuthorName,
          'reportReason': _reason,
          'submittedBy': userId,
          'contentType': actualContentType,
        },
      });

      debugPrint(
        '🔔 Admin notification created for $actualContentType report: $reportId',
      );
    } catch (e) {
      debugPrint('❌ Failed to create admin notification: $e');
      // Don't fail the report submission if notification fails
    }
  }
}
