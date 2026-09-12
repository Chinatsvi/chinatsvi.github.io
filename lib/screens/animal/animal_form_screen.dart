import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AnimalFormScreen extends StatefulWidget {
  final AnimalRepository repository;
  final String? registrationMode;

  const AnimalFormScreen({
    super.key,
    required this.repository,
    this.registrationMode,
  });

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _targetWeightController = TextEditingController(); // ✅ NEW
  final _totalCountController = TextEditingController(text: '1');
  final _maleCountController = TextEditingController();
  final _femaleCountController = TextEditingController();
  final _initialCostController = TextEditingController();
  final _currencyController = TextEditingController(text: r'$');
  final _notesController = TextEditingController();

  String? _selectedSex;
  String? _selectedPurpose; // ✅ NEW
  String? _selectedImagePath;
  String? _uploadedPhotoUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose(); // ✅
    _totalCountController.dispose();
    _maleCountController.dispose();
    _femaleCountController.dispose();
    _initialCostController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImagePath = picked.path;
        _uploadedPhotoUrl = null;
      });
    }
  }

  void _updateTotalFromMixed() {
    final males = int.tryParse(_maleCountController.text.trim()) ?? 0;
    final females = int.tryParse(_femaleCountController.text.trim()) ?? 0;
    final total = males + females;
    if (total > 0) {
      _totalCountController.text = total.toString();
    }
    setState(() {});
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      int? maleCount;
      int? femaleCount;
      int totalCount = int.tryParse(_totalCountController.text.trim()) ?? 1;

      if (_selectedSex == 'Mixed') {
        maleCount = int.tryParse(_maleCountController.text.trim()) ?? 0;
        femaleCount = int.tryParse(_femaleCountController.text.trim()) ?? 0;
        final sum = maleCount + femaleCount;
        if (sum > 0) totalCount = sum;
      } else if (_selectedSex == 'Female') {
        femaleCount = totalCount;
        maleCount = 0;
      } else if (_selectedSex == 'Male') {
        maleCount = totalCount;
        femaleCount = 0;
      }

      final initialCost = _initialCostController.text.trim().isEmpty
          ? 0.0
          : (double.tryParse(_initialCostController.text.trim()) ?? 0.0);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
        final animalTags = _idController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();
        final animalId = animalTags.isEmpty
          ? const Uuid().v4()
          : animalTags.first;

      String? uploadedPhotoUrl;
      if (_selectedImagePath != null) {
        final cloudinaryService = CloudinaryService();
        uploadedPhotoUrl = await cloudinaryService.uploadFile(
          file: File(_selectedImagePath!),
          folder: 'animals/$animalId',
          fileName: 'animal_$animalId',
        );

        if (uploadedPhotoUrl == null || uploadedPhotoUrl.isEmpty) {
          throw Exception('Image upload failed. Please try again.');
        }
      }

      final animal = Animal(
        id: animalId,
        animalTags: animalTags,
        species: _speciesController.text.trim(),
        breed: _breedController.text.trim(),
        ageMonths: int.tryParse(_ageController.text.trim()) ?? 0,
        sex: _selectedSex,
        maleCount: maleCount,
        femaleCount: femaleCount,
        photoUrl: uploadedPhotoUrl ?? _uploadedPhotoUrl,
        targetWeightKg: _targetWeightController.text.trim().isEmpty
            ? null
            : double.tryParse(
                _targetWeightController.text.trim(),
              ), // ✅ OPTIONAL
        purpose: _selectedPurpose, // ✅ NEW
        totalCount: totalCount < 1 ? 1 : totalCount,
        totalCost: initialCost,
        currency: _currencyController.text.trim().isNotEmpty
            ? _currencyController.text.trim()
            : r'$',
        notes: notes,
        createdAt: DateTime.now(),
      );

      await widget.repository.addAnimal(animal);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving animal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.registrationMode == 'birth'
              ? 'Register by Birth'
              : widget.registrationMode == 'purchase'
              ? 'Register by Purchase'
              : 'Register Animal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Animal Tag / Identifier
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Animal Tag / Names (optional)',
                        hintText: 'e.g. Bella, Thandi, 101',
                        helperText: 'For multiple animals, separate each name with a comma',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag, color: Colors.green),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Suggestions: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ...['Cattle A', 'Cattle B', 'Cattle 1', 'Cattle 2', 'Dairy Cow 1'].map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(tag, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() => _idController.text = tag);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Species
                    TextFormField(
                      controller: _speciesController,
                      decoration: const InputDecoration(
                        labelText: 'Species (Cattle, Goat, Sheep)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter species' : null,
                    ),
                    const SizedBox(height: 16),

                    /// Breed
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter breed' : null,
                    ),
                    const SizedBox(height: 16),

                    /// Age
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (months)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter age in months (e.g. 24 for 2 years)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter age';
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null || parsed < 0) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// ✅ TARGET WEIGHT (OPTIONAL)
                    TextFormField(
                      controller: _targetWeightController,
                      decoration: const InputDecoration(
                        labelText: 'Target Weight (kg) – optional',
                        border: OutlineInputBorder(),
                        helperText: 'Used for growth tracking comparison',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (double.tryParse(v) == null) {
                          return 'Enter valid weight';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Total figure
                    TextFormField(
                      controller: _totalCountController,
                      decoration: const InputDecoration(
                        labelText: 'Total figure',
                        border: OutlineInputBorder(),
                        helperText:
                            'Enter the number of animals in this record',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter total figure';
                        final value = int.tryParse(v);
                        if (value == null || value < 1) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    /// Cost & Currency
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _initialCostController,
                            decoration: InputDecoration(
                              labelText: 'Purchase / Initial Cost',
                              prefixText: _currencyController.text.trim().isNotEmpty
                                  ? '${_currencyController.text.trim()} '
                                  : r'$ ',
                              border: const OutlineInputBorder(),
                              helperText: 'Initial cost for profit/loss calculation',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. ZAR, R, USD',
                              helperText: 'Code / Symbol',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick currency chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Quick pick: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ...['ZAR', 'USD', 'KES', 'NGN', 'EUR', 'GBP'].map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(c, style: const TextStyle(fontSize: 11)),
                                selected: _currencyController.text.trim().toUpperCase() == c,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _currencyController.text = c);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional notes',
                        border: const OutlineInputBorder(),
                        helperText: widget.registrationMode == 'birth'
                            ? 'Add any details about the birth entry'
                            : widget.registrationMode == 'purchase'
                            ? 'Add any details about the purchase entry'
                            : 'Birth, purchase, or other notes',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    /// Sex
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedSex = v;
                          if (v == 'Mixed') {
                            _updateTotalFromMixed();
                          }
                        });
                      },
                      validator: (v) => v == null ? 'Select sex' : null,
                    ),
                    if (_selectedSex == 'Mixed') ...[
                      const SizedBox(height: 12),
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
                            const Text(
                              'Specify Mixed Counts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _maleCountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Males',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.male, color: Colors.blue),
                                      helperText: 'Number of males',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => _updateTotalFromMixed(),
                                    validator: (v) {
                                      if (_selectedSex == 'Mixed') {
                                        final males = int.tryParse(v ?? '') ?? 0;
                                        final females = int.tryParse(_femaleCountController.text.trim()) ?? 0;
                                        if (males <= 0 && females <= 0) {
                                          return 'Enter males';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _femaleCountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Females',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.female, color: Colors.pink),
                                      helperText: 'Used for milk production',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => _updateTotalFromMixed(),
                                    validator: (v) {
                                      if (_selectedSex == 'Mixed') {
                                        final females = int.tryParse(v ?? '') ?? 0;
                                        final males = int.tryParse(_maleCountController.text.trim()) ?? 0;
                                        if (males <= 0 && females <= 0) {
                                          return 'Enter females';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    /// ✅ PURPOSE (NEW)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder(),
                        helperText: 'Primary purpose of this animal',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'meat',
                          child: Text('Meat Production'),
                        ),
                        DropdownMenuItem(
                          value: 'dairy',
                          child: Text('Dairy/Milk Production'),
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
                          value: 'work',
                          child: Text('Work/Draft'),
                        ),
                        DropdownMenuItem(
                          value: 'pet',
                          child: Text('Pet/Companion'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedPurpose = v),
                      validator: (v) => v == null ? 'Select purpose' : null,
                    ),
                    const SizedBox(height: 16),

                    /// Photo
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
                        if (_selectedImagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImagePath!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// Save
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Animal',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
