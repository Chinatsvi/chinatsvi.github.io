import 'package:agribased/models/marketplace/seller_rating.dart';

/// Interface for handling seller ratings in the marketplace
abstract class RatingService {
  /// Get all ratings for a specific seller
  Future<List<SellerRating>> getRatingsForSeller(String sellerId);

  /// Add a new rating for a seller
  Future<void> addRating(SellerRating rating);

  /// Update an existing rating
  Future<void> updateRating(SellerRating rating);

  /// Delete a rating
  Future<void> deleteRating(String ratingId);

  /// Stream of ratings for a specific seller
  Stream<List<SellerRating>> streamSellerRatings(String sellerId);

  /// Get the current user's rating for a specific seller, if it exists
  Future<SellerRating?> getCurrentUserRating(String sellerId, String userId);
}
