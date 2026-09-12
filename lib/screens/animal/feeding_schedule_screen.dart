import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';

class FeedingScheduleScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;

  const FeedingScheduleScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<FeedingScheduleScreen> createState() => _FeedingScheduleScreenState();
}

class _FeedingScheduleScreenState extends State<FeedingScheduleScreen> {
  List<FeedingEntry> _entries = [];
  double? _currentWeight;
  double _recommendedFeedMin = 0.0;
  double _recommendedFeedMax = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return; // Check if widget is still mounted

    final entries = await widget.repository.listFeedingEntries(
      widget.animal.id,
    );
    final growthRecords = await widget.repository.listGrowthRecords(
      widget.animal.id,
    );


    // Get the most recent weight
    if (growthRecords.isNotEmpty) {
      final sortedRecords = List<GrowthRecord>.from(growthRecords)
        ..sort((a, b) => b.date.compareTo(a.date));
      _currentWeight = sortedRecords.first.weightKg;

      // Calculate recommended feed (2-3% of body weight)
      _recommendedFeedMin = _currentWeight! * 0.02;
      _recommendedFeedMax = _currentWeight! * 0.03;
    }

    if (mounted) {
      setState(() {
        _entries = entries;
      });
    }
  }

  Future<void> _addEntry() async {
    final feedCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    // Pre-fill with recommended feed amount if available
    if (_currentWeight != null) {
      final recommendedAmount = (_recommendedFeedMin + _recommendedFeedMax) / 2;
      qtyCtrl.text = recommendedAmount.toStringAsFixed(2);
    }

    final result = await showDialog<FeedingEntry>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Feeding Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: feedCtrl,
                  decoration: const InputDecoration(labelText: 'Feed type'),
                ),
                if (_currentWeight != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Weight: ${_currentWeight!.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Recommended Feed: ${_recommendedFeedMin.toStringAsFixed(2)} - ${_recommendedFeedMax.toStringAsFixed(2)} kg per day',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                        Text(
                          '(2-3% of body weight)',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Quantity (kg)',
                    hintText: _currentWeight != null
                        ? 'Recommended: ${((_recommendedFeedMin + _recommendedFeedMax) / 2).toStringAsFixed(2)} kg'
                        : 'Enter quantity',
                    helperText: _currentWeight != null
                        ? 'Based on current weight: ${_currentWeight!.toStringAsFixed(1)} kg'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
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
                final quantity = double.tryParse(qtyCtrl.text.trim()) ?? 0;

                // Validate quantity against recommendations
                String? validationMessage;
                if (_currentWeight != null) {
                  if (quantity < _recommendedFeedMin) {
                    validationMessage = 'Quantity is below recommended minimum';
                  } else if (quantity > _recommendedFeedMax * 1.5) {
                    validationMessage =
                        'Quantity is much higher than recommended';
                  }
                }

                final entry = FeedingEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: widget.animal.id,
                  date: DateTime.now(),
                  feedType: feedCtrl.text.trim().isEmpty
                      ? 'Feed'
                      : feedCtrl.text.trim(),
                  quantityKg: quantity,
                  cost: double.tryParse(costCtrl.text.trim()) ?? 0,
                  notes: notesCtrl.text.trim().isEmpty
                      ? validationMessage
                      : '${notesCtrl.text.trim()}${validationMessage != null ? '\n$validationMessage' : ''}',
                );
                Navigator.pop(context, entry);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await widget.repository.addFeedingEntry(result);
      _load();
    }
  }

  Future<void> _deleteEntry(FeedingEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Feeding Entry'),
          content: Text(
            'Are you sure you want to delete the feeding entry "${entry.feedType}" (${entry.quantityKg}kg) on ${entry.date.toLocal().toString().split(" ").first}?\n\n'
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
      final updatedEntry = entry.copyWith(deleted: true);

      // Update the record with deleted flag
      await widget.repository.updateFeedingEntry(updatedEntry);
      _load();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Feeding entry deleted')));
      }
    }
  }

  String _suggestNotes() {
    final species = widget.animal.species.toLowerCase();
    final weight =
        _currentWeight ??
        (widget.animal.ageMonths > 0
            ? widget.animal.ageMonths * 12
            : 350); // fallback weight
    final intake = _entries.fold<double>(0, (s, e) => s + e.quantityKg);

    String notes = '';

    // Weight-based recommendation
    if (_currentWeight != null) {
      final recommendedMin = _currentWeight! * 0.02;
      final recommendedMax = _currentWeight! * 0.03;
      final actualPercentage = (intake / _currentWeight!) * 100;

      notes += '📊 Current Weight: ${_currentWeight!.toStringAsFixed(1)} kg\n';
      notes +=
          '🎯 Recommended Feed: ${recommendedMin.toStringAsFixed(2)} - ${recommendedMax.toStringAsFixed(2)} kg/day (2-3% of body weight)\n';
      notes +=
          '📈 Current Intake: ${actualPercentage.toStringAsFixed(1)}% of body weight\n';

      if (intake < recommendedMin) {
        notes +=
            '⚠️ Underfeeding: Consider increasing feed for optimal growth.\n';
      } else if (intake > recommendedMax) {
        notes +=
            '⚠️ Overfeeding: Consider reducing feed to prevent waste and health issues.\n';
      } else {
        notes += '✅ Optimal feeding amount for current weight.\n';
      }
    }

    // Species-specific advice
    if (species.contains('cattle')) {
      notes +=
          'For cattle (~${weight}kg): Balance forage (silage, hay) with protein sources (soybean, cottonseed). '
          'Consistent growth improves beef/dairy profit.';
    } else if (species.contains('goat')) {
      notes +=
          'For goats (~${weight}kg): Mix browse + concentrate. Goats need higher protein for reproduction and milk yield.';
    } else if (species.contains('poultry')) {
      notes +=
          'For poultry: Provide ~120g feed/day per bird. '
          'Ensure calcium (limestone) and protein (fishmeal, soybean) for egg quality.';
    } else {
      notes +=
          'General feeding: Use balanced ration with forage + concentrate. Adjust for production goals.';
    }

    return notes;
  }

  Color _getFeedStatusColor(double quantity) {
    if (_currentWeight == null) return Colors.grey;

    if (quantity < _recommendedFeedMin) {
      return Colors.orange; // Underfeeding
    } else if (quantity > _recommendedFeedMax) {
      return Colors.red; // Overfeeding
    } else {
      return Colors.green; // Optimal
    }
  }

  String _getFeedStatusText(double quantity) {
    if (_currentWeight == null) return 'No weight data';

    final percentage = (quantity / _currentWeight!) * 100;

    if (quantity < _recommendedFeedMin) {
      return 'Underfeeding (${percentage.toStringAsFixed(1)}%)';
    } else if (quantity > _recommendedFeedMax) {
      return 'Overfeeding (${percentage.toStringAsFixed(1)}%)';
    } else {
      return 'Optimal (${percentage.toStringAsFixed(1)}%)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _entries.fold<double>(0, (sum, e) => sum + e.cost);
    final notes = _suggestNotes();

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: Column(
        children: [
          // Weight and Recommendation Header
          if (_currentWeight != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_weight, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Current Weight: ${_currentWeight!.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daily Feed Recommendation: ${_recommendedFeedMin.toStringAsFixed(2)} - ${_recommendedFeedMax.toStringAsFixed(2)} kg',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '(2-3% of body weight)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade500,
                    ),
                  ),
                ],
              ),
            ),

          // Daily Feeding Entries Header
          ListTile(
            title: const Text('Daily Feeding Entries'),
            trailing: Text(
              'Total cost: ${widget.animal.currencySymbol}${totalCost.toStringAsFixed(2)}',
            ),
            subtitle: _currentWeight != null
                ? Text(
                    'Target: ${_recommendedFeedMin.toStringAsFixed(2)}-${_recommendedFeedMax.toStringAsFixed(2)} kg/day',
                  )
                : null,
          ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No feeding entries yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          const FarmNativeAd(),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: FarmNativeAd(),
                        );
                      }
                      final e = _entries[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.restaurant,
                            color: Colors.green,
                          ),
                          title: Text('${e.feedType} • ${e.quantityKg} kg'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.date.toLocal().toString().split(" ").first}'
                                '${e.notes != null ? "\nNotes: ${e.notes}" : ""}',
                              ),
                              if (_currentWeight != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getFeedStatusColor(e.quantityKg),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getFeedStatusText(e.quantityKg),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (e.aiTips != null)
                                ...e.aiTips!.map((tip) => Text("• $tip")),
                            ],
                          ),
                          trailing: Text('${widget.animal.currencySymbol}${e.cost.toStringAsFixed(2)}'),
                          onLongPress: () => _deleteEntry(e),
                        ),
                      );
                    },
                  ),
          ),

          // Advisory notes card
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
        onPressed: _addEntry,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
