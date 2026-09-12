import 'package:flutter/material.dart';

class FeatureButton extends StatelessWidget {
  final IconData? icon;        // 👈 optional Material icon
  final Widget? customIcon;    // 👈 optional custom widget (e.g. Image.asset)
  final String label;
  final Color color;
  final VoidCallback onTap;

  const FeatureButton({
    this.icon,
    this.customIcon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: customIcon ??
                Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}