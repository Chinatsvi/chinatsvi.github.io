import 'package:flutter/material.dart';
import 'package:agribased/models/marketplace/seller_badge.dart';
import 'package:agribased/services/marketplace/badge_service.dart';

class BadgeProvider extends ChangeNotifier {
  final IBadgeService badgeService;

  BadgeProvider({required this.badgeService});

  final Map<String, SellerBadge> _badges = {};
  Map<String, SellerBadge> get badges => Map.unmodifiable(_badges);

  /// Loads and caches the badge for a specific seller
  Future<void> loadBadge(String sellerId) async {
    try {
      final badgeLevel = await badgeService.computeBadgeForSeller(sellerId);
      if (badgeLevel != null) {
        _badges[sellerId] = SellerBadge(
          sellerId: sellerId,
          totalSales: 0, // This will be updated by the service
          badgeLevel: badgeLevel,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load badge for $sellerId: $e');
      // Optionally set a default badge or rethrow the error
      _badges[sellerId] = SellerBadge(
        sellerId: sellerId,
        totalSales: 0,
        badgeLevel: 'none',
      );
      notifyListeners();
    }
  }

  /// Clears the badge cache for a specific seller
  void clearBadge(String sellerId) {
    _badges.remove(sellerId);
    notifyListeners();
  }

  /// Clears all cached badges
  void clearAllBadges() {
    _badges.clear();
    notifyListeners();
  }
}
