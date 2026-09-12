import 'package:flutter/material.dart';
import 'package:agribased/services/marketplace/boost_service.dart';

class BoostProvider extends ChangeNotifier {
  final IBoostService boostService;

  BoostProvider({required this.boostService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  /// Boosts an item for a specified number of days
  Future<bool> purchaseBoost(String itemId, int days) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await boostService.boostItem(itemId, days);
      if (!success) {
        _error = 'Failed to boost item';
      }
      return success;
    } catch (e) {
      _error = 'An error occurred while boosting the item';
      debugPrint('Boost purchase failed for $itemId: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Gets active boosts for an item
  Future<List<Map<String, dynamic>>> getActiveBoosts(String itemId) async {
    _setLoading(true);
    _error = null;

    try {
      return await boostService.getActiveBoosts(itemId);
    } catch (e) {
      _error = 'Failed to load active boosts';
      debugPrint('Error getting active boosts for $itemId: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Cancels an active boost
  Future<bool> cancelBoost(String boostId) async {
    _setLoading(true);
    _error = null;

    try {
      return await boostService.cancelBoost(boostId);
    } catch (e) {
      _error = 'Failed to cancel boost';
      debugPrint('Error cancelling boost $boostId: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
