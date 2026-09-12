import 'package:flutter/material.dart';
import 'package:agribased/widgets/safe_network_image.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'create_item_page.dart';
import 'item_details_page.dart';
import 'fullscreen_image_page.dart';
import 'package:agribased/app/utils/formatters.dart';

class MarketplaceHomePage extends StatefulWidget {
  final MarketplaceService marketplaceService;

  const MarketplaceHomePage({super.key, required this.marketplaceService});

  @override
  State<MarketplaceHomePage> createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  String _searchQuery = '';
  List<MarketplaceItem>? _cachedItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'My Orders',
            onPressed: () => Navigator.pushNamed(context, '/my-orders'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Item',
            onPressed: () async {
              final newItem = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateItemPage(
                    marketplaceService: widget.marketplaceService,
                  ),
                ),
              );
              if (newItem == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item added successfully')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Modern Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by title, description, category, price...',
                  prefixIcon: Icon(Icons.search, color: Colors.green),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase().trim();
                  });
                },
              ),
            ),
          ),

          // 🔹 Product Grid
          Expanded(
            child: StreamBuilder<List<MarketplaceItem>>(
              stream: widget.marketplaceService.streamMarketplaceItems(),
              builder: (context, snapshot) {
                // If waiting but we have cached items, show them immediately
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedItems != null) {
                  return _buildGrid(_cachedItems!);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading items: ${snapshot.error}'),
                  );
                }

                final items = snapshot.data ?? [];

                // Update cache when we receive data
                if (items.isNotEmpty) {
                  _cachedItems = items;
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No items yet'));
                }

                // Filter items by search
                final filteredItems = items.where((item) {
                  final title = item.title.toLowerCase();
                  final description = item.description.toLowerCase();
                  final category = item.category.toLowerCase();
                  final priceStr = item.price.toString();
                  return title.contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      priceStr.contains(_searchQuery);
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text('No items match your search'),
                  );
                }

                return _buildGrid(filteredItems);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<MarketplaceItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // two items per row
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailsPage(
                    item: item,
                    marketplaceService: widget.marketplaceService,
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: item.images.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullscreenImagePage(
                                      images: item.images,
                                      initialIndex: 0,
                                    ),
                                  ),
                                );
                              },
                              child: SafeNetworkImage(
                                imageUrl: item.images.first,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                    ),
                  ),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatter.formatCurrency(
                            item.price.toDouble(),
                            symbol: item.currencySymbol ?? 'ZAR',
                          ),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.status == ItemStatus.sold)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SOLD',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
