import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

enum FlockType { layer, broiler }

class PoultryFeedingScreen extends StatefulWidget {
  final String batchId;
  final PoultryRepository repository;
  final DateTime startDate; // flock start date for advisory
  final FlockType flockType;
  final int? flockSize; // Needed for broilers if no egg production

  const PoultryFeedingScreen({
    super.key,
    required this.batchId,
    required this.repository,
    required this.startDate,
    required this.flockType,
    this.flockSize,
  });

  @override
  State<PoultryFeedingScreen> createState() => _PoultryFeedingScreenState();
}

class _PoultryFeedingScreenState extends State<PoultryFeedingScreen> {
  List<PoultryFeedingRecord> _entries = [];
  int? _detectedFlockSize;
  String? _flockBreed;
  int? _batchAgeWeeks;
  DateTime? _batchStartDate;
  String? _batchCurrency;
  bool _isLoading = true;
  String _historyFilter = 'all'; // 'all', 'feeding', 'stock'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final feedList = await widget.repository.getFeedingRecords(
        widget.batchId,
      );

      // Try to read canonical batch counts, breed, and accurate start date from Firestore
      try {
        final batchDoc = await FirebaseFirestore.instance
            .collection('poultry_batches')
            .doc(widget.batchId)
            .get();
        if (batchDoc.exists) {
          final data = batchDoc.data() as Map<String, dynamic>;
          _detectedFlockSize =
              (data['currentCount'] ?? data['initialCount']) as int?;
          _flockBreed = data['breed'] as String?;
          _batchAgeWeeks = (data['ageWeeks'] as num?)?.toInt();
          if (data['startDate'] != null) {
            _batchStartDate = (data['startDate'] as Timestamp).toDate();
          }
          _batchCurrency = data['currency'] as String?;
        }
      } catch (_) {
        // ignore batch read errors
      }

      // Fallback check to animals collection if needed
      if (_detectedFlockSize == null || _detectedFlockSize! <= 0 || _flockBreed == null) {
        try {
          final animalDoc = await FirebaseFirestore.instance
              .collection('animals')
              .doc(widget.batchId)
              .get();
          if (animalDoc.exists) {
            final data = animalDoc.data() as Map<String, dynamic>;
            if (_detectedFlockSize == null || _detectedFlockSize! <= 0) {
              _detectedFlockSize =
                  (data['totalCount'] ?? data['initialFlockSize']) as int?;
            }
            if (_flockBreed == null || _flockBreed!.isEmpty) {
              _flockBreed = (data['breed'] ?? data['species']) as String?;
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          // Sort newest first
          feedList.sort((a, b) => b.date.compareTo(a.date));
          _entries = feedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  String get currencySymbol =>
      (_batchCurrency != null && _batchCurrency!.trim().isNotEmpty)
          ? _batchCurrency!.trim()
          : Formatter.currencySymbol;

  int get liveFlockCount {
    if (_detectedFlockSize != null && _detectedFlockSize! > 0) {
      return _detectedFlockSize!;
    }
    if (widget.flockSize != null && widget.flockSize! > 0) {
      return widget.flockSize!;
    }
    return 1;
  }

  String get displayBreed {
    if (_flockBreed != null && _flockBreed!.trim().isNotEmpty) {
      return _flockBreed!.trim();
    }
    return widget.flockType == FlockType.layer ? 'Layers' : 'Broilers';
  }

  int get currentAgeDays {
    final effectiveStart = _batchStartDate ?? widget.startDate;
    final elapsedDays = DateTime.now().difference(effectiveStart).inDays;
    final initialDays =
        (_batchAgeWeeks != null && _batchStartDate == null)
            ? (_batchAgeWeeks! * 7)
            : 0;
    final total = initialDays + elapsedDays;
    return total < 1 ? 1 : total;
  }

  int get currentAgeWeeks => (currentAgeDays / 7).floor();

  /* ───────────────────── FEED TYPE NORMALIZATION ───────────────────── */

  String _normalizeFeedType(String raw) {
    final clean = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (clean == 'starter' || clean == 'starter mash') return 'Starter Mash';
    if (clean == 'grower' || clean == 'grower_mash' || clean == 'grower mash') return 'Grower Mash';
    if (clean == 'finisher' || clean == 'finisher_mash' || clean == 'finisher mash') return 'Finisher Mash';
    if (clean == 'layer' || clean == 'layer_mash' || clean == 'layer mash') return 'Layer Mash';
    if (clean == 'broiler starter') return 'Broiler Starter';
    if (clean == 'broiler grower') return 'Broiler Grower';
    if (clean == 'broiler finisher') return 'Broiler Finisher';

    // Capitalize each word
    return raw.split(' ').map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  List<String> get _standardFeedTypes {
    if (widget.flockType == FlockType.layer) {
      return ['Starter Mash', 'Grower Mash', 'Layer Mash', 'Finisher Mash'];
    } else {
      return ['Starter Mash', 'Grower Mash', 'Layer Mash', 'Finisher Mash', 'Broiler Starter', 'Broiler Grower', 'Broiler Finisher'];
    }
  }

  /* ───────────────────── STOCK INVENTORY CALCULATIONS ───────────────────── */

  Map<String, double> get _stockAddedMap {
    final map = <String, double>{};
    for (final e in _entries) {
      if (e.isStockAddition) {
        final type = _normalizeFeedType(e.feedType);
        map[type] = (map[type] ?? 0.0) + e.quantityKg;
      }
    }
    return map;
  }

  Map<String, double> get _stockFedMap {
    final map = <String, double>{};
    for (final e in _entries) {
      if (!e.isStockAddition) {
        final type = _normalizeFeedType(e.feedType);
        map[type] = (map[type] ?? 0.0) + e.quantityKg;
      }
    }
    return map;
  }

  Map<String, double> get _stockRemainingMap {
    final map = <String, double>{};
    final allTypes = <String>{..._standardFeedTypes, ..._stockAddedMap.keys, ..._stockFedMap.keys};
    for (final type in allTypes) {
      final added = _stockAddedMap[type] ?? 0.0;
      final fed = _stockFedMap[type] ?? 0.0;
      map[type] = added - fed;
    }
    return map;
  }

  /// List of feed types to display in stock cards
  List<String> get _displayStockTypes {
    final types = <String>{};
    // Prioritize standard types that match flock
    if (widget.flockType == FlockType.layer) {
      types.addAll(['Starter Mash', 'Grower Mash', 'Layer Mash']);
    } else {
      types.addAll(['Starter Mash', 'Grower Mash', 'Finisher Mash']);
    }
    // Add any types that have been added or fed
    for (final key in _stockAddedMap.keys) {
      types.add(key);
    }
    for (final key in _stockFedMap.keys) {
      types.add(key);
    }
    return types.toList();
  }

  /* ───────────────────── RECOMMENDED FEED ADVISORY ───────────────────── */

  List<double> _recommendedRangeKgPerBirdPerDay() {
    final ageDays = currentAgeDays;

    if (widget.flockType == FlockType.broiler) {
      if (ageDays <= 7) return [0.015, 0.025]; // 15 - 25g (Week 1)
      if (ageDays <= 14) return [0.030, 0.050]; // 30 - 50g (Week 2)
      if (ageDays <= 21) return [0.050, 0.080]; // 50 - 80g (Week 3)
      if (ageDays <= 28) return [0.080, 0.120]; // 80 - 120g (Week 4)
      if (ageDays <= 35) return [0.120, 0.155]; // 120 - 155g (Week 5)
      if (ageDays <= 42) return [0.155, 0.185]; // 155 - 185g (Week 6)
      if (ageDays <= 56) return [0.180, 0.210]; // 180 - 210g (Weeks 7-8)
      return [0.190, 0.230]; // 190 - 230g
    }

    // Layers
    if (ageDays <= 7) return [0.010, 0.018];
    if (ageDays <= 14) return [0.018, 0.028];
    if (ageDays <= 28) return [0.028, 0.042];
    if (ageDays <= 56) return [0.042, 0.060];
    if (ageDays <= 98) return [0.060, 0.085];
    if (ageDays <= 126) return [0.085, 0.105];
    return [0.110, 0.130]; // 110 - 130g (Active laying)
  }

  /* ───────────────────── 1. ADD FEED TO STOCK DIALOG ───────────────────── */

  Future<void> _showAddFeedToStockDialog() async {
    final formKey = GlobalKey<FormState>();
    String selectedFeedType = _standardFeedTypes.first;
    String unit = 'bags'; // 'bags' or 'kg'
    final qtyCtrl = TextEditingController();
    final bagSizeCtrl = TextEditingController(text: '50');
    final costCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double qtyVal = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
          final double bagSizeVal = double.tryParse(bagSizeCtrl.text.trim()) ?? 50.0;
          final double calculatedKg = unit == 'bags' ? (qtyVal * bagSizeVal) : qtyVal;
          final double calculatedBags = unit == 'kg' && bagSizeVal > 0 ? (qtyVal / bagSizeVal) : qtyVal;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Feed to Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Record feed purchased or received',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Feed Type Dropdown
                    const Text(
                      'Feed Type',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFeedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      items: _standardFeedTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedFeedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Unit Selection Toggle
                    Row(
                      children: [
                        const Text(
                          'Unit:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Bags'),
                          selected: unit == 'bags',
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: unit == 'bags' ? Colors.green.shade900 : Colors.black87,
                            fontWeight: unit == 'bags' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => unit = 'bags');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Kilograms (kg)'),
                          selected: unit == 'kg',
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: unit == 'kg' ? Colors.green.shade900 : Colors.black87,
                            fontWeight: unit == 'kg' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => unit = 'kg');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quantity and Bag Size Fields
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit == 'bags' ? 'Quantity (bags)' : 'Quantity (kg)',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: qtyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: unit == 'bags' ? 'e.g. 5' : 'e.g. 250',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (_) => setModalState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter quantity';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'Enter valid amount';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (unit == 'bags') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bag size',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: bagSizeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    suffixText: 'kg',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final num = double.tryParse(v.trim());
                                    if (num == null || num <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Calculation Summary Banner
                    if (qtyVal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calculate_outlined, size: 18, color: Colors.green.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                unit == 'bags'
                                    ? '$qtyVal bags × ${bagSizeVal.toStringAsFixed(0)} kg = ${calculatedKg.toStringAsFixed(1)} kg total'
                                    : '${calculatedKg.toStringAsFixed(1)} kg = ${(calculatedBags).toStringAsFixed(1)} bags (${bagSizeVal.toStringAsFixed(0)} kg/bag)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Cost Field
                    const Text(
                      'Total Cost',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: '$currencySymbol ',
                        hintText: 'e.g. 2500',
                        helperText: 'Recorded here for Profit & Loss financial tracking',
                        helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date Received',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Change Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final costVal = double.tryParse(costCtrl.text.trim());
                          final id = 'stock_${DateTime.now().millisecondsSinceEpoch}';
                          final record = PoultryFeedingRecord(
                            id: id,
                            batchId: widget.batchId,
                            date: selectedDate,
                            feedType: selectedFeedType,
                            quantityKg: calculatedKg,
                            cost: costVal,
                            recordType: 'stock_addition',
                            bagsCount: unit == 'bags' ? qtyVal : calculatedBags,
                            bagSizeKg: bagSizeVal,
                            unit: unit,
                            notes: unit == 'bags'
                                ? 'Purchased ${qtyVal.toStringAsFixed(0)} bags (${calculatedKg.toStringAsFixed(1)} kg)'
                                : 'Purchased ${calculatedKg.toStringAsFixed(1)} kg',
                          );

                          try {
                            await widget.repository.addFeedingRecord(record);
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add feed to stock: $e')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Save to Stock',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feed successfully added to stock!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /* ───────────────────── 2. RECORD DAILY FEEDING DIALOG ───────────────────── */

  Future<void> _showRecordDailyFeedingDialog() async {
    final formKey = GlobalKey<FormState>();
    String selectedFeedType = _standardFeedTypes.first;
    String unit = 'bags'; // 'bags' or 'kg'
    final qtyCtrl = TextEditingController();
    final bagSizeCtrl = TextEditingController(text: '50');
    DateTime selectedDate = DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double qtyVal = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
          final double bagSizeVal = double.tryParse(bagSizeCtrl.text.trim()) ?? 50.0;
          final double calculatedKg = unit == 'bags' ? (qtyVal * bagSizeVal) : qtyVal;
          final double calculatedBags = unit == 'kg' && bagSizeVal > 0 ? (qtyVal / bagSizeVal) : qtyVal;
          final double currentStockKg = _stockRemainingMap[selectedFeedType] ?? 0.0;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.restaurant_outlined,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Record Daily Feeding',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Record feed given to birds today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Feed Type Dropdown
                    const Text(
                      'Feed Type',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFeedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      items: _standardFeedTypes.map((type) {
                        final remKg = _stockRemainingMap[type] ?? 0.0;
                        final remBags = (remKg / 50.0);
                        final stockLabel = remKg > 0
                            ? ' ($remKg kg / ${remBags.toStringAsFixed(1)} bags in stock)'
                            : ' (0 in stock)';
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            '$type$stockLabel',
                            style: const TextStyle(fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedFeedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Unit Toggle
                    Row(
                      children: [
                        const Text(
                          'Unit:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Bags'),
                          selected: unit == 'bags',
                          selectedColor: Colors.amber.shade100,
                          labelStyle: TextStyle(
                            color: unit == 'bags' ? Colors.amber.shade900 : Colors.black87,
                            fontWeight: unit == 'bags' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => unit = 'bags');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Kilograms (kg)'),
                          selected: unit == 'kg',
                          selectedColor: Colors.amber.shade100,
                          labelStyle: TextStyle(
                            color: unit == 'kg' ? Colors.amber.shade900 : Colors.black87,
                            fontWeight: unit == 'kg' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => unit = 'kg');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quantity Given
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit == 'bags' ? 'Quantity given (bags)' : 'Quantity given (kg)',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: qtyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: unit == 'bags' ? 'e.g. 1' : 'e.g. 50',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (_) => setModalState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter quantity given';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'Enter valid amount';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (unit == 'bags') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bag size',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: bagSizeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    suffixText: 'kg',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live preview & stock impact banner
                    if (qtyVal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                                const SizedBox(width: 6),
                                Text(
                                  unit == 'bags'
                                      ? '$qtyVal bag (${calculatedKg.toStringAsFixed(1)} kg) will be deducted from $selectedFeedType stock'
                                      : '${calculatedKg.toStringAsFixed(1)} kg will be deducted from $selectedFeedType stock',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock after feeding: ${(currentStockKg - calculatedKg).toStringAsFixed(1)} kg (${((currentStockKg - calculatedKg) / 50).toStringAsFixed(1)} bags)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: (currentStockKg - calculatedKg) < 0 ? Colors.red.shade700 : Colors.brown.shade700,
                                fontWeight: (currentStockKg - calculatedKg) < 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Date Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Feeding Date',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Change Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final id = 'feed_${DateTime.now().millisecondsSinceEpoch}';
                          final record = PoultryFeedingRecord(
                            id: id,
                            batchId: widget.batchId,
                            date: selectedDate,
                            feedType: selectedFeedType,
                            quantityKg: calculatedKg,
                            cost: null, // DO NOT ask for feed cost here!
                            recordType: 'daily_feeding',
                            bagsCount: unit == 'bags' ? qtyVal : calculatedBags,
                            bagSizeKg: bagSizeVal,
                            unit: unit,
                            notes: unit == 'bags'
                                ? 'Fed ${qtyVal.toStringAsFixed(0)} bags (${calculatedKg.toStringAsFixed(1)} kg)'
                                : 'Fed ${calculatedKg.toStringAsFixed(1)} kg',
                          );

                          try {
                            await widget.repository.addFeedingRecord(record);
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to record feeding: $e')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Record Daily Feeding',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Daily feeding recorded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /* ───────────────────── DELETE RECORD ───────────────────── */

  Future<void> _deleteRecord(PoultryFeedingRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete this ${record.isStockAddition ? "stock addition" : "daily feeding"} record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('poultry_feeding_records')
            .doc(record.id)
            .delete();
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  /* ───────────────────── UI BUILD ───────────────────── */

  @override
  Widget build(BuildContext context) {
    final flock = liveFlockCount;
    final breed = displayBreed;
    final weeks = currentAgeWeeks;

    final range = _recommendedRangeKgPerBirdPerDay();
    final minGrams = (range[0] * 1000).round();
    final maxGrams = (range[1] * 1000).round();
    final recMinFlockKg = (flock * range[0]).toStringAsFixed(2);
    final recMaxFlockKg = (flock * range[1]).toStringAsFixed(2);

    // Today's daily feedings
    final now = DateTime.now();
    final todayFeedings = _entries.where((e) {
      if (e.isStockAddition) return false;
      return e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day;
    }).toList();

    final latestFeeding = todayFeedings.isNotEmpty
        ? todayFeedings.first
        : _entries.where((e) => !e.isStockAddition).firstOrNull;

    // Filtered history list
    final filteredHistory = _entries.where((e) {
      if (_historyFilter == 'feeding') return !e.isStockAddition;
      if (_historyFilter == 'stock') return e.isStockAddition;
      return true;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // ── 1. Top Flock Information Card ──
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade800,
                            Colors.green.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$flock Birds · $breed · $weeks weeks',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Age: $currentAgeDays days (${widget.flockType == FlockType.layer ? "Layer Flock" : "Broiler Flock"})',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 2. Two Clear Action Buttons ──
                  Row(
                    children: [
                      // Button 1: Add Feed to Stock
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.add_shopping_cart, color: Colors.green.shade800, size: 19),
                          label: Text(
                            '+ Add Feed\nto Stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              height: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            side: BorderSide(color: Colors.green.shade700, width: 1.6),
                            backgroundColor: Colors.green.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _showAddFeedToStockDialog,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Button 2: Record Daily Feeding
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.restaurant, color: Colors.white, size: 19),
                          label: const Text(
                            '+ Record Daily\nFeeding',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            backgroundColor: Colors.amber.shade800,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _showRecordDailyFeedingDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Low Stock Warning Banners ──
                  ..._displayStockTypes.map((type) {
                    final remKg = _stockRemainingMap[type] ?? 0.0;
                    final remBags = remKg / 50.0;
                    final remBagsStr = remBags % 1 == 0 ? '${remBags.toInt()}' : remBags.toStringAsFixed(1);
                    final remKgStr = remKg % 1 == 0 ? '${remKg.toInt()}' : remKg.toStringAsFixed(1);

                    // If running low (1 bag or less remaining)
                    if (remKg > 0 && remKg <= 50.0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '⚠️ $type running low — $remBagsStr bag remaining ($remKgStr kg)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (remKg <= 0 && (_stockAddedMap[type] ?? 0) > 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade900, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '⚠️ $type is out of stock (0 kg remaining)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // ── 4. Daily Feeding Card & Advisory ──
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Title / Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.today, color: Colors.amber.shade900, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    todayFeedings.isNotEmpty
                                        ? 'Today — ${_normalizeFeedType(todayFeedings.first.feedType)}'
                                        : (latestFeeding != null
                                            ? 'Latest Feeding — ${_normalizeFeedType(latestFeeding.feedType)}'
                                            : 'Daily Feeding Status'),
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              if (todayFeedings.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Logged Today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 18),

                          // Given and Stock Remaining details
                          if (latestFeeding != null) ...[
                            Builder(
                              builder: (context) {
                                final normType = _normalizeFeedType(latestFeeding.feedType);
                                final double givenKg = latestFeeding.quantityKg;
                                final double givenBags = latestFeeding.bagsCount ?? (givenKg / 50.0);
                                final String givenBagsStr = givenBags % 1 == 0
                                    ? '${givenBags.toInt()} bag${givenBags == 1 ? "" : "s"}'
                                    : '${givenBags.toStringAsFixed(1)} bags';

                                final double remKg = _stockRemainingMap[normType] ?? 0.0;
                                final double remBags = remKg / 50.0;
                                final String remBagsStr = remBags % 1 == 0
                                    ? '${remBags.toInt()} bag${remBags == 1 ? "" : "s"}'
                                    : '${remBags.toStringAsFixed(1)} bags';
                                final String remKgStr = remKg % 1 == 0 ? '${remKg.toInt()}' : remKg.toStringAsFixed(1);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Given: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '$givenBagsStr (${givenKg.toStringAsFixed(1)} kg)',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          'Stock remaining: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '$remBagsStr ($remKgStr kg)',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: remKg <= 0
                                                ? Colors.red.shade700
                                                : (remKg <= 50 ? Colors.orange.shade800 : Colors.green.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'No daily feeding recorded yet today.\nTap "+ Record Daily Feeding" to log.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Feeding Guide Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueGrey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.blueGrey.shade800),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Feeding Guide:',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$flock birds · $minGrams–$maxGrams g/bird/day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Recommended for flock: $recMinFlockKg–$recMaxFlockKg kg/day',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '* The recommendation is advice only. Record what you actually feed.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 5. Stock Cards ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Feed Stock Inventory',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _showAddFeedToStockDialog,
                        child: const Text('+ Add Stock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  ..._displayStockTypes.map((type) {
                    final remKg = _stockRemainingMap[type] ?? 0.0;
                    final remBags = remKg / 50.0;
                    final remBagsStr = remBags % 1 == 0
                        ? '${remBags.toInt()} bag${remBags == 1 ? "" : "s"}'
                        : '${remBags.toStringAsFixed(1)} bags';
                    final remKgStr = remKg % 1 == 0 ? '${remKg.toInt()}' : remKg.toStringAsFixed(1);
                    final isLow = remKg > 0 && remKg <= 50.0;
                    final isOut = remKg <= 0 && (_stockAddedMap[type] ?? 0) > 0;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isOut
                              ? Colors.red.shade300
                              : (isLow ? Colors.orange.shade300 : Colors.grey.shade200),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOut
                              ? Colors.red.shade50
                              : (isLow ? Colors.orange.shade50 : Colors.green.shade50),
                          child: Icon(
                            Icons.inventory_2,
                            color: isOut
                                ? Colors.red.shade700
                                : (isLow ? Colors.orange.shade800 : Colors.green.shade700),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          remKg > 0
                              ? 'Remaining: $remBagsStr ($remKgStr kg)'
                              : (isOut ? 'Out of stock (0 kg)' : 'No stock added yet'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isOut
                                ? Colors.red.shade700
                                : (isLow ? Colors.orange.shade900 : Colors.grey.shade700),
                            fontWeight: isLow || isOut ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOut
                                ? Colors.red.shade50
                                : (isLow ? Colors.orange.shade50 : Colors.green.shade50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOut
                                  ? Colors.red.shade200
                                  : (isLow ? Colors.orange.shade200 : Colors.green.shade200),
                            ),
                          ),
                          child: Text(
                            remKg > 0 ? '$remKgStr kg' : '0 kg',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isOut
                                  ? Colors.red.shade900
                                  : (isLow ? Colors.orange.shade900 : Colors.green.shade900),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // ── 6. Activity & History Section ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${filteredHistory.length} records',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _historyFilter == 'all',
                          selectedColor: Colors.green.shade100,
                          onSelected: (s) {
                            if (s) setState(() => _historyFilter = 'all');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Daily Feedings'),
                          selected: _historyFilter == 'feeding',
                          selectedColor: Colors.amber.shade100,
                          onSelected: (s) {
                            if (s) setState(() => _historyFilter = 'feeding');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Stock Additions'),
                          selected: _historyFilter == 'stock',
                          selectedColor: Colors.blue.shade100,
                          onSelected: (s) {
                            if (s) setState(() => _historyFilter = 'stock');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (filteredHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 42, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            Text(
                              'No records found for this filter.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredHistory.map((e) {
                      final isStock = e.isStockAddition;
                      final type = _normalizeFeedType(e.feedType);
                      final bags = e.bagsCount ?? (e.quantityKg / 50.0);
                      final bagsStr = bags % 1 == 0 ? '${bags.toInt()} bags' : '${bags.toStringAsFixed(1)} bags';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0.8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isStock ? Colors.blue.shade50 : Colors.amber.shade50,
                            child: Icon(
                              isStock ? Icons.inventory_2_outlined : Icons.restaurant,
                              color: isStock ? Colors.blue.shade700 : Colors.amber.shade800,
                              size: 19,
                            ),
                          ),
                          title: Text(
                            isStock
                                ? '+ $type • ${e.quantityKg.toStringAsFixed(1)} kg ($bagsStr)'
                                : '$type • ${e.quantityKg.toStringAsFixed(1)} kg ($bagsStr)',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            '${isStock ? "Stock Purchase" : "Daily Feeding"} · ${DateFormat('dd MMM yyyy').format(e.date)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isStock && e.cost != null && e.cost! > 0)
                                Text(
                                  '$currencySymbol${e.cost!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.grey.shade500, size: 20),
                                onPressed: () => _deleteRecord(e),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 12),
                  const FarmNativeAd(),
                  const SizedBox(height: 70),
                ],
              ),
            ),
    );
  }
}
