import 'package:flutter/material.dart';
import '../../models/marketplace/seller_rating.dart';
import 'rating_stars.dart';

class ReviewTile extends StatelessWidget {
  final SellerRating review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingStars(rating: review.stars.toDouble(), size: 16),
            const SizedBox(height: 6),
            Text(review.comment, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              "- ${review.buyerId}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
