// marketplace_service.dart
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/image_upload_service.dart';

abstract class MarketplaceService {
  String get currentUserId;
  IImageUploadService get imageUploadService;
  
  Future<void> createItem(MarketplaceItem item);
  Future<void> updateItem(MarketplaceItem item);
  Future<void> deleteItem(String itemId);
  
  /// Stream all marketplace items (real-time, online & offline)
  Stream<List<MarketplaceItem>> streamMarketplaceItems();
  
  /// Stream items by specific user
  Stream<List<MarketplaceItem>> streamMarketplaceItemsByUser(String userId);
}