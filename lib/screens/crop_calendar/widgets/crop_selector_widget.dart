import 'package:flutter/material.dart';
import '../../../models/crop_calendar/crop_calendar_models.dart';

class CropSelectorWidget extends StatefulWidget {
  final List<HorticulturalCrop> crops;
  final HorticulturalCrop selectedCrop;
  final CropVariety? selectedVariety;
  final ValueChanged<HorticulturalCrop> onCropSelected;
  final ValueChanged<CropVariety?> onVarietySelected;

  const CropSelectorWidget({
    super.key,
    required this.crops,
    required this.selectedCrop,
    required this.selectedVariety,
    required this.onCropSelected,
    required this.onVarietySelected,
  });

  @override
  State<CropSelectorWidget> createState() => _CropSelectorWidgetState();
}

class _CropSelectorWidgetState extends State<CropSelectorWidget> {
  CropCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCrops = widget.crops.where((c) {
      final matchesCategory =
          _selectedCategory == null || c.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.selectedCrop.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What are you growing?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.selectedCrop.name} (${widget.selectedCrop.standardMaturityDaysMin}–${widget.selectedCrop.standardMaturityDaysMax} days)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(null, 'All Horticultural'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(CropCategory.vegetable, '🥬 Vegetables'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                      CropCategory.rootAndTuber, '🥔 Root & Tubers'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(CropCategory.herb, '🌿 Herbs'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search box
            TextField(
              decoration: InputDecoration(
                hintText: 'Search vegetable, tuber, or herb...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),

            const SizedBox(height: 12),

            // Horizontal Crops List / Grid
            SizedBox(
              height: 90,
              child: filteredCrops.isEmpty
                  ? Center(
                      child: Text(
                        'No crops found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredCrops.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final crop = filteredCrops[index];
                        final isSelected = crop.id == widget.selectedCrop.id;

                        return InkWell(
                          onTap: () {
                            widget.onCropSelected(crop);
                            widget.onVarietySelected(
                              crop.varieties.isNotEmpty
                                  ? crop.varieties.first
                                  : null,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 85,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green.shade700
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  crop.iconEmoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  crop.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Variety Selector
            Text(
              'Select Variety / Maturity Class',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),

            if (widget.selectedCrop.varieties.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Using general crop maturity range (${widget.selectedCrop.standardMaturityDaysMin}–${widget.selectedCrop.standardMaturityDaysMax} days).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: widget.selectedVariety?.id ??
                    widget.selectedCrop.varieties.first.id,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  ...widget.selectedCrop.varieties.map((v) {
                    return DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(
                        '${v.name} (${v.maturityDaysMin}–${v.maturityDaysMax} days)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                ],
                onChanged: (id) {
                  if (id != null) {
                    final selected = widget.selectedCrop.varieties.firstWhere(
                      (v) => v.id == id,
                    );
                    widget.onVarietySelected(selected);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(CropCategory? category, String label) {
    final isSelected = _selectedCategory == category;
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
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = category);
        }
      },
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
