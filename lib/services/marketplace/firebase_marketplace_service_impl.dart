import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/services/image_upload_service.dart';

class FirebaseMarketplaceService implements MarketplaceService {
  FirebaseMarketplaceService._internal();
  static final FirebaseMarketplaceService _instance =
      FirebaseMarketplaceService._internal();
  static FirebaseMarketplaceService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  IImageUploadService get imageUploadService => ImageUploadService();

  @override
  Future<void> createItem(MarketplaceItem item) async {
    await _firestore.collection('Marketplace').doc(item.id).set(item.toMap());
  }

  @override
  Future<void> updateItem(MarketplaceItem item) async {
    await _firestore
        .collection('Marketplace')
        .doc(item.id)
        .update(item.toMap());
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('Marketplace').doc(itemId).delete();
  }

  /// Stream all marketplace items (real-time, online & offline)
  @override
  Stream<List<MarketplaceItem>> streamMarketplaceItems() {
    return _firestore
        .collection('Marketplace')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketplaceItem.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream items by specific user
  @override
  Stream<List<MarketplaceItem>> streamMarketplaceItemsByUser(String userId) {
    return _firestore
        .collection('Marketplace')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketplaceItem.fromFirestore(doc))
              .toList(),
        );
  }
}
