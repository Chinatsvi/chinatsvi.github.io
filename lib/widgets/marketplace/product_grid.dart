// product_grid.dart
import 'package:flutter/material.dart';
import 'package:agribased/models/product.dart';
import 'package:agribased/widgets/marketplace/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onTap;
  final int crossAxisCount;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No items found', style: TextStyle(fontSize: 16)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) =>
          ProductCard(product: products[i], onTap: () => onTap(products[i])),
    );
  }
}
