import 'package:flutter/material.dart';
import 'package:agribased/models/mock_product.dart';
import 'package:agribased/services/mock_cash_handler.dart';

/// A simple test page to trigger mock purchases.
class MockStorePage extends StatelessWidget {
  final String userId;

  const MockStorePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Store')),
      body: ListView.builder(
        itemCount: mockProducts.length,
        itemBuilder: (context, index) {
          final product = mockProducts[index];
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: ElevatedButton(
              child: Text('Buy (${product.price} ZAR)'),
              onPressed: () => MockCashHandler.instance.purchase(
                product,
                userId: userId,
                context: context,
              ),
            ),
          );
        },
      ),
    );
  }
}
