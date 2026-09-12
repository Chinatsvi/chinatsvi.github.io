import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/crop_calendar/crop_calendar_models.dart';

class GrowingConditionsWidget extends StatefulWidget {
  final ProductionSystem productionSystem;
  final WaterSource waterSource;
  final DateTime plantingDate;
  final String? soilType;
  final bool soilTestAvailable;
  final ValueChanged<ProductionSystem> onProductionSystemChanged;
  final ValueChanged<WaterSource> onWaterSourceChanged;
  final ValueChanged<DateTime> onPlantingDateChanged;
  final ValueChanged<String?> onSoilTypeChanged;
  final ValueChanged<bool> onSoilTestAvailableChanged;

  const GrowingConditionsWidget({
    super.key,
    required this.productionSystem,
    required this.waterSource,
    required this.plantingDate,
    required this.soilType,
    required this.soilTestAvailable,
    required this.onProductionSystemChanged,
    required this.onWaterSourceChanged,
    required this.onPlantingDateChanged,
    required this.onSoilTypeChanged,
    required this.onSoilTestAvailableChanged,
  });

  @override
  State<GrowingConditionsWidget> createState() =>
      _GrowingConditionsWidgetState();
}

class _GrowingConditionsWidgetState extends State<GrowingConditionsWidget> {
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.plantingDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onPlantingDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: Colors.green.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growing System & Schedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Customizes recommendations to your farm setup',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Production System
            const Text(
              'Production System',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSystemChip(
                  ProductionSystem.openField,
                  '🌾 Open Field',
                ),
                _buildSystemChip(
                  ProductionSystem.greenhouse,
                  '🏡 Greenhouse / Tunnel',
                ),
                _buildSystemChip(
                  ProductionSystem.shadeNet,
                  '🛡️ Shade Net',
                ),
                _buildSystemChip(
                  ProductionSystem.containerGarden,
                  '🪴 Backyard / Container',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Water Availability
            const Text(
              'Water Availability / Irrigation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildWaterChip(
                  WaterSource.irrigated,
                  '💧 Full Irrigation (Reliable)',
                ),
                _buildWaterChip(
                  WaterSource.limitedIrrigation,
                  '🚰 Supplementary / Limited',
                ),
                _buildWaterChip(
                  WaterSource.rainFed,
                  '🌧️ Rain-Fed (Rainfall only)',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Planting Date Picker
            const Text(
              'When do you plan to plant?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(widget.plantingDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const Text(
                            'Tap to change planting / sowing date',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar,
                      size: 20,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Optional Soil Details Accordion
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                title: Text(
                  '🌱 Soil Information (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: const Text(
                  'Soil type, drainage, and test status',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: widget.soilType,
                    decoration: const InputDecoration(
                      labelText: 'Soil Type',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sandy Loam',
                        child: Text('Sandy Loam (Well-drained)'),
                      ),
                      DropdownMenuItem(
                        value: 'Clay Loam',
                        child: Text('Clay Loam (Heavy, moisture retentive)'),
                      ),
                      DropdownMenuItem(
                        value: 'Red Clay',
                        child: Text('Red Fersiallitic Clay (Rich, deep)'),
                      ),
                      DropdownMenuItem(
                        value: 'Sandy',
                        child: Text('Sandy (Leaches nutrients quickly)'),
                      ),
                      DropdownMenuItem(
                        value: 'Black Cotton',
                        child: Text('Vertisol / Black Cotton (Poor drainage)'),
                      ),
                    ],
                    onChanged: widget.onSoilTypeChanged,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text(
                      'Have you completed a certified soil test?',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Provides verified nutrient and pH levels',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: widget.soilTestAvailable,
                    activeThumbColor: Colors.green.shade700,
                    onChanged: widget.onSoilTestAvailableChanged,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemChip(ProductionSystem system, String label) {
    final isSelected = widget.productionSystem == system;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) widget.onProductionSystemChanged(system);
      },
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildWaterChip(WaterSource water, String label) {
    final isSelected = widget.waterSource == water;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) widget.onWaterSourceChanged(water);
      },
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.grey.shade100,
    );
  }
}
