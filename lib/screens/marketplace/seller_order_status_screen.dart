import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/utils/formatters.dart';
import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/order_service.dart';
import '../profile/farmer_profile_screen.dart';

class SellerOrderStatusScreen extends StatelessWidget {
  final String sellerId;
  final bool showCancelled;
  final bool showDelivered;

  const SellerOrderStatusScreen({
    super.key,
    required this.sellerId,
    required this.showCancelled,
    this.showDelivered = false,
  });

  String _normalized(String value) => value.trim().toLowerCase();

  bool _isCancelled(OrderModel order) {
    return _normalized(order.status) == 'cancelled' ||
        _normalized(order.deliveryStatus) == 'cancelled';
  }

  bool _isPaymentReleased(OrderModel order) {
    final status = _normalized(order.paymentStatus);
    return status == 'released' || status == 'paid' || status == 'completed';
  }

  bool _matches(OrderModel order) {
    if (showCancelled) return _isCancelled(order);
    if (showDelivered) {
      return !_isCancelled(order) &&
          _normalized(order.deliveryStatus) == 'delivered';
    }
    return !_isCancelled(order) && !_isPaymentReleased(order);
  }

  Future<void> _setDeliveryCost(BuildContext context, OrderModel order) async {
    final controller = TextEditingController(
      text: order.deliveryCost == 0 ? '' : order.deliveryCost.toString(),
    );
    final cost = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log delivery cost'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cost (${order.currency})',
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (cost == null) return;

    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
      'deliveryCost': cost,
      'deliveryCostCurrency': order.currency,
    });
  }

  Future<String> _buyerName(OrderModel order) async {
    if (order.buyerId.isEmpty) return order.buyerName;
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(order.buyerId)
        .get();
    final data = doc.data();
    if (data == null) return order.buyerName;

    final storedName =
        (data['user_name'] ?? data['name'] ?? data['displayName'])
            ?.toString()
            .trim();
    if (storedName != null && storedName.isNotEmpty) return storedName;

    final firstName = data['firstName']?.toString().trim() ?? '';
    final lastName = data['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? order.buyerName : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final title = showCancelled
        ? 'Returned goods'
        : showDelivered
        ? 'Delivered'
        : 'Pending Release';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading orders: ${snapshot.error}'),
            );
          }

          final fetchedOrders = snapshot.data!.docs
              .map((doc) => OrderModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();

          return FutureBuilder<List<OrderModel>>(
            future: _ordersWithExistingBuyers(fetchedOrders),
            builder: (context, ordersSnapshot) {
              if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = (ordersSnapshot.data ?? const <OrderModel>[])
                  .where(_matches)
                  .toList();

              if (orders.isEmpty) {
                return Center(child: Text('No ${title.toLowerCase()} orders'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return FutureBuilder<String>(
                    future: _buyerName(order),
                    builder: (context, buyerSnapshot) {
                      final buyerName = buyerSnapshot.data ?? order.buyerName;
                      final deliveryLabel = showCancelled
                          ? 'Delivery: Returned goods'
                          : showDelivered
                          ? 'Delivery cost: ${Formatter.formatCurrency(order.deliveryCost, symbol: order.currency)}'
                          : 'Awaiting payment release';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: showDelivered
                              ? () => _setDeliveryCost(context, order)
                              : null,
                          leading: order.image.isEmpty
                              ? const Icon(Icons.inventory_2)
                              : Image.network(
                                  order.image,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.inventory_2),
                                ),
                          title: Text(
                            order.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qty: ${order.quantity}  •  ${Formatter.formatCurrency(order.totalAmount, symbol: order.currency)}',
                              ),
                              if (order.buyerId.isNotEmpty)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FarmerProfileScreen(
                                        userId: order.buyerId,
                                        currentUserId: sellerId,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Buyer: $buyerName',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Text(deliveryLabel),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<OrderModel>> _ordersWithExistingBuyers(
    List<OrderModel> orders,
  ) async {
    return OrderService().filterDeliverableOrders(orders, checkBuyer: true);
  }
}
