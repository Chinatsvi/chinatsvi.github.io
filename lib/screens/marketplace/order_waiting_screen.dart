import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';
import '../../app/routes/app_routes.dart';
import 'received_order_screen.dart';

class OrderWaitingScreen extends StatelessWidget {
  final String orderId;

  const OrderWaitingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to My Orders screen
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.myOrders, (route) => false);
            },
            child: const Text(
              'My Orders',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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

            final String paymentStatus = data['paymentStatus'] ?? 'UNKNOWN';
            final String deliveryStatus = data['deliveryStatus'] ?? 'UNKNOWN';
            final String orderStatus = data['status'] ?? 'UNKNOWN';
            final bool isCancelled = orderStatus.trim().toLowerCase() ==
                'cancelled' ||
              deliveryStatus.trim().toLowerCase() == 'cancelled';

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
                  // ---------------- ORDER SUMMARY ----------------
                  Card(
                    child: ListTile(
                      leading: Image.network(
                        data['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                      title: Text(data['title']),
                      subtitle: Text(
                        'Qty: ${data['quantity']} • ${Formatter.formatCurrency((data['price'] ?? 0).toDouble(), symbol: orderCurrencySymbol)}',
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
                    icon: Icons.lock,
                    title: 'Payment Status',
                    value: paymentStatus,
                    color: paymentStatus == 'HELD'
                        ? Colors.orange
                        : Colors.green,
                  ),

                  _statusTile(
                    icon: Icons.local_shipping,
                    title: 'Delivery Status',
                    value: deliveryStatus,
                    color: deliveryStatus == 'DELIVERED'
                        ? Colors.green
                        : Colors.blue,
                  ),

                  const Spacer(),

                  // ---------------- VIEW ALL ORDERS BUTTON ----------------
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text('View All My Orders'),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.myOrders,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ---------------- BUYER ACTION ----------------
                  if (!isCancelled && deliveryStatus != 'DELIVERED')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirm I Received This Item'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReceivedOrderScreen(orderId: orderId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  if (isCancelled)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Completed Order'),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.myOrders,
                          );
                        },
                      ),
                    ),

                  if (deliveryStatus == 'DELIVERED')
                    const Center(
                      child: Text(
                        '✅ Delivery confirmed. Payment released to seller.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
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
  // This method is now handled in ReceivedOrderScreen

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
