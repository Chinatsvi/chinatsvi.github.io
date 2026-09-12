import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.blue.withOpacity(0.2),
    );
  }
}