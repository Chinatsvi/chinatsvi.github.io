// lib/widgets/animal/labeled_value.dart
import 'package:flutter/material.dart';

class LabeledValue extends StatelessWidget {
  final String label;
  final String value;

  const LabeledValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}