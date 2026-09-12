import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/marketplace/order_service.dart';
import '../../models/marketplace/order_model.dart';
import '../../app/utils/formatters.dart';
import '../../app/routes/app_routes.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  MyOrdersScreen({super.key});

  final OrderService service = OrderService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: const Text('My Orders'),
        ),
        body: const Center(child: Text('Please log in to view your orders.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cart);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: service.streamValidBuyerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('You have no active orders'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final image = (order.image.isNotEmpty) ? order.image : null;
              final paymentStatus = order.paymentStatus.toUpperCase();
              final deliveryStatus = order.deliveryStatus.toUpperCase();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Item Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image != null
                              ? Image.network(
                                  image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.image),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // 🔹 Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.title.isNotEmpty ? order.title : 'Item',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                'Quantity: ${order.quantity}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Price: ${Formatter.formatCurrency(order.price, symbol: order.currency)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),

                              // 🔹 Payment Status
                              Text(
                                'Payment: $paymentStatus',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: paymentStatus == 'RELEASED'
                                      ? Colors.green
                                      : (paymentStatus == 'HELD' || paymentStatus == 'PAID'
                                          ? Colors.orange
                                          : Colors.red),
                                ),
                              ),

                              // 🔹 Delivery Status
                              Text(
                                'Delivery: $deliveryStatus',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔹 Cancel Button (only pending)
                        if ((paymentStatus == 'HELD' || paymentStatus == 'UNPAID') &&
                            deliveryStatus == 'PENDING')
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              await service.cancelOrder(order.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order cancelled'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
