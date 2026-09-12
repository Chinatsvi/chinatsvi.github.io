import 'package:flutter/material.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'dart:developer' as developer;
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class PoultryHealthScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryHealthScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryHealthScreen> createState() => _PoultryHealthScreenState();
}

class _PoultryHealthScreenState extends State<PoultryHealthScreen> {
  List<PoultryHealthRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      developer.log(
        '🐔 Loading health records for poultry: ${widget.animal.id}',
        name: 'PoultryHealthScreen',
      );
      final list = await widget.repository.getHealthRecords(widget.animal.id);
      list.sort((a, b) => b.date.compareTo(a.date)); // newest first
      developer.log(
        '🐔 Loaded ${list.length} health records',
        name: 'PoultryHealthScreen',
      );
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (e) {
      developer.log(
        '❌ Error loading health records: $e',
        name: 'PoultryHealthScreen',
      );
      setState(() {
        _records = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading health records: $e')),
        );
      }
    }
  }

  Future<void> _addRecord() async {
    final typeCtrl = TextEditingController();
    final productCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    final result = await showDialog<PoultryHealthRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Health Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeCtrl.text.isNotEmpty ? typeCtrl.text : null,
                decoration: const InputDecoration(
                  labelText: 'Health Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'vaccination',
                    child: Text('Vaccination'),
                  ),
                  DropdownMenuItem(
                    value: 'treatment',
                    child: Text('Treatment'),
                  ),
                  DropdownMenuItem(
                    value: 'deworming',
                    child: Text('Deworming'),
                  ),
                  DropdownMenuItem(
                    value: 'checkup',
                    child: Text('Health Checkup'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    typeCtrl.text = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product/Medicine (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cost (R) (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeCtrl.text.trim().isEmpty) return;

              final record = PoultryHealthRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                batchId: widget.animal.id,
                date: DateTime.now(),
                type: typeCtrl.text.trim(),
                product: productCtrl.text.trim().isNotEmpty
                    ? productCtrl.text.trim()
                    : null,
                notes: notesCtrl.text.trim().isNotEmpty
                    ? notesCtrl.text.trim()
                    : null,
                cost: double.tryParse(costCtrl.text.trim()) ?? 0.0,
              );
              Navigator.pop(context, record);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        developer.log(
          '🐔 Adding health record: ${result.type}',
          name: 'PoultryHealthScreen',
        );
        await widget.repository.addHealthRecord(result);
        developer.log(
          '🐔 Health record added successfully',
          name: 'PoultryHealthScreen',
        );
        _loadRecords(); // Reload records
      } catch (e) {
        developer.log(
          '❌ Error adding health record: $e',
          name: 'PoultryHealthScreen',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving health record: $e')),
          );
        }
      }
    }
  }

  // Calculate total health cost
  double get totalHealthCost =>
      _records.fold<double>(0, (sum, r) => sum + (r.cost ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading health records...'),
                ],
              ),
            )
          : _records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.healing_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No health records yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const FarmNativeAd(),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Health Costs: ${Formatter.formatCurrency(totalHealthCost)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_records.length} records',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _records.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _records.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 60),
                            child: FarmNativeAd(),
                          );
                        }
                        final r = _records[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getHealthIcon(r.type),
                              color: _getHealthColor(r.type),
                            ),
                            title: Text(
                              '${r.date.toLocal().toString().split(' ')[0]} • ${r.type.toUpperCase()}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (r.product != null)
                                  Text('Product: ${r.product}'),
                                if (r.notes != null) Text('Notes: ${r.notes}'),
                                if (r.cost != null && r.cost! > 0)
                                  Text('Cost: ${Formatter.formatCurrency(r.cost!)}'),
                                Text(
                                  r.healthAdvisory(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.green.shade700,
        tooltip: 'Add Health Record',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getHealthIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines;
      case 'treatment':
        return Icons.medication;
      case 'deworming':
        return Icons.cleaning_services;
      case 'checkup':
        return Icons.health_and_safety;
      default:
        return Icons.medical_services;
    }
  }

  Color _getHealthColor(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Colors.blue;
      case 'treatment':
        return Colors.red;
      case 'deworming':
        return Colors.orange;
      case 'checkup':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
