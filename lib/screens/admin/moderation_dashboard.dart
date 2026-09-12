import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/farmer_reputation_service.dart';
import '../../services/moderation_service.dart';
import '../../services/verification_renewal_service.dart';
import 'farmer_management_tab.dart';
import 'status_scheduler_admin_screen.dart';
import '../farm_works/fertilizer_admin_screen.dart';
import 'package:agribased/widgets/safe_network_image.dart';

class ModerationDashboard extends StatefulWidget {
  final int initialTab;

  const ModerationDashboard({super.key, this.initialTab = 0});

  @override
  State<ModerationDashboard> createState() => _ModerationDashboardState();
}

class _ModerationDashboardState extends State<ModerationDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialTab,
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation Dashboard'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'Fertilizer Recommendation Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FertilizerAdminScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Reports', icon: Icon(Icons.report)),
              Tab(text: 'Appeals', icon: Icon(Icons.gavel)),
              Tab(text: 'Manage Farmers', icon: Icon(Icons.manage_accounts)),
              Tab(text: 'Verification Reminders', icon: Icon(Icons.notifications_active)),
              Tab(text: 'Status Scheduler', icon: Icon(Icons.schedule)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportsTab(),
            _AppealsTab(),
            FarmerManagementTab(),
            _VerificationRemindersTab(),
            _StatusSchedulerTab(),
          ],
        ),
      ),
    );
  }
}

class _VerificationRemindersTab extends StatefulWidget {
  const _VerificationRemindersTab();

  @override
  State<_VerificationRemindersTab> createState() =>
      _VerificationRemindersTabState();
}

class _VerificationRemindersTabState extends State<_VerificationRemindersTab> {
  bool _isSending = false;

  Future<void> _sendRemindersNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);

    try {
      await VerificationRenewalService().checkAndSendRenewalReminders();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Verification reminder scan completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to send verification reminders right now'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send verification repayment reminders to farmers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This triggers the renewal reminder service for farmers whose verification tick is due for repayment. The reminder notification keeps the “Renew Now” action visible to the farmer.',
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendRemindersNow,
                  icon: const Icon(Icons.notifications_active),
                  label: _isSending
                      ? const Text('Sending reminders...')
                      : const Text('Send reminders now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (_) {
        return 'Unknown';
      }
    } else {
      return 'Unknown';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessageToUser(
    BuildContext context,
    String userId,
    String userName,
    String type,
    String itemId,
  ) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Message to $userName'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
            'userId': userId,
            'title': 'Message from AgriBase Team',
            'body': controller.text.trim(),
            'type': 'admin_message',
            'relatedType': type,
            'relatedId': itemId,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'fromAdmin': true,
            'adminId': FirebaseAuth.instance.currentUser?.uid,
          });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Message sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmViolation(
    BuildContext context,
    String postId,
    String reportId,
    String? reportedUserId, {
    String contentType = 'post',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (contentType == 'marketplace') {
        await ModerationService.removeMarketplaceItem(
          postId,
          reason: 'Violation confirmed by admin',
        );
      } else if (contentType == 'profile_picture') {
        await ModerationService.removeProfilePicture(
          reportedUserId ?? postId,
          reason: 'Violation confirmed by admin',
        );
      } else if (contentType == 'cover_photo') {
        await ModerationService.removeCoverPhoto(
          reportedUserId ?? postId,
          reason: 'Violation confirmed by admin',
        );
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'communityHidden': true,
          'status': 'removed',
          'moderationStatus': 'violation_confirmed',
          'moderatedAt': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseFirestore.instance
          .collection('moderation_reports')
          .doc(reportId)
          .update({
            'status': 'resolved',
            'actionTaken': 'violationConfirmed',
            'moderatorId': FirebaseAuth.instance.currentUser?.uid,
            'resolvedAt': DateTime.now().toIso8601String(),
          });
      if (reportedUserId != null && reportedUserId.isNotEmpty) {
        await FarmerReputationService.onModerationAction(reportedUserId);
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Violation confirmed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeContent(
    BuildContext context,
    String? postId,
    Map<String, dynamic> reportData,
    String reportId,
  ) async {
    if (postId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final contentType = (reportData['reportedContentType'] ??
            reportData['contentType'] ??
            'post')
        .toString();
    final reportedUserId = reportData['reportedUserId'] as String?;
    try {
      if (contentType == 'marketplace') {
        await ModerationService.removeMarketplaceItem(
          postId,
          reason: 'Content removed by admin',
        );
      } else if (contentType == 'profile_picture') {
        await ModerationService.removeProfilePicture(
          reportedUserId ?? postId,
          reason: 'Content removed by admin',
        );
      } else if (contentType == 'cover_photo') {
        await ModerationService.removeCoverPhoto(
          reportedUserId ?? postId,
          reason: 'Content removed by admin',
        );
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      }
      await FirebaseFirestore.instance
          .collection('moderation_reports')
          .doc(reportId)
          .update({
            'status': 'resolved',
            'actionTaken': 'contentRemoval',
            'resolvedAt': DateTime.now().toIso8601String(),
          });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Content removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectReport(
    BuildContext context,
    String reportId, {
    String? postId,
    String contentType = 'post',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('moderation_reports')
          .doc(reportId)
          .update({
            'status': 'rejected',
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      if (postId != null && postId.isNotEmpty) {
        if (contentType == 'marketplace') {
          await ModerationService.restoreMarketplaceItem(
            postId,
            reason: 'Report rejected by admin',
          );
        } else {
          await ModerationService.restoreContent(
            postId,
            reason: 'Report rejected by admin',
          );
        }
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No pending reports'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final postId = data['reportedPostId'] as String?;
            final reportedUserId = data['reportedUserId'] as String?;
            final contentType = (data['reportedContentType'] ??
                    data['contentType'] ??
                    'post')
                .toString();

            return Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['description'] ?? 'Report',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(
                            contentType.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reported by: ${data['reporterName'] ?? 'Unknown'} • ${_formatDateTime(data['createdAt'])}',
                    ),
                    const SizedBox(height: 8),
                    if ((data['reportedMediaUrls'] as List<dynamic>?)?.isNotEmpty == true ||
                        (data['reported_media_urls'] as List<dynamic>?)?.isNotEmpty == true)
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: ((data['reportedMediaUrls'] as List?) ??
                                  (data['reported_media_urls'] as List?) ??
                                  [])
                              .map<Widget>((m) {
                                final url = m is String
                                    ? m
                                    : (m is Map ? m['url'] ?? '' : '');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SafeNetworkImage(
                                      imageUrl: url ?? '',
                                      width: 120,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorWidget: Container(
                                        color: Colors.grey.shade200,
                                        width: 120,
                                        height: 80,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'message') {
                              _sendMessageToUser(
                                context,
                                data['reporterId'] ?? '',
                                data['reporterName'] ?? 'User',
                                'report',
                                postId ?? '',
                              );
                            }
                            if (action == 'confirm' && postId != null) {
                              _confirmViolation(
                                context,
                                postId,
                                doc.id,
                                reportedUserId,
                                contentType: contentType,
                              );
                            }
                            if (action == 'remove' && postId != null) {
                              _removeContent(context, postId, data, doc.id);
                            }
                            if (action == 'reject') {
                              _rejectReport(
                                context,
                                doc.id,
                                postId: postId,
                                contentType: contentType,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'message',
                              child: Text('Message Reporter'),
                            ),
                            PopupMenuItem(
                              value: 'confirm',
                              child: Text('Confirm Violation'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove Content'),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text('Reject Report'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AppealsTab extends StatefulWidget {
  const _AppealsTab();

  @override
  State<_AppealsTab> createState() => _AppealsTabState();
}

class _AppealsTabState extends State<_AppealsTab> {
  final Set<String> _dismissedAppealIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appeals')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final visibleDocs = docs
            .where((doc) => !_dismissedAppealIds.contains(doc.id))
            .toList();

        if (visibleDocs.isEmpty) {
          return const Center(child: Text('No pending appeals'));
        }

        return ListView.builder(
          itemCount: visibleDocs.length,
          itemBuilder: (context, i) {
            final doc = visibleDocs[i];
            return _AppealDecisionCard(
              key: ValueKey(doc.id),
              doc: doc,
              onHandled: () {
                if (!mounted) return;
                setState(() {
                  _dismissedAppealIds.add(doc.id);
                });
              },
            );
          },
        );
      },
    );
  }
}

class _AppealDecisionCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onHandled;

  const _AppealDecisionCard({
    super.key,
    required this.doc,
    required this.onHandled,
  });

  @override
  State<_AppealDecisionCard> createState() => _AppealDecisionCardState();
}

class _AppealDecisionCardState extends State<_AppealDecisionCard> {
  final TextEditingController _reviewNoteController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _updateAppealStatus(String status, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('appeals')
          .doc(widget.doc.id)
          .update({
            'status': status,
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': DateTime.now().toIso8601String(),
            'adminNote': _reviewNoteController.text.trim(),
            'decision': status,
          });

      if (status == 'approved') {
        final appealData = widget.doc.data() as Map<String, dynamic>;
        final postId = appealData['postId'] as String?;
        final contentType = (appealData['contentType'] ??
                appealData['reportedContentType'] ??
                'post')
            .toString();
        if (postId != null && postId.isNotEmpty) {
          if (contentType == 'marketplace') {
            await ModerationService.restoreMarketplaceItem(
              postId,
              reason: 'Appeal approved by admin',
            );
          } else {
            await ModerationService.restoreContent(
              postId,
              reason: 'Appeal approved by admin',
            );
          }
        }
      }

      if (mounted) {
        widget.onHandled();
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: status == 'approved'
                ? Colors.green
                : status == 'rejected'
                    ? Colors.orange
                    : Colors.blue,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openOriginalReportComparison() async {
    final data = widget.doc.data() as Map<String, dynamic>;
    final postId = (data['postId'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? '';

    final reportQuery = await FirebaseFirestore.instance
        .collection('moderation_reports')
        .where('reportedPostId', isEqualTo: postId)
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    final reportDoc = reportQuery.docs.isNotEmpty ? reportQuery.docs.first : null;
    final reportData = reportDoc?.data();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final reportDescription = reportData?['description'] ?? 'No report description available';
        final reportStatus = reportData?['status'] ?? 'unknown';
        final reporterName = reportData?['reporterName'] ?? 'Unknown';
        final createdAt = reportData?['createdAt'];
        final mediaUrls = (reportData?['reportedMediaUrls'] as List?) ??
            (reportData?['reported_media_urls'] as List?) ??
            [];

        return AlertDialog(
          title: const Text('Original report record'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report ID: ${reportDoc?.id ?? 'Not found'}'),
                  const SizedBox(height: 8),
                  Text('Status: $reportStatus'),
                  const SizedBox(height: 8),
                  Text('Reported by: $reporterName'),
                  const SizedBox(height: 8),
                  Text('Description: $reportDescription'),
                  const SizedBox(height: 12),
                  if (mediaUrls.isNotEmpty) ...[
                    const Text(
                      'Media in report:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: mediaUrls.map<Widget>((item) {
                          final url = item is String
                              ? item
                              : (item is Map ? item['url'] ?? '' : '');
                          if (url.toString().isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SafeNetworkImage(
                              imageUrl: url.toString(),
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                width: 140,
                                height: 110,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (createdAt != null)
                    Text('Created: ${createdAt.toString()}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final postId = data['postId'] as String? ?? '';
    final userName = data['userName'] ?? 'Unknown user';
    final submitReason = data['reason'] ?? 'No reason provided';
    final userStatement = data['userStatement'] ?? '';
    final violations = (data['violations'] as Map?)?.keys.join(", ") ?? "Unknown";

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appeal from: $userName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Post ID: $postId'),
                      Text('Violations: $violations'),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openOriginalReportComparison,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Original report'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original moderation reason: $submitReason',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'User appeal statement: ${userStatement.isEmpty ? 'No statement provided' : userStatement}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (postId.isNotEmpty)
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final postData = postSnapshot.data?.data();
                  final content = postData?['content'] ??
                      postData?['description'] ??
                      'No post content available';
                  final media = (postData?['media'] as List?) ??
                      (postData?['mediaUrls'] as List?) ??
                      [];

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post preview:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(content.toString()),
                        if (media.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: media.map<Widget>((item) {
                                final url = item is String
                                    ? item
                                    : (item is Map ? item['url'] ?? '' : '');
                                if (url.toString().isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SafeNetworkImage(
                                    imageUrl: url.toString(),
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      width: 120,
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            const Text(
              'Reviewer note',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reviewNoteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add your review reason, follow-up, or requested clarification',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _updateAppealStatus(
                              'approved',
                              'Appeal approved',
                            ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _updateAppealStatus(
                              'rejected',
                              'Appeal rejected',
                            ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _updateAppealStatus(
                          'more_info_requested',
                          'More info requested from user',
                        ),
                icon: const Icon(Icons.help_outline),
                label: const Text('Ask for more info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewNoteController.dispose();
    super.dispose();
  }
}

class _StatusSchedulerTab extends StatelessWidget {
  const _StatusSchedulerTab();

  @override
  Widget build(BuildContext context) {
    return const StatusSchedulerAdminScreen();
  }
}
