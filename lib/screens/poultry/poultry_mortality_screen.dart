import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';

class PoultryMortalityScreen extends StatefulWidget {
  final String batchId;
  final PoultryRepository repository;
  final int flockSize; // initial flock size for % calculations

  const PoultryMortalityScreen({
    super.key,
    required this.batchId,
    required this.repository,
    required this.flockSize,
  });

  @override
  State<PoultryMortalityScreen> createState() => _PoultryMortalityScreenState();
}

class _PoultryMortalityScreenState extends State<PoultryMortalityScreen> {
  late Future<List<PoultryMortalityRecord>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.listPoultryMortalityRecords(widget.batchId);
    setState(() {});
  }

  Future<void> _addRecord() async {
    final countCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final expenseCtrl = TextEditingController();

    final result = await showDialog<PoultryMortalityRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mortality Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countCtrl,
              decoration: const InputDecoration(labelText: 'Number of deaths'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: expenseCtrl,
              decoration: const InputDecoration(
                labelText: 'Expense (optional)',
                hintText: 'e.g. 120.50',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final deaths = int.tryParse(countCtrl.text.trim()) ?? 0;
              if (deaths <= 0) return;

              final expense = double.tryParse(expenseCtrl.text.trim());

              final record = PoultryMortalityRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                batchId: widget.batchId,
                date: DateTime.now(),
                deaths: deaths,
                notes: notesCtrl.text.trim(),
                costLoss: expense,
              );

              try {
                debugPrint('Saving mortality record for batch ${record.batchId}: deaths=${record.deaths} id=${record.id}');
                await widget.repository.addPoultryMortalityRecord(record);
                debugPrint('Mortality record saved locally: ${record.id}');
                if (!mounted) return;
                Navigator.pop(context, record);
                _load();
              } catch (e, st) {
                debugPrint('Error saving mortality record: $e\n$st');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save mortality record: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) _load();
  }

  String _advisoryNotes(List<PoultryMortalityRecord> records) {
    if (widget.flockSize <= 0) {
      return '⚠️ No flock size recorded. Mortality rate cannot be calculated.';
    }

    final totalDeaths = records.fold<int>(0, (sum, r) => sum + r.deaths);
    final mortalityRate = (totalDeaths / widget.flockSize) * 100;

    String notes =
        'Total mortality: $totalDeaths birds\nMortality rate: ${mortalityRate.toStringAsFixed(1)}%';

    if (mortalityRate > 10) {
      notes +=
          '\n⚠️ High mortality! Review brooding, feed, vaccination, and hygiene.';
    } else if (mortalityRate > 5) {
      notes += '\nℹ️ Moderate mortality. Monitor flock closely.';
    } else {
      notes += '\n✅ Mortality is within normal range.';
    }

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: FutureBuilder<List<PoultryMortalityRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          records.sort((a, b) => a.date.compareTo(b.date));

          final notes = _advisoryNotes(records);

          return Column(
            children: [
              ListTile(
                title: const Text('Total Mortality'),
                trailing: Text(
                    '${records.fold<int>(0, (sum, r) => sum + r.deaths)} birds'),
              ),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_amber_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text('No mortality records yet',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final r = records[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.warning,
                                  color: Colors.red),
                              title: Text('${r.deaths} deaths'),
                              subtitle: Text(
                                '${r.date.toLocal().toString().split(" ").first} • ${r.notes ?? ''}' +
                                    (r.costLoss != null
                                        ? ' • Expense: ${Formatter.formatCurrency(r.costLoss!)}'
                                        : ''),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Card(
                color: Colors.yellow.shade50,
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(notes, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.green.shade700,
        tooltip: 'Add Mortality Record',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
