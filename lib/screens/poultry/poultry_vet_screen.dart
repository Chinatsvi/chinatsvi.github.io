import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class PoultryVetScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryVetScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryVetScreen> createState() => _PoultryVetScreenState();
}

class _PoultryVetScreenState extends State<PoultryVetScreen> {
  List<PoultryVetRecord> _records = [];
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
        '🐔 Loading vet records for poultry: ${widget.animal.id}',
        name: 'PoultryVetScreen',
      );
      final list = await widget.repository.getVetRecords(widget.animal.id);
      list.sort((a, b) => b.visitDate.compareTo(a.visitDate)); // newest first
      developer.log(
        '🐔 Loaded ${list.length} vet records',
        name: 'PoultryVetScreen',
      );
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (e) {
      developer.log(
        '❌ Error loading vet records: $e',
        name: 'PoultryVetScreen',
      );
      setState(() {
        _records = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vet records: $e')),
        );
      }
    }
  }

  Future<void> _addRecord() async {
    final reasonCtrl = TextEditingController();
    final diagnosisCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    final result = await showDialog<PoultryVetRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vet Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit',
                ),
              ),
              TextField(
                controller: diagnosisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis (optional)',
                ),
              ),
              TextField(
                controller: treatmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Treatment (optional)',
                ),
              ),
              TextField(
                controller: costCtrl,
                decoration: const InputDecoration(labelText: 'Cost (USD)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
              final record = PoultryVetRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                batchId: widget
                    .animal
                    .id, // Using animal.id as batchId since it's the identifier we have
                visitDate: DateTime.now(),
                reason: reasonCtrl.text.trim(),
                diagnosis: diagnosisCtrl.text.trim().isNotEmpty
                    ? diagnosisCtrl.text.trim()
                    : null,
                treatment: treatmentCtrl.text.trim().isNotEmpty
                    ? treatmentCtrl.text.trim()
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
          '🐔 Adding vet record: ${result.reason}',
          name: 'PoultryVetScreen',
        );
        await widget.repository.addVetRecord(result);
        developer.log(
          '🐔 Vet record added successfully',
          name: 'PoultryVetScreen',
        );
        _loadRecords(); // Reload records
      } catch (e) {
        developer.log(
          '❌ Error adding vet record: $e',
          name: 'PoultryVetScreen',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving vet record: $e')),
          );
        }
      }
    }
  }

  // Calculate total vet cost
  double get totalVetCost =>
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
                  Text('Loading vet records...'),
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
                      Icons.medical_services_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No vet records yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                    color: Colors.yellow.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Vet Costs: ${Formatter.formatCurrency(totalVetCost)}',
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
                            leading: const Icon(
                              Icons.medical_services,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              '${r.visitDate.toLocal().toString().split(' ')[0]} • ${r.reason}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (r.diagnosis != null)
                                  Text('Diagnosis: ${r.diagnosis}'),
                                if (r.treatment != null)
                                  Text('Treatment: ${r.treatment}'),
                                Text(
                                  'Cost: ${Formatter.formatCurrency(r.cost ?? 0)}',
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
        tooltip: 'Add Vet Record',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
