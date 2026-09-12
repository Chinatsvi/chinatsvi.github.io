import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:agribased/app/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';

import '../../models/animal/animal.dart';
import '../../models/poultry/poultry_batch.dart';
import '../../models/poultry/poultry_production_record.dart';
import '../../models/poultry/poultry_feeding_record.dart';
import '../../models/poultry/poultry_mortality_record.dart';
import '../../models/poultry/poultry_health_record.dart';
import '../../models/poultry/poultry_vet_record.dart';
import '../../models/poultry/poultry_exit_record.dart';
import '../../models/poultry/egg_stock.dart';
import '../../services/poultry/poultry_repository_interface.dart';

class _ReportItem {
  final String label;
  final double value;
  final Color color;

  _ReportItem(this.label, this.value, this.color);
}

class PoultryReportsScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryReportsScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryReportsScreen> createState() => _PoultryReportsScreenState();
}

class _PoultryReportsScreenState extends State<PoultryReportsScreen> {
  late Future<List<dynamic>> _reportsData;
  PoultryBatch? _batch;

  @override
  void initState() {
    super.initState();
    FarmInterstitialAd.preload();
    _loadReports();
  }

  void _loadReports() {
    _reportsData = _loadAllData();
  }

  Future<double> _calculateActivityCost() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0.0;

      final snap = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('animals')
          .doc(widget.animal.id)
          .collection('activityLogs')
          .get();

      return snap.docs.fold<double>(0.0, (total, doc) {
        final data = doc.data();
        if (data['deleted'] == true) return total;
        return total + ((data['cost'] as num?)?.toDouble() ?? 0.0);
      });
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<dynamic>> _loadAllData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }

      final batchId = widget.animal.id;

      // Try to load the actual PoultryBatch document from Firestore.
      // This ensures counts, chickCost and updates are taken from the
      // canonical batch record rather than a fallback created from
      // the `Animal` object which may be missing fields.
      try {
        final batchDoc = await FirebaseFirestore.instance
            .collection('poultry_batches')
            .doc(batchId)
            .get();

        if (batchDoc.exists) {
          final realBatch = PoultryBatch.fromDocument(batchDoc);
          setState(() {
            _batch = realBatch;
          });
        } else {
          // Fallback: create a simple batch object for calculations
          final batch = PoultryBatch(
            id: batchId,
            name: '${widget.animal.breed} Flock',
            breed: widget.animal.breed,
            purpose: widget.animal.purpose,
            ageWeeks: (widget.animal.ageMonths * 4.345)
                .floor(), // Convert months to weeks (months -> weeks)
            initialCount: widget.animal.initialFlockSize ?? 0,
            currentCount: widget.animal.initialFlockSize ?? 0,
            chickCost: null, // Animal model doesn't have chickCost
            startDate: widget.animal.createdAt,
            createdAt: widget.animal.createdAt,
            updatedAt: DateTime.now(),
          );

          setState(() {
            _batch = batch;
          });
        }
      } catch (e) {
        // On error use fallback batch but keep error silent for UX
        final batch = PoultryBatch(
          id: batchId,
          name: '${widget.animal.breed} Flock',
          breed: widget.animal.breed,
          purpose: widget.animal.purpose,
          ageWeeks: (widget.animal.ageMonths * 4.345).floor(),
          initialCount: widget.animal.initialFlockSize ?? 0,
          currentCount: widget.animal.initialFlockSize ?? 0,
          chickCost: null,
          startDate: widget.animal.createdAt,
          createdAt: widget.animal.createdAt,
          updatedAt: DateTime.now(),
        );

        setState(() {
          _batch = batch;
        });
      }

      // Load all data in parallel
      final results = await Future.wait([
        widget.repository.getFeedingRecords(batchId),
        widget.repository.listPoultryProductionRecords(batchId),
        widget.repository.listPoultryMortalityRecords(batchId),
        widget.repository.getHealthRecords(batchId),
        widget.repository.getVetRecords(batchId),
        widget.repository.getExitRecords(batchId),
        widget.repository.listEggStockTransactions(batchId),
        _calculateActivityCost(),
      ]);

      return [
        results[0], // feeding records
        results[1], // production records
        results[2], // mortality records
        results[3], // health records
        results[4], // vet records
        results[5], // exit records
        results[6], // egg stock transactions
        results[7], // activity costs
      ];
    } catch (e) {
      return [];
    }
  }

  // Calculate total batch cost (chickCost field now stores batch cost)
  double _calculateChickCost() {
    if (_batch == null || _batch!.chickCost == null) return 0.0;
    final cost = _batch!.chickCost!;

    // Backwards-compatibility heuristic:
    // Older records sometimes stored `chickCost` as per-bird price.
    // If the stored value looks like a per-bird amount (small value,
    // e.g. < 100) and we have an initialCount, convert to batch total.
    if (_batch!.initialCount > 0 && cost > 0 && cost < 100) {
      return cost * _batch!.initialCount;
    }

    return cost; // already whole-batch cost
  }

  // Calculate total feed cost
  double _calculateFeedCost(List<PoultryFeedingRecord> records) {
    return records.fold<double>(
      0.0,
      (total, record) => total + (record.cost ?? 0.0),
    );
  }

  // Calculate total veterinary cost (health + vet records)
  double _calculateVetCost(
    List<PoultryHealthRecord> healthRecords,
    List<PoultryVetRecord> vetRecords,
  ) {
    double totalCost = 0.0;

    // Add health record costs (medicines, vaccines, etc.)
    totalCost += healthRecords.fold<double>(
      0.0,
      (total, record) => total + (record.cost ?? 0.0),
    );

    // Add vet visit costs (consultation fees, treatments, etc.)
    totalCost += vetRecords.fold<double>(
      0.0,
      (total, record) => total + (record.cost ?? 0.0),
    );

    return totalCost;
  }

  // Calculate total mortality loss
  double _calculateMortalityLoss(List<PoultryMortalityRecord> records) {
    if (_batch == null || _batch!.chickCost == null) return 0.0;
    final totalDeaths = records.fold<int>(
      0,
      (total, record) => total + record.deaths,
    );

    if (_batch!.initialCount <= 0) return 0.0;

    // Use same heuristic as _calculateChickCost to derive per-bird cost.
    final batchCost = _calculateChickCost();
    final perBirdCost = batchCost / _batch!.initialCount;
    return totalDeaths * perBirdCost;
  }

  // Calculate total revenue from eggs (daily sales + stock sales)
  double _calculateEggRevenue(
    List<PoultryProductionRecord> records,
    List<EggStockTransaction> stockTransactions,
  ) {
    // Daily collection sales
    final dailyRevenue = records.fold<double>(
      0.0,
      (total, record) => total + (record.revenue ?? 0.0),
    );
    
    // Stock sales revenue
    final stockRevenue = stockTransactions
        .where((t) => t.type == 'sale')
        .fold<double>(0.0, (total, t) => total + (t.revenue ?? 0.0));
    
    return dailyRevenue + stockRevenue;
  }

  // Calculate revenue from sold birds
  double _calculateBirdSalesRevenue(List<PoultryExitRecord> exitRecords) {
    return exitRecords
        .where((record) => record.isSold && record.income != null)
        .fold<double>(0, (total, record) => total + record.income!);
  }

  Future<void> _exportPdf({
    required double chickCost,
    required double feedCost,
    required double vetCost,
    required double mortalityLoss,
    required double activityCost,
    required double eggRevenue,
    required double birdSalesRevenue,
    required double totalExpenses,
    required double totalRevenue,
    required double profit,
    required List<PoultryFeedingRecord> feedingRecords,
    required List<PoultryProductionRecord> productionRecords,
    required List<PoultryMortalityRecord> mortalityRecords,
    required List<PoultryExitRecord> exitRecords,
  }) async {
    try {
      final doc = pw.Document();
      final batchName = _batch?.name ?? '${widget.animal.breed} Flock';
      final breed = widget.animal.breed;
      final purpose = widget.animal.purpose;
      final initialCount = _batch?.initialCount ?? widget.animal.initialFlockSize ?? 0;
      final currentCount = _batch?.currentCount ?? initialCount;
      final totalDeaths = mortalityRecords.fold<int>(0, (total, r) => total + r.deaths);
      final totalExits = exitRecords.fold<int>(0, (total, r) => total + r.quantity);
      final marginPct = totalRevenue > 0 ? (profit / totalRevenue * 100) : 0.0;

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
                'Poultry Financial & Operations Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Batch: $batchName | Breed: $breed ($purpose) | Flock Size: $currentCount birds (Initial: $initialCount)',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.green800, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => [
            // KPI Financial Summary Cards
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: profit >= 0 ? PdfColors.green50 : PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: profit >= 0 ? PdfColors.green300 : PdfColors.red300,
                  width: 1,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfKpiStat('Total Revenue', Formatter.formatCurrency(totalRevenue), color: PdfColors.green900),
                  _pdfKpiStat('Total Expenses', Formatter.formatCurrency(totalExpenses), color: PdfColors.red900),
                  _pdfKpiStat(
                    profit >= 0 ? 'Net Profit' : 'Net Loss',
                    Formatter.formatCurrency(profit.abs()),
                    color: profit >= 0 ? PdfColors.green900 : PdfColors.red900,
                  ),
                  _pdfKpiStat('Profit Margin', '${marginPct.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Expense Breakdown Table
            pw.Text(
              'EXPENSE BREAKDOWN',
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
                    _pdfTableCell('Expense Category', bold: true),
                    _pdfTableCell('Amount', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('% of Total Expenses', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                if (chickCost > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Chick Purchase Cost'),
                    _pdfTableCell(Formatter.formatCurrency(chickCost), align: pw.TextAlign.right),
                    _pdfTableCell('${totalExpenses > 0 ? (chickCost / totalExpenses * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                if (feedCost > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Feed Costs'),
                    _pdfTableCell(Formatter.formatCurrency(feedCost), align: pw.TextAlign.right),
                    _pdfTableCell('${totalExpenses > 0 ? (feedCost / totalExpenses * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                if (vetCost > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Veterinary & Health Costs'),
                    _pdfTableCell(Formatter.formatCurrency(vetCost), align: pw.TextAlign.right),
                    _pdfTableCell('${totalExpenses > 0 ? (vetCost / totalExpenses * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                if (mortalityLoss > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Mortality Loss Value'),
                    _pdfTableCell(Formatter.formatCurrency(mortalityLoss), align: pw.TextAlign.right),
                    _pdfTableCell('${totalExpenses > 0 ? (mortalityLoss / totalExpenses * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                if (activityCost > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Farmer Activity & Labor Costs'),
                    _pdfTableCell(Formatter.formatCurrency(activityCost), align: pw.TextAlign.right),
                    _pdfTableCell('${totalExpenses > 0 ? (activityCost / totalExpenses * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red50),
                  children: [
                    _pdfTableCell('TOTAL OPERATING EXPENSES', bold: true),
                    _pdfTableCell(Formatter.formatCurrency(totalExpenses), bold: true, align: pw.TextAlign.right, color: PdfColors.red800),
                    _pdfTableCell('100.0%', bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Revenue Breakdown Table
            pw.Text(
              'REVENUE BREAKDOWN',
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
                    _pdfTableCell('Revenue Source', bold: true),
                    _pdfTableCell('Amount', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('% of Total Revenue', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                if (eggRevenue > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Egg Sales (Daily + Stock)'),
                    _pdfTableCell(Formatter.formatCurrency(eggRevenue), align: pw.TextAlign.right),
                    _pdfTableCell('${totalRevenue > 0 ? (eggRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                if (birdSalesRevenue > 0)
                  pw.TableRow(children: [
                    _pdfTableCell('Bird / Meat Sales'),
                    _pdfTableCell(Formatter.formatCurrency(birdSalesRevenue), align: pw.TextAlign.right),
                    _pdfTableCell('${totalRevenue > 0 ? (birdSalesRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ]),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _pdfTableCell('TOTAL FARM REVENUE', bold: true),
                    _pdfTableCell(Formatter.formatCurrency(totalRevenue), bold: true, align: pw.TextAlign.right, color: PdfColors.green800),
                    _pdfTableCell('100.0%', bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Flock Health & Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfKpiStat('Initial Birds', '$initialCount'),
                  _pdfKpiStat('Total Mortality', '$totalDeaths'),
                  _pdfKpiStat('Birds Exited/Sold', '$totalExits'),
                  _pdfKpiStat('Active Flock', '$currentCount'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Financial Advisory Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: profit >= 0 ? PdfColors.green50 : PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: profit >= 0 ? PdfColors.green200 : PdfColors.amber200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Financial Advisory & Action Plan',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: profit >= 0 ? PdfColors.green800 : PdfColors.brown800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    profit < 0
                        ? 'Loss Detected: Expenses exceed revenue. Focus on optimizing feed formulation, reducing mortality via strict biosecurity, and boosting daily egg/bird output.'
                        : (profit < totalRevenue * 0.15
                            ? 'Moderate Profit Margin (${marginPct.toStringAsFixed(1)}%): Maintain good flock health, explore bulk feed purchasing, and optimize egg marketing channels.'
                            : 'Healthy Profit Margin (${marginPct.toStringAsFixed(1)}%): Operation is financially sound. Consider scaling flock capacity and continuing current nutrition practices.'),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'poultry_report_${widget.animal.breed.toLowerCase().replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _pdfKpiStat(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.grey900,
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
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _reportsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading poultry reports...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading reports: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text('No data available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final feedingRecords =
              snapshot.data![0] as List<PoultryFeedingRecord>;
          final productionRecords =
              snapshot.data![1] as List<PoultryProductionRecord>;
          final mortalityRecords =
              snapshot.data![2] as List<PoultryMortalityRecord>;
          final healthRecords = snapshot.data![3] as List<PoultryHealthRecord>;
          final vetRecords = snapshot.data![4] as List<PoultryVetRecord>;
          final exitRecords = snapshot.data![5] as List<PoultryExitRecord>;
          final stockTransactions =
              snapshot.data![6] as List<EggStockTransaction>;
          final activityCost = snapshot.data![7] as double;

          // Calculate costs and revenues
          final chickCost = _calculateChickCost();
          final feedCost = _calculateFeedCost(feedingRecords);
          final vetCost = _calculateVetCost(healthRecords, vetRecords);
          final mortalityLoss = _calculateMortalityLoss(mortalityRecords);
          final eggRevenue = _calculateEggRevenue(productionRecords, stockTransactions);
          final birdSalesRevenue = _calculateBirdSalesRevenue(exitRecords);

          final totalExpenses = chickCost + feedCost + vetCost + mortalityLoss + activityCost;
          final totalRevenue = eggRevenue + birdSalesRevenue;
          final profit = totalRevenue - totalExpenses;

          // Prepare pie chart data
          final data = [
            if (chickCost > 0)
              _ReportItem('Chick Cost', chickCost, Colors.blue),
            if (feedCost > 0) _ReportItem('Feed Cost', feedCost, Colors.orange),
            if (vetCost > 0)
              _ReportItem('Veterinary Cost', vetCost, Colors.purple),
            if (mortalityLoss > 0)
              _ReportItem('Mortality Loss', mortalityLoss, Colors.red),
            if (activityCost > 0)
              _ReportItem('Farmer Activity Cost', activityCost, Colors.indigo),
            if (eggRevenue > 0)
              _ReportItem('Egg Revenue', eggRevenue, Colors.green),
            if (birdSalesRevenue > 0)
              _ReportItem('Bird Sales', birdSalesRevenue, Colors.teal),
            if (profit > 0) _ReportItem('Profit', profit, Colors.lightGreen),
            if (profit < 0) _ReportItem('Loss', profit.abs(), Colors.red),
          ];

          // Filter out zero values
          final chartData = data.where((item) => item.value > 0).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadReports();
              });
              await _reportsData;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profit & Loss Summary Card
                  Card(
                    color: profit >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profit & Loss Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: profit >= 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryItem(
                                  'Total Revenue',
                                  Formatter.formatCurrency(totalRevenue),
                                  Icons.arrow_upward,
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildSummaryItem(
                                  'Total Expenses',
                                  Formatter.formatCurrency(totalExpenses),
                                  Icons.arrow_downward,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: profit >= 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  profit >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: profit >= 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profit >= 0 ? 'PROFIT' : 'LOSS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: profit >= 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatter.formatCurrency(profit.abs()),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: profit >= 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              FarmInterstitialAd.show(
                                context: context,
                                screenKey: 'poultry_reports_pdf',
                                force: true,
                                onDone: () => _exportPdf(
                                  chickCost: chickCost,
                                  feedCost: feedCost,
                                  vetCost: vetCost,
                                  mortalityLoss: mortalityLoss,
                                  activityCost: activityCost,
                                  eggRevenue: eggRevenue,
                                  birdSalesRevenue: birdSalesRevenue,
                                  totalExpenses: totalExpenses,
                                  totalRevenue: totalRevenue,
                                  profit: profit,
                                  feedingRecords: feedingRecords,
                                  productionRecords: productionRecords,
                                  mortalityRecords: mortalityRecords,
                                  exitRecords: exitRecords,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade600,
                                  width: 1.2,
                                ),
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
                                  Icon(
                                    Icons.ondemand_video,
                                    color: Colors.green.shade800,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Watch Ad & Export Profit & Loss Summary',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const FarmNativeAd(),
                  const SizedBox(height: 16),

                  // Expense Breakdown
                  const Text(
                    'Expense Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (chickCost > 0)
                    _buildExpenseItem(
                      'Chick Purchase Cost',
                      chickCost,
                      Icons.catching_pokemon,
                      Colors.blue,
                    ),
                  if (feedCost > 0)
                    _buildExpenseItem(
                      'Feed Cost',
                      feedCost,
                      Icons.restaurant,
                      Colors.orange,
                    ),
                  if (vetCost > 0)
                    _buildExpenseItem(
                      'Veterinary Cost',
                      vetCost,
                      Icons.medical_services,
                      Colors.purple,
                    ),
                  if (mortalityLoss > 0)
                    _buildExpenseItem(
                      'Mortality Loss',
                      mortalityLoss,
                      Icons.warning,
                      Colors.red,
                    ),
                  if (activityCost > 0)
                    _buildExpenseItem(
                      'Farmer Activity Cost',
                      activityCost,
                      Icons.note_alt,
                      Colors.indigo,
                    ),

                  const SizedBox(height: 16),

                  // Revenue Breakdown
                  const Text(
                    'Revenue Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (eggRevenue > 0)
                    _buildRevenueItem(
                      'Egg Sales',
                      eggRevenue,
                      Icons.egg,
                      Colors.green,
                    ),
                  if (birdSalesRevenue > 0)
                    _buildRevenueItem(
                      'Bird Sales',
                      birdSalesRevenue,
                      Icons.pets,
                      Colors.teal,
                    ),

                  const SizedBox(height: 16),

                  // Chart
                  if (chartData.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Financial Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: PieChart(
                                PieChartData(
                                  sections: chartData.map((item) {
                                    return PieChartSectionData(
                                      color: item.color,
                                      value: item.value,
                                        title:
                                          '${item.label}\n${Formatter.formatCurrency(item.value)}',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Advisory Notes
                  _buildAdvisoryCard(profit, totalRevenue, totalExpenses),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(
          Formatter.formatCurrency(value),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueItem(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(
          Formatter.formatCurrency(value),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryCard(double profit, double revenue, double expenses) {
    String advisory;
    Color cardColor;
    IconData advisoryIcon;

    if (profit < 0) {
        advisory =
          '⚠️ Loss Detected: Your expenses (${Formatter.formatCurrency(expenses)}) exceed revenue (${Formatter.formatCurrency(revenue)}). Consider:\n\n• Reducing feed costs through better formulation\n• Improving egg production\n• Reviewing veterinary expenses\n• Implementing better biosecurity to reduce mortality';
      cardColor = Colors.red.shade50;
      advisoryIcon = Icons.warning;
    } else if (profit < revenue * 0.15) {
      advisory =
          'ℹ️ Low Profit Margin: Your profit margin is ${((profit / revenue) * 100).toStringAsFixed(1)}%. Consider:\n\n• Optimizing feed formulation for better cost-efficiency\n• Increasing egg production through better management\n• Exploring premium pricing for eggs';
      cardColor = Colors.orange.shade50;
      advisoryIcon = Icons.info;
    } else {
      advisory =
          '✅ Healthy Profit Margin: Your operation is profitable! Maintain current practices and consider:\n\n• Scaling up production\n• Exploring additional revenue streams\n• Reinvesting in improved equipment';
      cardColor = Colors.green.shade50;
      advisoryIcon = Icons.check_circle;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  advisoryIcon,
                  color: cardColor == Colors.green.shade50
                      ? Colors.green
                      : cardColor == Colors.orange.shade50
                      ? Colors.orange
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Financial Advisory',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(advisory),
          ],
        ),
      ),
    );
  }
}
