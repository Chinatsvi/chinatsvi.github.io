// lib/screens/poultry/poultry_exit_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/utils/exit_validation.dart';

class PoultryExitScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryExitScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryExitScreen> createState() => _PoultryExitScreenState();
}

class _PoultryExitScreenState extends State<PoultryExitScreen> {
  late Future<List<PoultryExitRecord>> _future;
  int _currentBatchCount = 0; // Track the current batch count

  @override
  void initState() {
    super.initState();
    _load();
    _loadBatchCount(); // Load the current batch count
  }

  void _load() {
    _future = widget.repository.getExitRecords(widget.animal.id);
  }

  Future<void> _loadBatchCount() async {
    final batch = await widget.repository.getPoultryBatch(widget.animal.id);
    if (batch != null && mounted) {
      setState(() {
        _currentBatchCount = batch.currentCount;
      });
    }
  }

  /// Add a new exit record
  Future<void> _addExitRecord() async {
    final quantityCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final incomeCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    // Fetch the current batch count to use in validation
    final currentBatch = await widget.repository.getPoultryBatch(widget.animal.id);
    final availableCount = currentBatch?.currentCount ?? _currentBatchCount;

    if (!mounted) return; // Check if widget is still mounted

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Poultry Exit Record'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Available: $availableCount poultry'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) {
                    return ExitValidation.validateQuantity(
                      value,
                      availableCount,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (Sold, Slaughtered, Culled)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: incomeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Income (optional)',
                    prefixText: '${Formatter.currencySymbol} ',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final quantity = int.tryParse(quantityCtrl.text.trim()) ?? 0;
              if (quantity <= 0) return;

              if (!mounted) return;

              final now = DateTime.now();
              final record = PoultryExitRecord(
                id: now.millisecondsSinceEpoch.toString(),
                batchId: widget.animal.id,
                date: now,
                quantity: quantity,
                reason: reasonCtrl.text,
                income: Formatter.parseCurrencyInput(incomeCtrl.text) ?? 0,
                createdAt: now,
                updatedAt: now,
              );

              try {
                await widget.repository.addExitRecord(record);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save exit record: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      _load();
      _loadBatchCount(); // Reload the current batch count
      setState(() {});
    }
  }

  /// Color code reason
  Color _reasonColor(String reason) {
    switch (reason.toLowerCase()) {
      case 'sold':
        return Colors.green;
      case 'slaughtered':
        return Colors.orange;
      case 'culled':
        return Colors.red;
      default:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: FutureBuilder<List<PoultryExitRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.output, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No poultry exit records yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const FarmNativeAd(),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _load();
              _loadBatchCount(); // Reload batch count on refresh
              final list = await widget.repository.getExitRecords(
                widget.animal.id,
              );
              setState(() => _future = Future.value(list));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length + 1,
              itemBuilder: (context, index) {
                if (index == records.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 60),
                    child: FarmNativeAd(),
                  );
                }
                final r = records[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.exit_to_app,
                      color: _reasonColor(r.reason),
                    ),
                    title: Text(DateFormat('dd MMM yyyy').format(r.date)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason: ${r.reason}'),
                        Text('Quantity: ${r.quantity}'),
                        if (r.income != null && r.income! > 0)
                          Text('Income: ${Formatter.formatCurrency(r.income!)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExitRecord,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
