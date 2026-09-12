import 'package:flutter/material.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/models/crop/crop_budget.dart';
import 'package:agribased/services/crop/crop_management_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';

// ─────────────────────────── Budget Planner Tab ───────────────────────────────

class BudgetPlannerTab extends StatelessWidget {
  final CropPlan plan;
  final CropManagementService _service = CropManagementService();

  BudgetPlannerTab({super.key, required this.plan});

  String get _currency => plan.currency ?? r'$';
  String _fmt(double v) => '$_currency${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CropBudget?>(
      stream: _service.getBudgetForCropPlan(plan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final budget = snapshot.data;
        if (budget == null) return _buildNoBudgetView(context);
        return _buildBudgetView(context, budget);
      },
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildNoBudgetView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'No Budget Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a budget to track input costs, labour, and expected income for this crop plan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showCreateBudgetDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Budget', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Budget View ─────────────────────────────────────────────────────────

  Widget _buildBudgetView(BuildContext context, CropBudget budget) {
    final inputItems = budget.items.where((i) => i.category == 'inputs').toList();
    final laborItems = budget.items.where((i) => i.category == 'labor').toList();
    final otherItems = budget.items.where((i) => i.category == 'other').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Cards Row ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total Costs',
                  budget.totalCosts,
                  Colors.red.shade600,
                  Colors.red.shade50,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'Expected Income',
                  budget.expectedIncome,
                  Colors.green.shade700,
                  Colors.green.shade50,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Full-width profit card
          _summaryCard(
            'Expected Profit',
            budget.expectedProfit,
            budget.expectedProfit >= 0
                ? Colors.blue.shade700
                : Colors.orange.shade700,
            budget.expectedProfit >= 0
                ? Colors.blue.shade50
                : Colors.orange.shade50,
            budget.expectedProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            fullWidth: true,
          ),
          const SizedBox(height: 28),

          // ─── Yield Information ──────────────────────────────────────
          if (budget.expectedYield != null) ...[
            _sectionTitle(context, 'Yield & Income', Icons.scale),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Expected Yield',
                        '${budget.formattedExpectedYield ?? budget.expectedYield} ${budget.yieldUnit ?? 'units'}'),
                    if (budget.pricePerUnit != null) ...[
                      const Divider(height: 20),
                      _infoRow('Price per Unit',
                          '$_currency${budget.pricePerUnit!.toStringAsFixed(2)}'),
                    ],
                    const Divider(height: 20),
                    _infoRow('Expected Income', _fmt(budget.expectedIncome),
                        valueColor: Colors.green.shade700, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ─── Cost Breakdown ─────────────────────────────────────────
          _sectionTitle(context, 'Cost Breakdown', Icons.receipt_long),
          const SizedBox(height: 14),

          _categoryCard(
            context: context,
            title: 'Inputs',
            subtitle: 'Seeds · Fertilizer · Chemicals',
            icon: Icons.shopping_basket,
            color: Colors.brown.shade600,
            bgColor: Colors.brown.shade50,
            items: inputItems,
            total: budget.totalInputCosts,
            budget: budget,
          ),
          const SizedBox(height: 14),

          // ── Native Ad between categories ──────────────────────────
          const FarmNativeAd(),
          const SizedBox(height: 14),

          _categoryCard(
            context: context,
            title: 'Labour',
            subtitle: 'Land prep · Planting · Weeding · Harvesting',
            icon: Icons.people,
            color: Colors.blue.shade700,
            bgColor: Colors.blue.shade50,
            items: laborItems,
            total: budget.totalLaborCosts,
            budget: budget,
          ),
          const SizedBox(height: 14),

          _categoryCard(
            context: context,
            title: 'Other Expenses',
            subtitle: 'Transport · Equipment · Misc',
            icon: Icons.more_horiz,
            color: Colors.grey.shade700,
            bgColor: Colors.grey.shade50,
            items: otherItems,
            total: budget.totalOtherCosts,
            budget: budget,
          ),
          const SizedBox(height: 24),

          // ─── Grand Total ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text('GRAND TOTAL COSTS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Text(
                  _fmt(budget.totalCosts),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Action Buttons ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddItemDialog(context, budget),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditBudgetDialog(context, budget),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Yield'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Export PDF (Rewarded ad) ────────────────────────────────
          FarmRewardedAdButton(
            label: 'Export Budget as PDF',
            icon: Icons.picture_as_pdf,
            color: Colors.green.shade800,
            onRewarded: () => _exportPdf(context, budget),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Summary Card ─────────────────────────────────────────────────────────────

  Widget _summaryCard(
    String title,
    double amount,
    Color textColor,
    Color bgColor,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: textColor.withOpacity(0.2)),
      ),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                  fontSize: 12, color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              '$_currency${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
        ),
      ],
    );
  }

  // ── Info Row ─────────────────────────────────────────────────────────────────

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Category Card ────────────────────────────────────────────────────────────

  Widget _categoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<BudgetItem> items,
    required double total,
    required CropBudget budget,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: bgColor,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: color)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(
                  '$_currency${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Items
          if (items.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('No items added yet',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                          fontSize: 13)),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Column(
                children: [
                  if (idx > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemRow(item, budget),
                ],
              );
            }),

          // Subtotal divider
          if (items.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${title} Subtotal',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  Text(
                    '$_currency${total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Item Row ─────────────────────────────────────────────────────────────────

  Widget _itemRow(BudgetItem item, CropBudget budget) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Item name
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          // Qty × Unit
          Expanded(
            flex: 2,
            child: Text(
              item.formattedQuantityWithUnit,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          // Unit cost
          Expanded(
            flex: 2,
            child: Text(
              '@$_currency${item.unitCost.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          // Total
          Expanded(
            flex: 2,
            child: Text(
              _fmt(item.totalCost),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF Export ───────────────────────────────────────────────────────────────

  Future<void> _exportPdf(BuildContext context, CropBudget budget) async {
    final doc = pw.Document();
    final inputItems =
        budget.items.where((i) => i.category == 'inputs').toList();
    final laborItems =
        budget.items.where((i) => i.category == 'labor').toList();
    final otherItems =
        budget.items.where((i) => i.category == 'other').toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Crop Budget Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Text(
              '${plan.cropName} — ${plan.fieldName}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Text(
              'Planting: ${plan.plantingDate.day}/${plan.plantingDate.month}/${plan.plantingDate.year}  •  '
              'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.green800, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (_) => [
          // Summary banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdStat('Total Costs', _fmt(budget.totalCosts)),
                _pdStat('Expected Income', _fmt(budget.expectedIncome)),
                _pdStat('Expected Profit', _fmt(budget.expectedProfit)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Yield info
          if (budget.expectedYield != null) ...[
            pw.Text(
              'YIELD & INCOME',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
                letterSpacing: 1.0,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _pdTableRow(['Expected Yield',
                    '${budget.formattedExpectedYield ?? budget.expectedYield} ${budget.yieldUnit ?? "units"}'], header: false),
                if (budget.pricePerUnit != null)
                  _pdTableRow(['Price per Unit',
                      '$_currency${budget.pricePerUnit!.toStringAsFixed(2)}'], header: false),
                _pdTableRow(['Expected Income', _fmt(budget.expectedIncome)],
                    header: false, boldValue: true),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Cost sections
          if (inputItems.isNotEmpty) ...[
            _pdCategorySection('INPUTS (Seeds, Fertilizer, Chemicals)',
                inputItems, budget.totalInputCosts),
            pw.SizedBox(height: 14),
          ],
          if (laborItems.isNotEmpty) ...[
            _pdCategorySection('LABOUR (Land prep, Planting, Weeding)',
                laborItems, budget.totalLaborCosts),
            pw.SizedBox(height: 14),
          ],
          if (otherItems.isNotEmpty) ...[
            _pdCategorySection('OTHER EXPENSES',
                otherItems, budget.totalOtherCosts),
            pw.SizedBox(height: 14),
          ],

          // Grand total
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.red200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GRAND TOTAL COSTS',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800)),
                pw.Text(_fmt(budget.totalCosts),
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'budget_${plan.cropName.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _pdStat(String label, String value) {
    return pw.Column(children: [
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      pw.SizedBox(height: 3),
      pw.Text(value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  static pw.Widget _pdCategorySection(
      String title, List<BudgetItem> items, double total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
                letterSpacing: 0.5)),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: ['Item', 'Qty', 'Unit', 'Unit Cost', 'Total'].map((h) =>
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  )).toList(),
            ),
            ...items.map((item) => pw.TableRow(children: [
                  _pdCell(item.name),
                  _pdCell(item.formattedQuantity, align: pw.TextAlign.center),
                  _pdCell(item.unit ?? '', align: pw.TextAlign.center),
                  _pdCell('@\$${item.unitCost.toStringAsFixed(2)}',
                      align: pw.TextAlign.right),
                  _pdCell('\$${item.totalCost.toStringAsFixed(2)}',
                      align: pw.TextAlign.right, bold: true),
                ])),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text('Subtotal',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                _pdCell('', align: pw.TextAlign.right),
                _pdCell('', align: pw.TextAlign.right),
                _pdCell('', align: pw.TextAlign.right),
                _pdCell('\$${total.toStringAsFixed(2)}',
                    align: pw.TextAlign.right, bold: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null)),
    );
  }

  static pw.TableRow _pdTableRow(
    List<String> cells, {
    bool header = false,
    bool boldValue = false,
  }) {
    return pw.TableRow(
      decoration: header
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: cells.asMap().entries.map((e) {
        final isBold = header || (boldValue && e.key == 1);
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(e.value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: isBold ? pw.FontWeight.bold : null)),
        );
      }).toList(),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showCreateBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreateBudgetDialog(plan: plan, onBudgetCreated: () {}),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, CropBudget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddBudgetItemDialog(budget: budget, onItemAdded: () {}),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, CropBudget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditBudgetDialog(budget: budget, onBudgetUpdated: () {}),
      ),
    );
  }
}
class CreateBudgetDialog extends StatefulWidget {
  final CropPlan plan;
  final VoidCallback onBudgetCreated;

  const CreateBudgetDialog({
    super.key,
    required this.plan,
    required this.onBudgetCreated,
  });

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _yieldController = TextEditingController();
  final _yieldUnitController = TextEditingController(text: 'kg');
  final _priceController = TextEditingController();

  // Controllers for adding new budget item
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final _itemUnitController = TextEditingController();
  final _itemCostController = TextEditingController();
  final _itemNotesController = TextEditingController();
  String _itemCategory = 'inputs';

  List<BudgetItem> _budgetItems = [];
  bool _isLoading = false;

  final _service = CropManagementService();

  @override
  void dispose() {
    _yieldController.dispose();
    _yieldUnitController.dispose();
    _priceController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _itemUnitController.dispose();
    _itemCostController.dispose();
    _itemNotesController.dispose();
    super.dispose();
  }

  void _addBudgetItem() {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter item name')));
      return;
    }

    final quantity = double.tryParse(_itemQuantityController.text) ?? 0;
    final unitCost = double.tryParse(_itemCostController.text) ?? 0;
    final totalCost = quantity * unitCost;

    final newItem = BudgetItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _itemCategory,
      name: _itemNameController.text.trim(),
      quantity: quantity,
      unit: _itemUnitController.text.trim().isNotEmpty
          ? _itemUnitController.text.trim()
          : null,
      unitCost: unitCost,
      totalCost: totalCost,
      expectedDate: null,
      notes: _itemNotesController.text.trim().isNotEmpty
          ? _itemNotesController.text.trim()
          : null,
    );

    setState(() {
      _budgetItems.add(newItem);
      _clearItemForm();
    });
  }

  void _clearItemForm() {
    _itemNameController.clear();
    _itemQuantityController.clear();
    _itemUnitController.clear();
    _itemCostController.clear();
    _itemNotesController.clear();
    _itemCategory = 'inputs';
  }

  void _removeItem(int index) {
    setState(() {
      _budgetItems.removeAt(index);
    });
  }

  double get _totalInputCosts => _budgetItems
      .where((i) => i.category == 'inputs')
      .fold(0, (sum, i) => sum + i.totalCost);

  double get _totalLaborCosts => _budgetItems
      .where((i) => i.category == 'labor')
      .fold(0, (sum, i) => sum + i.totalCost);

  double get _totalOtherCosts => _budgetItems
      .where((i) => i.category == 'other')
      .fold(0, (sum, i) => sum + i.totalCost);

  double get _totalCosts =>
      _totalInputCosts + _totalLaborCosts + _totalOtherCosts;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expectedYield = double.tryParse(_yieldController.text) ?? 0;
      final pricePerUnit = double.tryParse(_priceController.text) ?? 0;
      final expectedIncome = expectedYield * pricePerUnit;

      final budget = CropBudget(
        id: '',
        farmerId: widget.plan.farmerId,
        cropPlanId: widget.plan.id,
        cropPlanName: widget.plan.cropName,
        items: _budgetItems,
        expectedIncome: expectedIncome,
        expectedYield: expectedYield,
        yieldUnit: _yieldUnitController.text.trim(),
        pricePerUnit: pricePerUnit,
        createdAt: DateTime.now(),
      );

      await _service.createBudget(budget);
      widget.onBudgetCreated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
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

  String _getCategoryName(String category) {
    switch (category) {
      case 'inputs':
        return 'Inputs';
      case 'labor':
        return 'Labor';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'inputs':
        return Colors.brown;
      case 'labor':
        return Colors.blue;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.plan.currency ?? r'$';
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
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
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Budget',
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
                      // Expected Yield & Income Section
                      _buildSectionTitle('Expected Yield & Income'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yieldController,
                              decoration: const InputDecoration(
                                labelText: 'Expected Yield *',
                                prefixIcon: Icon(Icons.scale),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter expected yield';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yieldUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price per Unit *',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter price per unit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Budget Summary Card
                      if (_budgetItems.isNotEmpty) ...[
                        _buildSectionTitle('Budget Summary'),
                        const SizedBox(height: 12),
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  'Inputs',
                                  _totalInputCosts,
                                  currency,
                                  Colors.brown,
                                ),
                                _buildSummaryRow(
                                  'Labor',
                                  _totalLaborCosts,
                                  currency,
                                  Colors.blue,
                                ),
                                _buildSummaryRow(
                                  'Other',
                                  _totalOtherCosts,
                                  currency,
                                  Colors.grey,
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Total Costs',
                                  _totalCosts,
                                  currency,
                                  Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Added Budget Items List
                      if (_budgetItems.isNotEmpty) ...[
                        _buildSectionTitle('Budget Items'),
                        const SizedBox(height: 12),
                        ..._budgetItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _buildBudgetItemCard(item, index, currency);
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Add New Item Section
                      _buildSectionTitle('Add Budget Item'),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _itemCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'inputs',
                                    child: Text(
                                      'Inputs (Seeds, Fertilizer, Chemicals)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'labor',
                                    child: Text(
                                      'Labor (Land prep, Planting, Weeding)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text('Other Expenses'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _itemCategory = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _itemNameController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Item Name * (e.g., Compound D, Land prep)',
                                  prefixIcon: Icon(Icons.label),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _itemQuantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        prefixIcon: Icon(Icons.numbers),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _itemUnitController,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        hintText: 'bags, kg, hrs',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _itemCostController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cost',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _itemNotesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                  prefixIcon: Icon(Icons.notes),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addBudgetItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add to Budget'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Create Budget Button
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Create Budget',
                                  style: TextStyle(fontSize: 16),
                                ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade700,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    String currency,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItemCard(BudgetItem item, int index, String currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(item.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getCategoryName(item.category),
            style: TextStyle(
              fontSize: 12,
              color: _getCategoryColor(item.category),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.formattedQuantityWithUnit} @ $currency${item.unitCost.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency${item.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _removeItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBudgetItemDialog extends StatefulWidget {
  final CropBudget budget;
  final VoidCallback onItemAdded;

  const AddBudgetItemDialog({
    super.key,
    required this.budget,
    required this.onItemAdded,
  });

  @override
  State<AddBudgetItemDialog> createState() => _AddBudgetItemDialogState();
}

class _AddBudgetItemDialogState extends State<AddBudgetItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'inputs';
  DateTime? _expectedDate;
  bool _isLoading = false;

  final _service = CropManagementService();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _expectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final unitCost = double.tryParse(_unitCostController.text) ?? 0;

      final newItem = BudgetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: _category,
        name: _nameController.text.trim(),
        quantity: quantity,
        unit: _unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : null,
        unitCost: unitCost,
        totalCost: quantity * unitCost,
        expectedDate: _expectedDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final updatedItems = [...widget.budget.items, newItem];
      final updatedBudget = widget.budget.copyWith(items: updatedItems);

      await _service.updateBudget(updatedBudget);
      widget.onItemAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
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
      initialChildSize: 0.85,
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
                  Icon(Icons.add_shopping_cart, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Add Budget Item',
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
                          DropdownMenuItem(
                            value: 'inputs',
                            child: Text('Inputs (Seeds, Fertilizer)'),
                          ),
                          DropdownMenuItem(
                            value: 'labor',
                            child: Text('Labor'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other Expenses'),
                          ),
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
                                labelText: 'Unit',
                                prefixIcon: Icon(Icons.straighten),
                                hintText: 'bags, kg, hrs',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _unitCostController,
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
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.green.shade700,
                        ),
                        title: const Text('Expected Date (Optional)'),
                        subtitle: Text(
                          _expectedDate != null
                              ? '${_expectedDate!.day}/${_expectedDate!.month}/${_expectedDate!.year}'
                              : 'Not set',
                        ),
                        trailing: TextButton(
                          onPressed: _selectDate,
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Add Item',
                                  style: TextStyle(fontSize: 16),
                                ),
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

class EditBudgetDialog extends StatefulWidget {
  final CropBudget budget;
  final VoidCallback onBudgetUpdated;

  const EditBudgetDialog({
    super.key,
    required this.budget,
    required this.onBudgetUpdated,
  });

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _yieldController = TextEditingController(
    text: widget.budget.expectedYield?.toString() ?? '',
  );
  late final _yieldUnitController = TextEditingController(
    text: widget.budget.yieldUnit ?? 'kg',
  );
  late final _priceController = TextEditingController(
    text: widget.budget.pricePerUnit?.toString() ?? '',
  );
  bool _isLoading = false;

  final _service = CropManagementService();

  @override
  void dispose() {
    _yieldController.dispose();
    _yieldUnitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expectedYield = double.tryParse(_yieldController.text) ?? 0;
      final pricePerUnit = double.tryParse(_priceController.text) ?? 0;
      final expectedIncome = expectedYield * pricePerUnit;

      final updatedBudget = widget.budget.copyWith(
        expectedYield: expectedYield,
        yieldUnit: _yieldUnitController.text.trim(),
        pricePerUnit: pricePerUnit,
        expectedIncome: expectedIncome,
      );

      await _service.updateBudget(updatedBudget);
      widget.onBudgetUpdated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully!'),
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
      initialChildSize: 0.7,
      maxChildSize: 0.9,
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
                    'Edit Budget',
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
                      Text(
                        'Update Expected Yield & Income',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yieldController,
                              decoration: const InputDecoration(
                                labelText: 'Expected Yield *',
                                prefixIcon: Icon(Icons.scale),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter expected yield';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yieldUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price per Unit *',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter price per unit';
                          }
                          return null;
                        },
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 16),
                                ),
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

