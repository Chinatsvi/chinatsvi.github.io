import 'package:flutter/material.dart';

class SellerBadgeWidget extends StatelessWidget {
  final String badge;

  const SellerBadgeWidget({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Colors.blue;

    if (badge == "Super Seller") badgeColor = Colors.purple;
    if (badge == "Trusted Seller") badgeColor = Colors.green;
    if (badge == "New Seller") badgeColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        badge,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}