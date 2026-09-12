import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agribased/services/marketplace/rating_service.dart';
import 'package:agribased/models/marketplace/seller_rating.dart';

class RatingProvider extends ChangeNotifier {
  final RatingService ratingService;
  StreamSubscription<List<SellerRating>>? _ratingsSubscription;
  String? _currentSellerId;

  RatingProvider({required this.ratingService});

  List<SellerRating> _ratings = [];
  List<SellerRating> get ratings => _ratings;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Get the average rating for the current seller
  double get averageRating {
    if (_ratings.isEmpty) return 0.0;
    return _ratings.map((r) => r.stars).reduce((a, b) => a + b) /
        _ratings.length;
  }

  /// Get the total number of ratings
  int get ratingCount => _ratings.length;

  /// Start listening to rating updates for a specific seller
  void startListeningToRatings(String sellerId) {
    if (_currentSellerId == sellerId) {
      return; // Already listening to this seller
    }

    _currentSellerId = sellerId;
    _ratingsSubscription?.cancel();
    _ratingsSubscription = ratingService
        .streamSellerRatings(sellerId)
        .listen(
          (ratings) {
            _ratings = ratings;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load ratings: $error';
            _ratings = [];
            notifyListeners();
          },
        );
  }

  /// Stop listening to rating updates
  void stopListening() {
    _ratingsSubscription?.cancel();
    _ratingsSubscription = null;
    _currentSellerId = null;
  }

  /// Get the current user's rating for the current seller, if it exists
  Future<SellerRating?> getCurrentUserRating(String userId) async {
    if (_currentSellerId == null) return null;
    try {
      return await ratingService.getCurrentUserRating(
        _currentSellerId!,
        userId,
      );
    } catch (e) {
      _error = 'Failed to load your rating';
      notifyListeners();
      return null;
    }
  }

  /// Add a new rating or update an existing one
  Future<bool> submitRating(SellerRating rating) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final existingRating = await getCurrentUserRating(rating.buyerId);
      if (existingRating != null) {
        // Update existing rating
        final updatedRating = SellerRating(
          id: existingRating.id,
          sellerId: rating.sellerId,
          buyerId: rating.buyerId,
          stars: rating.stars,
          comment: rating.comment,
          createdAt: existingRating.createdAt,
        );
        await ratingService.updateRating(updatedRating);
      } else {
        // Add new rating
        await ratingService.addRating(rating);
      }
      return true;
    } catch (e) {
      _error = 'Failed to submit rating: $e';
      debugPrint(_error);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete a rating
  Future<bool> deleteRating(String ratingId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await ratingService.deleteRating(ratingId);
      return true;
    } catch (e) {
      _error = 'Failed to delete rating: $e';
      debugPrint(_error);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ratingsSubscription?.cancel();
    super.dispose();
  }
}
