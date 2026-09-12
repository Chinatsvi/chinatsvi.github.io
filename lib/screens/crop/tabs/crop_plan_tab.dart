import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/services/crop/crop_management_service.dart';

class CropPlanTab extends StatelessWidget {
  final CropPlan plan;

  const CropPlanTab({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Crop Information',
              [
                _buildInfoRow('Crop Name', plan.cropName),
                if (plan.variety != null) _buildInfoRow('Variety', plan.variety!),
                if (plan.purpose != null) _buildInfoRow('Purpose', plan.purpose!),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Field Information',
              [
                _buildInfoRow('Field Name/Location', plan.fieldName),
                if (plan.fieldSize != null)
                  _buildInfoRow(
                    'Field Size',
                    '${plan.fieldSize} ${plan.fieldSizeUnit ?? 'units'}',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Timeline',
              [
                _buildInfoRow(
                  'Planting Date',
                  _formatDate(plan.plantingDate),
                ),
                if (plan.expectedHarvestDate != null)
                  _buildInfoRow(
                    'Expected Harvest',
                    _formatDate(plan.expectedHarvestDate!),
                  ),
                _buildInfoRow(
                  'Created',
                  _formatDate(plan.createdAt),
                ),
              ],
            ),
            if (plan.notes != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Notes',
                [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(plan.notes!),
                  ),
                ],
              ),
            ],
            // ── Native Ad: after plan details ──
            const FarmNativeAd(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEditDialog(context),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Crop Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditCropPlanDialog(plan: plan),
      ),
    );
  }
}

class EditCropPlanDialog extends StatefulWidget {
  final CropPlan plan;

  const EditCropPlanDialog({super.key, required this.plan});

  @override
  State<EditCropPlanDialog> createState() => _EditCropPlanDialogState();
}

class _EditCropPlanDialogState extends State<EditCropPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _cropNameController = TextEditingController(text: widget.plan.cropName);
  late final _varietyController = TextEditingController(text: widget.plan.variety ?? '');
  late final _fieldNameController = TextEditingController(text: widget.plan.fieldName);
  late final _fieldSizeController = TextEditingController(
    text: widget.plan.fieldSize?.toString() ?? '',
  );
  late final _purposeController = TextEditingController(text: widget.plan.purpose ?? '');
  late final _notesController = TextEditingController(text: widget.plan.notes ?? '');
  late DateTime _plantingDate = widget.plan.plantingDate;
  late DateTime? _expectedHarvestDate = widget.plan.expectedHarvestDate;
  late String _fieldSizeUnit = widget.plan.fieldSizeUnit ?? 'acres';
  bool _isLoading = false;

  final _service = CropManagementService();

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
      initialDate: _expectedHarvestDate ?? _plantingDate.add(const Duration(days: 90)),
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
      final updatedPlan = widget.plan.copyWith(
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
      );

      await _service.updateCropPlan(updatedPlan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop plan updated successfully!'),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                  Icon(Icons.edit, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Crop Plan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildSectionTitle('Crop Information'),
                      TextFormField(
                        controller: _cropNameController,
                        decoration: const InputDecoration(
                          labelText: 'Crop Name *',
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
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Purpose (Optional)',
                          prefixIcon: Icon(Icons.flag),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Field Information'),
                      TextFormField(
                        controller: _fieldNameController,
                        decoration: const InputDecoration(
                          labelText: 'Field Name/Location *',
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
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              keyboardType: TextInputType.number,
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
                                  .map((unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      ))
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
                      _buildSectionTitle('Timeline'),
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.green.shade700),
                        title: const Text('Planting Date *'),
                        subtitle: Text('${_plantingDate.day}/${_plantingDate.month}/${_plantingDate.year}'),
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
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Notes'),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Additional information...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
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
                              : const Text('Save Changes', style: TextStyle(fontSize: 16)),
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
      },
    );
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
}

