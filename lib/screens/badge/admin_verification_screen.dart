import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:agribased/app/routes/app_routes.dart';
import 'package:agribased/app/utils/formatters.dart';

import '../../models/post_model.dart';
import '../../models/marketplace/marketplace_item_model.dart';
import '../../services/farmer_reputation_service.dart';
import '../books/book_upload_screen.dart';
import '../jobs/admin_job_verification_screen.dart';
import '../marketplace/item_details_page.dart';
import '../post/post_details_screen.dart';

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  // ---------------- Approve Farmer ----------------
  Future<void> approveFarmer(
    BuildContext context,
    String farmerId,
    String farmerName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .update({
            'isVerified': true,
            'verificationStatus': 'approved',
            'verificationApprovedAt': FieldValue.serverTimestamp(),
          });

      // 🔔 Send notification to user about approval with payment button
      await _sendApprovalNotification(farmerId, farmerName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$farmerName approved ✅ - User notified to pay'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error approving farmer: $e', name: 'AdminVerification');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔔 Send approval notification to user with payment button
  Future<void> _sendApprovalNotification(
    String farmerId,
    String farmerName,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(farmerId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🎉 Verification Approved!',
        'body':
            'Congratulations $farmerName! Your verification request has been approved. Please complete the payment to activate your verification tick.',
        'type': 'verification_approved',
        'relatedType': 'verification',
        'farmerId': farmerId,
        'farmerName': farmerName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Pay Now',
        'actionScreen': 'verification_payment',
      });

      developer.log(
        '🔔 Approval notification sent to user: $farmerId',
        name: 'AdminVerification',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending approval notification: $e',
        name: 'AdminVerification',
      );
    }
  }

  // ---------------- Reject Farmer ----------------
  Future<void> rejectFarmer(String farmerId) async {
    await FirebaseFirestore.instance
        .collection('farmers')
        .doc(farmerId)
        .update({
          'isVerified': false,
          'verificationStatus': 'rejected',
          'verificationRejectedAt': FieldValue.serverTimestamp(),
        });
  }

  // ---------------- Approve Boost Request ----------------
  Future<void> _approveBoostRequest(
    BuildContext context,
    String boostId,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final userId = boostData['userId'] as String?;
      final packageTitle = boostData['packageTitle'] ?? 'Boost Package';

      // Update boost status to approved_awaiting_payment
      await FirebaseFirestore.instance
          .collection('post_boosts')
          .doc(boostId)
          .update({
            'status': 'approved_awaiting_payment',
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'admin',
          });

      // Send notification to user for payment
      if (userId != null) {
        await _sendBoostApprovalNotification(
          userId,
          boostId,
          packageTitle,
          boostData,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$packageTitle approved - User notified to pay ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error approving boost: $e', name: 'AdminVerification');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔔 Send boost approval notification to user
  Future<void> _sendBoostApprovalNotification(
    String userId,
    String boostId,
    String packageTitle,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🎉 Boost Request Approved!',
        'body':
            'Your $packageTitle has been approved! Complete payment to activate your boost.',
        'type': 'boost_approved_for_payment',
        'boostId': boostId,
        'postId': boostData['postId'],
        'price': boostData['price'],
        'packageTitle': packageTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Pay Now',
        'actionScreen': 'boost_payment',
      });

      developer.log(
        '🔔 Boost approval notification sent to user: $userId',
        name: 'AdminVerification',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending boost approval notification: $e',
        name: 'AdminVerification',
      );
    }
  }

  // ---------------- Reject Boost Request ----------------
  Future<void> _rejectBoostRequest(
    BuildContext context,
    String boostId,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final userId = boostData['userId'] as String?;
      final packageTitle = boostData['packageTitle'] ?? 'Boost Package';

      // Update boost status to rejected
      await FirebaseFirestore.instance
          .collection('post_boosts')
          .doc(boostId)
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': 'admin',
          });

      // Send notification to user
      if (userId != null) {
        await _sendBoostRejectionNotification(userId, packageTitle);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$packageTitle rejected ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error rejecting boost: $e', name: 'AdminVerification');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔔 Send boost rejection notification to user
  Future<void> _sendBoostRejectionNotification(
    String userId,
    String packageTitle,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': 'Boost Request Not Approved',
        'body':
            'Your $packageTitle request was not approved. You can try again with different content.',
        'type': 'boost_rejected',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      developer.log(
        '🔔 Boost rejection notification sent to user: $userId',
        name: 'AdminVerification',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending boost rejection notification: $e',
        name: 'AdminVerification',
      );
    }
  }

  // ---------------- Legacy: Direct Approve Boost ----------------
  Future<void> approveBoost(String boostId, int days) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    // Get the boost document to find the farmer ID
    final boostDoc = await FirebaseFirestore.instance
        .collection('post_boosts')
        .doc(boostId)
        .get();

    if (!boostDoc.exists) return;

    final boostData = boostDoc.data()!;
    final farmerId = boostData['farmerId'] as String?;

    // Update the boost status
    await FirebaseFirestore.instance
        .collection('post_boosts')
        .doc(boostId)
        .update({
          'status': 'active',
          'startDate': now,
          'endDate': endDate,
          'approvedAt': FieldValue.serverTimestamp(),
        });

    // Recalculate reputation from actual moderation history instead of
    // manually forcing the status to a better value during approval.
    if (farmerId != null) {
      try {
        await FarmerReputationService.updateFarmerStatus(farmerId);
      } catch (e) {
        developer.log(
          'Error recalculating farmer reputation after boost approval: $e',
          name: 'AdminVerification',
        );
      }
    }
  }

  // ---------------- Reject Boost ----------------
  Future<void> rejectBoost(String boostId) async {
    await FirebaseFirestore.instance
        .collection('post_boosts')
        .doc(boostId)
        .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
  }

  String? _normalizeDocumentId(Object? rawId) {
    if (rawId == null) return null;

    if (rawId is DocumentReference) {
      return rawId.id;
    }

    if (rawId is String) {
      final trimmed = rawId.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.contains('/')) {
        final segments = trimmed.split('/');
        return segments.lastWhere((segment) => segment.isNotEmpty, orElse: () => trimmed);
      }
      return trimmed;
    }

    if (rawId is Map<String, dynamic>) {
      return _normalizeDocumentId(rawId['id']) ??
          _normalizeDocumentId(rawId['postId']) ??
          _normalizeDocumentId(rawId['documentId']);
    }

    return rawId.toString().trim();
  }

  Future<void> _openPostPreview(
    BuildContext context,
    Object? rawPostId, {
    Map<String, dynamic>? boostData,
  }) async {
    final postId = _normalizeDocumentId(rawPostId);
    developer.log('🔍 Admin preview requested for postId: $postId', name: 'AdminVerification');

    if (postId == null || postId.isEmpty || postId == 'Unknown') {
      developer.log('❌ Invalid postId: $postId', name: 'AdminVerification');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Preview unavailable'),
            content: const Text(
              'This boost request does not contain a valid post reference.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    bool isLoadingDialogVisible = false;
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    try {
      developer.log('🔄 Fetching post $postId from Firestore server...', name: 'AdminVerification');

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading post preview...'),
              ],
            ),
          ),
        ),
      );
      isLoadingDialogVisible = true;

      var postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Post fetch timed out after 10 seconds');
          });

      developer.log('✅ Post document fetched from server. Exists: ${postDoc.exists}', name: 'AdminVerification');

      if (!postDoc.exists) {
        developer.log('⚠️ Server fetch did not find post $postId. Trying default source fallback.', name: 'AdminVerification');
        try {
          postDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get()
              .timeout(const Duration(seconds: 10), onTimeout: () {
                throw TimeoutException('Fallback post fetch timed out after 10 seconds');
              });
          developer.log('✅ Fallback fetch completed. Exists: ${postDoc.exists}', name: 'AdminVerification');
        } catch (fallbackError) {
          developer.log('⚠️ Fallback post fetch failed: $fallbackError', name: 'AdminVerification');
        }
      }

      if (!postDoc.exists) {
        developer.log('⚠️ Trying cache source fallback for post $postId', name: 'AdminVerification');
        try {
          postDoc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get(const GetOptions(source: Source.cache))
              .timeout(const Duration(seconds: 10), onTimeout: () {
                throw TimeoutException('Cache post fetch timed out after 10 seconds');
              });
          developer.log('✅ Cache fetch completed. Exists: ${postDoc.exists}', name: 'AdminVerification');
        } catch (cacheError) {
          developer.log('⚠️ Cache post fetch failed: $cacheError', name: 'AdminVerification');
        }
      }

      if (!context.mounted) return;

      if (isLoadingDialogVisible && rootNavigator.canPop()) {
        try {
          rootNavigator.pop();
          developer.log('🔽 Loading dialog closed', name: 'AdminVerification');
        } catch (closeError) {
          developer.log('⚠️ Unable to close loading dialog: $closeError', name: 'AdminVerification');
        }
        isLoadingDialogVisible = false;
      }

      if (!postDoc.exists) {
        developer.log('❌ Post document does not exist in Firestore', name: 'AdminVerification');
        if (boostData != null) {
          await _openBoostRequestFallback(
            context,
            postId: postId,
            boostData: boostData,
          );
          return;
        }
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Post Not Found'),
              content: const Text(
                'The post was not found in the database. It may have been deleted. The boost request can still be approved or rejected.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final postData = postDoc.data() as Map<String, dynamic>?;
      if (postData == null) {
        developer.log('❌ Post data is null', name: 'AdminVerification');
        if (boostData != null) {
          await _openBoostRequestFallback(
            context,
            postId: postId,
            boostData: boostData,
          );
          return;
        }
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Invalid Post Data'),
              content: const Text('Post document is empty or corrupted.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      developer.log('✅ Post data valid. Keys: ${postData.keys.toList()}', name: 'AdminVerification');
      developer.log('📝 Post content preview: ${(postData['content'] as String?)?.substring(0, min(50, (postData['content'] as String?)?.length ?? 0)) ?? 'N/A'}...', name: 'AdminVerification');

      try {
        final post = Post.fromFirestore(postDoc);
        developer.log('✅ Post model created successfully: ${post.id}', name: 'AdminVerification');
        developer.log('📊 Post details: author=${post.authorName}, content_len=${post.content.length}, media_count=${post.media.length}', name: 'AdminVerification');
      } catch (parseError) {
        developer.log('⚠️ Post parse error (will still show detail screen): $parseError', name: 'AdminVerification');
      }

      if (context.mounted) {
        developer.log('🚀 Pushing PostDetailScreen for postId: $postId', name: 'AdminVerification');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              postId: postId,
              initialPostSnapshot: postDoc,
              isAdminPreview: true,
            ),
          ),
        );
        developer.log('✅ PostDetailScreen closed/popped', name: 'AdminVerification');
      }
    } on TimeoutException catch (e) {
      developer.log('❌ Timeout: $e', name: 'AdminVerification');
      if (!context.mounted) return;
      if (isLoadingDialogVisible) {
        await rootNavigator.maybePop();
        isLoadingDialogVisible = false;
      }
      if (boostData != null) {
        await _openBoostRequestFallback(
          context,
          postId: postId,
          boostData: boostData,
        );
        return;
      }
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Network Timeout'),
            content: const Text('Failed to load post preview. Please check your internet connection and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error in post preview: $e', name: 'AdminVerification');
      if (!context.mounted) return;
      if (isLoadingDialogVisible) {
        await rootNavigator.maybePop();
        isLoadingDialogVisible = false;
      }
      if (boostData != null) {
        await _openBoostRequestFallback(
          context,
          postId: postId,
          boostData: boostData,
        );
        return;
      }
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error Loading Preview'),
            content: Text('Error: $e\n\nYou can still approve or reject this boost request.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _openBoostRequestFallback(
    BuildContext context, {
    required String postId,
    required Map<String, dynamic> boostData,
  }) async {
    if (!context.mounted) return;

    final postSummary = boostData['postContent']?.toString().trim();
    final postImage = boostData['postImage']?.toString().trim();
    final postAuthorName = boostData['postAuthorName']?.toString() ?? 'Unknown';
    final packageTitle = boostData['packageTitle']?.toString() ?? 'Boost Request';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Boost Preview'),
            backgroundColor: Colors.green,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (postImage != null && postImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      postImage,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 240,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 240,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  packageTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Author: $postAuthorName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Post ID',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectableText(postId),
                const SizedBox(height: 16),
                const Text(
                  'Post Preview',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  postSummary ?? 'No text preview available for this post.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Close Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openItemPreview(BuildContext context, Object? rawItemId) async {
    final itemId = _normalizeDocumentId(rawItemId);

    if (itemId == null || itemId.isEmpty || itemId == 'Unknown') {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Preview unavailable'),
            content: const Text(
              'This boost request does not contain a valid marketplace item reference.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      DocumentSnapshot? itemDoc;
      for (final collectionName in ['Marketplace', 'marketplace']) {
        final snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(itemId)
            .get();

        if (snapshot.exists) {
          itemDoc = snapshot;
          break;
        }
      }

      if (itemDoc != null && itemDoc!.exists && context.mounted) {
        final itemData = Map<String, dynamic>.from(
          itemDoc!.data() as Map? ?? {},
        );
        final item = MarketplaceItem.fromMap({...itemData, 'id': itemDoc!.id});

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailsPage(item: item)),
        );
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Preview unavailable'),
            content: const Text(
              'The linked marketplace item could not be found. The boost request can still be approved or rejected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Preview error'),
            content: Text('Could not load item preview: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Verification'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_center),
            tooltip: 'Job Verification',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminJobVerificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Upload Books',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookUploadScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.gavel),
            tooltip: 'Moderation Dashboard',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.moderationDashboard,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- FARMER VERIFICATION ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Farmer Verification Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('farmers')
                        .where('verificationStatus', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Error loading verification requests: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No pending verification requests',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final farmers = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: farmers.length,
                        itemBuilder: (context, index) {
                          try {
                            final farmer = farmers[index];
                            final data =
                                farmer.data() as Map<String, dynamic>? ?? {};
                            final name =
                                (data['user_name'] ??
                                        data['name'] ??
                                        'Unnamed Farmer')
                                    as String;
                            final locationRaw = data['location'];
                            final formattedLoc = Formatter.formatLocation(locationRaw);
                            final String location = formattedLoc.isNotEmpty
                                ? formattedLoc
                                : 'No location';

                            // Get verification document info
                            final verificationDoc =
                                data['verificationDocument']
                                    as Map<String, dynamic>?;
                            final docUrl = verificationDoc?['url'] as String?;
                            final docType =
                                verificationDoc?['type'] as String? ??
                                'Document';

                            // Get selfie info
                            final selfieUrl = data['selfieUrl'] as String?;
                            final selfieVideoUrl =
                                data['selfieVideoUrl'] as String?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Location: $location',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        await approveFarmer(
                                          context,
                                          farmer.id,
                                          name,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await rejectFarmer(farmer.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('$name rejected ❌'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                children: [
                                  // Document Section
                                  if (docUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '📄 $docType',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              docUrl,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Text(
                                                          'Failed to load document',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Selfie Section (image)
                                  if (selfieUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📸 Selfie Verification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              selfieUrl,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Text(
                                                          'Failed to load selfie',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Selfie Video Section (inline player)
                                  if (selfieVideoUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🎬 Selfie Video Verification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: InlineVideoPreview(
                                              url: selfieVideoUrl!,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (docUrl == null && selfieUrl == null)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        '⚠️ No documents or selfie uploaded',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          } catch (e, st) {
                            developer.log(
                              'Error rendering farmer tile: $e\n$st',
                              name: 'AdminVerification',
                            );
                            return ListTile(
                              title: const Text('Error loading farmer data'),
                              subtitle: Text(e.toString()),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- BOOST APPROVAL SECTION ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Boost Approval Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('post_boosts')
                        .where('status', isEqualTo: 'pending_approval')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rocket_launch,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No pending boost requests',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final boosts = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: boosts.length,
                        itemBuilder: (context, index) {
                          final boost = boosts[index];
                          final data = boost.data() as Map<String, dynamic>;
                          final title =
                              data['packageTitle'] ?? 'Unknown Package';
                          final days = data['days'] ?? 0;
                          final price = data['price'] ?? 0;
                          final postId = data['postId'] ?? 'Unknown';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange[100],
                                child: const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.orange,
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Post: $postId',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Duration: $days days',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Amount: ${Formatter.formatCurrency(price.toDouble())}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const Text(
                                    'Status: Payment Completed - Awaiting Approval',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Preview Post',
                                    onPressed: () => _openPostPreview(
                                      context,
                                      data['postId'],
                                      boostData: data,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Approve - Send payment request',
                                    onPressed: () async {
                                      await _approveBoostRequest(
                                        context,
                                        boost.id,
                                        data,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Reject',
                                    onPressed: () async {
                                      await _rejectBoostRequest(
                                        context,
                                        boost.id,
                                        data,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- ITEM BOOST APPROVAL SECTION ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.purple, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Item Boost Approval',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('item_boosts')
                        .where('status', isEqualTo: 'pending_approval')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No pending item boost requests',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final boosts = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: boosts.length,
                        itemBuilder: (context, index) {
                          final boost = boosts[index];
                          final data = boost.data() as Map<String, dynamic>;
                          final title =
                              data['packageTitle'] ?? 'Unknown Package';
                          final days = data['days'] ?? 0;
                          final price = data['price'] ?? 0;
                          final itemId = data['itemId'] ?? 'Unknown';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[100],
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.purple,
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item: $itemId',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Duration: $days days',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Amount: ${Formatter.formatCurrency(price.toDouble())}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const Text(
                                    'Status: Pending Approval',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Preview Item',
                                    onPressed: () => _openItemPreview(
                                      context,
                                      data['itemId'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Approve - Send payment request',
                                    onPressed: () async {
                                      await _approveItemBoostRequest(
                                        context,
                                        boost.id,
                                        data,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Reject',
                                    onPressed: () async {
                                      await _rejectItemBoostRequest(
                                        context,
                                        boost.id,
                                        data,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Approve Item Boost Request ----------------
  Future<void> _approveItemBoostRequest(
    BuildContext context,
    String boostId,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final userId = boostData['userId'] as String?;
      final packageTitle = boostData['packageTitle'] ?? 'Item Boost';

      // Update boost status to approved_awaiting_payment
      await FirebaseFirestore.instance
          .collection('item_boosts')
          .doc(boostId)
          .update({
            'status': 'approved_awaiting_payment',
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'admin',
          });

      // Send notification to user for payment
      if (userId != null) {
        await _sendItemBoostApprovalNotification(
          userId,
          boostId,
          packageTitle,
          boostData,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$packageTitle approved - User notified to pay ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error approving item boost: $e',
        name: 'AdminVerification',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving item boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔔 Send item boost approval notification to user
  Future<void> _sendItemBoostApprovalNotification(
    String userId,
    String boostId,
    String packageTitle,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🛍️ Item Boost Approved!',
        'body':
            'Your $packageTitle has been approved! Complete payment to boost your item visibility.',
        'type': 'item_boost_approved_for_payment',
        'boostId': boostId,
        'itemId': boostData['itemId'],
        'price': boostData['price'],
        'packageTitle': packageTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Pay Now',
        'actionScreen': 'item_boost_payment',
      });

      developer.log(
        '🔔 Item boost approval notification sent to user: $userId',
        name: 'AdminVerification',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending item boost approval notification: $e',
        name: 'AdminVerification',
      );
    }
  }

  // ---------------- Reject Item Boost Request ----------------
  Future<void> _rejectItemBoostRequest(
    BuildContext context,
    String boostId,
    Map<String, dynamic> boostData,
  ) async {
    try {
      final userId = boostData['userId'] as String?;
      final packageTitle = boostData['packageTitle'] ?? 'Item Boost';

      // Update boost status to rejected
      await FirebaseFirestore.instance
          .collection('item_boosts')
          .doc(boostId)
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': 'admin',
          });

      // Send notification to user
      if (userId != null) {
        await _sendItemBoostRejectionNotification(userId, packageTitle);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$packageTitle rejected ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log(
        '❌ Error rejecting item boost: $e',
        name: 'AdminVerification',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting item boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔔 Send item boost rejection notification to user
  Future<void> _sendItemBoostRejectionNotification(
    String userId,
    String packageTitle,
  ) async {
    try {
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': 'Item Boost Not Approved',
        'body': 'Your $packageTitle request was not approved.',
        'type': 'item_boost_rejected',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      developer.log(
        '🔔 Item boost rejection notification sent to user: $userId',
        name: 'AdminVerification',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending item boost rejection notification: $e',
        name: 'AdminVerification',
      );
    }
  }
}

/// Full-screen video player for admin preview
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.network(widget.url);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load video: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Video'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// Inline video preview widget used inside admin list
class InlineVideoPreview extends StatefulWidget {
  final String url;
  const InlineVideoPreview({super.key, required this.url});

  @override
  State<InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<InlineVideoPreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoController = VideoPlayerController.network(widget.url);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
      );
      if (mounted) setState(() {});
    } catch (e) {
      // don't crash the admin screen; show a small error box
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: _chewieController != null
          ? Chewie(controller: _chewieController!)
          : Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
