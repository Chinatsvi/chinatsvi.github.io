// lib/screens/animal/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class _ReportItem {
  final String label;
  final double value;
  final Color color;
  _ReportItem(this.label, this.value, this.color);
}

class ReportsScreen extends StatelessWidget {
  final Animal animal;
  final AnimalRepository repository;

  static double calculateTotalExpenses({
    required double initialCost,
    required double feedCost,
    required double vetCost,
    required double healthCost,
    required double breedingCost,
    double milkSpoilCost = 0.0,
  }) {
    return initialCost + feedCost + vetCost + healthCost + breedingCost + milkSpoilCost;
  }

  const ReportsScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  Future<double> _feedCostTotal() async {
    final entries = await repository.listFeedingEntries(animal.id);
    return entries.fold<double>(0.0, (double sum, e) => sum + e.cost);
  }

  Future<double> _vetCostTotal() async {
    final visits = await repository.listVetVisits(animal.id);
    return visits.fold<double>(0.0, (double sum, v) => sum + (v.cost ?? 0.0));
  }

  Future<double> _healthCostTotal() async {
    final records = await repository.listHealthRecords(animal.id);
    return records.fold<double>(0.0, (double sum, r) => sum + (r.cost ?? 0.0));
  }

  Future<double> _breedingCostTotal() async {
    final records = await repository.listBreedingRecords(animal.id);
    return records.fold<double>(0.0, (double sum, r) => sum + (r.cost ?? 0.0));
  }

  Future<double> _activityCostTotal() async {
    final records = await repository.listActivityLogs(animal.id);
    return records.fold<double>(0.0, (double sum, r) => sum + (r.cost ?? 0.0));
  }

  Future<double> _salesTotal() async {
    final exits = await repository.listExitRecords(animal.id);
    return exits
        .where((e) => e.salePrice != null)
        .fold<double>(0.0, (double sum, e) => sum + (e.salePrice ?? 0.0));
  }

  Future<double> _milkSalesTotal() async {
    try {
      final records = await repository.listMilkProductionRecords(animal.id);
      return records.fold<double>(0.0, (double sum, r) => sum + (r.revenue ?? 0.0));
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> _milkSpoilageCostTotal() async {
    try {
      final records = await repository.listMilkProductionRecords(animal.id);
      return records.fold<double>(0.0, (double sum, r) => sum + r.effectiveSpoilCost);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _exportPdf(
    BuildContext context, {
    required double feedCost,
    required double vetCost,
    required double healthCost,
    required double breedingCost,
    required double activityCost,
    required double milkSpoilCost,
    required double animalSales,
    required double milkSales,
    required double totalSales,
    required double totalExpenses,
    required double profit,
    required String advisory,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Animal Profit & Loss Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Text(
              '${animal.species} - ${animal.breed}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Text(
              'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.green800, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (_) => [
          // Summary
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: profit >= 0 ? PdfColors.green50 : PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: profit >= 0 ? PdfColors.green200 : PdfColors.orange200,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('Total Expenses', _formatPdfMoney(animal, totalExpenses)),
                _pdfStat('Total Revenue', _formatPdfMoney(animal, totalSales)),
                _pdfStat(
                  profit >= 0 ? 'Net Profit' : 'Net Loss',
                  _formatPdfMoney(animal, profit.abs()),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Revenue Breakdown
          pw.Text(
            'REVENUE / INCOME BREAKDOWN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                children: [
                  _pdfCell('Income Category', bold: true),
                  _pdfCell('Amount', bold: true, align: pw.TextAlign.right),
                ],
              ),
              if (animalSales > 0)
                pw.TableRow(children: [
                  _pdfCell('Animal Sales / Exits'),
                  _pdfCell(_formatPdfMoney(animal, animalSales), align: pw.TextAlign.right),
                ]),
              if (milkSales > 0)
                pw.TableRow(children: [
                  _pdfCell('Milk Production Sales'),
                  _pdfCell(_formatPdfMoney(animal, milkSales), align: pw.TextAlign.right),
                ]),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _pdfCell('Total Revenue', bold: true),
                  _pdfCell(_formatPdfMoney(animal, totalSales), bold: true, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'EXPENSE BREAKDOWN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.red100),
                children: [
                  _pdfCell('Expense Category', bold: true),
                  _pdfCell('Amount', bold: true, align: pw.TextAlign.right),
                ],
              ),
              if (feedCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Feed Costs'),
                  _pdfCell(_formatPdfMoney(animal, feedCost), align: pw.TextAlign.right),
                ]),
              if (vetCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Vet & Medical Visits'),
                  _pdfCell(_formatPdfMoney(animal, vetCost), align: pw.TextAlign.right),
                ]),
              if (healthCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Health & Treatments'),
                  _pdfCell(_formatPdfMoney(animal, healthCost), align: pw.TextAlign.right),
                ]),
              if (breedingCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Breeding & Insemination'),
                  _pdfCell(_formatPdfMoney(animal, breedingCost), align: pw.TextAlign.right),
                ]),
              if (activityCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Activity & Farm Management'),
                  _pdfCell(_formatPdfMoney(animal, activityCost), align: pw.TextAlign.right),
                ]),
              if (milkSpoilCost > 0)
                pw.TableRow(children: [
                  _pdfCell('Milk Spoilage / Loss Cost'),
                  _pdfCell(_formatPdfMoney(animal, milkSpoilCost), align: pw.TextAlign.right),
                ]),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.red50),
                children: [
                  _pdfCell('TOTAL EXPENSES', bold: true),
                  _pdfCell(_formatPdfMoney(animal, totalExpenses),
                      bold: true, color: PdfColors.red, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.lightGreen100),
                children: [
                  _pdfCell('Total Revenue', bold: true),
                  _pdfCell(_formatPdfMoney(animal, totalSales),
                      bold: true, color: PdfColors.green800, align: pw.TextAlign.right),
                ],
              ),
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: profit >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                ),
                children: [
                  _pdfCell(profit >= 0 ? 'NET PROFIT' : 'NET LOSS', bold: true),
                  _pdfCell(_formatPdfMoney(animal, profit.abs()),
                      bold: true,
                      color: profit >= 0 ? PdfColors.blue800 : PdfColors.deepOrange,
                      align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.lightGreen50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Advisory',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
                pw.SizedBox(height: 6),
                pw.Text(advisory, style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'animal_report_${animal.species.toLowerCase()}.pdf',
    );
  }

  static String _formatPdfMoney(Animal animal, double amount) {
    if (amount % 1 == 0 || (amount - amount.round()).abs() < 0.00001) {
      return '${animal.currencySymbol}${amount.round()}';
    }
    return '${animal.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  static pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _feedCostTotal(),
          _vetCostTotal(),
          _healthCostTotal(),
          _breedingCostTotal(),
          _activityCostTotal(),
          _salesTotal(),
          _milkSalesTotal(),
          _milkSpoilageCostTotal(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedCost = snapshot.data![0] as double;
          final vetCost = snapshot.data![1] as double;
          final healthCost = snapshot.data![2] as double;
          final breedingCost = snapshot.data![3] as double;
          final activityCost = snapshot.data![4] as double;
          final animalSales = snapshot.data![5] as double;
          final milkSales = snapshot.data![6] as double;
          final milkSpoilCost = snapshot.data![7] as double;
          final totalSales = animalSales + milkSales;

          final initialCost = animal.totalCost;
          final totalExpenses = calculateTotalExpenses(
            initialCost: initialCost,
            feedCost: feedCost,
            vetCost: vetCost,
            healthCost: healthCost,
            breedingCost: breedingCost + activityCost,
            milkSpoilCost: milkSpoilCost,
          );
          final profit = totalSales - totalExpenses;

          final chartData = <_ReportItem>[
            if (feedCost > 0) _ReportItem('Feed Cost', feedCost, Colors.red),
            if (vetCost > 0) _ReportItem('Vet Costs', vetCost, Colors.orange),
            if (healthCost > 0) _ReportItem('Health', healthCost, Colors.purple),
            if (breedingCost > 0) _ReportItem('Breeding', breedingCost, Colors.pink),
            if (activityCost > 0) _ReportItem('Activity', activityCost, Colors.indigo),
            if (milkSpoilCost > 0) _ReportItem('Milk Spoilage', milkSpoilCost, Colors.amber.shade800),
            if (animalSales > 0) _ReportItem('Animal Sales', animalSales, Colors.green),
            if (milkSales > 0) _ReportItem('Milk Sales', milkSales, Colors.teal),
            if (profit > 0) _ReportItem('Net Profit', profit, Colors.blue),
          ].where((i) => i.value > 0).toList();

          String advisory;
          if (profit < 0) {
            advisory =
                'Loss detected: Total expenses (${_money(totalExpenses)}) exceed revenue (${_money(totalSales)}). Review all expense categories.';
          } else if (totalSales > 0 && profit < totalExpenses * 0.2) {
            advisory =
                'Profit margin is low (${((profit / totalSales) * 100).toStringAsFixed(1)}%). Consider optimizing costs or improving sales prices.';
          } else {
            advisory = 'Healthy margin: Total revenue comfortably exceeds all expenses.';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profit/Loss Summary Banner ────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: profit >= 0
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.orange.shade50, Colors.orange.shade100],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        profit >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 40,
                        color: profit >= 0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profit >= 0 ? 'NET PROFIT' : 'NET LOSS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money(profit.abs()),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniStat('Total Expenses',
                              _money(totalExpenses),
                              Colors.red),
                          _miniStat('Total Revenue',
                              _money(totalSales), Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Revenue Breakdown ────────────────────────────────────
              _sectionHeader('Revenue / Income', Icons.attach_money),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (animalSales > 0)
                      _expenseRow('Animal Sales / Exits', animalSales,
                          Icons.sell, Colors.green),
                    if (milkSales > 0)
                      _expenseRow('Milk Production Sales', milkSales,
                          Icons.water_drop, Colors.teal),
                    if (animalSales == 0 && milkSales == 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No revenue recorded yet.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Revenue',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            _money(totalSales),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Expense Breakdown ────────────────────────────────────
              _sectionHeader('Expense Breakdown', Icons.receipt_long),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (initialCost > 0)
                      _expenseRow('Initial Animal Cost', initialCost,
                          Icons.pets, Colors.brown),
                    if (feedCost > 0)
                      _expenseRow('Feed Costs', feedCost,
                          Icons.restaurant, Colors.red),
                    if (vetCost > 0)
                      _expenseRow('Vet Costs', vetCost,
                          Icons.medical_services, Colors.orange),
                    if (healthCost > 0)
                      _expenseRow('Health Costs', healthCost,
                          Icons.healing, Colors.purple),
                    if (breedingCost > 0)
                      _expenseRow('Breeding Costs', breedingCost,
                          Icons.favorite, Colors.pink),
                    if (activityCost > 0)
                      _expenseRow('Activity Costs', activityCost,
                          Icons.note_alt, Colors.indigo),
                    if (milkSpoilCost > 0)
                      _expenseRow('Milk Spoilage / Loss', milkSpoilCost,
                          Icons.warning_amber_outlined, Colors.amber.shade900),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Expenses',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            _money(totalExpenses),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pie Chart ────────────────────────────────────────────
              if (chartData.isNotEmpty) ...[
                _sectionHeader('Financial Breakdown', Icons.pie_chart),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 260,
                          child: PieChart(
                            PieChartData(
                              sections: chartData
                                  .map((d) => PieChartSectionData(
                                        color: d.color,
                                        value: d.value,
                                        title:
                                            '${d.label}\n${_money(d.value)}',
                                        radius: 80,
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ))
                                  .toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                            ),
                            duration: const Duration(milliseconds: 400),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: chartData
                              .map((d) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                            color: d.color,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(d.label,
                                          style:
                                              const TextStyle(fontSize: 11)),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Advisory Card ────────────────────────────────────────
              Card(
                color: Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(advisory,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade900)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Generate Report (Interstitial) ───────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    FarmInterstitialAd.show(
                      context: context,
                      screenKey: 'animal_reports',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Generate Report',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Export PDF (Rewarded ad) ──────────────────────────────
              FarmRewardedAdButton(
                label: 'Watch Ad & Export Profit & Loss Summary',
                icon: Icons.picture_as_pdf,
                color: Colors.green.shade800,
                onRewarded: () => _exportPdf(
                  context,
                  feedCost: feedCost,
                  vetCost: vetCost,
                  healthCost: healthCost,
                  breedingCost: breedingCost,
                  activityCost: activityCost,
                  milkSpoilCost: milkSpoilCost,
                  animalSales: animalSales,
                  milkSales: milkSales,
                  totalSales: totalSales,
                  totalExpenses: totalExpenses,
                  profit: profit,
                  advisory: advisory,
                ),
              ),
              const SizedBox(height: 20),

              // ── Native Ad: below summary and reports ──
              const FarmNativeAd(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _money(double amount) {
    if (amount % 1 == 0 || (amount - amount.round()).abs() < 0.00001) {
      return '${animal.currencySymbol}${amount.round()}';
    }
    return '${animal.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _expenseRow(
      String label, double amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            _money(amount),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      ],
    );
  }
}
