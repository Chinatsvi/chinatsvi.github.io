import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';

class VetVisitScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  const VetVisitScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<VetVisitScreen> createState() => _VetVisitScreenState();
}

class _VetVisitScreenState extends State<VetVisitScreen> {
  List<VetVisit> _visits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.listVetVisits(widget.animal.id);
    setState(() => _visits = list);
  }

  Future<void> _addVisit() async {
    final vetCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    final result = await showDialog<VetVisit>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Vet Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vetCtrl,
                  decoration: const InputDecoration(labelText: 'Vet name'),
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
                final visit = VetVisit(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: widget.animal.id,
                  visitDate: DateTime.now(),
                  vetName: vetCtrl.text.trim().isEmpty
                      ? 'Vet'
                      : vetCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                  cost: costCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(costCtrl.text.trim()),
                );
                Navigator.pop(context, visit);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await widget.repository.addVetVisit(result);
      _load();
    }
  }

  Future<void> _deleteVisit(VetVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Vet Visit'),
          content: Text(
            'Are you sure you want to delete the vet visit with ${visit.vetName} on ${visit.visitDate.toLocal().toString().split(" ").first}?\n\n'
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
      final updatedVisit = visit.copyWith(deleted: true);

      // Update the record with deleted flag
      await widget.repository.updateVetVisit(updatedVisit);
      _load();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vet visit deleted')));
      }
    }
  }

  String _advisoryNotes() {
    if (_visits.isEmpty) {
      return 'No vet visits recorded yet. ⚠️ Routine check‑ups every 6 months are recommended.';
    }
    final last = _visits.last;
    final lastDate = last.visitDate.toLocal().toString().split(" ").first;

    String notes = 'Last vet visit: ${last.vetName} on $lastDate.';

    // Advisory logic
    final monthsSince = DateTime.now().difference(last.visitDate).inDays ~/ 30;
    if (monthsSince >= 6) {
      notes +=
          '\n💉 Reminder: It has been over 6 months since the last check‑up.';
    }
    if (last.notes != null &&
        last.notes!.toLowerCase().contains('vaccination')) {
      notes += '\n📌 Follow‑up: Ensure booster vaccinations are scheduled.';
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
            child: _visits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No vet visits yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          const FarmNativeAd(),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _visits.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _visits.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: FarmNativeAd(),
                        );
                      }
                      final v = _visits[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.local_hospital,
                            color: Colors.blueAccent,
                          ),
                          title: Text(v.vetName),
                          subtitle: Text(
                            '${v.visitDate.toLocal().toString().split(" ").first}'
                            '${v.cost != null ? " • Cost: ${widget.animal.currencySymbol}${v.cost!.toStringAsFixed(2)}" : ""}'
                            '${v.notes != null ? " • ${v.notes}" : ""}',
                          ),
                          onLongPress: () => _deleteVisit(v),
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
        onPressed: _addVisit,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
