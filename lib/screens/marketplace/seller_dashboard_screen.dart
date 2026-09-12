import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/order_service.dart';
import '../../screens/marketplace/order_detail_screen.dart';
import '../../screens/marketplace/seller_order_status_screen.dart';
import '../../screens/marketplace/farmer_sell_list_screen.dart';
import '../../services/marketplace/firebase_marketplace_service.dart';
import '../profile/farmer_profile_screen.dart';
import '../profile/farmer_model.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String sellerId;

  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Security check: ensure current user matches the sellerId
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != widget.sellerId) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'You can only view your own seller dashboard.',
                style: TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please go back and view your own profile.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Load every seller order so pending and cancelled orders are visible.
    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: widget.sellerId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.black,
        title: const Text('Seller Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Orders'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final fetchedOrders = (snapshot.data?.docs ?? []).map((doc) {
            final orderData = doc.data() as Map<String, dynamic>;
            // Add document ID to the data since OrderModel expects it
            orderData['id'] = doc.id; // Use Firestore document ID
            return OrderModel.fromMap(orderData);
          }).toList();

          return FutureBuilder<List<OrderModel>>(
            future: _ordersWithExistingBuyers(fetchedOrders),
            builder: (context, ordersSnapshot) {
              if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allOrders = ordersSnapshot.data ?? const <OrderModel>[];
              final orders = allOrders
                  .where((order) => !_isCancelled(order))
                  .toList();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Marketplace')
                    .where('sellerId', isEqualTo: widget.sellerId)
                    .snapshots(),
                builder: (context, inventorySnapshot) {
                  if (inventorySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final activeInventoryCount =
                      (inventorySnapshot.data?.docs ?? []).where((doc) {
                        final status = (doc.data()['status'] ?? 'active')
                            .toString()
                            .toLowerCase();
                        return status == 'active';
                      }).length;
                  final pendingReleaseCount = orders
                      .where((order) => !_isPaymentReleased(order))
                      .fold<int>(0, (total, order) => total + order.quantity);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(
                        orders,
                        allOrders,
                        activeInventoryCount,
                        pendingReleaseCount,
                      ),
                      _buildOrdersTab(orders),
                      _buildAnalyticsTab(orders),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    List<OrderModel> orders,
    List<OrderModel> allOrders,
    int activeInventoryCount,
    int pendingReleaseCount,
  ) {
    final totalEarnings = <String, double>{};
    for (final order in orders) {
      if (_isPaymentReleased(order) && !_isCancelled(order)) {
        totalEarnings[order.currency] =
            (totalEarnings[order.currency] ?? 0) +
            order.totalAmount -
            order.deliveryCost;
      }
    }

    final returnedItems = allOrders
        .where(_isCancelled)
        .fold<int>(0, (total, order) => total + order.quantity);
    final deliveredItems = orders
        .where(
          (order) =>
              !_isCancelled(order) &&
              _normalized(order.deliveryStatus) == 'delivered',
        )
        .fold<int>(0, (total, order) => total + order.quantity);
    final totalItemsSold = orders
        .where((order) => !_isCancelled(order) && _isPaymentReleased(order))
        .fold<int>(0, (total, order) => total + order.quantity);
    // Payment notifications removed to prevent spam
    // Notifications should only show when genuinely new payments arrive
    // Not every time dashboard opens or rebuilds

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...totalEarnings.entries.map(
                  (entry) => Text(
                    Formatter.formatCurrency(entry.value, symbol: entry.key),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Orders: ${orders.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              _buildStatCard(
                'Pending Release',
                pendingReleaseCount.toString(),
                Icons.pending_actions,
                Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerOrderStatusScreen(
                      sellerId: widget.sellerId,
                      showCancelled: false,
                    ),
                  ),
                ),
              ),
              _buildStatCard(
                'Returned goods',
                returnedItems.toString(),
                Icons.assignment_return,
                Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerOrderStatusScreen(
                      sellerId: widget.sellerId,
                      showCancelled: true,
                    ),
                  ),
                ),
              ),
              _buildStatCard(
                'Items Sold',
                totalItemsSold.toString(),
                Icons.shopping_cart,
                Colors.teal,
              ),
              _buildStatCard(
                'Delivered',
                deliveredItems.toString(),
                Icons.local_shipping,
                Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerOrderStatusScreen(
                      sellerId: widget.sellerId,
                      showCancelled: false,
                      showDelivered: true,
                    ),
                  ),
                ),
              ),
              _buildStatCard(
                'Completed',
                totalItemsSold.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'My Inventory',
                activeInventoryCount.toString(),
                Icons.inventory,
                Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmerSellListScreen(
                      farmerId: widget.sellerId,
                      farmerName: 'My Inventory',
                      marketplaceService: FirebaseMarketplaceService.instance,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recent Orders Preview
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...orders.take(3).map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 8,
                color: color.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<OrderModel>> _ordersWithExistingBuyers(
    List<OrderModel> orders,
  ) async {
    return OrderService().filterDeliverableOrders(orders, checkBuyer: true);
  }

  Widget _buildOrdersTab(List<OrderModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Future<String> _buyerName(OrderModel order) async {
    final storedOrderName = order.buyerName.trim();
    if (order.buyerId.isEmpty) return storedOrderName;

    final buyerDoc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(order.buyerId)
        .get();
    final buyerData = buyerDoc.data();
    if (buyerData == null) return storedOrderName;

    final directName =
        (buyerData['user_name'] ??
                buyerData['name'] ??
                buyerData['displayName'])
            ?.toString()
            .trim();
    if (directName != null && directName.isNotEmpty) return directName;

    final firstName = buyerData['firstName']?.toString().trim() ?? '';
    final lastName = buyerData['lastName']?.toString().trim() ?? '';
    return '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : storedOrderName;
  }

  Widget _buildOrderCard(OrderModel order) {
    return FutureBuilder<String>(
      future: _buyerName(order),
      builder: (context, snapshot) {
        final buyerName = snapshot.data ?? order.buyerName;
        return _buildOrderCardContent(order, buyerName);
      },
    );
  }

  Widget _buildOrderCardContent(OrderModel order, String buyerName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        onTap: () {
          // Validate order ID before navigation
          if (order.id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order ID is missing'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        leading: order.image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image),
              ),
        title: Text(
          order.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qty: ${order.quantity}'),
            Text(
              'Total: ${Formatter.formatCurrency(order.totalAmount, symbol: order.currency)}',
            ),
            if (order.buyerId.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmerProfileScreen(
                      userId: order.buyerId,
                      currentUserId: widget.sellerId,
                      initialFarmer:
                          buyerName.trim().isEmpty ||
                              buyerName.trim().toLowerCase() == 'unknown buyer'
                          ? null
                          : FarmerModel(
                              id: order.buyerId,
                              name: buyerName.trim(),
                            ),
                    ),
                  ),
                ),
                child: Text(
                  'Buyer: $buyerName',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _statusChip(
                  'Payment: ${order.paymentStatus}',
                  _getPaymentStatusColor(order.paymentStatus),
                ),
                _statusChip(
                  'Delivery: ${_displayDeliveryStatus(order)}',
                  _isCancelled(order)
                      ? Colors.red
                      : _getDeliveryStatusColor(order.deliveryStatus),
                ),
              ],
            ),
          ],
        ),
        trailing: _statusIcon(order.deliveryStatus, order.paymentStatus),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(List<OrderModel> orders) {
    // Calculate analytics data
    final monthlyData = <String, Map<String, double>>{};
    final statusCounts = <String, int>{};
    final paymentMethodCounts = <String, int>{};

    for (final order in orders) {
      // Monthly earnings - count any completed payments
      final month =
          '${order.createdAt.toDate().month}-${order.createdAt.toDate().year}';
      if (_isPaymentReleased(order) && !_isCancelled(order)) {
        final currencyTotals = monthlyData.putIfAbsent(
          month,
          () => <String, double>{},
        );
        currencyTotals[order.currency] =
            (currencyTotals[order.currency] ?? 0) + order.totalAmount;
      }

      // Status counts
      final status = _displayDeliveryStatus(order);
      statusCounts[status] = (statusCounts[status] ?? 0) + order.quantity;
      paymentMethodCounts[order.paymentMethod] =
          (paymentMethodCounts[order.paymentMethod] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...statusCounts.entries.map(
            (entry) => _buildAnalyticsItem(
              entry.key,
              entry.value.toString(),
              _getStatusColor(entry.key),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Payment Methods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...paymentMethodCounts.entries.map(
            (entry) => _buildAnalyticsItem(
              entry.key,
              entry.value.toString(),
              Colors.blue,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Monthly Earnings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...monthlyData.entries.expand(
            (monthEntry) => monthEntry.value.entries.map(
              (currencyEntry) => _buildAnalyticsItem(
                '${monthEntry.key} ${currencyEntry.key}',
                Formatter.formatCurrency(
                  currencyEntry.value,
                  symbol: currencyEntry.key,
                ),
                Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (_normalized(status)) {
      case 'released':
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (_normalized(status)) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (_normalized(status)) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'returned goods':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusIcon(String deliveryStatus, String paymentStatus) {
    final normalizedPaymentStatus = _normalized(paymentStatus);
    if (normalizedPaymentStatus == 'released' ||
        normalizedPaymentStatus == 'paid' ||
        normalizedPaymentStatus == 'completed') {
      return const Icon(Icons.verified, color: Colors.green);
    }

    switch (_normalized(deliveryStatus)) {
      case 'delivered':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'shipped':
        return const Icon(Icons.local_shipping, color: Colors.blue);
      case 'cancelled':
        return const Icon(Icons.assignment_return, color: Colors.red);
      case 'pending':
      case 'preparing':
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      default:
        return const Icon(Icons.inventory_2, color: Colors.grey);
    }
  }

  String _normalized(String value) => value.trim().toLowerCase();

  bool _isPaymentReleased(OrderModel order) {
    final status = _normalized(order.paymentStatus);
    return status == 'released' || status == 'paid' || status == 'completed';
  }

  bool _isCancelled(OrderModel order) {
    return _normalized(order.status) == 'cancelled' ||
        _normalized(order.deliveryStatus) == 'cancelled';
  }

  String _displayDeliveryStatus(OrderModel order) {
    if (_isCancelled(order)) return 'Returned goods';
    final status = _normalized(order.deliveryStatus);
    if (status == 'preparing' || status == 'pending' || status.isEmpty) {
      return 'Pending';
    }
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}
