import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final TextEditingController cropController = TextEditingController();
  final TextEditingController inputCostController = TextEditingController();
  final TextEditingController laborCostController = TextEditingController();
  final TextEditingController expectedIncomeController =
      TextEditingController();
  Position? currentPosition;
  bool isSubmitting = false;

  Future<void> getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() => currentPosition = position);
  }

  Future<void> submitBudget() async {
    final crop = cropController.text.trim();
    final inputCost = double.tryParse(inputCostController.text.trim()) ?? 0;
    final laborCost = double.tryParse(laborCostController.text.trim()) ?? 0;
    final expectedIncome =
        double.tryParse(expectedIncomeController.text.trim()) ?? 0;

    if (crop.isEmpty || currentPosition == null) return;

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection('plan_book').add({
      'budget_item': crop,
      'input_cost': inputCost,
      'labor_cost': laborCost,
      'expected_income': expectedIncome,
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => isSubmitting = false);
    cropController.clear();
    inputCostController.clear();
    laborCostController.clear();
    expectedIncomeController.clear();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget plan saved')));
    }
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cropController,
              decoration: const InputDecoration(labelText: 'Crop Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: inputCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Input Cost'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: laborCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Labor Cost'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expectedIncomeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Expected Income'),
            ),
            const SizedBox(height: 12),
            currentPosition == null
                ? const Text('Getting GPS...')
                : Text(
                    'GPS: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : submitBudget,
              icon: const Icon(Icons.save),
              label: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
