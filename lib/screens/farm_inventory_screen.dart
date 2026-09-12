import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class FarmInventoryScreen extends StatefulWidget {
  const FarmInventoryScreen({super.key});

  @override
  State<FarmInventoryScreen> createState() => _FarmInventoryScreenState();
}

class _FarmInventoryScreenState extends State<FarmInventoryScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String selectedCategory = 'Seed';
  Position? currentPosition;
  bool isSubmitting = false;

  final List<String> categories = [
    'Seed',
    'Fertilizer',
    'Pesticide',
    'Tool',
    'Feed',
    'Other',
  ];

  Future<void> getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() => currentPosition = position);
  }

  Future<void> submitInventory() async {
    final item = itemController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;

    if (item.isEmpty || quantity <= 0 || currentPosition == null) return;

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection('plan_book').add({
      'inventory_item': item,
      'quantity': quantity,
      'category': selectedCategory,
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => isSubmitting = false);
    itemController.clear();
    quantityController.clear();
    selectedCategory = 'Seed';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inventory item saved')));
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
        title: const Text('Farm Inventory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            currentPosition == null
                ? const Text('Getting GPS...')
                : Text(
                    'GPS: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : submitInventory,
              icon: const Icon(Icons.save),
              label: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}
