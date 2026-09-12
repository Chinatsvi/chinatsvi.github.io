import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/widgets/safe_network_image.dart';
import '../../models/post_model.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'boost_request_utils.dart';
import 'boost_objective_page.dart';

class BoostPostPage extends StatelessWidget {
  final Post post;
  final BoostObjective objective;

  const BoostPostPage({super.key, required this.post, required this.objective});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Post'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Post Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show media preview if available, otherwise show truncated text
                    if (post.media.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SafeNetworkImage(
                            imageUrl: post.media.first.url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.content.isNotEmpty
                              ? post.content.length > 100
                                    ? '${post.content.substring(0, 100)}...'
                                    : post.content
                              : 'No content',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(objective.icon, size: 16, color: objective.color),
                        const SizedBox(width: 6),
                        Text(
                          'Goal: ${objective.title}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: objective.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current reach: ${post.analytics.viewsCount} views',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boost Packages
            const Text(
              'Choose Boost Package',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildBoostPackage(
              'Basic Boost',
              _packageDescription(1000, 3),
              Formatter.formatCurrency(2.99),
              Icons.rocket_launch,
              Colors.blue,
              () => _purchaseBoost('basic', context),
            ),

            const SizedBox(height: 12),

            _buildBoostPackage(
              'Standard Boost',
              _packageDescription(5000, 7),
              Formatter.formatCurrency(9.99),
              Icons.trending_up,
              Colors.green,
              () => _purchaseBoost('standard', context),
            ),

            const SizedBox(height: 12),

            _buildBoostPackage(
              'Premium Boost',
              _packageDescription(10000, 14),
              Formatter.formatCurrency(19.99),
              Icons.star,
              Colors.amber,
              () => _purchaseBoost('premium', context),
            ),

            const SizedBox(height: 16),

            // Benefits
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Boost Benefits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem('✓ Increased visibility in feed'),
                    _buildBenefitItem('✓ Reach targeted audience'),
                    _buildBenefitItem('✓ Higher engagement rates'),
                    _buildBenefitItem('✓ Real-time analytics'),
                    _buildBenefitItem('✓ 24-48 hour activation'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostPackage(
    String title,
    String description,
    String price,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  String _packageDescription(int reach, int days) {
    final goal = switch (objective.id) {
      'engagement' => 'Get more engagement from',
      'followers' => 'Attract followers with',
      'profile_visits' => 'Drive profile visits from',
      _ => 'Reach',
    };
    return '$goal $reach more people over $days days';
  }

  Future<void> _purchaseBoost(String package, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to boost posts')),
      );
      return;
    }

    // Define package details
    final packageDetails = _getPackageDetails(package);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm ${packageDetails['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(packageDetails['description']!),
              const SizedBox(height: 16),
              Text(
                'Price: ${Formatter.formatCurrency(packageDetails['price']!)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your boost request will be sent for admin approval. Once approved, you will be notified to complete payment.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _createBoostRequest(
                  context,
                  package,
                  packageDetails,
                  user.uid,
                );
              },
              child: const Text('Request Boost'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getPackageDetails(String package) {
    switch (package) {
      case 'basic':
        return {
          'title': 'Basic Boost',
          'description': _packageDescription(1000, 3),
          'price': 2.99,
          'days': 3,
          'reach': 1000,
        };
      case 'standard':
        return {
          'title': 'Standard Boost',
          'description': _packageDescription(5000, 7),
          'price': 9.99,
          'days': 7,
          'reach': 5000,
        };
      case 'premium':
        return {
          'title': 'Premium Boost',
          'description': _packageDescription(10000, 14),
          'price': 19.99,
          'days': 14,
          'reach': 10000,
        };
      default:
        return {
          'title': 'Boost',
          'description': 'Boost your post',
          'price': 9.99,
          'days': 7,
          'reach': 5000,
        };
    }
  }

  Future<void> _createBoostRequest(
    BuildContext context,
    String package,
    Map<String, dynamic> packageDetails,
    String userId,
  ) async {
    bool isLoadingDialogVisible = false;
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      isLoadingDialogVisible = true;
      print('🔥 [BOOST] Loading dialog shown for post ${post.id}');

      print(
        '🔥 [BOOST] Creating boost request for post ${post.id}, user $userId',
      );

      // Create pending boost request with timeout
      final boostRef = FirebaseFirestore.instance
          .collection('post_boosts')
          .doc();
      print('🔥 [BOOST] Writing to post_boosts/${boostRef.id}');

      final payload = buildPostBoostRequestPayload(
        postId: post.id,
        userId: userId,
        packageType: package,
        packageTitle: packageDetails['title'].toString(),
        description: packageDetails['description'].toString(),
        price: (packageDetails['price'] as num).toDouble(),
        days: (packageDetails['days'] as num).toInt(),
        reach: (packageDetails['reach'] as num).toInt(),
        postContent: post.content.length > 100
            ? '${post.content.substring(0, 100)}...'
            : post.content,
        postAuthorName: post.authorName,
        postAuthorId: post.authorId,
        postImage: post.media.isNotEmpty ? post.media.first.url : null,
        objectiveId: objective.id,
        objectiveTitle: objective.title,
      );

      await boostRef
          .set({
            ...payload,
            'id': boostRef.id,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Boost request creation timed out. Check your internet connection.',
              );
            },
          );
      print('✅ [BOOST] Boost request created: ${boostRef.id}');

      // Send notification to admin
      print('🔥 [BOOST] Sending admin notification...');
      await _notifyAdmin(boostRef.id, packageDetails, userId);
      print('✅ [BOOST] Admin notification sent');

      // Close loading dialog first
      if (isLoadingDialogVisible && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isLoadingDialogVisible = false;
          print('✅ [BOOST] Loading dialog dismissed');
        } catch (e) {
          print('⚠️ [BOOST] Failed to close loading dialog: $e');
        }
      }

      // Show success message
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Boost Request Sent!'),
            content: const Text(
              'Your boost request has been submitted for admin review. You will receive a notification once it is approved.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ [BOOST] Error creating boost request: $e');
      if (context.mounted) {
        // Close loading dialog if visible
        if (isLoadingDialogVisible) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
            isLoadingDialogVisible = false;
            print('✅ [BOOST] Loading dialog dismissed after error');
          } catch (e2) {
            print('⚠️ [BOOST] Failed to close loading dialog on error: $e2');
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating boost request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Ensure loading dialog is closed in all cases
      if (isLoadingDialogVisible && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isLoadingDialogVisible = false;
          print('✅ [BOOST] Loading dialog dismissed in finally');
        } catch (e) {
          print('⚠️ [BOOST] Failed to close loading dialog in finally: $e');
        }
      }
    }
  }

  Future<void> _notifyAdmin(
    String boostId,
    Map<String, dynamic> packageDetails,
    String userId,
  ) async {
    try {
      print('🔥 [BOOST_ADMIN] Creating admin notification for boost $boostId');

      // Create admin notification in the correct collection for badge count
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .doc();

      await notificationRef
          .set({
            'id': notificationRef.id,
            'type': 'boost_request',
            'title': 'New Boost Request',
            'body':
                '${post.authorName} requested ${packageDetails['title']} for their post - goal: ${objective.title}',
            'boostId': boostId,
            'postId': post.id,
            'userId': userId,
            'userName': post.authorName,
            'packageTitle': packageDetails['title'],
            'objectiveId': objective.id,
            'objectiveTitle': objective.title,
            'price': packageDetails['price'],
            'isRead': false,
            'requiresAction': true,
            'actionText': 'Review',
            'actionScreen': 'admin_verification',
            'createdAt': FieldValue.serverTimestamp(),
            'postContent': post.content.length > 50
                ? '${post.content.substring(0, 50)}...'
                : post.content,
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Admin notification timed out');
            },
          );

      print(
        '✅ [BOOST_ADMIN] Admin notification created: ${notificationRef.id}',
      );
    } catch (e) {
      print('❌ [BOOST_ADMIN] Error sending admin notification: $e');
      // Rethrow so caller knows admin notification failed
      throw Exception('Failed to notify admin: $e');
    }
  }
}
