import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';

class BreedingScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  const BreedingScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  List<BreedingRecord> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.listBreedingRecords(widget.animal.id);
    setState(() => _logs = list);
  }

  Future<void> _addBreedingRecord() async {
    final methodCtrl = TextEditingController();
    final sireCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? expectedDueDate;

    final result = await showDialog<BreedingRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Breeding Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: methodCtrl,
                  decoration: const InputDecoration(labelText: 'Method'),
                ),
                TextField(
                  controller: sireCtrl,
                  decoration: const InputDecoration(labelText: 'Sire Name/ID'),
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
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 280),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      expectedDueDate = picked;
                    }
                  },
                  child: const Text('Pick Expected Due Date'),
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
                final record = BreedingRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: widget.animal.id,
                  date: DateTime.now(),
                  method: methodCtrl.text,
                  sireName: sireCtrl.text.isNotEmpty ? sireCtrl.text : null,
                  cost: costCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(costCtrl.text.trim()),
                  expectedDueDate: expectedDueDate,
                  notes: notesCtrl.text,
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
      await widget.repository.addBreedingRecord(result);
      _load();
    }
  }

  Future<void> _deleteRecord(BreedingRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Breeding Record'),
          content: Text(
            'Are you sure you want to delete the breeding record "${record.method}" on ${record.date.toLocal().toString().split(" ").first}?\n\n'
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
      await widget.repository.updateBreedingRecord(updatedRecord);
      _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Breeding record deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: _logs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No breeding records yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const FarmNativeAd(),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ..._logs.map((r) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: Text(r.method),
                      subtitle: Text(
                        'Date: ${r.date.toLocal().toString().split(" ").first}\n'
                        '${r.sireName != null ? "Sire: ${r.sireName}\n" : ""}'
                        '${r.cost != null ? "Cost: ${widget.animal.currencySymbol}${r.cost!.toStringAsFixed(2)}\n" : ""}'
                        '${r.notes ?? ""}',
                      ),
                      trailing: Text(
                        r.expectedDueDate != null
                            ? 'Due: ${r.expectedDueDate!.toLocal().toString().split(" ").first}'
                            : '',
                      ),
                      onLongPress: () => _deleteRecord(r),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const FarmNativeAd(),
                const SizedBox(height: 60),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBreedingRecord,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
