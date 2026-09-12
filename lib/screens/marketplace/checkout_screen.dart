import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/services/marketplace/cart_service.dart';
import 'package:agribased/screens/marketplace/order_waiting_screen.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/models/notification_model.dart';
import 'package:agribased/services/notifications/notification_service.dart';

enum PaymentState { unpaid, paidUnverified }

String resolveCheckoutCurrency(Iterable<dynamic> items) {
  for (final item in items) {
    final data = item is Map<String, dynamic>
        ? item
        : Map<String, dynamic>.from(item);
    final currency =
        (data['currencySymbol'] ?? data['currency'] ?? data['currencyCode'])
            ?.toString();
    if (currency != null && currency.trim().isNotEmpty) {
      return Formatter.normalizeCurrencyCode(currency);
    }
  }
  return 'ZAR';
}

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot>? selectedItems;

  const CheckoutScreen({super.key, this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  User? _user;

  String? _paymentMethod;
  bool _placingOrder = false;

  Future<String> _buyerName() async {
    final buyerId = _user?.uid;
    if (buyerId == null || buyerId.isEmpty) return 'A buyer';
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(buyerId)
        .get();
    final data = doc.data();
    return (data?['user_name'] ?? data?['name'] ?? 'A buyer').toString();
  }

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    debugPrint('DEBUG: Current user in checkout: ${_user?.uid}');
    if (_user == null) {
      debugPrint('DEBUG: No user found in checkout!');
    }
  }

  // ---------------- PER-ITEM PAYMENT METHODS ----------------
  Map<String, Set<String>> _getItemPaymentMethods(
    List<QueryDocumentSnapshot> items,
  ) {
    final Map<String, Set<String>> itemMethods = {};

    for (final doc in items) {
      final data = doc.data() as Map<String, dynamic>;

      // Debug: Print full item data
      debugPrint('DEBUG: Full item data for ${doc.id}: $data');

      final List methods = data['paymentMethods'] ?? [];

      // If no payment methods found for this item, provide defaults
      if (methods.isEmpty) {
        debugPrint(
          'DEBUG: No payment methods for item ${doc.id}, providing defaults. Item title: ${data['title']}',
        );
        // Provide all payment methods as default for old items
        itemMethods[doc.id] = {'card', 'mobile_money', 'cod'};
        debugPrint(
          'DEBUG: Provided default methods for item ${doc.id}: ${itemMethods[doc.id]}',
        );
      } else {
        itemMethods[doc.id] = methods.map((e) => e.toString()).toSet();
        debugPrint(
          'DEBUG: Using existing methods for item ${doc.id}: ${itemMethods[doc.id]}',
        );
      }

      // Debug: Print what methods we're getting
      debugPrint(
        'DEBUG: Item ${doc.id} paymentMethods: ${itemMethods[doc.id]}',
      );
      debugPrint('DEBUG: Item ${doc.id} title: ${data['title']}');
    }

    debugPrint('DEBUG: Final item payment methods: $itemMethods');
    return itemMethods;
  }

  // ---------------- GET SELLER'S PRIMARY PAYMENT METHOD ----------------
  String? _getSellerPrimaryPaymentMethod(List<QueryDocumentSnapshot> items) {
    // Get the first item's payment methods (assuming all items have same seller)
    if (items.isEmpty) return null;

    final firstItem = items.first;
    final data = firstItem.data() as Map<String, dynamic>;
    final List methods = data['paymentMethods'] ?? [];

    if (methods.isEmpty) {
      debugPrint(
        'DEBUG: No seller payment methods found, using default COD for old item',
      );
      return 'cod'; // Default to COD for old items
    }

    // Return the first payment method (seller's primary choice)
    debugPrint('DEBUG: Seller primary payment method: ${methods.first}');
    return methods.first;
  }

  // ---------------- GET ALL AVAILABLE METHODS ----------------
  Set<String> _getAllAvailableMethods(List<QueryDocumentSnapshot> items) {
    final Set<String> allMethods = {};

    for (final doc in items) {
      final data = doc.data() as Map<String, dynamic>;
      final List methods = data['paymentMethods'] ?? [];
      allMethods.addAll(methods.map((e) => e.toString()));
    }

    // If no payment methods found, provide default options
    if (allMethods.isEmpty) {
      debugPrint(
        'DEBUG: No payment methods found in items, providing defaults',
      );
      allMethods.addAll(['card', 'mobile_money', 'cod']);
    }

    debugPrint('DEBUG: All available methods: $allMethods');
    return allMethods;
  }

  // ---------------- PAYMENT TILE ----------------
  Widget _paymentTile({
    required String value,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return Card(
      color: enabled ? null : Colors.grey.shade100,
      child: RadioListTile<String>(
        value: value,
        groupValue: _paymentMethod,
        onChanged: enabled ? (v) => setState(() => _paymentMethod = v) : null,
        title: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        secondary: Icon(icon, color: enabled ? Colors.green : Colors.grey),
      ),
    );
  }

  // ---------------- PAYMENT METHODS UI ----------------
  Widget _buildPaymentMethods(List<QueryDocumentSnapshot> items) {
    final allMethods = _getAllAvailableMethods(items);
    final itemMethods = _getItemPaymentMethods(items);
    final sellerPrimaryMethod = _getSellerPrimaryPaymentMethod(items);

    if (allMethods.isEmpty) {
      return const Text(
        '❌ No payment methods available for these items.',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    // Auto-select seller's primary payment method
    if (sellerPrimaryMethod != null) {
      _paymentMethod = sellerPrimaryMethod;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  sellerPrimaryMethod == 'cod'
                      ? Icons.money
                      : sellerPrimaryMethod == 'card'
                      ? Icons.credit_card
                      : Icons.phone_android,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment: ${_getPaymentMethodLabel(sellerPrimaryMethod)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCompatibleItems(items, itemMethods),
        ],
      );
    }

    // If no seller preference, show all available methods
    _paymentMethod ??= allMethods.first;
    debugPrint('DEBUG: Auto-selecting payment method: $_paymentMethod');

    return Column(
      children: [
        _paymentTile(
          value: 'card',
          label: 'Pay with Card',
          icon: Icons.credit_card,
          enabled: allMethods.contains('card'),
        ),
        _paymentTile(
          value: 'mobile_money',
          label: 'Mobile Money',
          icon: Icons.phone_android,
          enabled: allMethods.contains('mobile_money'),
        ),
        _paymentTile(
          value: 'cod',
          label: 'Cash on Delivery',
          icon: Icons.money,
          enabled: allMethods.contains('cod'),
        ),
        const SizedBox(height: 16),
        // Show which items support the selected payment method
        _buildCompatibleItems(items, itemMethods),
      ],
    );
  }

  // ---------------- GET PAYMENT METHOD LABEL ----------------
  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'Card Payment';
      case 'mobile_money':
        return 'Mobile Money';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return method;
    }
  }

  // ---------------- SHOW COMPATIBLE ITEMS ----------------
  Widget _buildCompatibleItems(
    List<QueryDocumentSnapshot> items,
    Map<String, Set<String>> itemMethods,
  ) {
    if (_paymentMethod == null) return const SizedBox.shrink();

    final compatibleItems = <QueryDocumentSnapshot>[];
    final incompatibleItems = <QueryDocumentSnapshot>[];

    for (final item in items) {
      final methods = itemMethods[item.id] ?? <String>{};
      if (methods.contains(_paymentMethod)) {
        compatibleItems.add(item);
      } else {
        incompatibleItems.add(item);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compatibleItems.isNotEmpty) ...[
          Text(
            '✅ Items compatible with $_paymentMethod:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          ...compatibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• ${item['title'] ?? 'Unknown Item'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
        if (incompatibleItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '❌ Items NOT compatible with $_paymentMethod:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          ...incompatibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• ${item['title'] ?? 'Unknown Item'}',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 Tip: Remove incompatible items or choose a different payment method to checkout all items together.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- CREATE PER-ITEM ORDERS ----------------
  Future<void> _createOrders(List<QueryDocumentSnapshot> items) async {
    final batch = FirebaseFirestore.instance.batch();
    final ordersRef = FirebaseFirestore.instance.collection('orders');
    final marketplaceRef = FirebaseFirestore.instance.collection(
      'Marketplace',
    ); // Fixed: uppercase M

    String? lastOrderId;
    final sellerIds = <String>{};
    final buyerName = await _buyerName();

    for (final doc in items) {
      final data = doc.data() as Map<String, dynamic>;
      final orderRef = ordersRef.doc();
      lastOrderId = orderRef.id;
      final sellerId = (data['sellerId'] ?? '').toString();
      if (sellerId.isNotEmpty) sellerIds.add(sellerId);

      batch.set(orderRef, {
        'orderId': orderRef.id,
        'buyerId': _user?.uid ?? '',
        'buyerName': buyerName,
        'sellerId': sellerId,
        'itemId': data['itemId'],
        'title': data['title'],
        'image': data['image'],
        'price': data['price'],
        'quantity': data['quantity'],
        'totalAmount': (data['price'] * data['quantity']).toDouble(),
        'currency': resolveCartItemCurrency(data),
        'paymentMethod': _paymentMethod,
        'paymentDetails': data['paymentDetails'],
        'paymentStatus': _paymentMethod == 'cod'
            ? PaymentState.unpaid.name
            : PaymentState.paidUnverified.name,
        'deliveryStatus': 'PENDING',
        'sellerPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update marketplace item status to sold - check if document exists first
      final itemRef = marketplaceRef.doc(data['itemId']);
      final itemDoc = await itemRef.get();

      if (!itemDoc.exists) {
        throw Exception('This item is no longer available.');
      }

      final itemData = itemDoc.data() ?? {};
      final currentStatus = (itemData['status'] ?? 'active')
          .toString()
          .trim()
          .toLowerCase();
      if (currentStatus != 'active') {
        throw Exception('This item has already been sold or removed.');
      }

      final isDiscreet =
          itemData['isDiscreet'] == true || itemData['is_discreet'] == true;
      final nextStatus = MarketplaceItem.resolveStatusAfterPurchase(
        isDiscreet: isDiscreet,
      );

      final updateData = <String, dynamic>{
        'status': nextStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (nextStatus == ItemStatus.sold) {
        updateData.addAll({
          'soldAt': FieldValue.serverTimestamp(),
          'soldTo': _user?.uid ?? '',
        });
      }

      batch.update(itemRef, updateData);

      batch.delete(doc.reference);
    }

    await batch.commit();

    await Future.wait(
      sellerIds.map(
        (sellerId) => NotificationService().sendNotification(
          userId: sellerId,
          type: NotificationType.orderPlaced,
          title: 'New order received',
          body: '$buyerName placed an order. Organise delivery with the buyer.',
          additionalData: {
            'kind': 'marketplaceOrder',
            'buyerId': _user?.uid ?? '',
            'buyerName': buyerName,
          },
        ),
      ),
    );

    if (!mounted || lastOrderId == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderWaitingScreen(orderId: lastOrderId!),
      ),
    );
  }

  // ---------------- PLACE ORDER ----------------
  Future<void> _placeOrder(List<QueryDocumentSnapshot> items) async {
    try {
      final itemMethods = _getItemPaymentMethods(items);
      final allMethods = _getAllAvailableMethods(items);

      debugPrint('DEBUG: Selected payment method: $_paymentMethod');
      debugPrint('DEBUG: All available methods: $allMethods');

      if (_paymentMethod == null || _paymentMethod!.isEmpty) {
        debugPrint('DEBUG: No payment method selected!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Please select a payment method')),
          );
        }
        return;
      }

      if (!allMethods.contains(_paymentMethod)) {
        debugPrint('DEBUG: Payment method not available!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Selected payment method not available'),
            ),
          );
        }
        return;
      }

      // Filter items that support the selected payment method
      final compatibleItems = items.where((item) {
        final methods = itemMethods[item.id] ?? <String>{};
        return methods.contains(_paymentMethod);
      }).toList();

      if (compatibleItems.isEmpty) {
        debugPrint('DEBUG: No items compatible with selected payment method!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No items support this payment method'),
            ),
          );
        }
        return;
      }

      if (compatibleItems.length < items.length) {
        // Some items are incompatible, ask user to confirm
        final shouldProceed = await _showIncompatibleItemsDialog(
          items.length,
          compatibleItems.length,
        );
        if (!shouldProceed) return;
      }

      setState(() => _placingOrder = true);

      bool success = true;

      if (_paymentMethod != 'cod') {
        debugPrint(
          'DEBUG: Processing non-COD payment - Paystack removed, treating as COD',
        );
        // Paystack removed - treat all orders as COD for now
        success = true;
      } else {
        debugPrint('DEBUG: Processing COD order');
      }

      if (!success) {
        debugPrint('DEBUG: Payment failed, showing error');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('❌ Payment failed')));
          setState(() => _placingOrder = false);
        }
        return;
      }

      debugPrint('DEBUG: Payment successful, creating orders');
      await _createOrders(compatibleItems);

      if (mounted) setState(() => _placingOrder = false);
    } catch (e) {
      debugPrint('DEBUG: Error in _placeOrder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Order failed: ${e.toString()}')),
        );
        setState(() => _placingOrder = false);
      }
    }
  }

  // ---------------- SHOW INCOMPATIBLE ITEMS DIALOG ----------------
  Future<bool> _showIncompatibleItemsDialog(
    int totalItems,
    int compatibleItems,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Some Items Incompatible'),
          content: Text(
            'Only $compatibleItems out of $totalItems items support your selected payment method.\n\n'
            'Do you want to proceed with only the compatible items?\n\n'
            'The incompatible items will remain in your cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.green[700],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please log in to proceed with checkout'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedItems != null ? 'Checkout Selected Items' : 'Checkout',
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _getItemsForCheckout(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('🛒 No items to checkout'));
            }

            final totals = calculateCartTotals(
              items.map((doc) => doc.data() as Map<String, dynamic>),
            );

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text(
                        widget.selectedItems != null
                            ? 'Payment Method (${items.length} items selected)'
                            : 'Payment Method',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentMethods(items),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: totals.entries
                            .map(
                              (entry) => Text(
                                'Total: ${Formatter.formatCurrency(entry.value, symbol: entry.key)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      ElevatedButton(
                        onPressed: _placingOrder
                            ? null
                            : () => _placeOrder(items),
                        child: _placingOrder
                            ? const CircularProgressIndicator()
                            : Text(
                                _paymentMethod == 'cod'
                                    ? 'Confirm Order'
                                    : 'Confirm & Pay',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------- GET ITEMS FOR CHECKOUT ----------------
  Future<List<QueryDocumentSnapshot>> _getItemsForCheckout() async {
    debugPrint('DEBUG: _getItemsForCheckout called');
    debugPrint(
      'DEBUG: widget.selectedItems is null: ${widget.selectedItems == null}',
    );

    if (widget.selectedItems != null) {
      // Use pre-selected items from cart
      debugPrint(
        'DEBUG: Using selectedItems: ${widget.selectedItems!.length} items',
      );
      return widget.selectedItems!;
    } else {
      // Get all items from cart
      debugPrint('DEBUG: Fetching all cart items for user: ${_user?.uid}');
      if (_user?.uid == null) {
        debugPrint('DEBUG: No user UID available, returning empty list');
        return [];
      }
      final snapshot = await _cartService.fetchCartItems(_user!.uid);
      debugPrint('DEBUG: Fetched ${snapshot.length} items from cart');
      return snapshot;
    }
  }
}
