import 'package:flutter/material.dart';
import '../../models/marketplace/seller_model.dart';
import 'rating_stars.dart';
import '../user_info_display.dart';

class SellerInfoTile extends StatelessWidget {
  final SellerModel seller;

  const SellerInfoTile({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: UserProfileImage(
        userId: seller.id,
        radius: 24,
        initialImageUrl: seller.profileImage.isNotEmpty && seller.profileImage.startsWith('http')
            ? seller.profileImage
            : '',
      ),
      title: Text(
        seller.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          RatingStars(rating: seller.rating),
          const SizedBox(height: 4),
          if (seller.isVerified)
            const Icon(Icons.verified, color: Colors.blue, size: 16),
        ],
      ),
    );
  }
}
