import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/milk_production_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';

class MilkProductionScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;

  const MilkProductionScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<MilkProductionScreen> createState() => _MilkProductionScreenState();
}

class _MilkProductionScreenState extends State<MilkProductionScreen> {
  List<MilkProductionRecord> _records = [];
  List<ExitRecord> _exitRecords = [];
  bool _loading = true;
  String _chartMetric = 'yield'; // 'yield', 'split', 'revenue'
  int _chartDays = 14; // 7, 14, 30, 0 (all)
  late TrackballBehavior _trackballBehavior;
  String _selectedCattle = 'All';

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        format: 'point.x: point.y',
      ),
    );
    FarmInterstitialAd.preload();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rawList = await widget.repository.listMilkProductionRecords(widget.animal.id);
      rawList.sort((a, b) => b.date.compareTo(a.date));
      final exitList = await widget.repository.listExitRecords(widget.animal.id);

      if (mounted) {
        setState(() {
          _records = rawList;
          _exitRecords = exitList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading milk records: $e')),
        );
      }
    }
  }

  int get _activeFemales => widget.animal.totalFemales;

  Set<String> get _exitedCattleTags {
    return _exitRecords
        .map((e) => e.animalTag?.trim())
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  Set<String> get _cattleList {
    final recordedTags = _records
        .map((r) => r.cowIdentifier?.trim())
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet();
    final registeredTags = widget.animal.animalTags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    return {...registeredTags, ...recordedTags};
  }

  List<MilkProductionRecord> get _filteredRecords {
    if (_selectedCattle == 'All') return _records;
    return _records.where((r) => (r.cowIdentifier ?? 'Herd Total').trim() == _selectedCattle).toList();
  }

  double get _totalLitersProduced =>
      _filteredRecords.fold<double>(0.0, (sum, r) => sum + r.totalLiters);

  double get _totalLitersSold =>
      _filteredRecords.fold<double>(0.0, (sum, r) => sum + r.litersSold);

  double get _totalLitersConsumed =>
      _filteredRecords.fold<double>(0.0, (sum, r) => sum + r.litersConsumed);

  double get _totalSpoilageLiters =>
      _filteredRecords.fold<double>(0.0, (sum, r) => sum + r.litersSpoiled);

  double get _totalRevenue =>
      _filteredRecords.fold<double>(0.0, (sum, r) => sum + (r.revenue ?? 0.0));

  /// Remaining milk available in stock
  double get _availableStock {
    final stock = _totalLitersProduced - _totalLitersSold - _totalLitersConsumed - _totalSpoilageLiters;
    return stock < 0 ? 0.0 : stock;
  }

  List<MilkProductionRecord> get _chartRecords {
    final sorted = List<MilkProductionRecord>.from(_filteredRecords)
      ..sort((a, b) => a.date.compareTo(b.date));
    if (_chartDays == 0 || sorted.length <= _chartDays) {
      return sorted;
    }
    return sorted.sublist(sorted.length - _chartDays);
  }

  MilkProductionRecord? _findRecordForDate(DateTime date, [String? cattleId]) {
    final requestedTag = cattleId?.trim().toLowerCase();
    try {
      return _records.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day &&
            (r.cowIdentifier?.trim().toLowerCase() == requestedTag),
      );
    } catch (_) {
      return null;
    }
  }

  MilkProductionRecord? get _todayRecord => _findRecordForDate(DateTime.now());

  double get _averageYieldPerFemale {
    if (_filteredRecords.isEmpty || _activeFemales <= 0) return 0.0;
    return _totalLitersProduced / (_filteredRecords.length * _activeFemales);
  }

  /* ───────────────────── ADD / EDIT COLLECTION ───────────────────── */

  Future<void> _addOrEditRecord([
    MilkProductionRecord? existing,
    DateTime? initialDate,
    bool focusEvening = false,
  ]) async {
    DateTime selectedDate = initialDate ?? existing?.date ?? DateTime.now();
    MilkProductionRecord? targetRecord = existing;

    final cowIdentifierCtrl = TextEditingController(text: targetRecord?.cowIdentifier ?? '');
    final morningCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.morningLiters > 0
          ? targetRecord.morningLiters.toString()
          : '',
    );
    final eveningCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.eveningLiters > 0
          ? targetRecord.eveningLiters.toString()
          : '',
    );
    final totalCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.totalLiters > 0
          ? targetRecord.totalLiters.toString()
          : '',
    );
    final femalesMilkedCtrl = TextEditingController(
      text: (targetRecord?.milkingFemalesCount ?? (_activeFemales > 0 ? _activeFemales : 1)).toString(),
    );
    final soldCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.litersSold > 0
          ? targetRecord.litersSold.toString()
          : '',
    );
    final priceCtrl = TextEditingController(
      text: targetRecord?.pricePerLiter != null
          ? targetRecord!.pricePerLiter.toString()
          : '',
    );
    final consumedCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.litersConsumed > 0
          ? targetRecord.litersConsumed.toString()
          : '',
    );
    final spoiledCtrl = TextEditingController(
      text: targetRecord != null && targetRecord.litersSpoiled > 0
          ? targetRecord.litersSpoiled.toString()
          : '',
    );
    final spoiledCostCtrl = TextEditingController(
      text: targetRecord?.spoiledCost != null
          ? targetRecord!.spoiledCost.toString()
          : '',
    );
    final notesCtrl = TextEditingController(text: targetRecord?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    void populateForDate(DateTime newDate, StateSetter setDialogState) {
      selectedDate = newDate;
      targetRecord = _findRecordForDate(newDate, cowIdentifierCtrl.text.trim().isNotEmpty ? cowIdentifierCtrl.text.trim() : null);
      if (targetRecord != null) {
        cowIdentifierCtrl.text = targetRecord!.cowIdentifier ?? '';
        morningCtrl.text = targetRecord!.morningLiters > 0 ? targetRecord!.morningLiters.toString() : '';
        eveningCtrl.text = targetRecord!.eveningLiters > 0 ? targetRecord!.eveningLiters.toString() : '';
        totalCtrl.text = targetRecord!.totalLiters.toString();
        femalesMilkedCtrl.text = (targetRecord!.milkingFemalesCount ?? _activeFemales).toString();
        soldCtrl.text = targetRecord!.litersSold > 0 ? targetRecord!.litersSold.toString() : '';
        priceCtrl.text = targetRecord!.pricePerLiter != null ? targetRecord!.pricePerLiter.toString() : '';
        consumedCtrl.text = targetRecord!.litersConsumed > 0 ? targetRecord!.litersConsumed.toString() : '';
        spoiledCtrl.text = targetRecord!.litersSpoiled > 0 ? targetRecord!.litersSpoiled.toString() : '';
        spoiledCostCtrl.text = targetRecord!.spoiledCost != null ? targetRecord!.spoiledCost.toString() : '';
        notesCtrl.text = targetRecord!.notes ?? '';
      }
      setDialogState(() {});
    }

    void updateTotal(StateSetter setDialogState) {
      final m = double.tryParse(morningCtrl.text.trim()) ?? 0.0;
      final e = double.tryParse(eveningCtrl.text.trim()) ?? 0.0;
      final tot = m + e;
      if (tot > 0) {
        totalCtrl.text = tot % 1 == 0 ? tot.toInt().toString() : tot.toStringAsFixed(1);
      }
      setDialogState(() {});
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sold = double.tryParse(soldCtrl.text.trim()) ?? 0.0;
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final calcRevenue = sold * price;
            final hasExisting = targetRecord != null;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    hasExisting ? Icons.edit_note : Icons.add_circle_outline,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasExisting ? 'Update Milk Record' : 'Log Milk Collection',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today, color: Colors.blue),
                          title: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            hasExisting
                                ? 'Existing record loaded • Update values'
                                : 'Select collection date',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasExisting ? Colors.green.shade800 : Colors.blue.shade800,
                              fontWeight: hasExisting ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (picked != null) {
                              populateForDate(picked, setDialogState);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cow / Cattle Tag Identifier
                      TextFormField(
                        controller: cowIdentifierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cattle Tag / Cow Identifier (optional)',
                          hintText: 'e.g. Cattle A, Cattle 1, Cow #12',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pets, color: Colors.green),
                          helperText: 'Tag individual cattle to monitor per-cow yield drops',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ...[..._cattleList, 'Herd Total'].map(
                            (tag) => ActionChip(
                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                              onPressed: () {
                                cowIdentifierCtrl.text = tag;
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Morning and Evening Yield
                      const Text(
                        'Milking Sessions (Liters)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: morningCtrl,
                              autofocus: !focusEvening,
                              decoration: InputDecoration(
                                labelText: 'Morning (L)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                                filled: true,
                                fillColor: Colors.orange.shade50.withValues(alpha: 0.3),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              onChanged: (_) => updateTotal(setDialogState),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: eveningCtrl,
                              autofocus: focusEvening,
                              decoration: InputDecoration(
                                labelText: 'Evening (L)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.nightlight_outlined, color: Colors.indigo),
                                filled: true,
                                fillColor: Colors.indigo.shade50.withValues(alpha: 0.3),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              onChanged: (_) => updateTotal(setDialogState),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Liters & Milking Females
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: totalCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Total Yield (L)*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              validator: (v) {
                                final val = double.tryParse(v ?? '');
                                if (val == null || val <= 0) return 'Enter total yield';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: femalesMilkedCtrl,
                              decoration: InputDecoration(
                                labelText: 'Females Milked',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.female, color: Colors.pink),
                                helperText: 'Active: $_activeFemales',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.remove_circle_outline, size: 16, color: Colors.amber.shade900),
                                const SizedBox(width: 6),
                                Text(
                                  'Milk Used & Deductions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: consumedCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Calf Feeding / Home Consumption (L)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_cafe_outlined, color: Colors.brown),
                                helperText: 'Liters used on farm',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: spoiledCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Spoiled / Wasted (L)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.warning_amber_outlined, color: Colors.red),
                                      helperText: 'Liters lost',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: spoiledCostCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Spoil Cost (${widget.animal.currencySymbol})',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.money_off, color: Colors.red),
                                      helperText: 'Counted in profit & loss',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monetization_on_outlined, size: 16, color: Colors.green.shade900),
                                const SizedBox(width: 6),
                                Text(
                                  'Direct Sale (Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: soldCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Liters Sold',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.sell_outlined, color: Colors.green),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: priceCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Price/Liter (${widget.animal.currencySymbol})',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            if (calcRevenue > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Calculated Revenue: ${widget.animal.formatMoney(calcRevenue)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final morning = double.tryParse(morningCtrl.text.trim()) ?? 0.0;
                    final evening = double.tryParse(eveningCtrl.text.trim()) ?? 0.0;
                    final females = int.tryParse(femalesMilkedCtrl.text.trim()) ?? _activeFemales;
                    final sold = double.tryParse(soldCtrl.text.trim()) ?? 0.0;
                    final price = double.tryParse(priceCtrl.text.trim());
                    final consumed = double.tryParse(consumedCtrl.text.trim()) ?? 0.0;
                    final spoiled = double.tryParse(spoiledCtrl.text.trim()) ?? 0.0;
                    final spoiledCost = double.tryParse(spoiledCostCtrl.text.trim()) ??
                        ((price != null && price > 0 && spoiled > 0) ? (spoiled * price) : null);
                    final notes = notesCtrl.text.trim();
                    final cowTag = cowIdentifierCtrl.text.trim();
                    final matchingRecord = targetRecord ??
                      _findRecordForDate(
                        selectedDate,
                        cowTag.isEmpty ? null : cowTag,
                      );
                    final isMergingNewEntry =
                      targetRecord == null && matchingRecord != null;
                    final mergedMorning = isMergingNewEntry && morningCtrl.text.trim().isEmpty
                      ? matchingRecord.morningLiters
                      : morning;
                    final mergedEvening = isMergingNewEntry && eveningCtrl.text.trim().isEmpty
                      ? matchingRecord.eveningLiters
                      : evening;
                    final mergedSold = isMergingNewEntry && soldCtrl.text.trim().isEmpty
                      ? matchingRecord.litersSold
                      : sold;
                    final mergedConsumed = isMergingNewEntry && consumedCtrl.text.trim().isEmpty
                      ? matchingRecord.litersConsumed
                      : consumed;
                    final mergedSpoiled = isMergingNewEntry && spoiledCtrl.text.trim().isEmpty
                      ? matchingRecord.litersSpoiled
                      : spoiled;
                    final mergedSpoiledCost = isMergingNewEntry && spoiledCostCtrl.text.trim().isEmpty
                      ? matchingRecord.spoiledCost
                      : spoiledCost;
                    final mergedNotes = isMergingNewEntry && notes.isEmpty
                      ? matchingRecord.notes
                      : (notes.isNotEmpty ? notes : null);

                    final newRecord = MilkProductionRecord(
                      id: matchingRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: widget.animal.id,
                      date: selectedDate,
                      cowIdentifier: cowTag.isNotEmpty ? cowTag : null,
                      morningLiters: mergedMorning,
                      eveningLiters: mergedEvening,
                      totalLiters: mergedMorning + mergedEvening,
                      litersSold: mergedSold,
                      pricePerLiter: price ?? matchingRecord?.pricePerLiter,
                      revenue: (price ?? matchingRecord?.pricePerLiter) != null
                        ? mergedSold * (price ?? matchingRecord!.pricePerLiter!)
                        : null,
                      litersConsumed: mergedConsumed,
                      litersSpoiled: mergedSpoiled,
                      spoiledCost: mergedSpoiledCost,
                      milkingFemalesCount: females > 0 ? females : null,
                      notes: mergedNotes,
                      createdAt: matchingRecord?.createdAt ?? DateTime.now(),
                    );

                    if (matchingRecord != null) {
                      await widget.repository.updateMilkProductionRecord(newRecord);
                    } else {
                      await widget.repository.addMilkProductionRecord(newRecord);
                    }

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(
                    hasExisting ? 'Save Changes' : 'Log Collection',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk production record saved!')),
        );
      }
    }
  }

  /* ───────────────────── SELL MILK FROM STOCK ───────────────────── */

  Future<void> _sellMilkFromStock([MilkProductionRecord? targetRecord]) async {
    DateTime saleDate = targetRecord?.date ?? DateTime.now();
    final soldCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: targetRecord?.pricePerLiter != null ? targetRecord!.pricePerLiter.toString() : '',
    );
    final buyerNotesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sold = double.tryParse(soldCtrl.text.trim()) ?? 0.0;
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final revenue = sold * price;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.point_of_sale, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Text('Sell Milk from Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _availableStock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _availableStock > 0 ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available Milk in Stock', style: TextStyle(fontSize: 11, color: Colors.black54)),
                            Text(
                              '${_availableStock.toStringAsFixed(1)} Liters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _availableStock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: Colors.blue),
                        title: Text(
                          '${saleDate.day}/${saleDate.month}/${saleDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Sale Date'),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: saleDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setDialogState(() => saleDate = picked);
                          }
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: soldCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Liters to Sell*',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                          helperText: 'Max available: ${_availableStock.toStringAsFixed(1)} L',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'Enter liters to sell';
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      if (_availableStock > 0)
                        Wrap(
                          spacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('5 L', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                soldCtrl.text = '5';
                                setDialogState(() {});
                              },
                            ),
                            ActionChip(
                              label: const Text('10 L', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                soldCtrl.text = '10';
                                setDialogState(() {});
                              },
                            ),
                            ActionChip(
                              label: const Text('All Stock', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                soldCtrl.text = _availableStock % 1 == 0
                                    ? _availableStock.toInt().toString()
                                    : _availableStock.toStringAsFixed(1);
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: priceCtrl,
                        decoration: InputDecoration(
                          labelText: 'Price per Liter (${widget.animal.currencySymbol})*',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'Enter price per liter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      if (revenue > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Total Sale Revenue: ${widget.animal.formatMoney(revenue)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: buyerNotesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buyer Name / Receipt Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final sold = double.tryParse(soldCtrl.text.trim()) ?? 0.0;
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final notes = buyerNotesCtrl.text.trim();

                    if (targetRecord != null) {
                      final rec = targetRecord;
                      final updated = rec.copyWith(
                        litersSold: rec.litersSold + sold,
                        pricePerLiter: price,
                        revenue: (rec.revenue ?? 0.0) + (sold * price),
                        notes: notes.isNotEmpty
                            ? (rec.notes != null ? '${rec.notes}; Sold $sold L to $notes' : 'Sold $sold L to $notes')
                            : rec.notes,
                      );
                      await widget.repository.updateMilkProductionRecord(updated);
                    } else {
                      final existingDay = _findRecordForDate(saleDate);
                      if (existingDay != null) {
                        final updated = existingDay.copyWith(
                          litersSold: existingDay.litersSold + sold,
                          pricePerLiter: price,
                          revenue: (existingDay.revenue ?? 0.0) + (sold * price),
                          notes: notes.isNotEmpty
                              ? (existingDay.notes != null ? '${existingDay.notes}; Sold $sold L to $notes' : 'Sold $sold L to $notes')
                              : existingDay.notes,
                        );
                        await widget.repository.updateMilkProductionRecord(updated);
                      } else {
                        final newRec = MilkProductionRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          animalId: widget.animal.id,
                          date: saleDate,
                          litersSold: sold,
                          pricePerLiter: price,
                          revenue: sold * price,
                          notes: notes.isNotEmpty ? 'Sold $sold L to $notes' : null,
                          createdAt: DateTime.now(),
                        );
                        await widget.repository.addMilkProductionRecord(newRec);
                      }
                    }

                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Confirm Sale', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk sale recorded successfully!')),
        );
      }
    }
  }

  /* ───────────────────── LOG SPOILAGE / LOSS ───────────────────── */

  Future<void> _logConsumedMilk() async {
    DateTime useDate = DateTime.now();
    final usedCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final tagCtrl = TextEditingController(
      text: _selectedCattle == 'All' ? '' : _selectedCattle,
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.local_cafe_outlined, color: Colors.brown.shade700),
              const SizedBox(width: 8),
              const Text('Log Used Milk', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.brown.shade50,
                    child: Text(
                      'Available Stock: ${_availableStock.toStringAsFixed(1)} L',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cattle Tag (optional)',
                      hintText: 'e.g. Cattle A or Herd Total',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pets),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: usedCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Liters Used*',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.local_cafe_outlined, color: Colors.brown),
                      helperText: 'Maximum: ${_availableStock.toStringAsFixed(1)} L',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (_) => setDialogState(() {}),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) return 'Enter liters used';
                      if (amount > _availableStock) return 'Exceeds available stock';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Used for (optional)',
                      hintText: 'Calves, home use, tea, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: Text('${useDate.day}/${useDate.month}/${useDate.year}'),
                    subtitle: const Text('Usage date'),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: useDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setDialogState(() => useDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final used = double.tryParse(usedCtrl.text.trim()) ?? 0.0;
                final tag = tagCtrl.text.trim();
                final existing = _findRecordForDate(useDate, tag.isEmpty ? null : tag);
                if (existing != null) {
                  await widget.repository.updateMilkProductionRecord(
                    existing.copyWith(
                      litersConsumed: existing.litersConsumed + used,
                      notes: notesCtrl.text.trim().isEmpty
                          ? existing.notes
                          : '${existing.notes == null ? '' : '${existing.notes}; '}Used $used L: ${notesCtrl.text.trim()}',
                    ),
                  );
                } else {
                  await widget.repository.addMilkProductionRecord(
                    MilkProductionRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: widget.animal.id,
                      date: useDate,
                      cowIdentifier: tag.isEmpty ? null : tag,
                      litersConsumed: used,
                      notes: notesCtrl.text.trim().isEmpty ? null : 'Used: ${notesCtrl.text.trim()}',
                      createdAt: DateTime.now(),
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save Used Milk', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Used milk recorded and stock updated')),
        );
      }
    }
  }

  Future<void> _logSpoilage([MilkProductionRecord? targetRecord]) async {
    DateTime spoilDate = targetRecord?.date ?? DateTime.now();
    final spoiledCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Record Milk Spoilage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Available Stock: ${_availableStock.toStringAsFixed(1)} Liters',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: Colors.red),
                        title: Text('${spoilDate.day}/${spoilDate.month}/${spoilDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Incident Date'),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: spoilDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setDialogState(() => spoilDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: spoiledCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Spoiled Liters*',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning_amber_outlined, color: Colors.red),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) return 'Enter spoiled liters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: costCtrl,
                        decoration: InputDecoration(
                          labelText: 'Estimated Spoilage Cost / Loss (${widget.animal.currencySymbol})',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.money_off, color: Colors.red),
                          helperText: 'Will count as production cost in Profit & Loss tab',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason (e.g. power outage, souring, contamination)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final spoiled = double.tryParse(spoiledCtrl.text.trim()) ?? 0.0;
                    final cost = double.tryParse(costCtrl.text.trim());
                    final reason = reasonCtrl.text.trim();

                    if (targetRecord != null) {
                      final rec = targetRecord;
                      final updated = rec.copyWith(
                        litersSpoiled: rec.litersSpoiled + spoiled,
                        spoiledCost: (rec.spoiledCost ?? 0.0) + (cost ?? 0.0),
                        notes: reason.isNotEmpty
                            ? (rec.notes != null ? '${rec.notes}; Spoiled: $reason' : 'Spoiled: $reason')
                            : rec.notes,
                      );
                      await widget.repository.updateMilkProductionRecord(updated);
                    } else {
                      final newRec = MilkProductionRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        animalId: widget.animal.id,
                        date: spoilDate,
                        litersSpoiled: spoiled,
                        spoiledCost: cost,
                        notes: reason.isNotEmpty ? 'Spoiled: $reason' : null,
                        createdAt: DateTime.now(),
                      );
                      await widget.repository.addMilkProductionRecord(newRec);
                    }

                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Record Spoilage', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spoilage recorded and stock updated')),
        );
      }
    }
  }

  Future<void> _deleteRecord(MilkProductionRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text('Delete milk collection for ${record.date.day}/${record.date.month}/${record.date.year}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteMilkProductionRecord(widget.animal.id, record.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted')),
        );
      }
    }
  }

  /* ───────────────────── PDF EXPORT ───────────────────── */

  Future<void> _exportPdf() async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Milk Production Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              '${widget.animal.species} • ${widget.animal.breed} (Active Females: $_activeFemales)',
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (_) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _pdfCell('Date', bold: true),
                  _pdfCell('Cattle Tag', bold: true),
                  _pdfCell('Morning (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Evening (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Yield (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Calf/Home (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Spoiled (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Sold (L)', bold: true, align: pw.TextAlign.right),
                  _pdfCell('Revenue', bold: true, align: pw.TextAlign.right),
                ],
              ),
              ..._filteredRecords.map(
                (r) => pw.TableRow(
                  children: [
                    _pdfCell('${r.date.day}/${r.date.month}/${r.date.year}'),
                    _pdfCell(r.cowIdentifier ?? 'Herd'),
                    _pdfCell(r.morningLiters > 0 ? r.morningLiters.toStringAsFixed(1) : '-', align: pw.TextAlign.right),
                    _pdfCell(r.eveningLiters > 0 ? r.eveningLiters.toStringAsFixed(1) : '-', align: pw.TextAlign.right),
                    _pdfCell(r.totalLiters.toStringAsFixed(1), align: pw.TextAlign.right),
                    _pdfCell(r.litersConsumed > 0 ? r.litersConsumed.toStringAsFixed(1) : '-', align: pw.TextAlign.right),
                    _pdfCell(r.litersSpoiled > 0 ? r.litersSpoiled.toStringAsFixed(1) : '-', align: pw.TextAlign.right),
                    _pdfCell(r.litersSold > 0 ? r.litersSold.toStringAsFixed(1) : '-', align: pw.TextAlign.right),
                    _pdfCell(r.revenue != null ? widget.animal.formatMoney(r.revenue!) : '-', align: pw.TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'milk_production_report.pdf',
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayRec = _todayRecord;
    final todayYield = todayRec?.totalLiters ?? 0.0;
    final todayMorning = todayRec?.morningLiters ?? 0.0;
    final todayEvening = todayRec?.eveningLiters ?? 0.0;
    final milkingRate = _activeFemales > 0
        ? (((todayRec?.milkingFemalesCount ?? _activeFemales) / _activeFemales) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.lightBlue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
                              radius: 20,
                              child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Milk Production', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryStat(
                          label: "Today's Yield",
                          value: '${todayYield.toStringAsFixed(1)} L',
                          subtitle: 'M: ${todayMorning.toStringAsFixed(1)} | E: ${todayEvening.toStringAsFixed(1)}',
                          color: Colors.blue.shade800,
                        ),
                        _summaryStat(
                          label: 'Available Stock',
                          value: '${_availableStock.toStringAsFixed(1)} L',
                          subtitle: 'Net available',
                          color: _availableStock > 0 ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                        _summaryStat(
                          label: 'Total Revenue',
                          value: widget.animal.formatMoney(_totalRevenue),
                          subtitle: '${_totalLitersSold.toStringAsFixed(1)} L sold',
                          color: Colors.teal.shade800,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _miniCard(
                            icon: Icons.percent,
                            label: 'Milking Rate',
                            value: '${milkingRate.toStringAsFixed(0)}%',
                            color: Colors.indigo.shade800,
                            bgColor: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniCard(
                            icon: Icons.trending_up,
                            label: 'Avg/Female',
                            value: '${_averageYieldPerFemale.toStringAsFixed(1)} L',
                            color: Colors.teal.shade800,
                            bgColor: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniCard(
                            icon: Icons.local_cafe_outlined,
                            label: 'Home/Calf',
                            value: '${_totalLitersConsumed.toStringAsFixed(1)} L',
                            color: Colors.brown.shade800,
                            bgColor: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _miniCard(
                            icon: Icons.warning_amber_outlined,
                            label: 'Spoiled',
                            value: '${_totalSpoilageLiters.toStringAsFixed(1)} L',
                            color: Colors.red.shade800,
                            bgColor: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_cattleList.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Filter Cattle: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('All Herd', style: TextStyle(fontSize: 11)),
                        selected: _selectedCattle == 'All',
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedCattle = 'All');
                        },
                      ),
                    ),
                    ..._cattleList.map(
                      (c) {
                        final isExited = _exitedCattleTags.contains(c);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              isExited ? '$c (Exited)' : c,
                              style: TextStyle(
                                fontSize: 11,
                                color: isExited ? Colors.grey.shade800 : null,
                                fontStyle: isExited ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                            selected: _selectedCattle == c,
                            selectedColor: isExited ? Colors.amber.shade100 : Colors.green.shade100,
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedCattle = c);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.show_chart, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedCattle == 'All' ? 'Production Trends' : 'Trend: $_selectedCattle',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              _chartMetric == 'yield'
                                  ? 'Daily milk collection (Liters)'
                                  : _chartMetric == 'split'
                                      ? 'Morning vs Evening collections'
                                      : 'Daily milk sales revenue',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        DropdownButton<int>(
                          value: _chartDays,
                          isDense: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.calendar_month, size: 18, color: Colors.green),
                          items: const [
                            DropdownMenuItem(value: 7, child: Text('7 Days', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 14, child: Text('14 Days', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 30, child: Text('30 Days', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 0, child: Text('All Time', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _chartDays = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Total Yield (L)', style: TextStyle(fontSize: 11)),
                            selected: _chartMetric == 'yield',
                            selectedColor: Colors.green.shade100,
                            onSelected: (_) => setState(() => _chartMetric = 'yield'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Morning vs Evening', style: TextStyle(fontSize: 11)),
                            selected: _chartMetric == 'split',
                            selectedColor: Colors.orange.shade100,
                            onSelected: (_) => setState(() => _chartMetric = 'split'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text('Revenue (${widget.animal.currencySymbol})', style: const TextStyle(fontSize: 11)),
                            selected: _chartMetric == 'revenue',
                            selectedColor: Colors.teal.shade100,
                            onSelected: (_) => setState(() => _chartMetric = 'revenue'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_chartRecords.isNotEmpty)
                      SizedBox(
                        height: 240,
                        child: SfCartesianChart(
                          plotAreaBorderWidth: 0,
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat.MMMd(),
                            majorGridLines: const MajorGridLines(width: 0),
                            axisLine: const AxisLine(width: 1, color: Colors.grey),
                          ),
                          primaryYAxis: NumericAxis(
                            title: AxisTitle(
                              text: _chartMetric == 'revenue'
                                  ? 'Revenue (${widget.animal.currencySymbol})'
                                  : 'Liters (L)',
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          trackballBehavior: _trackballBehavior,
                          series: _chartMetric == 'yield'
                              ? <CartesianSeries<MilkProductionRecord, DateTime>>[
                                  SplineAreaSeries<MilkProductionRecord, DateTime>(
                                    name: 'Milk Yield (L)',
                                    dataSource: _chartRecords,
                                    xValueMapper: (r, _) => r.date,
                                    yValueMapper: (r, _) => r.totalLiters,
                                    color: Colors.green.shade600.withValues(alpha: 0.35),
                                    borderColor: Colors.green.shade700,
                                    borderWidth: 2,
                                  ),
                                ]
                              : _chartMetric == 'split'
                                  ? <CartesianSeries<MilkProductionRecord, DateTime>>[
                                      SplineSeries<MilkProductionRecord, DateTime>(
                                        name: 'Morning (L)',
                                        dataSource: _chartRecords,
                                        xValueMapper: (r, _) => r.date,
                                        yValueMapper: (r, _) => r.morningLiters,
                                        color: Colors.orange.shade700,
                                      ),
                                      SplineSeries<MilkProductionRecord, DateTime>(
                                        name: 'Evening (L)',
                                        dataSource: _chartRecords,
                                        xValueMapper: (r, _) => r.date,
                                        yValueMapper: (r, _) => r.eveningLiters,
                                        color: Colors.indigo.shade600,
                                      ),
                                    ]
                                  : <CartesianSeries<MilkProductionRecord, DateTime>>[
                                      ColumnSeries<MilkProductionRecord, DateTime>(
                                        name: 'Revenue',
                                        dataSource: _chartRecords,
                                        xValueMapper: (r, _) => r.date,
                                        yValueMapper: (r, _) => r.revenue ?? 0.0,
                                        color: Colors.teal.shade600,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ],
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.show_chart, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'Log daily milk to see production trend graphs here',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_records.isNotEmpty) ...[
              FarmRewardedAdButton(
                label: 'Watch Ad & Export Milk PDF',
                icon: Icons.picture_as_pdf,
                color: Colors.blue.shade700,
                onRewarded: _exportPdf,
              ),
              const SizedBox(height: 16),
            ],
            _buildMilkActionBanner(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collection History (${_filteredRecords.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditRecord(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_filteredRecords.isEmpty)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(Icons.water_drop_outlined, size: 54, color: Colors.blue.shade200),
                      const SizedBox(height: 12),
                      const Text(
                        'No milk records logged yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredRecords.map((r) {
                final dateStr = '${r.date.day}/${r.date.month}/${r.date.year}';
                final yieldPerFemale = r.averageYieldPerFemale(_activeFemales);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  radius: 18,
                                  child: Icon(Icons.water_drop, color: Colors.blue.shade800, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (r.cowIdentifier != null && r.cowIdentifier!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.green.shade300),
                                            ),
                                            child: Text(
                                              r.cowIdentifier!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${r.milkingFemalesCount ?? _activeFemales} females • ${yieldPerFemale.toStringAsFixed(1)} L/female',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _addOrEditRecord(r, r.date);
                                } else if (val == 'sell') {
                                  _sellMilkFromStock(r);
                                } else if (val == 'spoilage') {
                                  _logSpoilage(r);
                                } else if (val == 'delete') {
                                  _deleteRecord(r);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Record')),
                                const PopupMenuItem(value: 'sell', child: Text('Record Milk Sale')),
                                const PopupMenuItem(value: 'spoilage', child: Text('Log Spoilage')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _recordDetailItem('Morning', '${r.morningLiters.toStringAsFixed(1)} L', Icons.wb_sunny_outlined, Colors.orange),
                              _recordDetailItem('Evening', '${r.eveningLiters.toStringAsFixed(1)} L', Icons.nightlight_outlined, Colors.indigo),
                              _recordDetailItem('Total Yield', '${r.totalLiters.toStringAsFixed(1)} L', Icons.water_drop, Colors.blue.shade700),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            const FarmNativeAd(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMilkActionBanner() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.amber.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milk Stock Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _milkActionButton(
                    icon: Icons.add_circle,
                    label: 'Log Milk',
                    color: Colors.green.shade700,
                    onTap: _addOrEditRecord,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _milkActionButton(
                    icon: Icons.point_of_sale,
                    label: 'Sell Milk',
                    color: Colors.teal.shade700,
                    onTap: _sellMilkFromStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _milkActionButton(
                    icon: Icons.warning_amber,
                    label: 'Log Spoiled',
                    color: Colors.red.shade700,
                    onTap: _logSpoilage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _milkActionButton(
                    icon: Icons.local_cafe,
                    label: 'Log Used',
                    color: Colors.brown.shade700,
                    onTap: _logConsumedMilk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _milkActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _recordDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}
