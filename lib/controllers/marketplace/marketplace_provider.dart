import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/services/moderation_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceService marketplaceService;

  MarketplaceProvider({required this.marketplaceService});

  List<MarketplaceItem> _items = [];
  List<MarketplaceItem> get items => _items;

  bool _loading = false;
  bool get loading => _loading;

  /// Returns a stream of all marketplace items
  Stream<List<MarketplaceItem>> streamMarketplaceItems() {
    return marketplaceService.streamMarketplaceItems().asyncMap((items) async {
      // Apply moderation filtering
      final filteredItems = await _filterModeratedItems(items);
      // Apply boost-aware ranking
      return _rankMarketplaceItems(filteredItems);
    })..listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  /// Rank marketplace items with boost priority
  List<MarketplaceItem> _rankMarketplaceItems(List<MarketplaceItem> items) {
    final now = DateTime.now();

    // Separate boosted and non-boosted items
    final boostedItems = items.where((item) {
      return item.isBoosted &&
          item.boostExpiresAt != null &&
          item.boostExpiresAt!.isAfter(now);
    }).toList();

    final nonBoostedItems = items.where((item) {
      return !(item.isBoosted &&
          item.boostExpiresAt != null &&
          item.boostExpiresAt!.isAfter(now));
    }).toList();

    // Sort boosted items by boost expiry (newest boosts first)
    boostedItems.sort((a, b) {
      final aExpiry = a.boostExpiresAt ?? DateTime.now();
      final bExpiry = b.boostExpiresAt ?? DateTime.now();
      return aExpiry.compareTo(bExpiry);
    });

    // Sort non-boosted items by creation time (newest first)
    nonBoostedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Combine: boosted items first, then non-boosted items
    return [...boostedItems, ...nonBoostedItems];
  }

  /// Returns a stream of marketplace items for a specific user
  Stream<List<MarketplaceItem>> streamMarketplaceItemsByUser(String userId) {
    return marketplaceService.streamMarketplaceItemsByUser(userId)
      ..listen((userItems) {
        // Update local items list with user's items
        for (var item in userItems) {
          final index = _items.indexWhere((e) => e.id == item.id);
          if (index != -1) {
            _items[index] = item;
          } else {
            _items.add(item);
          }
        }
        notifyListeners();
      });
  }

  /// Add a new marketplace item
  Future<void> addItem(MarketplaceItem item) async {
    try {
      _loading = true;
      notifyListeners();

      await marketplaceService.createItem(item);
      // Background moderation is automatically initiated by the service
    } catch (e) {
      debugPrint('Failed to add item: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update an existing marketplace item
  Future<void> updateItem(MarketplaceItem item) async {
    try {
      _loading = true;
      notifyListeners();
      await marketplaceService.updateItem(item);
      // No need to manually update _items as the stream will update it
    } catch (e) {
      debugPrint('Failed to update item: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete a marketplace item
  Future<void> deleteItem(String id) async {
    try {
      _loading = true;
      notifyListeners();
      await marketplaceService.deleteItem(id);
      // No need to manually remove from _items as the stream will update it
    } catch (e) {
      debugPrint('Failed to delete item: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Filter out marketplace items that are moderated (banned users or violating content)
  Future<List<MarketplaceItem>> _filterModeratedItems(
    List<MarketplaceItem> items,
  ) async {
    final moderatedItems = <MarketplaceItem>[];

    for (final item in items) {
      // Check if user is banned
      final isBanned = await ModerationService.isUserBanned(item.sellerId);
      if (isBanned) {
        continue;
      }

      // Check if item has active moderation reports (pending status)
      final hasActiveReports = await _hasActiveReports(item.id);
      if (hasActiveReports) {
        continue;
      }

      moderatedItems.add(item);
    }

    return moderatedItems;
  }

  /// Check if item has active moderation reports
  Future<bool> _hasActiveReports(String itemId) async {
    try {
      final reports = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reportedPostId', isEqualTo: itemId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return reports.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
