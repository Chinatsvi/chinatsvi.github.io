import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'crop_history_screen.dart';

class CropEntryScreen extends StatefulWidget {
  const CropEntryScreen({super.key});

  @override
  State<CropEntryScreen> createState() => _CropEntryScreenState();
}

class _CropEntryScreenState extends State<CropEntryScreen> {
  final TextEditingController notesController = TextEditingController();
  String selectedCrop = 'Maize';
  DateTime selectedDate = DateTime.now();
  Position? currentPosition;
  bool isSubmitting = false;

  final List<String> cropTypes = [
    'Maize',
    'Tomato',
    'Cabbage',
    'Onion',
    'Potato',
    'Carrot',
    'Spinach',
    'Sorghum',
    'Beans',
    'Groundnuts',
  ];

  Future<void> getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() => currentPosition = position);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> submitEntry() async {
    final notes = notesController.text.trim();
    if (selectedCrop.isEmpty || currentPosition == null) return;

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection('plan_book').add({
      'crop': selectedCrop,
      'notes': notes,
      'planting_date': selectedDate.toIso8601String(),
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => isSubmitting = false);
    notesController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Crop entry submitted')));
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
        title: const Text('Smart Crop Entry'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CropHistoryScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Text('View Crop History'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCrop,
              items: cropTypes.map((crop) {
                return DropdownMenuItem(value: crop, child: Text(crop));
              }).toList(),
              onChanged: (value) => setState(() => selectedCrop = value!),
              decoration: const InputDecoration(labelText: 'Select Crop Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Field Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                const Spacer(),
                TextButton(onPressed: pickDate, child: const Text('Pick Date')),
              ],
            ),
            const SizedBox(height: 12),
            currentPosition == null
                ? const Text('Getting GPS location...')
                : Text(
                    'GPS: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : submitEntry,
              icon: const Icon(Icons.save),
              label: const Text('Submit Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
