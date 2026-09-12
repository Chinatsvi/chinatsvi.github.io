import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/app/utils/formatters.dart';

import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';

import 'package:agribased/widgets/brooding_advisory_card.dart';
import 'package:agribased/services/storage_router_service.dart';
import 'package:agribased/services/imagekit_upload_service.dart';

class PoultryRegistrationScreen extends StatefulWidget {
  final PoultryRepository poultryRepository;
  final AnimalRepository animalRepository;

  const PoultryRegistrationScreen({
    super.key,
    required this.poultryRepository,
    required this.animalRepository,
  });

  @override
  State<PoultryRegistrationScreen> createState() =>
      _PoultryRegistrationScreenState();
}

class _PoultryRegistrationScreenState extends State<PoultryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final countCtrl = TextEditingController();
  final ageCtrl = TextEditingController(); // ✅ NEW: Age in weeks
  final chickCostCtrl = TextEditingController(); // ✅ NEW: Cost per batch
  final initialWeightCtrl = TextEditingController(); // ✅ NEW: initial avg weight (kg)
  String? _selectedCurrency;

  DateTime? _batchStartDate; // ✅ HATCH / START DATE
  String? _selectedPurpose; // ✅ NEW
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Listen to breed changes to auto-detect purpose
    breedCtrl.addListener(_autoDetectPurpose);
  }

  /// Auto-detect purpose based on entered breed name
  void _autoDetectPurpose() {
    final breed = breedCtrl.text.trim();
    if (breed.isNotEmpty) {
      final detectedPurpose = detectPoultryPurpose(breed);
      setState(() => _selectedPurpose = detectedPurpose);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.removeListener(_autoDetectPurpose);
    breedCtrl.dispose();
    countCtrl.dispose();
    ageCtrl.dispose(); // ✅ NEW
    chickCostCtrl.dispose(); // ✅ NEW
    initialWeightCtrl.dispose();
    super.dispose();
  }

  /// Pick hatch / batch start date
  Future<void> _pickBatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _batchStartDate = picked);
    }
  }

  /// Pick photo
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  /// Calculate age in months from batch date
  int _calculateAgeMonths(DateTime startDate) {
    final now = DateTime.now();
    int months =
        (now.year - startDate.year) * 12 + (now.month - startDate.month);
    if (now.day < startDate.day) months--;
    return months < 0 ? 0 : months;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_batchStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select batch start date')),
      );
      return;
    }

    setState(() => _saving = true);

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ageMonths = _calculateAgeMonths(_batchStartDate!);

    // If user entered age in weeks, derive startDate from that to keep
    // age-consistent across the app (overrides selected batch date).
    DateTime effectiveStartDate = _batchStartDate!;
    final enteredWeeks = int.tryParse(ageCtrl.text.trim());
    if (enteredWeeks != null) {
      effectiveStartDate = DateTime.now().subtract(Duration(days: enteredWeeks * 7));
    }

    String? uploadedPhotoUrl;
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      final uploadedUrl = await StorageRouterService.instance.uploadFile(
        file: File(_photoPath!),
        folder: 'farmers/poultry/$id',
        fileName: 'poultry_$id.jpg',
      );

      if (!ImageKitUploadService.isRemoteImageUrl(uploadedUrl)) {
        throw Exception('Image upload failed. Please try again.');
      }

      uploadedPhotoUrl = uploadedUrl;
    }

    final batch = PoultryBatch(
      id: id,
      name: nameCtrl.text.trim(),
      breed: breedCtrl.text.trim(),
      purpose: _selectedPurpose, // ✅ NEW
      ageWeeks: int.tryParse(ageCtrl.text.trim()), // ✅ NEW
      initialCount: int.parse(countCtrl.text.trim()),
      currentCount: int.parse(
        countCtrl.text.trim(),
      ), // Initially same as initialCount
      chickCost: Formatter.parseCurrencyInput(chickCostCtrl.text.trim()), // ✅ NEW (cost per batch)
      initialAverageWeightKg: double.tryParse(initialWeightCtrl.text.trim()),
      userId: FirebaseAuth.instance.currentUser?.uid,
      startDate: effectiveStartDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      photoUrl: uploadedPhotoUrl,
    );

    final animal = Animal(
      id: id, // 🔑 SAME ID
      species: 'poultry',
      breed: batch.breed,
      ageMonths: ageMonths, // ✅ AUTO CALCULATED
      sex: null,
      photoUrl: uploadedPhotoUrl,
      purpose: _selectedPurpose, // ✅ NEW
      initialFlockSize: batch.initialCount,
      createdAt: batch.startDate,
    );

    try {
      // Apply selected currency globally for display/parsing (persisted)
      if (_selectedCurrency != null) await Formatter.setCurrencySymbol(_selectedCurrency!);
      // 1️⃣ Save poultry batch
      await widget.poultryRepository.addPoultryBatch(batch);

      // 2️⃣ Save animal record
      await widget.animalRepository.addAnimal(animal);

      if (!mounted) return;

      // Brooding advisory
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Brooding Advisory'),
          content: BroodingAdvisoryCard(
            startDate: batch.startDate,
            flockSize: batch.initialCount,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Poultry'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: breedCtrl,
                      decoration: InputDecoration(
                        labelText: 'Breed',
                        border: const OutlineInputBorder(),
                        helperText: 'Enter breed name (e.g., Hyline, Ross, Rhode Island Red) - Purpose will be auto-detected',
                        hintText: 'e.g., Hyline, Ross, Cobb...',
                        suffixText: _selectedPurpose != null ? '(Purpose: $_selectedPurpose)' : null,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: countCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Number of birds',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// ✅ AGE IN WEEKS (NEW)
                    TextFormField(
                      controller: ageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Age (weeks)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Current age of poultry in weeks (e.g., 20 for layers)',
                        hintText:
                            'e.g., 1 for day-old chicks, 20 for laying hens',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        if (int.tryParse(v)! < 0) {
                          return 'Age cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// � Batch Cost (NEW)
                    TextFormField(
                      controller: chickCostCtrl,
                      decoration: InputDecoration(
                        labelText: 'Cost per batch',
                        border: const OutlineInputBorder(),
                        helperText: 'Total cost for the batch (e.g., 1500.00)',
                        hintText: 'e.g., 1500.00',
                        prefixText: '${Formatter.currencySymbol} ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid amount';
                        if (double.tryParse(v)! < 0) {
                          return 'Cost cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// �📅 Batch start date
                    InkWell(
                      onTap: _pickBatchDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Batch start / hatch date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _batchStartDate == null
                              ? 'Select date'
                              : DateFormat('dd MMM yyyy').format(_batchStartDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency selection (mandatory)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                        helperText: 'Select your national currency symbol',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'R', child: Text('South African Rand (R)')),
                        DropdownMenuItem(value: r'$', child: Text('US Dollar (\$)')),
                        DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                        DropdownMenuItem(value: '£', child: Text('Pound Sterling (£)')),
                        DropdownMenuItem(value: '₦', child: Text('Nigerian Naira (₦)')),
                      ],
                      onChanged: (v) => setState(() => _selectedCurrency = v),
                      validator: (v) => v == null || v.isEmpty ? 'Select currency' : null,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    // Initial average weight per bird (kg)
                    TextFormField(
                      controller: initialWeightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Initial average weight (kg)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Average bird weight at registration (e.g., 0.04 for day-old chicks)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        if (double.tryParse(v)! < 0) {
                          return 'Weight cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// ✅ PURPOSE (NEW)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPurpose,
                      decoration: InputDecoration(
                        labelText: 'Purpose',
                        border: const OutlineInputBorder(),
                        helperText: _selectedPurpose != null 
                          ? 'Auto-detected from breed name. You can override if needed.'
                          : 'Primary purpose of this poultry batch (auto-detected from breed)',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'meat',
                          child: Text('Meat Production (Broilers)'),
                        ),
                        DropdownMenuItem(
                          value: 'eggs',
                          child: Text('Egg Production (Layers)'),
                        ),
                        DropdownMenuItem(
                          value: 'breeding',
                          child: Text('Breeding/Reproduction'),
                        ),
                        DropdownMenuItem(
                          value: 'show',
                          child: Text('Show/Exhibition'),
                        ),
                        DropdownMenuItem(
                          value: 'dual',
                          child: Text('Dual Purpose'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedPurpose = v),
                      validator: (v) => v == null ? 'Select purpose' : null,
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_photoPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_photoPath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Unable to preview this image'),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                      ),
                      child: const Text('Save Poultry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
