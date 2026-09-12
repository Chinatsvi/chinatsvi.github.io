// lib/screens/animal/daily_ration_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'feeding_suggestions_screen.dart'; // import the new screen

class DailyRationPlannerScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;

  const DailyRationPlannerScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<DailyRationPlannerScreen> createState() =>
      _DailyRationPlannerScreenState();
}

class _DailyRationPlannerScreenState extends State<DailyRationPlannerScreen> {
  final _weightCtrl = TextEditingController(text: '350'); // kg
  final _intakePercentCtrl = TextEditingController(text: '3'); // % of BW
  final _feedTypeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _intakePercentCtrl.dispose();
    _feedTypeCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Calculate daily intake as % of body weight
  double get _dailyIntakeKg {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final p = double.tryParse(_intakePercentCtrl.text) ?? 0;
    return w * (p / 100);
  }

  /// Save ration plan as FeedingEntry
  Future<void> _save() async {
    final intake = _dailyIntakeKg;
    final feedType = _feedTypeCtrl.text.trim().isEmpty
        ? 'Daily ration'
        : _feedTypeCtrl.text.trim();
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0;
    final notes = _notesCtrl.text.trim();

    final entry = FeedingEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      animalId: widget.animal.id,
      date: DateTime.now(),
      feedType: feedType,
      quantityKg: intake,
      cost: cost,
      notes: notes.isEmpty ? null : notes,
    );

    await widget.repository.addFeedingEntry(entry);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ration plan saved')));
  }

  /// Open AI-driven feeding suggestions screen
  Future<void> _openSuggestions() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => FeedingSuggestionsScreen(
          animal: widget.animal,
          repository: widget.repository,
        ),
      ),
    );

    if (result != null) {
      // Apply suggested values back into planner
      if (result['weight'] != null) _weightCtrl.text = result['weight']!;
      if (result['feedType'] != null) _feedTypeCtrl.text = result['feedType']!;
      if (result['notes'] != null) _notesCtrl.text = result['notes']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intake = _dailyIntakeKg;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Ration Planner'),
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
            controller: _intakePercentCtrl,
            decoration: const InputDecoration(
              labelText: 'Intake (% body weight)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Estimated daily intake'),
            trailing: Text('${intake.toStringAsFixed(1)} kg'),
          ),
          TextField(
            controller: _feedTypeCtrl,
            decoration: const InputDecoration(labelText: 'Feed type'),
          ),
          TextField(
            controller: _costCtrl,
            decoration: const InputDecoration(
              labelText: 'Cost (local currency)',
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (feeding times, mixes)',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Save ration plan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openSuggestions,
            icon: const Icon(Icons.lightbulb, color: Colors.green),
            label: const Text('Get Feeding Suggestions'),
          ),
        ],
      ),
    );
  }
}
