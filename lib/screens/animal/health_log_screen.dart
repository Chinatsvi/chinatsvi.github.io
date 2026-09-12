// lib/screens/animal/health_log_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class HealthLogScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  const HealthLogScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  List<HealthRecord> _logs = [];
  List<GrowthRecord> _growthRecords = []; // integrated growth data

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.listHealthRecords(widget.animal.id);
    final growthList = await widget.repository.listGrowthRecords(
      widget.animal.id,
    );
    setState(() {
      _logs = list;
      _growthRecords = growthList;
    });
  }

  Future<void> _addRecord() async {
    final typeCtrl = TextEditingController();
    final productCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final result = await showDialog<HealthRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Health Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type (Vaccination, Treatment, Dipping)',
                  ),
                ),
                TextField(
                  controller: productCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product/Medicine',
                  ),
                ),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cost (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
                final record = HealthRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: widget.animal.id,
                  date: DateTime.now(),
                  type: typeCtrl.text.trim().isEmpty
                      ? 'Health Event'
                      : typeCtrl.text.trim(),
                  product: productCtrl.text.trim().isEmpty
                      ? null
                      : productCtrl.text.trim(),
                  cost: costCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(costCtrl.text.trim()),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                Navigator.pop(context, record);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await widget.repository.addHealthRecord(result);
      _load();
    }
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Health Record'),
          content: Text(
            'Are you sure you want to delete the health record "${record.type}" on ${record.date.toLocal().toString().split(" ").first}?\n\n'
            'Note: This record will be hidden from the list but preserved for profit/loss calculations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Soft delete: mark as deleted instead of actually deleting (for profit/loss reports)
      final updatedRecord = record.copyWith(deleted: true);

      // Update the record with deleted flag
      await widget.repository.updateHealthRecord(updatedRecord);
      _load();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Health record deleted')));
      }
    }
  }

  String _advisoryNotes() {
    String notes = '';

    if (_logs.isEmpty) {
      notes =
          'No health records yet. ⚠️ Remember routine vaccinations, deworming, and dipping schedules.';
    } else {
      final last = _logs.last;
      final lastDate = last.date.toLocal().toString().split(" ").first;
      notes =
          'Last health event: ${last.type} on $lastDate. Keep track of routine vaccinations, deworming, and dipping.';

      if (last.type.toLowerCase().contains('vaccination')) {
        notes += '\n💉 Next vaccination due in ~6 months.';
      }
      if (last.type.toLowerCase().contains('dipping')) {
        notes +=
            '\n🪳 Dipping recommended every 4 weeks to prevent tick-borne diseases.';
      }
    }

    // Seasonal outbreak prediction
    final month = DateTime.now().month;
    if (month >= 11 || month <= 2) {
      notes +=
          '\n⚠️ High risk season for lumpy skin disease and FMD. Monitor animals closely.';
    } else if (month >= 5 && month <= 8) {
      notes += '\n⚠️ Winter stress may increase respiratory disease risk.';
    }

    // Growth slowdown integration
    if (_growthRecords.length >= 2) {
      final first = _growthRecords.first;
      final last = _growthRecords.last;
      final days = last.date.difference(first.date).inDays;
      final gain = last.weightKg - first.weightKg;
      final avgDailyGain = days > 0 ? gain / days : 0;

      if (avgDailyGain < 0.2) {
        notes +=
            '\n🚨 Growth slowdown detected: Average daily gain ${avgDailyGain.toStringAsFixed(2)} kg/day. '
            'Possible health issue — check nutrition, parasites, or disease.';
      }
    }

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final notes = _advisoryNotes();

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: Column(
        children: [
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.healing_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No health records yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          const FarmNativeAd(),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _logs.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: FarmNativeAd(),
                        );
                      }
                      final r = _logs[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.healing,
                            color: Colors.redAccent,
                          ),
                          title: Text('${r.type} • ${r.product ?? ''}'),
                          subtitle: Text(
                            '${r.date.toLocal().toString().split(" ").first}'
                            '${r.cost != null ? " • Cost: ${widget.animal.currencySymbol}${r.cost!.toStringAsFixed(2)}" : ""}'
                            '${r.notes != null ? "\nNotes: ${r.notes}" : ""}',
                          ),
                          onLongPress: () => _deleteRecord(r),
                        ),
                      );
                    },
                  ),
          ),
          Card(
            color: Colors.green.shade50,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(notes, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
