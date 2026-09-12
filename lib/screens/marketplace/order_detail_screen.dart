import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/order_service.dart';
import '../../app/utils/formatters.dart';
import 'orders_received_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  Future<bool> _checkUserDocExists(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      final doc = await FirebaseFirestore.instance.collection('farmers').doc(userId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red[700],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Order ID is missing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please go back and try again.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final orderService = OrderService();
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final order = OrderModel.fromMap(data);
          final String currentOrderId = data['orderId'] ?? data['id'] ?? orderId;

          final bool isBuyer = user.uid == order.buyerId;
          final String otherPartyId = isBuyer ? order.sellerId : order.buyerId;
          final bool isCancelled = order.status.trim().toLowerCase() == 'cancelled' ||
              order.deliveryStatus.trim().toLowerCase() == 'cancelled';

          return FutureBuilder<bool>(
            future: _checkUserDocExists(otherPartyId),
            builder: (context, docSnapshot) {
              final otherPartyExists = docSnapshot.data ?? true;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!otherPartyExists && !isCancelled)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isBuyer
                                    ? 'Notice: Seller account no longer exists in Firestore. You can cancel this order.'
                                    : 'Notice: Buyer account no longer exists in Firestore (nowhere to deliver).',
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _infoRow('Order', order.title),
                    _infoRow('Quantity', order.quantity.toString()),
                    _infoRow(
                      'Total',
                      Formatter.formatCurrency(
                        order.totalAmount,
                        symbol: order.currency,
                      ),
                    ),
                    _infoRow('Delivery status', order.deliveryStatus),
                    _infoRow('Payment status', order.paymentStatus),
                    const SizedBox(height: 20),
                    if (isBuyer) ...[
                      if (!isCancelled &&
                          order.deliveryStatus.toUpperCase() != 'DELIVERED' &&
                          order.paymentStatus.toUpperCase() != 'RELEASED' &&
                          otherPartyExists)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirm I Received This Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Confirm receipt'),
                                  content: const Text(
                                    'Have you received this item? This will release the payment to the seller.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed != true) return;

                              try {
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(currentOrderId)
                                    .update({
                                  'deliveryStatus': 'DELIVERED',
                                  'paymentStatus': 'RELEASED',
                                  'sellerPaid': true,
                                  'deliveredAt': FieldValue.serverTimestamp(),
                                });

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delivery confirmed. Payment released to seller.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to confirm delivery: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      if (isCancelled || order.paymentStatus.toUpperCase() == 'RELEASED')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('View Completed Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrdersReceivedScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      if ((order.status == 'pending' || !otherPartyExists) && !isCancelled) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              try {
                                await orderService.cancelOrder(currentOrderId);
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order cancelled successfully'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to cancel order: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                    if (!isBuyer && !otherPartyExists && !isCancelled) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel / Void Undeliverable Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            try {
                              await orderService.cancelOrder(currentOrderId);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Undeliverable order cancelled'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- SMALL HELPER ----------------
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
