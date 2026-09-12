import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/marketplace/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Place new order
  Future<void> placeOrder(OrderModel order) async {
    await _db.collection('orders').add(order.toMap());
  }

  /// Buyer orders raw stream
  Stream<QuerySnapshot<Map<String, dynamic>>> buyerOrders(String buyerId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots();
  }

  /// Seller orders raw stream
  Stream<QuerySnapshot<Map<String, dynamic>>> sellerOrders(String sellerId) {
    return _db
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();
  }

  /// Stream buyer orders, automatically filtering out orders where seller or buyer doc is missing in Firestore
  Stream<List<OrderModel>> streamValidBuyerOrders(String buyerId) {
    return _db
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();

      return await filterDeliverableOrders(orders, checkSeller: true, checkBuyer: true);
    });
  }

  /// Stream seller orders, automatically filtering out orders where buyer doc is missing in Firestore (nowhere to deliver)
  Stream<List<OrderModel>> streamValidSellerOrders(String sellerId) {
    return _db
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();

      return await filterDeliverableOrders(orders, checkSeller: false, checkBuyer: true);
    });
  }

  /// Filter out orders whose associated Firestore documents (buyer / seller / marketplace item) no longer exist.
  /// This prevents ghost / orphaned orders from remaining stuck in "pending" when there is nowhere to deliver.
  Future<List<OrderModel>> filterDeliverableOrders(
    List<OrderModel> orders, {
    bool checkBuyer = true,
    bool checkSeller = false,
  }) async {
    if (orders.isEmpty) return [];

    final Set<String> validBuyerIds = {};
    final Set<String> validSellerIds = {};

    final buyerIds = orders
        .map((o) => o.buyerId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final sellerIds = orders
        .map((o) => o.sellerId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    // Verify Buyer Documents exist in Firestore
    if (checkBuyer && buyerIds.isNotEmpty) {
      await Future.wait(
        buyerIds.map((bId) async {
          try {
            final doc = await _db.collection('farmers').doc(bId).get();
            if (doc.exists) {
              validBuyerIds.add(bId);
            }
          } catch (e) {
            developer.log('Error checking buyer doc $bId: $e', name: 'OrderService');
          }
        }),
      );
    }

    // Verify Seller Documents exist in Firestore
    if (checkSeller && sellerIds.isNotEmpty) {
      await Future.wait(
        sellerIds.map((sId) async {
          try {
            final doc = await _db.collection('farmers').doc(sId).get();
            if (doc.exists) {
              validSellerIds.add(sId);
            }
          } catch (e) {
            developer.log('Error checking seller doc $sId: $e', name: 'OrderService');
          }
        }),
      );
    }

    return orders.where((order) {
      // 1. Buyer check
      if (checkBuyer) {
        final bId = order.buyerId.trim();
        if (bId.isEmpty || !validBuyerIds.contains(bId)) {
          return false; // Nowhere to be delivered because buyer profile doesn't exist
        }
      }

      // 2. Seller check
      if (checkSeller) {
        final sId = order.sellerId.trim();
        if (sId.isEmpty || !validSellerIds.contains(sId)) {
          return false; // No seller profile exists to deliver the order
        }
      }

      return true;
    }).toList();
  }

  /// Update delivery status
  Future<void> updateDeliveryStatus(
    String orderId,
    String deliveryStatus,
  ) async {
    await _db.collection('orders').doc(orderId).update({
      'deliveryStatus': deliveryStatus,
    });
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'deliveryStatus': 'CANCELLED',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update delivery status (alias for updateDeliveryStatus for backward compatibility)
  Future<void> updateDelivery(String orderId, String deliveryStatus) async {
    return updateDeliveryStatus(orderId, deliveryStatus);
  }
}
