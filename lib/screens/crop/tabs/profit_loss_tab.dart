import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/services/crop/crop_management_service.dart';

class _ChartItem {
  final String label;
  final double value;
  final Color color;

  _ChartItem(this.label, this.value, this.color);
}

class ProfitLossTab extends StatelessWidget {
  final CropPlan plan;
  final CropManagementService _service = CropManagementService();

  ProfitLossTab({super.key, required this.plan});

  String get _currency => plan.currency ?? r'$';
  String _formatMoney(double amount) =>
      '$_currency${amount.toStringAsFixed(2)}';
  String _formatMoneyShort(double amount) =>
      '$_currency${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getProfitLossAnalysis(plan.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading analysis: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? {};
          
          // Check if there's any data to display
          final hasData = (data['actualIncome'] as double? ?? 0) > 0 ||
                         (data['actualCosts'] as double? ?? 0) > 0 ||
                         (data['budgetedIncome'] as double? ?? 0) > 0 ||
                         (data['advice'] as List<dynamic>?)?.isNotEmpty == true;

          if (!hasData) {
            return _buildNoDataView(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                _buildProfitLossSummary(context, data),
                const SizedBox(height: 12),

                // ── Native Ad: below P&L summary ──
                const FarmNativeAd(),
                const SizedBox(height: 16),

                // Pie Chart
                _buildPieChart(context, data),
                const SizedBox(height: 24),

                // Budget vs Actual
                _buildBudgetComparison(context, data),
                const SizedBox(height: 24),

                // Advice Section
                if ((data['advice'] as List<dynamic>?)?.isNotEmpty == true)
                  _buildAdviceSection(context, data['advice'] as List<dynamic>),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Profit & Loss Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget and add production records to see your profit analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Budget tab
                    DefaultTabController.of(context).animateTo(1);
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Create Budget'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to Production tab
                DefaultTabController.of(context).animateTo(4);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add Production Record'),
            ),
            const SizedBox(height: 16),
            const FarmNativeAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitLossSummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final actualProfit = data['actualProfit'] as double? ?? 0;
    final isProfitable = actualProfit >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isProfitable
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              isProfitable ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: isProfitable
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              isProfitable ? 'PROFIT' : 'LOSS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isProfitable
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatMoney(actualProfit.abs()),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isProfitable
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  'Total Revenue',
                  data['actualIncome'] ?? 0,
                  Colors.green,
                ),
                _buildMiniStat(
                  'Production Costs',
                  data['actualCosts'] ?? 0,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                FarmInterstitialAd.show(
                  context: context,
                  screenKey: 'crop_profit_loss_report',
                  force: true,
                  onDone: () => _exportPdf(context, data),
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
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          _formatMoney(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, dynamic> data) {
    final actualIncome = data['actualIncome'] as double? ?? 0;
    final actualProfit = data['actualProfit'] as double? ?? 0;
    final totalInputCosts = data['totalInputCosts'] as double? ?? 0;
    final totalLaborCosts = data['totalLaborCosts'] as double? ?? 0;
    final totalOtherCosts = data['totalOtherCosts'] as double? ?? 0;
    final totalLossCosts = data['totalLossCosts'] as double? ?? 0;

    // Build chart data
    final chartItems = <_ChartItem>[
      if (totalInputCosts > 0)
        _ChartItem('Inputs', totalInputCosts, Colors.orange),
      if (totalLaborCosts > 0)
        _ChartItem('Labor', totalLaborCosts, Colors.blue),
      if (totalOtherCosts > 0)
        _ChartItem('Other', totalOtherCosts, Colors.purple),
      if (totalLossCosts > 0)
        _ChartItem('Damage/Loss', totalLossCosts, Colors.red.shade400),
      if (actualIncome > 0) _ChartItem('Revenue', actualIncome, Colors.green),
      if (actualProfit > 0)
        _ChartItem('Profit', actualProfit, Colors.lightGreen),
      if (actualProfit < 0) _ChartItem('Loss', actualProfit.abs(), Colors.red),
    ];

    if (chartItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Financial Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: chartItems.map((item) {
                    return PieChartSectionData(
                      color: item.color,
                      value: item.value,
                      title: _formatMoneyShort(item.value),
                      radius: 60,
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
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: chartItems.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${item.label}: ${_formatMoneyShort(item.value)}'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetComparison(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final budgetedIncome = data['budgetedIncome'] as double? ?? 0;
    final budgetedCosts = data['budgetedCosts'] as double? ?? 0;
    final budgetedProfit = data['budgetedProfit'] as double? ?? 0;
    final actualIncome = data['actualIncome'] as double? ?? 0;
    final actualCosts = data['actualCosts'] as double? ?? 0;
    final actualProfit = data['actualProfit'] as double? ?? 0;
    final variance = data['variance'] as double? ?? 0;
    final variancePercentage = data['variancePercentage'] as double? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget vs Actual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              'Expected Income',
              budgetedIncome,
              actualIncome,
              true,
            ),
            const Divider(),
            _buildComparisonRow(
              'Production Costs',
              budgetedCosts,
              actualCosts,
              false,
            ),
            const Divider(),
            _buildComparisonRow(
              'Expected Profit',
              budgetedProfit,
              actualProfit,
              true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: variance >= 0
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    variance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: variance >= 0 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Variance: ${_formatMoney(variance.abs())} (${variancePercentage.abs().toStringAsFixed(1)}% ${variance >= 0 ? 'better' : 'worse'} than budget)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: variance >= 0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    double budgeted,
    double actual,
    bool higherIsBetter,
  ) {
    final difference = actual - budgeted;
    final isPositive = higherIsBetter ? difference >= 0 : difference <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            child: Text(
              _formatMoneyShort(budgeted),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              _formatMoneyShort(actual),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Icon(
            isPositive ? Icons.check_circle : Icons.warning,
            color: isPositive ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(BuildContext context, List<dynamic> advice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Text(
                  'Smart Advice',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...advice.map((tip) => _buildAdviceItem(tip.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceItem(String advice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(advice)),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, Map<String, dynamic> data) async {
    try {
      final doc = pw.Document();
      final actualProfit = data['actualProfit'] as double? ?? 0;
      final actualIncome = data['actualIncome'] as double? ?? 0;
      final actualCosts = data['actualCosts'] as double? ?? 0;
      final totalLossCosts = data['totalLossCosts'] as double? ?? 0;
      final budgetedIncome = data['budgetedIncome'] as double? ?? 0;
      final budgetedCosts = data['budgetedCosts'] as double? ?? 0;
      final budgetedProfit = data['budgetedProfit'] as double? ?? 0;
      final totalInputCosts = data['totalInputCosts'] as double? ?? 0;
      final totalLaborCosts = data['totalLaborCosts'] as double? ?? 0;
      final totalOtherCosts = data['totalOtherCosts'] as double? ?? 0;
      final advice = (data['advice'] as List<dynamic>?) ?? [];

      final isProfitable = actualProfit >= 0;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'AgriBase Crop Management',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Crop Profit & Loss Analysis Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Crop: ${plan.cropName} | Field: ${plan.fieldName} | Season: ${plan.plantingDate.year}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.green800, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (_) => [
            // KPI Overview Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: isProfitable ? PdfColors.green50 : PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: isProfitable ? PdfColors.green300 : PdfColors.orange300,
                  width: 1,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfKpiStat(
                    isProfitable ? 'Net Profit' : 'Net Loss',
                    _formatMoney(actualProfit.abs()),
                    color: isProfitable ? PdfColors.green900 : PdfColors.deepOrange900,
                  ),
                  _pdfKpiStat('Total Revenue', _formatMoney(actualIncome), color: PdfColors.green900),
                  _pdfKpiStat('Production Costs', _formatMoney(actualCosts), color: PdfColors.red800),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Actual Costs Breakdown Table
            pw.Text(
              'COST & EXPENSE BREAKDOWN',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
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
                    _pdfTableCell('Actual Amount', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('% of Total Cost', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Inputs (Seeds, Fertilizers, Chemicals)'),
                    _pdfTableCell(_formatMoney(totalInputCosts), align: pw.TextAlign.right),
                    _pdfTableCell('${actualCosts > 0 ? (totalInputCosts / actualCosts * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Labor & Field Operations'),
                    _pdfTableCell(_formatMoney(totalLaborCosts), align: pw.TextAlign.right),
                    _pdfTableCell('${actualCosts > 0 ? (totalLaborCosts / actualCosts * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Other Operational Expenses'),
                    _pdfTableCell(_formatMoney(totalOtherCosts), align: pw.TextAlign.right),
                    _pdfTableCell('${actualCosts > 0 ? (totalOtherCosts / actualCosts * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                  ],
                ),
                if (totalLossCosts > 0)
                  pw.TableRow(
                    children: [
                      _pdfTableCell('Losses & Damages Value'),
                      _pdfTableCell(_formatMoney(totalLossCosts), align: pw.TextAlign.right),
                      _pdfTableCell('${actualCosts > 0 ? (totalLossCosts / actualCosts * 100).toStringAsFixed(1) : 0}%', align: pw.TextAlign.right),
                    ],
                  ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfTableCell('TOTAL ACTUAL EXPENSES', bold: true),
                    _pdfTableCell(_formatMoney(actualCosts), bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('100.0%', bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Budget vs Actual Comparison Table
            pw.Text(
              'BUDGET VS ACTUAL COMPARISON',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green100),
                  children: [
                    _pdfTableCell('Metric', bold: true),
                    _pdfTableCell('Budgeted Target', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Actual Achieved', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Variance', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Total Revenue / Income'),
                    _pdfTableCell(_formatMoney(budgetedIncome), align: pw.TextAlign.right),
                    _pdfTableCell(_formatMoney(actualIncome), bold: true, align: pw.TextAlign.right),
                    _pdfTableCell(_formatMoney(actualIncome - budgetedIncome), align: pw.TextAlign.right, color: (actualIncome >= budgetedIncome) ? PdfColors.green900 : PdfColors.red900),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Total Expenses / Costs'),
                    _pdfTableCell(_formatMoney(budgetedCosts), align: pw.TextAlign.right),
                    _pdfTableCell(_formatMoney(actualCosts), bold: true, align: pw.TextAlign.right),
                    _pdfTableCell(_formatMoney(actualCosts - budgetedCosts), align: pw.TextAlign.right, color: (actualCosts <= budgetedCosts) ? PdfColors.green900 : PdfColors.red900),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfTableCell('Net Profit / (Loss)', bold: true),
                    _pdfTableCell(_formatMoney(budgetedProfit), bold: true, align: pw.TextAlign.right),
                    _pdfTableCell(_formatMoney(actualProfit), bold: true, align: pw.TextAlign.right, color: isProfitable ? PdfColors.green900 : PdfColors.red900),
                    _pdfTableCell(_formatMoney(actualProfit - budgetedProfit), bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),

            // Advice & Recommendations
            if (advice.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'EXPERT ADVICE & RECOMMENDATIONS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.green200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: advice.map((a) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text('• $a', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'crop_profit_loss_${plan.cropName.toLowerCase().replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
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
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
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
}
