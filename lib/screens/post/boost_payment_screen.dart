import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/mock_cash_handler.dart';
import '../../models/mock_product.dart';
import '../../services/marketplace_boost_service.dart';
import 'package:agribased/app/utils/formatters.dart';

class BoostPaymentScreen extends StatefulWidget {
  final String boostId;
  final Map<String, dynamic> boostData;

  const BoostPaymentScreen({
    super.key,
    required this.boostId,
    required this.boostData,
  });

  @override
  State<BoostPaymentScreen> createState() => _BoostPaymentScreenState();
}

class _BoostPaymentScreenState extends State<BoostPaymentScreen> {
  bool _isProcessing = false;
  bool _paymentComplete = false;

  @override
  Widget build(BuildContext context) {
    final packageTitle = widget.boostData['packageTitle'] ?? 'Boost Package';
    final price = (widget.boostData['price'] ?? 0.0).toDouble();
    final days = widget.boostData['days'] ?? 7;
    final reach = widget.boostData['reach'] ?? 5000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade50,
      body: _paymentComplete
          ? _buildSuccessView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Colors.orange.shade700,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  packageTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow('Duration:', '$days days'),
                          _buildDetailRow('Estimated Reach:', '$reach people'),
                          _buildDetailRow(
                            'Post:',
                            widget.boostData['postContent'] ?? 'Your post',
                          ),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Formatter.formatCurrency(price),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Mock Payment Option
                  Card(
                    child: InkWell(
                      onTap: _isProcessing ? null : _processMockPayment,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.credit_card,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mock Payment (Demo)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Simulate payment for testing',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isProcessing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Google Play Placeholder
                  Card(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Google Play Billing will be integrated here',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Google Play (Coming Soon)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Will be available after Play Store verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.lock,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your boost will be activated immediately after payment. You can track the performance in your post analytics.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade500, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your boost is now active and your post will reach more people.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processMockPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      // Create mock product
      final mockProduct = MockProduct(
        'boost_${widget.boostId}',
        widget.boostData['packageTitle'] ?? 'Boost',
        'Post boost for ${widget.boostData['days'] ?? 7} days',
        (widget.boostData['price'] ?? 0.0).toDouble(),
      );

      // Process mock purchase
      await MockCashHandler.instance.purchase(
        mockProduct,
        userId: user.uid,
        context: context,
      );

      // Activate the boost
      await _activateBoost();

      setState(() {
        _isProcessing = false;
        _paymentComplete = true;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  Future<void> _activateBoost() async {
    try {
      final boostId = widget.boostId;
      final days = widget.boostData['days'] ?? 7;
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: days));

      final itemId = widget.boostData['itemId']?.toString();
      final postId = widget.boostData['postId']?.toString();
      final isItemBoost =
          (itemId != null && itemId.isNotEmpty) ||
          widget.boostData['itemType']?.toString() == 'marketplace';

      final boostCollections = <String>['post_boosts', 'item_boosts'];
      if (isItemBoost) {
        boostCollections.remove('post_boosts');
        boostCollections.insert(0, 'item_boosts');
      }

      bool updatedBoostRecord = false;
      for (final collectionName in boostCollections) {
        final ref = FirebaseFirestore.instance
            .collection(collectionName)
            .doc(boostId);
        final snap = await ref.get();
        if (snap.exists) {
          await ref.update({
            'status': 'active',
            'paidAt': FieldValue.serverTimestamp(),
            'activatedAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'paymentMethod': 'mock',
            'objectiveId': widget.boostData['objectiveId'],
            'objectiveTitle': widget.boostData['objectiveTitle'],
            'impressionBudget': widget.boostData['reach'] ?? 5000,
            'impressionsDelivered': 0,
          });
          updatedBoostRecord = true;
          break;
        }
      }

      if (!updatedBoostRecord) {
        debugPrint('No matching boost request document found for $boostId');
      }

      if (isItemBoost && itemId != null && itemId.isNotEmpty) {
        await MarketplaceBoostService.instance.updateMarketplaceItemBoost(
          postId: postId ?? itemId,
          days: days,
          marketplaceItemId: itemId,
          allowAutoResolve: false,
        );
      } else if (postId != null && postId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .update({
              'isBoosted': true,
              'boostEndDate': Timestamp.fromDate(expiresAt),
              'boostExpiresAt': Timestamp.fromDate(expiresAt),
              'boostObjectiveId': widget.boostData['objectiveId'],
              'boostObjectiveTitle': widget.boostData['objectiveTitle'],
            });
      }

      await _sendSuccessNotification();
    } catch (e) {
      debugPrint('Error activating boost: $e');
    }
  }

  Future<void> _sendSuccessNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'title': '🚀 Boost Activated!',
        'body':
            'Your ${widget.boostData['packageTitle']} is now active and reaching more people.',
        'type': 'boost_activated',
        'boostId': widget.boostId,
        'postId': widget.boostData['postId'],
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
