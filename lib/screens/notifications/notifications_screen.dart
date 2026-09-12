import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../moderation/appeal_form_screen.dart';
import '../admin/moderation_dashboard.dart';
import '../badge/renewal_payment_screen.dart';
import '../badge/admin_verification_screen.dart';
import '../jobs/admin_job_verification_screen.dart';
import '../post/boost_payment_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../../services/job/job_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/notification_ui_utils.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final AuthController _authController = AuthController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, DateTime> _appealDeadlines = {};
  final Set<String> _appealedPosts = {};
  bool _isAdmin = false;
  bool _adminStatusLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAppealDeadlines();
    _checkAdminStatus();
  }

  /// Check if current user is admin
  Future<void> _checkAdminStatus() async {
    final currentUserId = _authController.currentUser?.uid;
    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          _adminStatusLoaded = true;
        });
      }
      return;
    }

    try {
      final doc = await _firestore
          .collection('farmers')
          .doc(currentUserId)
          .get();
      final isAdmin = doc.exists && doc.data()?['role'] == 'admin';
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _adminStatusLoaded = true;
        });
      }
      debugPrint('🔐 Admin status for user $currentUserId: $isAdmin');
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _adminStatusLoaded = true;
        });
      }
    }
  }

  /// Load existing appeal deadlines from Firestore
  Future<void> _loadAppealDeadlines() async {
    final currentUserId = _authController.currentUser?.uid;
    if (currentUserId == null) return;

    final appealsSnapshot = await _firestore
        .collection('appeals')
        .where('userId', isEqualTo: currentUserId)
        .get();

    for (final doc in appealsSnapshot.docs) {
      final data = doc.data();
      final postId = data['postId'] as String?;
      final submittedAt =
          (data['appealedAt'] as Timestamp?)?.toDate() ??
          (data['submittedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : null);

      if (postId != null && submittedAt != null) {
        final deadline = submittedAt.add(const Duration(days: 7));
        setState(() {
          _appealDeadlines[postId] = deadline;
          _appealedPosts.add(postId);
        });
      }
    }
  }

  /// Check if user can appeal (within 7 days and not already appealed)
  bool _canAppeal(String postId, DateTime? deadline) {
    if (deadline == null) return false;

    final remaining = deadline.difference(DateTime.now());
    return remaining.inMilliseconds > 0 && !_appealedPosts.contains(postId);
  }

  /// Get remaining time for appeal
  String _getRemainingTime(DateTime? deadline) {
    if (deadline == null) return '';

    final remaining = deadline.difference(DateTime.now());
    if (remaining.inMilliseconds <= 0) return 'Expired';

    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours % 24;
    return '${daysLeft}d ${hoursLeft}h left';
  }

  DateTime? _resolveAppealDeadline(DocumentSnapshot notif) {
    final dataMap = notif.data() as Map<String, dynamic>?;
    final postId =
        (notif['postId'] as String?) ??
        (dataMap?['postId'] as String?) ??
        (dataMap?['contentId'] as String?);

    if (postId != null && _appealDeadlines.containsKey(postId)) {
      return _appealDeadlines[postId];
    }

    final createdAtRaw = notif['createdAt'] ?? dataMap?['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    if (createdAt == null) return null;

    return createdAt.add(const Duration(days: 7));
  }

  /// Build appeal button with countdown and status
  Widget _buildAppealButton(DocumentSnapshot notif) {
    final dataMap = notif.data() as Map<String, dynamic>?;
    final postId =
        (notif['postId'] as String?) ??
        (dataMap?['postId'] as String?) ??
        (dataMap?['contentId'] as String?);

    if (postId == null) {
      return const Text(
        'Appeal data not available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final deadline = _resolveAppealDeadline(notif);
    final canAppeal = _canAppeal(postId, deadline);
    final hasAppealed = _appealedPosts.contains(postId);
    final remainingTime = _getRemainingTime(deadline);

    if (hasAppealed) {
      return const Text(
        'Appealed',
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    if (deadline == null || !canAppeal) {
      return const Text(
        'Appeal expired',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    Color appealColor = Colors.green;
    if (remainingTime.isNotEmpty && remainingTime != 'Expired') {
      final remaining = deadline.difference(DateTime.now());
      final totalHours = remaining.inHours;

      if (totalHours < 24) {
        appealColor = Colors.red;
      } else if (totalHours < 72) {
        appealColor = Colors.orange;
      } else {
        appealColor = Colors.green;
      }
    }

    return GestureDetector(
      onTap: () => _fileAppeal(notif),
      child: Text(
        'Appeal',
        style: TextStyle(
          color: appealColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// File appeal with deadline tracking
  Future<void> _fileAppeal(DocumentSnapshot notif) async {
    final dataMap = notif.data() as Map<String, dynamic>?;
    final postId =
        (notif['postId'] as String?) ??
        (dataMap?['postId'] as String?) ??
        (dataMap?['contentId'] as String?);

    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appeal data not available')),
      );
      return;
    }

    final deadline = _resolveAppealDeadline(notif);
    if (deadline == null || deadline.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appeal expired. The 7-day window has passed.'),
        ),
      );
      return;
    }

    if (_appealedPosts.contains(postId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already appealed this post')),
      );
      return;
    }

    // Navigate to appeal form - don't record appeal yet
    final reason = notif['body'] ?? '';
    final violations =
        (dataMap?['violations'] as List<dynamic>?)?.cast<String>() ??
        ['violation'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppealFormScreen(
          appealId: postId,
          postId: postId,
          reason: reason,
          violations: violations,
        ),
      ),
    );
  }

  /// Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    final currentUserId = _authController.currentUser?.uid;
    if (currentUserId == null) return;

    final notificationPath = _isAdmin
        ? _firestore
              .collection('notifications')
              .doc('admin')
              .collection('items')
        : _firestore
              .collection('notifications')
              .doc(currentUserId)
              .collection('items');

    await notificationPath.doc(notificationId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteNotification(notificationId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete notification
  Future<void> _deleteNotification(String notificationId) async {
    final currentUserId = _authController.currentUser?.uid;
    if (currentUserId == null) return;

    final notificationPath = _isAdmin
        ? _firestore
              .collection('notifications')
              .doc('admin')
              .collection('items')
        : _firestore
              .collection('notifications')
              .doc(currentUserId)
              .collection('items');

    await notificationPath.doc(notificationId).delete();
  }

  /// Widget that navigates directly to the Appeals tab in ModerationDashboard
  Widget _AppealsTabNavigator() {
    return const ModerationDashboard(initialTab: 1); // Appeals tab is index 1
  }

  /// Widget that navigates directly to the Reports tab in ModerationDashboard
  Widget _ReportsTabNavigator() {
    return const ModerationDashboard(initialTab: 0); // Reports tab is index 0
  }

  /// Build admin verification button for admin notifications
  Widget _buildAdminVerificationButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
        );
      },
      icon: const Icon(Icons.verified_user, size: 16),
      label: const Text('Review Request'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Build generic action button based on notification action fields
  Widget _buildGenericActionButton(Map<String, dynamic> data) {
    final actionText = data['actionText'] as String?;
    final actionScreen = data['actionScreen'] as String?;
    final jobId = data['jobId'] as String?;

    if (actionText == null || actionScreen == null)
      return const SizedBox.shrink();

    // Determine button color based on action type
    Color buttonColor = Colors.blue;
    if (actionScreen.contains('verification') ||
        actionScreen.contains('approval')) {
      buttonColor = Colors.orange;
    } else if (actionScreen.contains('job')) {
      buttonColor = Colors.green;
    }

    return ElevatedButton.icon(
      onPressed: () {
        _handleNotificationAction(actionScreen, jobId: jobId);
      },
      icon: Icon(
        actionScreen.contains('verification') ||
                actionScreen.contains('approval')
            ? Icons.verified_user
            : actionScreen.contains('job')
            ? Icons.work
            : Icons.arrow_forward,
        size: 16,
      ),
      label: Text(actionText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Handle navigation based on actionScreen
  void _handleNotificationAction(String actionScreen, {String? jobId}) {
    debugPrint('🔔 Handling action: $actionScreen, jobId: $jobId');

    switch (actionScreen) {
      case 'admin_job_verification':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminJobVerificationScreen()),
        );
        break;
      case 'admin_verification':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
        );
        break;
      case 'job_detail':
        if (jobId != null) {
          _navigateToJobDetail(jobId);
        }
        break;
      default:
        debugPrint('🔔 Unknown action screen: $actionScreen');
    }
  }

  /// Navigate to job detail screen
  Future<void> _navigateToJobDetail(String jobId) async {
    final jobService = JobService();
    final job = await jobService.getJobById(jobId);
    if (job != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load job details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build job verification button for admin job notifications
  Widget _buildJobVerificationButton(String jobId) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminJobVerificationScreen()),
        );
      },
      icon: const Icon(Icons.work, size: 16),
      label: const Text('Review Job'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Build view job detail button for admin to see full content before approval
  Widget _buildViewJobDetailButton(String jobId) {
    return OutlinedButton.icon(
      onPressed: () async {
        // Fetch job details and show full content
        final jobService = JobService();
        final job = await jobService.getJobById(jobId);
        if (job != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load job details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: const Icon(Icons.visibility, size: 16),
      label: const Text('View Full Content'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Build payment button for boost approved notifications
  Widget _buildBoostPaymentButton(Map<String, dynamic> data) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoostPaymentScreen(
              boostId: data['boostId'] ?? '',
              boostData: data,
            ),
          ),
        );
      },
      icon: const Icon(Icons.payment, size: 16),
      label: const Text('Pay Now'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Build payment button for verification approved notifications
  Widget _buildVerificationPaymentButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RenewalPaymentScreen()),
        );
      },
      icon: const Icon(Icons.payment, size: 16),
      label: const Text('Pay Now'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Build renewal button for renewal reminder notifications
  Widget _buildRenewalButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RenewalPaymentScreen()),
        );
      },
      icon: const Icon(Icons.payment, size: 16),
      label: const Text('Renew Now'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authController.currentUser?.uid;
    final isAdmin = _isAdmin;

    if (!_adminStatusLoaded && currentUserId != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isAdmin
            ? Colors.purple.shade700
            : Colors.green.shade700,
        title: Text(isAdmin ? "Admin Notifications" : "Notifications"),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('ADMIN'),
                backgroundColor: Colors.purple.shade100,
                labelStyle: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),

      body: currentUserId == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
              key: ValueKey(
                'notifications_stream_$currentUserId',
              ), // Rebuild stream when user changes
              stream: isAdmin
                  ? _firestore
                        .collection('notifications')
                        .doc('admin')
                        .collection('items')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : _firestore
                        .collection('notifications')
                        .doc(currentUserId)
                        .collection('items')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
              builder: (context, snapshot) {
                debugPrint(
                  '🔔 Notification snapshot state: ${snapshot.connectionState}',
                );
                debugPrint(
                  '🔔 Notification data count: ${snapshot.hasData ? snapshot.data!.docs.length : 0}',
                );

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notifications"));
                }

                final notifications = snapshot.data!.docs;
                debugPrint(
                  '🔔 Processing ${notifications.length} notifications',
                );

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];

                    // Guard: Verify notification belongs to current user to prevent flickering cross-user notifications
                    final notifData = notif.data() as Map<String, dynamic>?;
                    final notifUserId = notifData?['userId'] as String?;

                    // For non-admin users, verify the notification belongs to them
                    if (!isAdmin &&
                        notifUserId != null &&
                        notifUserId != currentUserId) {
                      debugPrint(
                        '⚠️ GUARD: Skipping notification $index - belongs to userId: $notifUserId, current: $currentUserId',
                      );
                      return const SizedBox.shrink(); // Skip this notification silently
                    }

                    debugPrint('🔔 Notification $index: ${notif.data()}');

                    final isRead = notif.data() != null && notif.data() is Map
                        ? (notif.data() as Map).containsKey('isRead')
                              ? (notif.data() as Map)['isRead'] as bool? ??
                                    false
                              : false
                        : false;
                    final type = notif['type'];
                    debugPrint('🔔 Notification type: $type');

                    return ListTile(
                      tileColor: isRead
                          ? Colors.grey.shade200
                          : isAdmin
                          ? Colors.purple.shade50
                          : Colors.green.shade50,
                      leading: Icon(
                        isRead
                            ? Icons.notifications
                            : _isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.notifications_active,
                        color: isRead
                            ? Colors.grey
                            : isAdmin
                            ? Colors.purple.shade700
                            : Colors.green.shade700,
                      ),
                      title: Text(
                        notif['title'] ?? "",
                        style: TextStyle(
                          fontWeight: isAdmin && !isRead
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isAdmin && !isRead
                              ? Colors.purple.shade700
                              : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif['body'] ?? ""),
                          const SizedBox(height: 8),
                          // Show appeal info for admin notifications
                          if (isAdmin && type == 'admin_appeal_notification')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.gavel,
                                    size: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Requires Review',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Show report info for admin notifications
                          if (isAdmin && type == 'admin_report_notification')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.report,
                                    size: 14,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${notif['metadata']?['contentType']?.toString().toUpperCase() ?? 'CONTENT'} Report',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Only show the appeal button for moderation
                          // removal notifications that are explicitly
                          // linked to an appeal record.
                          if (!isAdmin &&
                              shouldShowAppealButton(
                                type: type?.toString(),
                                data: notif.data() as Map<String, dynamic>?,
                              ))
                            _buildAppealButton(notif),
                          // Show renewal button for renewal reminder notifications
                          if (!isAdmin &&
                              (type == 'renewal_reminder' ||
                                  type == 'renewal_expired'))
                            _buildRenewalButton(),
                          // Show payment button for verification approved
                          if (!isAdmin && type == 'verification_approved')
                            _buildVerificationPaymentButton(),
                          // Show payment button for boost approved
                          if (!isAdmin &&
                              (type == 'boost_approved_for_payment' ||
                                  type == 'item_boost_approved_for_payment'))
                            _buildBoostPaymentButton(
                              notif.data() as Map<String, dynamic>,
                            ),
                          // Show admin verification button for admin
                          if (isAdmin && type == 'admin_verification_request')
                            _buildAdminVerificationButton(),
                          // Show job verification buttons for admin job notifications
                          if (isAdmin &&
                              (type == 'job_pending_approval' ||
                                  type == 'job_approval')) ...[
                            const SizedBox(height: 8),
                            _buildJobVerificationButton(notif['jobId'] ?? ''),
                            const SizedBox(height: 8),
                            _buildViewJobDetailButton(notif['jobId'] ?? ''),
                          ],
                          // Generic action button fallback for admin notifications
                          if (isAdmin &&
                              type != 'job_pending_approval' &&
                              type != 'job_approval' &&
                              type != 'admin_verification_request' &&
                              type != 'admin_appeal_notification' &&
                              type != 'admin_report_notification' &&
                              (notif.data()
                                      as Map<
                                        String,
                                        dynamic
                                      >?)?['requiresAction'] ==
                                  true) ...[
                            const SizedBox(height: 8),
                            _buildGenericActionButton(
                              (notif.data() as Map<String, dynamic>?) ?? {},
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        notif['createdAt'] != null
                            ? (notif['createdAt'] is Timestamp
                                  ? (notif['createdAt'] as Timestamp)
                                        .toDate()
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16) // Remove seconds
                                  : DateTime.tryParse(
                                          notif['createdAt'] as String,
                                        )?.toLocal().toString().substring(
                                          0,
                                          16,
                                        ) ??
                                        notif['createdAt'].toString().substring(
                                          0,
                                          16,
                                        ))
                            : "",
                        style: const TextStyle(fontSize: 10),
                      ),
                      onTap: () {
                        if (!isRead) _markAsRead(notif.id);
                        // For admin notifications, navigate to appropriate screen
                        if (isAdmin && type == 'admin_appeal_notification') {
                          debugPrint(
                            '🔔 Admin appeal notification tapped - navigating to appeals tab',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _AppealsTabNavigator(),
                            ),
                          );
                        } else if (isAdmin &&
                            type == 'admin_report_notification') {
                          debugPrint(
                            '🔔 Admin report notification tapped - navigating to reports tab',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _ReportsTabNavigator(),
                            ),
                          );
                        } else if (isAdmin &&
                            type == 'admin_verification_request') {
                          debugPrint(
                            '🔔 Admin verification notification tapped - navigating to admin verification',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminVerificationScreen(),
                            ),
                          );
                        } else if (isAdmin &&
                            (type == 'job_pending_approval' ||
                                type == 'job_approval' ||
                                (notif['actionScreen'] ==
                                    'admin_job_verification'))) {
                          debugPrint(
                            '🔔 Admin job notification tapped - navigating to admin job verification',
                          );
                          _handleNotificationAction(
                            'admin_job_verification',
                            jobId: notif['jobId'] as String?,
                          );
                        } else if (!isAdmin &&
                            type == 'verification_approved') {
                          debugPrint(
                            '🔔 Verification approved notification tapped - navigating to payment',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RenewalPaymentScreen(),
                            ),
                          );
                        } else if (!isAdmin &&
                            (type == 'boost_approved_for_payment' ||
                                type == 'item_boost_approved_for_payment')) {
                          debugPrint(
                            '🔔 Boost approved notification tapped - navigating to boost payment',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BoostPaymentScreen(
                                boostId: notif['boostId'] ?? '',
                                boostData: notif.data() as Map<String, dynamic>,
                              ),
                            ),
                          );
                        } else if (isAdmin &&
                            (type == 'boost_request' ||
                                type == 'post_boost_request' ||
                                type == 'item_boost_request')) {
                          debugPrint(
                            '🔔 Admin boost notification tapped - navigating to admin verification',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminVerificationScreen(),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        _showDeleteConfirmation(context, notif.id);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
