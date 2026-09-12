import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({this.size = 16, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/verification_tick.png',
      width: size,
      height: size,
    );
  }
}