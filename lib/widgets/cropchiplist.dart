import 'package:flutter/material.dart';

class CropListWidget extends StatelessWidget {
  final List<String> crops;

  const CropListWidget({
    super.key,
    required this.crops,
  });

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Crops: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: crops.map((crop) {
                return Chip(
                  label: Text(crop),
                  backgroundColor: Colors.green[100],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}