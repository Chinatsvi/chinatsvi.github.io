import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';

String resolveCartItemCurrency(Map<String, dynamic> data) {
  return Formatter.normalizeCurrencyCode(
    (data['currencySymbol'] ?? data['currency'] ?? data['currencyCode'])
        ?.toString(),
  );
}

Map<String, double> calculateCartTotals(Iterable<Map<String, dynamic>> items) {
  final totals = <String, double>{};

  for (final data in items) {
    final rawPrice = data['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : (rawPrice is String ? double.tryParse(rawPrice) ?? 0.0 : 0.0);
    final rawQuantity = data['quantity'] ?? 1;
    final quantity = rawQuantity is num
        ? rawQuantity.toInt()
        : int.tryParse(rawQuantity.toString()) ?? 1;
    final currency = resolveCartItemCurrency(data);

    totals[currency] = (totals[currency] ?? 0) + price * quantity;
  }

  return totals;
}

class CartService {
  final FirebaseFirestore? _db;

  CartService({FirebaseFirestore? firestore}) : _db = firestore;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  String buildCartItemId(Map<String, dynamic> data) {
    final itemId = data['itemId']?.toString() ?? '';
    final sellerId = data['sellerId']?.toString() ?? '';
    return '$itemId::$sellerId';
  }

  Map<String, dynamic> normalizeCartItemData(
    Map<String, dynamic> data, {
    int? existingQuantity,
  }) {
    final normalizedData = Map<String, dynamic>.from(data);
    final rawPrice = normalizedData['price'];
    if (rawPrice is num) {
      normalizedData['price'] = rawPrice.toDouble();
    } else if (rawPrice is String) {
      normalizedData['price'] = double.tryParse(rawPrice) ?? 0.0;
    } else {
      normalizedData['price'] = 0.0;
    }

    var quantity = 1;
    if (normalizedData['quantity'] is int) {
      quantity = normalizedData['quantity'] as int;
    } else if (normalizedData['quantity'] is num) {
      quantity = (normalizedData['quantity'] as num).toInt();
    }

    if (existingQuantity != null) {
      quantity += existingQuantity;
    }

    normalizedData['quantity'] = quantity;
    normalizedData['totalPrice'] =
        (normalizedData['price'] as num).toDouble() * quantity;

    return normalizedData;
  }

  /// Add an item to the cart for a specific buyer
  Future<void> addToCart(Map<String, dynamic> data, String buyerId) async {
    if (!data.containsKey('itemId')) {
      throw Exception('Item must have an "itemId"');
    }

    final existingCartItemId = buildCartItemId(data);

    final existingDoc = await _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .doc(existingCartItemId)
        .get();

    final existingQuantity = existingDoc.exists
        ? (existingDoc.data()?['quantity'] is num
              ? (existingDoc.data()!['quantity'] as num).toInt()
              : 0)
        : 0;

    final normalizedData = normalizeCartItemData(
      data,
      existingQuantity: existingQuantity,
    );
    normalizedData['buyerId'] = buyerId;

    debugPrint('DEBUG: Adding to cart - Buyer ID: $buyerId');
    debugPrint('DEBUG: Adding to cart - Item data: $normalizedData');

    final saveCartItemId = buildCartItemId(normalizedData);

    await _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .doc(saveCartItemId)
        .set(normalizedData, SetOptions(merge: true));

    debugPrint('DEBUG: Item added to cart successfully');
  }

  /// Remove an item from the cart
  Future<void> removeFromCart(String buyerId, String itemId) async {
    await _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  /// Update the quantity of an item in the cart
  Future<void> updateQuantity(
    String buyerId,
    String itemId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      // Remove item if quantity is zero or less
      await removeFromCart(buyerId, itemId);
      return;
    }

    await _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .doc(itemId)
        .update({'quantity': quantity});
  }

  /// Get the cart items as a stream (real-time updates)
  Stream<QuerySnapshot> getCartItems(String buyerId) {
    return _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .snapshots();
  }

  /// Get cart items once (non-stream)
  Future<List<QueryDocumentSnapshot>> fetchCartItems(String buyerId) async {
    debugPrint(
      'DEBUG: CartService.fetchCartItems called for buyerId: $buyerId',
    );
    final snapshot = await _firestore
        .collection('carts')
        .doc(buyerId)
        .collection('items')
        .get();
    debugPrint(
      'DEBUG: CartService fetched ${snapshot.docs.length} items from Firestore',
    );
    return snapshot.docs;
  }

  /// Clear the entire cart
  Future<void> clearCart(String buyerId) async {
    final items = await fetchCartItems(buyerId);
    final batch = _firestore.batch();

    for (final doc in items) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
