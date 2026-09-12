import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationFormScreen extends StatefulWidget {
  const LocationFormScreen({super.key});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Mandatory fields
  final countryController = TextEditingController();
  final provinceController = TextEditingController();
  final districtController = TextEditingController();
  final villageController = TextEditingController();

  // Optional fields
  final farmNameController = TextEditingController();
  final landmarkController = TextEditingController();
  final gpsController = TextEditingController();

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farm Location Details"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔴 Mandatory Section
              const Text(
                "Required Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _requiredField(countryController, "Country"),
              _requiredField(provinceController, "Province / State"),
              _requiredField(districtController, "District / City"),
              _requiredField(villageController, "Village / Suburb"),

              const SizedBox(height: 24),

              /// 🟡 Optional Section
              const Text(
                "Optional Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _optionalField(farmNameController, "Farm Name (optional)"),
              _optionalField(landmarkController, "Nearest Landmark (optional)"),
              _optionalField(gpsController, "GPS Coordinates / Directions (optional)"),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Location",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔴 Required Field Widget
  Widget _requiredField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "$label *",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }

  /// 🟡 Optional Field Widget
  Widget _optionalField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  /// 💾 Save to Firestore
  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .update({
      'location': {
        'country': countryController.text.trim(),
        'province': provinceController.text.trim(),
        'district': districtController.text.trim(),
        'village': villageController.text.trim(),
        'farmName': farmNameController.text.trim(),
        'landmark': landmarkController.text.trim(),
        'gps': gpsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }
    });

    setState(() => _saving = false);

    Navigator.pop(context, true);
  }
}
