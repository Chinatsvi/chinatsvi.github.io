import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/models/crop/inventory_item.dart';
import 'package:agribased/services/crop/crop_management_service.dart';

class InventoryTab extends StatefulWidget {
  final CropPlan plan;
  final CropManagementService _service = CropManagementService();

  InventoryTab({super.key, required this.plan});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {

  String get _currency => widget.plan.currency ?? r'$';
  String _formatMoney(double amount) =>
      '$_currency${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      stream: widget._service.getInventory(widget.plan.farmerId, widget.plan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if any
        if (snapshot.hasError) {
          print('❌ [INVENTORY_TAB] Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Failed to load inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];
        print('🔍 [INVENTORY_TAB] Displaying ${items.length} items');

        if (items.isEmpty) {
          return _buildEmptyView(context);
        }

        return _buildInventoryView(context, items);
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Inventory Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add seeds, fertilizer, tools, and other items to track your farm inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 16),
            const FarmNativeAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryView(BuildContext context, List<InventoryItem> items) {
    // Group by category
    final categories = <String, List<InventoryItem>>{};
    for (final item in items) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Total Inventory Value',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatMoney(_calculateTotalValue(items)),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} items in stock',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Native Ad: after summary card ──
          const FarmNativeAd(),
          const SizedBox(height: 12),

          // Category sections
          ...categories.entries.map((entry) {
            return _buildCategorySection(entry.key, entry.value);
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<InventoryItem> items) {
    final categoryInfo = _getCategoryInfo(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(categoryInfo.icon, color: categoryInfo.color),
        title: Text(
          categoryInfo.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${items.length} items • ${_formatMoney(_calculateTotalValue(items))}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        children: items.map((item) => _buildItemTile(item)).toList(),
      ),
    );
  }

  Widget _buildItemTile(InventoryItem item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.brand != null) Text('Brand: ${item.brand}'),
          Text(
            '${item.formattedQuantityWithUnit} @ ${_formatMoney(item.costPerUnit)} each',
          ),
          if (item.expiryDate != null)
            Text(
              'Expires: ${_formatDate(item.expiryDate!)}',
              style: TextStyle(
                color: _isExpiringSoon(item.expiryDate!)
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatMoney(item.totalCost),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  double _calculateTotalValue(List<InventoryItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalCost);
  }

  _CategoryInfo _getCategoryInfo(String category) {
    switch (category.toLowerCase()) {
      case 'seeds':
        return _CategoryInfo('Seeds', Icons.grain, Colors.brown);
      case 'fertilizer':
        return _CategoryInfo('Fertilizer', Icons.local_florist, Colors.green);
      case 'tools':
        return _CategoryInfo('Tools', Icons.build, Colors.blue);
      case 'chemicals':
        return _CategoryInfo('Chemicals', Icons.science, Colors.purple);
      default:
        return _CategoryInfo('Other', Icons.inventory_2, Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isExpiringSoon(DateTime expiryDate) {
    final daysUntil = expiryDate.difference(DateTime.now()).inDays;
    return daysUntil <= 30 && daysUntil >= 0;
  }

  void _showAddItemDialog(BuildContext context) {
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
        child: AddInventoryItemDialog(
          farmerId: widget.plan.farmerId,
          cropPlanId: widget.plan.id,
          onItemAdded: () => setState(() {}),
        ),
      ),
    );
  }
}

class AddInventoryItemDialog extends StatefulWidget {
  final String farmerId;
  final String cropPlanId;
  final VoidCallback onItemAdded;

  const AddInventoryItemDialog({
    super.key,
    required this.farmerId,
    required this.cropPlanId,
    required this.onItemAdded,
  });

  @override
  State<AddInventoryItemDialog> createState() => _AddInventoryItemDialogState();
}

class _AddInventoryItemDialogState extends State<AddInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _supplierController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'units');
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'other';
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final _service = CropManagementService();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final costPerUnit = double.tryParse(_costController.text) ?? 0;

      final item = InventoryItem(
        id: '',
        farmerId: widget.farmerId,
        cropPlanId: widget.cropPlanId,
        category: _category,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
        quantity: quantity,
        unit: _unitController.text.trim(),
        costPerUnit: costPerUnit,
        totalCost: quantity * costPerUnit,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      await _service.addInventoryItem(item);
      widget.onItemAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory item added successfully!'),
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
                  Icon(Icons.inventory, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Add Inventory Item',
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
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'seeds', child: Text('Seeds')),
                          DropdownMenuItem(value: 'fertilizer', child: Text('Fertilizer')),
                          DropdownMenuItem(value: 'tools', child: Text('Tools')),
                          DropdownMenuItem(value: 'chemicals', child: Text('Chemicals')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand (Optional)',
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _supplierController,
                        decoration: const InputDecoration(
                          labelText: 'Supplier (Optional)',
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter unit';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost per Unit *',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter cost per unit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.green.shade700),
                        title: const Text('Purchase Date (Optional)'),
                        subtitle: Text(
                          _purchaseDate != null
                              ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                              : 'Not set',
                        ),
                        trailing: TextButton(
                          onPressed: _selectPurchaseDate,
                          child: const Text('Set'),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.event_busy, color: Colors.orange.shade700),
                        title: const Text('Expiry Date (Optional)'),
                        subtitle: Text(
                          _expiryDate != null
                              ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                              : 'Not set',
                        ),
                        trailing: TextButton(
                          onPressed: _selectExpiryDate,
                          child: const Text('Set'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
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
                              : const Text('Add Item', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
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
}

class _CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  _CategoryInfo(this.name, this.icon, this.color);
}

