import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/marketplace/order_service.dart';
import '../../models/marketplace/order_model.dart';
import '../../app/utils/formatters.dart';
import 'order_detail_screen.dart';

class OrdersReceivedScreen extends StatefulWidget {
  const OrdersReceivedScreen({super.key});

  @override
  State<OrdersReceivedScreen> createState() => _OrdersReceivedScreenState();
}

class _OrdersReceivedScreenState extends State<OrdersReceivedScreen> {
  final OrderService service = OrderService();
  final Set<String> _notifiedOrders = {};

  // Cache for buyer names
  final Map<String, String> _buyerNames = {};

  Future<String> _getBuyerName(String buyerId) async {
    if (_buyerNames.containsKey(buyerId)) {
      return _buyerNames[buyerId]!;
    }

    try {
      final buyerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(buyerId)
          .get();

      if (buyerDoc.exists) {
        final buyerData = buyerDoc.data();
        if (buyerData != null) {
          final name = buyerData['user_name'] ?? buyerData['name'] ?? 'Unknown Buyer';
          _buyerNames[buyerId] = name.toString();
          return name.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetching buyer name: $e');
    }

    return 'Unknown Buyer';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: const Text('Completed Orders'),
        ),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('Completed Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: service.streamValidSellerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data ?? [];
          final releasedOrders = allOrders
              .where((o) => o.paymentStatus.toUpperCase() == 'RELEASED')
              .toList();

          if (releasedOrders.isEmpty) {
            return const Center(child: Text('No completed orders yet.'));
          }

          // Trigger notifications for newly released payments
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var order in releasedOrders) {
              if (!_notifiedOrders.contains(order.id)) {
                _notifiedOrders.add(order.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '💰 Payment released for order: ${order.title}',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: releasedOrders.length,
            itemBuilder: (context, index) {
              final order = releasedOrders[index];

              return FutureBuilder<String>(
                future: _getBuyerName(order.buyerId),
                builder: (context, nameSnapshot) {
                  final buyerName = nameSnapshot.data ?? order.buyerName;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderId: order.id),
                          ),
                        );
                      },
                      leading: order.image.isNotEmpty
                          ? Image.network(
                              order.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image),
                            ),
                      title: Text(
                        order.title.isNotEmpty ? order.title : 'Item',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qty: ${order.quantity}'),
                          Text(
                            'Total: ${Formatter.formatCurrency(order.totalAmount, symbol: order.currency)}',
                          ),
                          Text('Buyer: $buyerName'),
                          Text('Delivery: ${order.deliveryStatus}'),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
