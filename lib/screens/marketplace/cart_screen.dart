import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agribased/services/marketplace/cart_service.dart';
import 'package:agribased/app/routes/app_routes.dart';
import 'package:agribased/app/utils/formatters.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cartService = CartService();
  final User user = FirebaseAuth.instance.currentUser!;

  // Track selected items for individual checkout
  final Set<String> _selectedItems = {};
  bool _isSelectMode = false;

  @override
  Widget build(BuildContext context) {
    // Debug: Check if user is logged in
    debugPrint('DEBUG: Current user UID: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text(
          _isSelectMode ? 'Select Items (${_selectedItems.length})' : 'My Cart',
        ),
        actions: [
          if (_isSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart_checkout),
              onPressed: _selectedItems.isNotEmpty ? _checkoutSelected : null,
              tooltip: 'Checkout Selected',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectMode,
              tooltip: 'Cancel',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _enterSelectMode,
              tooltip: 'Select Items',
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartService.getCartItems(user.uid),
        builder: (context, snapshot) {
          debugPrint(
            'DEBUG: Cart snapshot connection state: ${snapshot.connectionState}',
          );
          debugPrint('DEBUG: Cart has data: ${snapshot.hasData}');
          debugPrint('DEBUG: Cart has error: ${snapshot.error}');

          if (snapshot.hasData) {
            debugPrint('DEBUG: Cart docs count: ${snapshot.data!.docs.length}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('🛒 Your cart is empty'));
          }

          final items = snapshot.data!.docs;
          final itemData = items
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          final totals = calculateCartTotals(itemData);
          final selectedTotals = calculateCartTotals(
            items
                .where((doc) => _selectedItems.contains(doc.id))
                .map((doc) => doc.data() as Map<String, dynamic>),
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = _selectedItems.contains(doc.id);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: _isSelectMode
                          ? null
                          : () => _confirmRemoveItem(doc.id, data),
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        color: isSelected ? Colors.green.shade50 : null,
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSelectMode)
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedItems.add(doc.id);
                                      } else {
                                        _selectedItems.remove(doc.id);
                                      }
                                    });
                                  },
                                ),
                              Image.network(
                                data['image'],
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.image),
                              ),
                            ],
                          ),
                          title: Text(data['title']),
                          subtitle: Text(
                            'Qty: ${data['quantity']}  •  ${Formatter.formatCurrency((data['price'] ?? 0).toDouble(), symbol: data['currencySymbol'] ?? data['currency'] ?? data['currencyCode'])}',
                          ),
                          trailing: _isSelectMode
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.shopping_cart_checkout,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _checkoutSingle(doc),
                                  tooltip: 'Checkout This Item',
                                ),
                          onTap: _isSelectMode
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedItems.remove(doc.id);
                                    } else {
                                      _selectedItems.add(doc.id);
                                    }
                                  });
                                }
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...totals.entries.map(
                          (entry) => Text(
                            'Total: ${Formatter.formatCurrency(entry.value, symbol: entry.key)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedItems.isNotEmpty)
                          ...selectedTotals.entries.map(
                            (entry) => Text(
                              'Selected: ${Formatter.formatCurrency(entry.value, symbol: entry.key)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_isSelectMode)
                      ElevatedButton.icon(
                        onPressed: _selectedItems.isNotEmpty
                            ? _checkoutSelected
                            : null,
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: Text('Checkout (${_selectedItems.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.checkout);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Checkout All'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedItems.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelectAll() async {
    final allItems = await cartService.fetchCartItems(user.uid);

    setState(() {
      if (_selectedItems.length == allItems.length) {
        // If all items are selected, deselect all
        _selectedItems.clear();
      } else {
        // Select all items
        _selectedItems.clear();
        for (final doc in allItems) {
          _selectedItems.add(doc.id);
        }
      }
    });
  }

  Future<void> _confirmRemoveItem(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove ${data['title'] ?? 'this item'} from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    final removerContext = context;
    await cartService.removeFromCart(user.uid, docId);
    if (!mounted) return;
    if (!removerContext.mounted) return;
    ScaffoldMessenger.of(
      removerContext,
    ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
  }

  void _checkoutSingle(QueryDocumentSnapshot doc) {
    Navigator.pushNamed(
      context,
      AppRoutes.checkout,
      arguments: {
        'selectedItems': [doc],
      },
    );
  }

  void _checkoutSelected() async {
    if (_selectedItems.isEmpty) return;

    // Get the selected items from the current stream
    final allItems = await cartService.fetchCartItems(user.uid);
    final selectedDocs = allItems
        .where((doc) => _selectedItems.contains(doc.id))
        .toList();

    debugPrint('DEBUG: Selected items for checkout: ${selectedDocs.length}');
    for (final doc in selectedDocs) {
      debugPrint('DEBUG: Selected item: ${doc.id} - ${doc['title']}');
    }

    if (!mounted) return;

    final checkoutContext = context;
    if (!checkoutContext.mounted) return;

    Navigator.pushNamed(
      checkoutContext,
      AppRoutes.checkout,
      arguments: {'selectedItems': selectedDocs},
    );
  }
}
