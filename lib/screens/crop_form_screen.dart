import 'package:flutter/material.dart';

class CropFormScreen extends StatefulWidget {
  final String? selectedCropType;
  final Function(String?) onCropTypeChanged;

  const CropFormScreen({
    super.key,
    required this.selectedCropType,
    required this.onCropTypeChanged,
  });

  @override
  State<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends State<CropFormScreen> {
  @override
  Widget build(BuildContext context) {
    final cropTypes = ['Maize', 'Tomato', 'Cabbage', 'Onion', 'Carrot'];

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Crop Data')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text('Crop Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: widget.selectedCropType,
              hint: const Text('Select crop type'),
              items: cropTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                widget.onCropTypeChanged(value);
                setState(() {});
              },
            ),
            // Add other fields here later (crop name, notes, etc.)
          ],
        ),
      ),
    );
  }
}