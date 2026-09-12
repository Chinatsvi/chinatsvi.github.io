import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/activity_log_record.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';

class ActivityLogScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  final ValueChanged<Animal>? onAnimalUpdated;
  final Future<void> Function(ActivityLogRecord record, Animal updatedAnimal)?
  onActivityRecorded;
  final String title;
  final String quantityLabel;

  const ActivityLogScreen({
    super.key,
    required this.animal,
    required this.repository,
    this.onAnimalUpdated,
    this.onActivityRecorded,
    this.title = 'Activity',
    this.quantityLabel = 'Animals added (optional)',
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<ActivityLogRecord> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.listActivityLogs(widget.animal.id);
    if (mounted) setState(() => _logs = list);
  }

  Future<void> _showAddDialog() async {
    final noteController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_ActivityDialogResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record activity'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: noteController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Activity note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.quantityLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 1) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cost (optional)',
                    border: OutlineInputBorder(),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _ActivityDialogResult(
                    note: noteController.text.trim(),
                    quantity: quantityController.text.trim().isEmpty
                        ? null
                        : int.parse(quantityController.text.trim()),
                    cost: costController.text.trim().isEmpty
                        ? null
                        : double.tryParse(costController.text.trim()),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    Animal updatedAnimal = widget.animal;
    if (result.quantity != null) {
      updatedAnimal = widget.animal.addActivityCount(result.quantity!);
      await widget.repository.updateAnimal(updatedAnimal);
    }

    final note = result.note.isNotEmpty
        ? result.note
        : (result.quantity != null
              ? 'Added ${result.quantity} animal(s)'
              : 'Activity recorded');

    final record = ActivityLogRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      animalId: widget.animal.id,
      date: DateTime.now(),
      notes: note,
      animalsAdded: result.quantity,
      cost: result.cost,
    );

    await widget.repository.addActivityLog(record);
    await widget.onActivityRecorded?.call(record, updatedAnimal);
    widget.onAnimalUpdated?.call(updatedAnimal);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.quantity != null
                ? 'Recorded activity and added ${result.quantity} animal(s).'
                : 'Activity recorded.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteRecord(ActivityLogRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete activity log?'),
          content: const Text('This will remove the entry from the list.'),
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
      await widget.repository.updateActivityLog(record.copyWith(deleted: true));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No activity logs yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 16),
                            const FarmNativeAd(),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _logs.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 60),
                            child: FarmNativeAd(),
                          );
                        }
                        final log = _logs[index];
                        return GestureDetector(
                          onDoubleTap: () => _deleteRecord(log),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.note_alt, color: Colors.green),
                              title: Text(log.notes),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.date.toLocal().toString().split(' ').first,
                                  ),
                                  if (log.animalsAdded != null && log.animalsAdded! > 0)
                                    Text('Added figure: ${log.animalsAdded}'),
                                  if (log.cost != null)
                                    Text('Cost: ${widget.animal.currencySymbol}${log.cost!.toStringAsFixed(2)}'),
                                ],
                              ),
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
        backgroundColor: Colors.green.shade700,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ActivityDialogResult {
  final String note;
  final int? quantity;
  final double? cost;

  const _ActivityDialogResult({required this.note, this.quantity, this.cost});
}
