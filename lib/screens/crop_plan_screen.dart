import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CropPlanScreen extends StatefulWidget {
  const CropPlanScreen({super.key});

  @override
  State<CropPlanScreen> createState() => _CropPlanScreenState();
}

class _CropPlanScreenState extends State<CropPlanScreen> {
  final TextEditingController notesController = TextEditingController();

  Future<void> savePlan() async {
    await FirebaseFirestore.instance.collection('plan_book').add({
      'notes': notesController.text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan saved')));
    notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Plan Notes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Write your crop plan notes below:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'E.g. Plant maize early due to expected rains...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: savePlan,
              icon: const Icon(Icons.save),
              label: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
