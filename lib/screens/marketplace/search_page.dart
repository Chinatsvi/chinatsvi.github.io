import 'package:flutter/material.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/app/utils/formatters.dart';

class SearchPage extends StatefulWidget {
  final MarketplaceService marketplaceService;

  const SearchPage({super.key, required this.marketplaceService});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<MarketplaceItem> results = [];
  bool searching = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      // Get all items from the stream and filter them
      final stream = widget.marketplaceService.streamMarketplaceItems();
      final allItems = await stream.first;
      results = allItems
          .where(
            (i) =>
                i.title.toLowerCase().contains(q.toLowerCase()) ||
                i.description.toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    } catch (e) {
      results = [];
    } finally {
      setState(() => searching = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Marketplace'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search items...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _search(v),
            ),
            const SizedBox(height: 12),
            if (searching) const LinearProgressIndicator(),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final it = results[idx];
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
            ),
          ],
        ),
      ),
    );
  }
}
