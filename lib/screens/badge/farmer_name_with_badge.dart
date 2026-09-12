import 'package:flutter/material.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'verified_badge.dart';

class FarmerNameWithBadge extends StatelessWidget {
  final FarmerModel farmer;

  const FarmerNameWithBadge({required this.farmer, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(farmer.name, style: const TextStyle(fontSize: 16)),
        if (farmer.showTick) ...[
          const SizedBox(width: 4),
          const VerifiedBadge(size: 18),
        ],
      ],
    );
  }
}