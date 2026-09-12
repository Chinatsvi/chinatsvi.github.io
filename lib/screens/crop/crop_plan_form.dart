import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/services/crop/crop_management_service.dart';
import 'package:agribased/app/utils/formatters.dart';

class CropPlanForm extends StatefulWidget {
  final String farmerId;
  final ScrollController scrollController;
  final CropPlan? cropPlan; // If provided, form is in edit mode

  const CropPlanForm({
    super.key,
    required this.farmerId,
    required this.scrollController,
    this.cropPlan,
  });

  @override
  State<CropPlanForm> createState() => _CropPlanFormState();
}

class _CropPlanFormState extends State<CropPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _fieldNameController = TextEditingController();
  final _fieldSizeController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _plantingDate = DateTime.now();
  DateTime? _expectedHarvestDate;
  String _fieldSizeUnit = 'acres';
  String? _selectedCurrency;
  bool _isLoading = false;

  final _service = CropManagementService();

  bool get isEditMode => widget.cropPlan != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      // Pre-fill controllers with existing data
      final plan = widget.cropPlan!;
      _cropNameController.text = plan.cropName;
      _varietyController.text = plan.variety ?? '';
      _fieldNameController.text = plan.fieldName;
      _fieldSizeController.text = plan.fieldSize?.toString() ?? '';
      _purposeController.text = plan.purpose ?? '';
      _notesController.text = plan.notes ?? '';
      _plantingDate = plan.plantingDate;
      _expectedHarvestDate = plan.expectedHarvestDate;
      _fieldSizeUnit = plan.fieldSizeUnit ?? 'acres';
      _selectedCurrency = plan.currency;
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _varietyController.dispose();
    _fieldNameController.dispose();
    _fieldSizeController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Future<void> _selectPlantingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
    }
  }

  Future<void> _selectHarvestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expectedHarvestDate ?? _plantingDate.add(const Duration(days: 90)),
      firstDate: _plantingDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _expectedHarvestDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Apply selected currency globally for display/parsing (persisted)
      if (_selectedCurrency != null) {
        await Formatter.setCurrencySymbol(_selectedCurrency!);
      }

      final plan = CropPlan(
        id: isEditMode ? widget.cropPlan!.id : '',
        farmerId: widget.farmerId,
        cropName: _cropNameController.text.trim(),
        variety: _varietyController.text.trim().isNotEmpty
            ? _varietyController.text.trim()
            : null,
        fieldName: _fieldNameController.text.trim(),
        fieldSize: _fieldSizeController.text.isNotEmpty
            ? double.tryParse(_fieldSizeController.text)
            : null,
        fieldSizeUnit: _fieldSizeUnit,
        plantingDate: _plantingDate,
        expectedHarvestDate: _expectedHarvestDate,
        purpose: _purposeController.text.trim().isNotEmpty
            ? _purposeController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        currency: _selectedCurrency,
        createdAt: isEditMode ? widget.cropPlan!.createdAt : DateTime.now(),
      );

      if (isEditMode) {
        await _service.updateCropPlan(plan);
      } else {
        await _service.createCropPlan(plan);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop plan created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.spa, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                isEditMode ? 'Edit Crop Plan' : 'Register New Crop Plan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: widget.scrollController,
                children: [
                  // Crop Information Section
                  _buildSectionTitle('Crop Information'),
                  TextFormField(
                    controller: _cropNameController,
                    decoration: const InputDecoration(
                      labelText: 'Crop Name *',
                      hintText: 'e.g., Maize, Tomatoes, Beans',
                      prefixIcon: Icon(Icons.spa),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter crop name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _varietyController,
                    decoration: const InputDecoration(
                      labelText: 'Variety (Optional)',
                      hintText: 'e.g., SC 719, Roma VF',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose (Optional)',
                      hintText: 'e.g., Commercial sale, Household consumption',
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Currency selection
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency *',
                      prefixIcon: Icon(Icons.currency_exchange),
                      helperText: 'Select currency for budget calculations',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'R',
                        child: Text('South African Rand (R)'),
                      ),
                      DropdownMenuItem(
                        value: r'$',
                        child: Text('US Dollar (\$)'),
                      ),
                      DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                      DropdownMenuItem(
                        value: '£',
                        child: Text('Pound Sterling (£)'),
                      ),
                      DropdownMenuItem(
                        value: '₦',
                        child: Text('Nigerian Naira (₦)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedCurrency = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select currency' : null,
                  ),
                  const SizedBox(height: 24),

                  // Field Information Section
                  _buildSectionTitle('Field Information'),
                  TextFormField(
                    controller: _fieldNameController,
                    decoration: const InputDecoration(
                      labelText: 'Field Name/Location *',
                      hintText: 'e.g., Field A, Home Garden',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter field name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fieldSizeController,
                          decoration: const InputDecoration(
                            labelText: 'Field Size',
                            hintText: 'e.g., 2.5',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fieldSizeUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            prefixIcon: Icon(Icons.scale),
                          ),
                          items: ['acres', 'hectares', 'sq meters', 'plots']
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _fieldSizeUnit = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Timeline Section
                  _buildSectionTitle('Timeline'),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.green.shade700,
                    ),
                    title: const Text('Planting Date *'),
                    subtitle: Text(
                      '${_plantingDate.day}/${_plantingDate.month}/${_plantingDate.year}',
                    ),
                    trailing: TextButton(
                      onPressed: _selectPlantingDate,
                      child: const Text('Change'),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.event, color: Colors.green.shade700),
                    title: const Text('Expected Harvest Date'),
                    subtitle: Text(
                      _expectedHarvestDate != null
                          ? '${_expectedHarvestDate!.day}/${_expectedHarvestDate!.month}/${_expectedHarvestDate!.year}'
                          : 'Not set',
                    ),
                    trailing: TextButton(
                      onPressed: _selectHarvestDate,
                      child: const Text('Set'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes Section
                  _buildSectionTitle('Additional Notes'),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText:
                          'Any additional information about this crop plan...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditMode
                                  ? 'Update Crop Plan'
                                  : 'Create Crop Plan',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
