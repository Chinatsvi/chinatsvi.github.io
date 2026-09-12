import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/app/utils/formatters.dart';

class CategoryPage extends StatefulWidget {
  final String category;
  final MarketplaceService marketplaceService;

  const CategoryPage({
    super.key,
    required this.category,
    required this.marketplaceService,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<MarketplaceItem> items = [];
  bool loading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => loading = true);
    _subscription?.cancel();
    _subscription = widget.marketplaceService.streamMarketplaceItems().listen(
      (allItems) {
        if (mounted) {
          setState(() {
            items = allItems
                .where(
                  (i) =>
                      i.category.toLowerCase() == widget.category.toLowerCase(),
                )
                .toList();
            loading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            items = [];
            loading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.green[700],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('No items in this category'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final it = items[index];
                return ListTile(
                  leading: it.images.isNotEmpty
                      ? Image.network(
                          it.images.first,
                          width: 56,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                  title: Text(it.title),
                  subtitle: Text(
                    Formatter.formatCurrency(
                      it.price.toDouble(),
                      symbol: it.currencySymbol ?? 'ZAR',
                    ),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/marketplace/item',
                    arguments: it,
                  ),
                );
              },
            ),
    );
  }
}
