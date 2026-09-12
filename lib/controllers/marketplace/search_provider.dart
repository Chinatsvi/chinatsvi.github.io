import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';

class SearchProvider extends ChangeNotifier {
  final MarketplaceService marketplaceService;
  Timer? _debounce;
  StreamSubscription<List<MarketplaceItem>>? _itemsSubscription;

  SearchProvider({required this.marketplaceService});

  List<MarketplaceItem> _results = [];
  List<MarketplaceItem> get results => _results;

  bool _searching = false;
  bool get searching => _searching;

  String? _error;
  String? get error => _error;

  /// Initialize the search provider by listening to marketplace items
  void initialize() {
    _itemsSubscription?.cancel();
    _itemsSubscription = marketplaceService.streamMarketplaceItems().listen(
      (items) {
        _results = items;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load marketplace items: $error';
        _results = [];
        notifyListeners();
      },
    );
  }

  /// Search marketplace items with debounce
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  /// Perform the actual search
  void _performSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _searching = true;
    _error = null;
    notifyListeners();

    try {
      _itemsSubscription?.onData((items) {
        _results = items.where((item) {
          // Search in title, description, and category
          return item.title.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q);
        }).toList();
        _searching = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Search failed: $e';
      _searching = false;
      _results = [];
      notifyListeners();
    }
  }

  /// Clear search results
  void clearResults() {
    _results = [];
    _searching = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
