import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';

class ReceivedOrderScreen extends StatelessWidget {
  final String orderId;

  const ReceivedOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('❌ Order not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final orderCurrency = (data['currencySymbol'] ?? data['currency'] ?? data['currencyCode'])?.toString();
            final orderCurrencySymbol = orderCurrency != null && orderCurrency.trim().isNotEmpty
                ? orderCurrency
                : 'ZAR';
            final String deliveryStatus = data['deliveryStatus'] ?? 'UNKNOWN';
            final String paymentStatus = data['paymentStatus'] ?? 'UNKNOWN';

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- ORDER INFO ----------------
                  Card(
                    child: ListTile(
                      leading: Image.network(
                        data['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                      title: Text(data['title'] ?? 'Item'),
                      subtitle: Text(
                        'Qty: ${data['quantity'] ?? 1} • ${Formatter.formatCurrency((data['price'] ?? 0).toDouble(), symbol: orderCurrencySymbol)}',
                      ),
                      trailing: Text(
                        Formatter.formatCurrency(
                          (data['totalAmount'] ?? 0).toDouble(),
                          symbol: orderCurrencySymbol,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- STATUS ----------------
                  _statusTile(
                    icon: Icons.local_shipping,
                    title: 'Delivery Status',
                    value: deliveryStatus,
                    color: deliveryStatus == 'DELIVERED'
                        ? Colors.green
                        : Colors.blue,
                  ),

                  _statusTile(
                    icon: Icons.account_balance_wallet,
                    title: 'Payment Status',
                    value: paymentStatus,
                    color: paymentStatus == 'RELEASED'
                        ? Colors.green
                        : Colors.orange,
                  ),

                  const Spacer(),

                  // ---------------- CONFIRMATION SECTION ----------------
                  if (deliveryStatus != 'DELIVERED')
                    Column(
                      children: [
                        const Text(
                          'Have you received this item?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Confirming delivery will release the payment to the seller.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirm I Received This Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size.fromHeight(50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _confirmDelivery(context),
                          ),
                        ),
                      ],
                    ),

                  // ---------------- ALREADY DELIVERED ----------------
                  if (deliveryStatus == 'DELIVERED')
                    const Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 80,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '✅ Delivery Already Confirmed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Payment has been released to the seller.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- CONFIRM DELIVERY ----------------
  Future<void> _confirmDelivery(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'deliveryStatus': 'DELIVERED',
            'paymentStatus': 'RELEASED',
            'sellerPaid': true,
            'deliveredAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Delivery confirmed! Payment released to seller.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to confirm delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------- STATUS TILE ----------------
  Widget _statusTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
