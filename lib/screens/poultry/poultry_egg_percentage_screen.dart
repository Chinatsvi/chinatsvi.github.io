import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/egg_stock.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';

class PoultryEggPercentageScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryEggPercentageScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryEggPercentageScreen> createState() =>
      _PoultryEggPercentageScreenState();
}

class _PoultryEggPercentageScreenState
    extends State<PoultryEggPercentageScreen> {
  List<PoultryProductionRecord> _records = [];
  List<PoultryMortalityRecord> _mortality = [];
  List<PoultryExitRecord> _exits = [];
  List<EggStockTransaction> _stockTransactions = [];
  PoultryBatch? _batch;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    FarmInterstitialAd.preload();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prodList = await widget.repository.listPoultryProductionRecords(
        widget.animal.id,
      );
      final mortList = await widget.repository.listPoultryMortalityRecords(
        widget.animal.id,
      );
      final exitList = await widget.repository.getExitRecords(widget.animal.id);
      final stockList = await widget.repository.listEggStockTransactions(
        widget.animal.id,
      );
      final batchDoc = await FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(widget.animal.id)
          .get();

      setState(() {
        _records = prodList;
        _mortality = mortList;
        _exits = exitList;
        _stockTransactions = stockList;
        _batch = batchDoc.exists ? PoultryBatch.fromDocument(batchDoc) : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  int _currentFlockSize() {
    if (_batch != null && _batch!.currentCount > 0) {
      return _batch!.currentCount;
    }

    final totalDeaths = _mortality.fold<int>(0, (total, r) => total + r.deaths);
    final totalExited = _exits.fold<int>(0, (total, e) => total + e.quantity);
    return (widget.animal.initialFlockSize ?? 0) - totalDeaths - totalExited;
  }

  Future<void> _addEggCollection() async {
    final eggsCtrl = TextEditingController();
    final soldCtrl = TextEditingController();
    final brokenCtrl = TextEditingController();
    final revenueCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<PoultryProductionRecord>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Daily Egg Collection'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Collection Date'),
                subtitle: Text(
                  '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: eggsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eggs Collected',
                  border: OutlineInputBorder(),
                  helperText: 'Number of eggs collected today',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: soldCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eggs Sold',
                  border: OutlineInputBorder(),
                  helperText: 'Number of eggs sold today',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: brokenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Eggs Broken/Damaged',
                  border: OutlineInputBorder(),
                  helperText: 'Number of eggs broken or damaged',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: revenueCtrl,
                decoration: InputDecoration(
                  labelText: 'Revenue (${Formatter.currencySymbol}) - Optional',
                  border: const OutlineInputBorder(),
                  helperText: 'Total income from eggs sold',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final eggs = int.tryParse(eggsCtrl.text.trim());
              final sold = int.tryParse(soldCtrl.text.trim()) ?? 0;
              final broken = int.tryParse(brokenCtrl.text.trim()) ?? 0;

              if (eggs == null || eggs < 0) return;
              if (sold < 0 || broken < 0) return;
              if (sold + broken > eggs) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sold + broken eggs cannot exceed collected eggs',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final record = PoultryProductionRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                batchId: widget.animal.id,
                date: selectedDate,
                eggsCollected: eggs,
                eggsSold: sold,
                eggsBroken: broken,
                revenue: double.tryParse(revenueCtrl.text.trim()),
              );
              Navigator.pop(context, record);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await widget.repository.addPoultryProductionRecord(result);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Egg collection recorded successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving record: $e')));
        }
      }
    }
  }

  Future<void> _recordStockTransaction(String type) async {
    final quantityCtrl = TextEditingController();
    final revenueCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Get current stock summary first
    final summary = await widget.repository.calculateEggStockSummary(widget.animal.id);
    final availableStock = summary.totalAvailable;

    final result = await showDialog<EggStockTransaction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'sale' ? 'Sell Eggs from Stock' : 'Record Egg Breakage'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show available stock
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.egg, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Available Stock: $availableStock eggs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Transaction Date'),
                subtitle: Text(
                  '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityCtrl,
                decoration: InputDecoration(
                  labelText: type == 'sale' ? 'Eggs to Sell *' : 'Eggs Broken *',
                  border: const OutlineInputBorder(),
                  helperText: 'Number of eggs from stock',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (type == 'sale')
                TextField(
                  controller: revenueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Revenue (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Total income from sale',
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (type == 'sale') const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Customer name, reason for breakage',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityCtrl.text.trim());
              
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (quantity > availableStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot ${type == 'sale' ? 'sell' : 'record'} more than available stock ($availableStock eggs)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final transaction = EggStockTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                batchId: widget.animal.id,
                type: type,
                quantity: quantity,
                revenue: type == 'sale' 
                    ? double.tryParse(revenueCtrl.text.trim()) 
                    : null,
                transactionDate: selectedDate,
                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
              );
              Navigator.pop(context, transaction);
            },
            child: Text(type == 'sale' ? 'Sell' : 'Record'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await widget.repository.addEggStockTransaction(result);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                type == 'sale' 
                    ? 'Sold ${result.quantity} eggs from stock'
                    : 'Recorded ${result.quantity} broken eggs from stock',
              ),
              backgroundColor: type == 'sale' ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _updateEggSales(PoultryProductionRecord record) async {
    final soldCtrl = TextEditingController(text: record.eggsSold.toString());
    final brokenCtrl = TextEditingController(
      text: record.eggsBroken.toString(),
    );
    final revenueCtrl = TextEditingController(
      text: record.revenue?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Sales for ${record.date.day}-${record.date.month}-${record.date.year}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total collected: ${record.eggsCollected} eggs'),
            const SizedBox(height: 16),
            TextField(
              controller: soldCtrl,
              decoration: const InputDecoration(
                labelText: 'Eggs Sold',
                border: OutlineInputBorder(),
                helperText: 'Update number of eggs sold',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: brokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Eggs Broken/Damaged',
                border: OutlineInputBorder(),
                helperText: 'Update number of eggs broken',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: revenueCtrl,
              decoration: InputDecoration(
                labelText: 'Revenue (${Formatter.currencySymbol}) - Optional',
                border: const OutlineInputBorder(),
                helperText: 'Total income from eggs sold',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sold = int.tryParse(soldCtrl.text.trim()) ?? 0;
              final broken = int.tryParse(brokenCtrl.text.trim()) ?? 0;

              if (sold < 0 || broken < 0) return;
              if (sold + broken > record.eggsCollected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sold + broken eggs cannot exceed collected eggs',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedRecord = record.copyWith(
                eggsSold: sold,
                eggsBroken: broken,
                revenue: double.tryParse(revenueCtrl.text.trim()),
              );

              try {
                await widget.repository.updatePoultryProductionRecord(updatedRecord);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating record: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales record updated successfully')),
        );
      }
    }
  }

  String _advisoryNotes(double avgPercentage) {
    final totalEggs = _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    final totalSold = _records.fold<int>(0, (sum, r) => sum + r.eggsSold) +
      _stockTransactions
        .where((transaction) => transaction.type == 'sale')
        .fold<int>(0, (sum, transaction) => sum + transaction.quantity);
    final totalBroken =
      _records.fold<int>(0, (sum, r) => sum + r.eggsBroken) +
      _stockTransactions
        .where((transaction) => transaction.type == 'breakage')
        .fold<int>(0, (sum, transaction) => sum + transaction.quantity);

    String notes = 'Average egg laying: ${avgPercentage.toStringAsFixed(1)}%';

    if (avgPercentage < 50) {
      notes +=
          '\n⚠️ Low production. Review feed quality, lighting hours, and flock health.';
    } else if (avgPercentage < 80) {
      notes +=
          '\nℹ️ Moderate production. Monitor feed conversion and vaccination schedule.';
    } else {
      notes +=
          '\n✅ Excellent production. Keep feeding and housing strategy consistent.';
    }

    final currentFlock = _currentFlockSize();
    notes += '\n🐔 Current flock size: $currentFlock birds';

    // Sales and breakage analysis
    if (totalEggs > 0) {
      final salesPercentage = (totalSold / totalEggs * 100);
      final breakagePercentage = (totalBroken / totalEggs * 100);

      notes +=
          '\n💰 Sales rate: ${salesPercentage.toStringAsFixed(1)}% ($totalSold/$totalEggs eggs)';

      if (breakagePercentage > 5) {
        notes +=
            '\n⚠️ High breakage rate: ${breakagePercentage.toStringAsFixed(1)}% - Review handling procedures';
      } else if (breakagePercentage > 2) {
        notes +=
            '\nℹ️ Moderate breakage rate: ${breakagePercentage.toStringAsFixed(1)}%';
      } else {
        notes +=
            '\n✅ Low breakage rate: ${breakagePercentage.toStringAsFixed(1)}% - Excellent handling';
      }

      final availableEggs = totalEggs - totalSold - totalBroken;
      notes += '\n📦 Total Production eggs: $availableEggs';
    }

    return notes;
  }

  Future<void> _exportPdf() async {
    try {
      final currentFlock = _currentFlockSize();
      final avgPercentage = (_records.isEmpty || currentFlock <= 0)
          ? 0.0
          : _records.fold<double>(
                  0.0,
                  (sum, r) => sum + (r.eggsCollected / currentFlock * 100),
                ) /
                _records.length;
      final totalEggs = _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
      final totalSold = _records.fold<int>(0, (sum, r) => sum + r.eggsSold) +
          _stockTransactions
              .where((t) => t.type == 'sale')
              .fold<int>(0, (sum, t) => sum + t.quantity);
      final totalBroken = _records.fold<int>(0, (sum, r) => sum + r.eggsBroken) +
          _stockTransactions
              .where((t) => t.type == 'breakage')
              .fold<int>(0, (sum, t) => sum + t.quantity);
      final totalRevenue = _records.fold<double>(
            0.0,
            (sum, r) => sum + (r.revenue ?? 0.0),
          ) +
          _stockTransactions
              .where((t) => t.type == 'sale')
              .fold<double>(0.0, (sum, t) => sum + (t.revenue ?? 0.0));
      final availableStock = totalEggs - totalSold - totalBroken;
      final breakageRate = totalEggs > 0 ? (totalBroken / totalEggs * 100) : 0.0;
      final salesRate = totalEggs > 0 ? (totalSold / totalEggs * 100) : 0.0;

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AgriBase Poultry Management',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Egg Production & Sales Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Flock: ${widget.animal.breed} (${widget.animal.species}) | Flock Size: $currentFlock birds',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.green800, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => [
            // KPI Summary Cards
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green300, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfKpiItem('Avg Laying %', '${avgPercentage.toStringAsFixed(1)}%'),
                      _pdfKpiItem('Current Flock', '$currentFlock birds'),
                      _pdfKpiItem('Total Collected', '$totalEggs eggs'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.green200, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfKpiItem('Total Sold', '$totalSold eggs'),
                      _pdfKpiItem('Total Revenue', Formatter.formatCurrency(totalRevenue)),
                      _pdfKpiItem('Available Stock', '$availableStock eggs'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.green200, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfKpiItem('Sales Rate', '${salesRate.toStringAsFixed(1)}%'),
                      _pdfKpiItem('Breakage Rate', '${breakageRate.toStringAsFixed(1)}%'),
                      _pdfKpiItem('Total Broken', '$totalBroken eggs'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Daily Production Records Table
            pw.Text(
              'DAILY PRODUCTION LOG',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            if (_records.isEmpty)
              pw.Text('No daily egg collection records recorded yet.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      _pdfTableCell('Date', bold: true),
                      _pdfTableCell('Collected', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Laying %', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Sold', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Broken', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Revenue', bold: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ..._records.map((r) {
                    final layPct = currentFlock > 0 ? (r.eggsCollected / currentFlock * 100) : 0.0;
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(DateFormat('dd MMM yyyy').format(r.date)),
                        _pdfTableCell('${r.eggsCollected}', align: pw.TextAlign.right),
                        _pdfTableCell('${layPct.toStringAsFixed(1)}%', align: pw.TextAlign.right),
                        _pdfTableCell('${r.eggsSold}', align: pw.TextAlign.right),
                        _pdfTableCell('${r.eggsBroken}', align: pw.TextAlign.right),
                        _pdfTableCell(r.revenue != null ? Formatter.formatCurrency(r.revenue!) : '-', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 16),

            // Stock Transactions Table (if any)
            if (_stockTransactions.isNotEmpty) ...[
              pw.Text(
                'EGG STOCK TRANSACTIONS (SALES & BREAKAGES)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      _pdfTableCell('Date', bold: true),
                      _pdfTableCell('Type', bold: true),
                      _pdfTableCell('Quantity', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Revenue', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Notes', bold: true),
                    ],
                  ),
                  ..._stockTransactions.map((t) {
                    return pw.TableRow(
                      children: [
                        _pdfTableCell(DateFormat('dd MMM yyyy').format(t.transactionDate)),
                        _pdfTableCell(t.type == 'sale' ? 'Sale' : 'Breakage',
                            color: t.type == 'sale' ? PdfColors.green800 : PdfColors.red800),
                        _pdfTableCell('${t.quantity}', align: pw.TextAlign.right),
                        _pdfTableCell(t.revenue != null ? Formatter.formatCurrency(t.revenue!) : '-', align: pw.TextAlign.right),
                        _pdfTableCell(t.notes ?? '-'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Advisory & Recommendations
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Production Advisory & Best Practices',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown800)),
                  pw.SizedBox(height: 4),
                  pw.Text(_advisoryNotes(avgPercentage),
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'egg_report_${widget.animal.breed.toLowerCase().replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _pdfKpiItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfTableCell(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFlock = _currentFlockSize();
    final avgPercentage = (_records.isEmpty || currentFlock <= 0)
        ? 0.0
        : _records.fold<double>(
                0.0,
                (sum, r) => sum + (r.eggsCollected / currentFlock * 100),
              ) /
              _records.length;

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryCard(avgPercentage),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        FarmInterstitialAd.show(
                          context: context,
                          screenKey: 'egg_production_report',
                          force: true,
                          onDone: () => _exportPdf(),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade600, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade100.withValues(alpha: 0.6),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.ondemand_video, color: Colors.green.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Watch Ad & Export Egg Production',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'PDF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildProductionChart(),
                  _buildRecordsList(),
                  _buildStockTransactionsList(),
                  _buildAdvisoryCard(avgPercentage),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stock Breakage button
          FloatingActionButton.small(
            heroTag: 'breakage',
            onPressed: () => _recordStockTransaction('breakage'),
            backgroundColor: Colors.red.shade400,
            child: const Icon(Icons.broken_image, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Stock Sale button
          FloatingActionButton.small(
            heroTag: 'sale',
            onPressed: () => _recordStockTransaction('sale'),
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.sell, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Add Collection button
          FloatingActionButton(
            heroTag: 'collection',
            onPressed: _addEggCollection,
            backgroundColor: Colors.orange.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double avgPercentage) {
    final currentFlock = _currentFlockSize();
    final todayPercentage = _getTodayPercentage();
    final totalEggs = _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    final totalSold = _records.fold<int>(0, (sum, r) => sum + r.eggsSold);
    final totalBroken = _records.fold<int>(0, (sum, r) => sum + r.eggsBroken);
    
    // Calculate stock transactions
    final totalSoldFromStock = _stockTransactions
        .where((t) => t.type == 'sale')
        .fold<int>(0, (sum, t) => sum + t.quantity);
    final totalBrokenFromStock = _stockTransactions
        .where((t) => t.type == 'breakage')
        .fold<int>(0, (sum, t) => sum + t.quantity);
    
    // Calculate accumulated stock
    final eggStock = EggStockSummary(
      totalCollected: totalEggs,
      totalSoldFromDaily: totalSold,
      totalBrokenFromDaily: totalBroken,
      totalSoldFromStock: totalSoldFromStock,
      totalBrokenFromStock: totalBrokenFromStock,
    );
    final currentStock = eggStock.totalAvailable;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.egg, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Egg Production Tracking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.animal.breed} - $currentFlock layers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Stock',
                  '$currentStock',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Sold',
                  '${totalSold + totalSoldFromStock}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Broken',
                  '${totalBroken + totalBrokenFromStock}',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s %',
                  '${todayPercentage.toStringAsFixed(1)}%',
                  todayPercentage >= 80 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Average %',
                  '${avgPercentage.toStringAsFixed(1)}%',
                  avgPercentage >= 80 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Eggs',
                  '$totalEggs',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show accumulated stock
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Stock: $currentStock eggs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _getTodayPercentage() {
    final today = DateTime.now();
    final todayRecord = _records.firstWhere(
      (record) =>
          record.date.day == today.day &&
          record.date.month == today.month &&
          record.date.year == today.year,
      orElse: () => PoultryProductionRecord(
        id: '',
        batchId: widget.animal.id,
        date: today,
        eggsCollected: 0,
      ),
    );

    final currentFlock = _currentFlockSize();
    return currentFlock > 0
        ? (todayRecord.eggsCollected / currentFlock) * 100
        : 0;
  }

  Widget _buildProductionChart() {
    if (_records.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No production data yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                'Add daily egg collections to see trends',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final currentFlock = _currentFlockSize();
    final chartData = _records.map((record) {
      return EggChartData(
        record.date,
        record.eggsCollected.toDouble(),
        currentFlock > 0 ? (record.eggsCollected / currentFlock) * 100 : 0,
      );
    }).toList();

    return Container(
      height: 350,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Production Trends',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('dd/MM'),
                title: const AxisTitle(text: 'Date'),
              ),
              primaryYAxis: const NumericAxis(
                title: AxisTitle(text: 'Eggs / Percentage'),
              ),
              legend: const Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<EggChartData, DateTime>>[
                LineSeries<EggChartData, DateTime>(
                  name: 'Eggs Collected',
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.date,
                  yValueMapper: (data, _) => data.eggs,
                  color: Colors.orange.shade600,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    color: Colors.orange,
                    shape: DataMarkerType.circle,
                  ),
                ),
                LineSeries<EggChartData, DateTime>(
                  name: 'Laying %',
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.date,
                  yValueMapper: (data, _) => data.percentage,
                  color: Colors.green.shade600,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    color: Colors.green,
                    shape: DataMarkerType.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    final currentFlock = _currentFlockSize();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Production Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No records yet. Tap + to add your first egg collection!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    final percentage = currentFlock > 0
                        ? (record.eggsCollected / currentFlock) * 100
                        : 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(Icons.egg, color: Colors.orange.shade700),
                      ),
                      title: Text(
                        '${record.eggsCollected} eggs collected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}% laying rate • ${record.date.day}-${record.date.month}-${record.date.year}',
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${record.eggsSold} sold',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${record.eggsBroken} broken',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (record.revenue != null)
                            Text(
                              record.revenue != null
                                  ? Formatter.formatCurrency(record.revenue!)
                                  : '',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateEggSales(record),
                            tooltip: 'Update Sales',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStockTransactionsList() {
    if (_stockTransactions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Stock Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = _stockTransactions[index];
              return ListTile(
                leading: Icon(
                  transaction.type == 'sale' ? Icons.sell : Icons.broken_image,
                  color: transaction.type == 'sale' ? Colors.green : Colors.red,
                ),
                title: Text(
                  transaction.type == 'sale' ? 'Stock Sale' : 'Stock Breakage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${transaction.quantity} eggs'),
                    if (transaction.revenue != null)
                      Text(
                        'Revenue: ${Formatter.currencySymbol}${transaction.revenue!.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    if (transaction.notes != null)
                      Text(
                        transaction.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  '${transaction.transactionDate.day}/${transaction.transactionDate.month}/${transaction.transactionDate.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(double avgPercentage) {
    final notes = _advisoryNotes(avgPercentage);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Advisory Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// Chart data class
class EggChartData {
  EggChartData(this.date, this.eggs, this.percentage);
  final DateTime date;
  final double eggs;
  final double percentage;
}
