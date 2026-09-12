// lib/screens/animal/feeding_suggestions_screen.dart
import 'package:flutter/material.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';

class FeedingSuggestionsScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;

  const FeedingSuggestionsScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<FeedingSuggestionsScreen> createState() =>
      _FeedingSuggestionsScreenState();
}

class _FeedingSuggestionsScreenState extends State<FeedingSuggestionsScreen> {
  final _weightCtrl = TextEditingController();
  final _productionCtrl = TextEditingController(); // milk, meat, eggs
  final _marketCtrl = TextEditingController(); // local, export

  List<FeedingEntry> _feedingHistory = [];
  List<GrowthRecord> _growthHistory = [];

  @override
  void initState() {
    super.initState();
    _weightCtrl.text = widget.animal.ageMonths > 0
        ? (widget.animal.ageMonths * 12).toString()
        : '350'; // fallback weight
    _loadRecords();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _productionCtrl.dispose();
    _marketCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final feedList =
        await widget.repository.listFeedingEntries(widget.animal.id);
    final growthList =
        await widget.repository.listGrowthRecords(widget.animal.id);

    setState(() {
      _feedingHistory = feedList;
      _growthHistory = growthList;
    });
  }

  double get _dailyIntakeKg {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    return w * 0.03; // assume 3% body weight intake
  }

  /// AI advisory logic (replace with actual AI service call)
  List<String> _generateAITips() {
    final production = _productionCtrl.text.trim().toLowerCase();
    final market = _marketCtrl.text.trim().toLowerCase();
    final intake = _dailyIntakeKg;

    final latestGrowth =
        _growthHistory.isNotEmpty ? _growthHistory.last.weightKg : null;
    final avgFeedCost = _feedingHistory.isNotEmpty
        ? _feedingHistory.map((f) => f.cost).reduce((a, b) => a + b) /
            _feedingHistory.length
        : 0;

    if (production.contains('milk')) {
      return [
        "Provide ~${intake.toStringAsFixed(1)} kg dry matter/day.",
        "Focus on maize silage + soybean meal for milk solids.",
        "Market '$market' requires consistent fat/protein quality.",
        if (avgFeedCost > 0)
          "Average feed cost is ${widget.animal.currencySymbol}${avgFeedCost.toStringAsFixed(2)} — monitor profit margins."
      ];
    } else if (production.contains('meat')) {
      return [
        "Provide ~${intake.toStringAsFixed(1)} kg/day for steady growth.",
        "Balance pasture with energy feeds for faster weight gain.",
        "Market '$market' values carcass weight — aim for steady growth.",
        if (latestGrowth != null)
          "Latest recorded weight: ${latestGrowth.toStringAsFixed(1)} kg."
      ];
    } else if (production.contains('egg') || production.contains('poultry')) {
      return [
        "Provide ~${(intake * 1000).toStringAsFixed(0)} g feed/day per bird.",
        "Ensure calcium (limestone) + protein (fishmeal, soybean) for shell strength.",
        "Market '$market' demands uniform egg size and quality."
      ];
    } else {
      return [
        "General feeding: ~${intake.toStringAsFixed(1)} kg/day.",
        "Use balanced ration with forage + concentrate.",
        "Adjust based on production goals and market '$market'."
      ];
    }
  }

  void _applySuggestion() {
    Navigator.pop(context, {
      'weight': _weightCtrl.text,
      'feedType': _productionCtrl.text,
      'notes': _generateAITips().join("\n"),
    });
  }

  @override
  Widget build(BuildContext context) {
    final intake = _dailyIntakeKg;
    final tips = _generateAITips();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding Suggestions'),
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _weightCtrl,
            decoration: const InputDecoration(labelText: 'Animal weight (kg)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _productionCtrl,
            decoration: const InputDecoration(
                labelText: 'Production goal (milk, meat, eggs)'),
          ),
          TextField(
            controller: _marketCtrl,
            decoration: const InputDecoration(
                labelText: 'Target market (local, export, etc.)'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Estimated daily intake'),
            trailing: Text('${intake.toStringAsFixed(1)} kg'),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AI Advisory",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...tips.map((tip) => Text("• $tip")),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _applySuggestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Apply suggestion to planner'),
          ),
          const SizedBox(height: 16),
          if (_feedingHistory.isNotEmpty || _growthHistory.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Past Records",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_feedingHistory.isNotEmpty)
                      Text(
                          "Feeding entries: ${_feedingHistory.length}, latest cost ${widget.animal.currencySymbol}${_feedingHistory.last.cost.toStringAsFixed(2)}"),
                    if (_growthHistory.isNotEmpty)
                      Text(
                          "Growth records: ${_growthHistory.length}, latest weight ${_growthHistory.last.weightKg.toStringAsFixed(1)} kg"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}