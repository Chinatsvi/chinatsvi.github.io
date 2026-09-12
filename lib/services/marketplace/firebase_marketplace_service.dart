import 'dart:async';
import 'dart:developer' as developer;
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/image_upload_service.dart';
import 'package:agribased/services/smart_moderation_service.dart';
import 'marketplace_service.dart';

class FirebaseMarketplaceService implements MarketplaceService {
  static final FirebaseMarketplaceService instance = FirebaseMarketplaceService._internal();
  final FirestoreService _firestore = FirestoreService();
  final IImageUploadService _imageUploadService = ImageUploadService(); // ✅ concrete implementation

  FirebaseMarketplaceService._internal();

  @override
  String get currentUserId => _firestore.currentUserId;

  @override
  IImageUploadService get imageUploadService => _imageUploadService;

  @override
  Future<void> createItem(MarketplaceItem item) async {
    await _firestore.createMarketplaceItem(item);
    unawaited(_runBackgroundMarketplaceModeration(item));
  }

  @override
  Future<void> updateItem(MarketplaceItem item) async {
    await _firestore.updateMarketplaceItem(item);
    unawaited(_runBackgroundMarketplaceModeration(item));
  }

  Future<void> _runBackgroundMarketplaceModeration(MarketplaceItem item) async {
    try {
      developer.log(
        '🔍 Running background AI moderation for marketplace listing ${item.id}',
        name: 'MarketplaceModeration',
      );

      final content = 'Title: ${item.title}\nDescription: ${item.description}\nCategory: ${item.category}';
      await SmartModerationService.moderateContent(
        content: content,
        postId: item.id,
        userId: item.sellerId,
        userName: item.sellerName,
        contentType: 'marketplace',
        mediaUrls: item.images,
      );
    } catch (e) {
      developer.log(
        '❌ Background marketplace moderation error for ${item.id}: $e',
        name: 'MarketplaceModeration',
      );
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _firestore.deleteMarketplaceItem(itemId);
  }

  @override
  Stream<List<MarketplaceItem>> streamMarketplaceItems() {
    return _firestore.streamMarketplaceItems();
  }

  @override
  Stream<List<MarketplaceItem>> streamMarketplaceItemsByUser(String userId) {
    return _firestore.streamMarketplaceItemsByUser(userId);
  }
}