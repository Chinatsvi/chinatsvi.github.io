import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/models/crop/production_record.dart';
import 'package:agribased/services/crop/crop_management_service.dart';

class ProductionTab extends StatelessWidget {
  final CropPlan plan;
  final CropManagementService _service = CropManagementService();

  ProductionTab({super.key, required this.plan});

  String get _currency => plan.currency ?? r'$';
  String _formatMoney(double amount) =>
      '$_currency${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductionRecord>>(
      stream: _service.getProductionRecordsForCropPlan(plan.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];

        final sales = records.where((r) => r.isSale).toList();
        final losses = records.where((r) => r.isLoss).toList();
        final harvests = records.where((r) => r.isHarvest).toList();

        final totalSales = sales.fold<double>(
          0,
          (sum, r) => sum + r.calculatedValue,
        );

        final totalLossCost = losses.fold<double>(
          0,
          (sum, r) => sum + (r.cost ?? 0),
        );

        return Scaffold(
          bottomNavigationBar: const FarmBannerAd(),
          body: records.isEmpty
              ? _buildEmptyView(context)
              : _buildProductionView(
                  context,
                  records,
                  sales,
                  losses,
                  harvests,
                  totalSales,
                  totalLossCost,
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddRecordDialog(context, records),
            backgroundColor: Colors.green.shade700,
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
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
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Production Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record your harvests, crop sales, surplus input sales, and farm losses to track production.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddRecordDialog(context, const []),
              icon: const Icon(Icons.add),
              label: const Text('Record First Harvest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const FarmNativeAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionView(
    BuildContext context,
    List<ProductionRecord> records,
    List<ProductionRecord> sales,
    List<ProductionRecord> losses,
    List<ProductionRecord> harvests,
    double totalSales,
    double totalLossCost,
  ) {
    final totalHarvestQty = harvests.fold<double>(0, (sum, r) => sum + r.quantity);
    final harvestUnit = harvests.isNotEmpty ? harvests.first.unit : 'kg';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sales Revenue',
                  _formatMoney(totalSales),
                  Colors.green.shade700,
                  subtitle: '${sales.length} sales recorded',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Harvested Crop',
                  harvests.isNotEmpty
                      ? '${UnitProductionSummary.formatNum(totalHarvestQty)} $harvestUnit'
                      : '0 $harvestUnit',
                  Colors.orange.shade800,
                  subtitle: harvests.isNotEmpty
                      ? '${harvests.length} harvest logs'
                      : 'No harvests recorded yet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Export PDF (Rewarded ad) ────────────────────────────────
          FarmRewardedAdButton(
            label: 'Watch Ad & Export Production Report',
            icon: Icons.picture_as_pdf,
            color: Colors.green.shade800,
            onRewarded: () => _exportPdf(
              context,
              sales: sales,
              losses: losses,
              harvests: harvests,
              totalSales: totalSales,
              totalLossCost: totalLossCost,
            ),
          ),
          const SizedBox(height: 18),

          // Sales Section
          if (sales.isNotEmpty) ...[
            _buildSectionHeader(
              'Sales Records',
              Icons.trending_up,
              Colors.green.shade700,
            ),
            const SizedBox(height: 12),
            ...sales.map((record) => _buildRecordCard(record)),
            const SizedBox(height: 24),
          ],

          // Harvests Section
          if (harvests.isNotEmpty) ...[
            _buildSectionHeader(
              'Harvest Records',
              Icons.agriculture,
              Colors.orange.shade800,
            ),
            const SizedBox(height: 12),
            ...harvests.map((record) => _buildRecordCard(record)),
            const SizedBox(height: 24),
          ],

          // Losses Section
          if (losses.isNotEmpty) ...[
            _buildSectionHeader(
              'Losses & Damages',
              Icons.warning_amber_rounded,
              Colors.red.shade700,
            ),
            const SizedBox(height: 12),
            ...losses.map((record) => _buildRecordCard(record)),
            const SizedBox(height: 16),
          ],

          // ── Native Ad: after production records ──
          const FarmNativeAd(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, {String? subtitle}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(ProductionRecord record) {
    final isCropSale = record.isCropSale;
    final isOtherSale = record.isOtherSale;
    final isSale = record.isSale;
    final isLoss = record.isLoss;

    final Color cardBg = isCropSale
        ? Colors.green.shade50
        : isOtherSale
        ? Colors.teal.shade50
        : isLoss
        ? Colors.red.shade50
        : Colors.orange.shade50;

    final Color iconBg = isCropSale
        ? Colors.green.shade100
        : isOtherSale
        ? Colors.teal.shade100
        : isLoss
        ? Colors.red.shade100
        : Colors.orange.shade100;

    final IconData iconData = isCropSale
        ? Icons.payments_outlined
        : isOtherSale
        ? Icons.storefront
        : isLoss
        ? Icons.warning_amber_rounded
        : Icons.agriculture;

    final Color iconColor = isCropSale
        ? Colors.green.shade800
        : isOtherSale
        ? Colors.teal.shade800
        : isLoss
        ? Colors.red.shade800
        : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: cardBg,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              record.recordTypeDisplay,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (record.quantity > 0)
              Text(
                isCropSale
                    ? '- ${record.formattedQuantityWithUnit}'
                    : isOtherSale
                    ? record.formattedQuantityWithUnit
                    : isLoss
                    ? record.formattedQuantityWithUnit
                    : '+ ${record.formattedQuantityWithUnit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCropSale
                      ? Colors.green.shade800
                      : isOtherSale
                      ? Colors.teal.shade800
                      : isLoss
                      ? Colors.red.shade800
                      : Colors.orange.shade800,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCropSale)
              Text(
                'Sold: ${record.formattedQuantityWithUnit} (from harvest)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              )
            else if (isOtherSale)
              Text(
                record.notes != null ? 'Item: ${record.notes}' : 'Other Farm Sale',
                style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w500),
              )
            else if (isLoss)
              Text(
                record.lossReason != null ? 'Reason: ${record.lossReason}' : 'Loss/Damage',
                style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600),
              )
            else
              Text(
                'Harvested: ${record.formattedQuantityWithUnit} (Added to stock)',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            if (record.buyer != null) Text('Buyer: ${record.buyer}'),
            if (isLoss && record.notes != null && record.notes!.isNotEmpty)
              Text('Notes: ${record.notes}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(record.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: isSale && record.calculatedValue > 0
            ? Text(
                _formatMoney(record.calculatedValue),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCropSale ? Colors.green.shade700 : Colors.teal.shade700,
                ),
              )
            : (isLoss && record.cost != null && record.cost! > 0
                ? Text(
                    '- ${_formatMoney(record.cost!)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  )
                : null),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddRecordDialog(BuildContext context, List<ProductionRecord> existingRecords) {
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
        child: AddProductionRecordDialog(
          plan: plan,
          existingRecords: existingRecords,
          onRecordAdded: () {},
        ),
      ),
    );
  }

  Future<void> _exportPdf(
    BuildContext context, {
    required List<ProductionRecord> sales,
    required List<ProductionRecord> losses,
    required List<ProductionRecord> harvests,
    required double totalSales,
    required double totalLossCost,
  }) async {
    try {
      final doc = pw.Document();

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
                'Crop Production & Sales Report',
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
            // KPI Summary Cards
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green300, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfKpiStat('Total Sales Revenue', _formatMoney(totalSales), color: PdfColors.green900),
                  _pdfKpiStat('Sales Logs', '${sales.length} entries'),
                  _pdfKpiStat('Harvest Logs', '${harvests.length} entries'),
                  _pdfKpiStat('Total Loss Costs', _formatMoney(totalLossCost), color: PdfColors.red800),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Sales Records Table
            if (sales.isNotEmpty) ...[
              pw.Text(
                'SALES & REVENUE RECORDS',
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
                      _pdfTableCell('Date', bold: true),
                      _pdfTableCell('Type / Description', bold: true),
                      _pdfTableCell('Quantity', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Total Revenue', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Buyer / Contact', bold: true),
                    ],
                  ),
                  ...sales.map((r) => pw.TableRow(
                    children: [
                      _pdfTableCell('${r.date.day}/${r.date.month}/${r.date.year}'),
                      _pdfTableCell(r.isOtherSale ? (r.notes ?? 'Other Sale') : 'Crop Harvest Sale'),
                      _pdfTableCell(r.formattedQuantityWithUnit, align: pw.TextAlign.right),
                      _pdfTableCell(_formatMoney(r.calculatedValue), bold: true, align: pw.TextAlign.right, color: PdfColors.green900),
                      _pdfTableCell(r.buyer != null ? '${r.buyer}${r.buyerContact != null ? " (${r.buyerContact})" : ""}' : '-'),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Harvest Records Table
            if (harvests.isNotEmpty) ...[
              pw.Text(
                'HARVEST PRODUCTION RECORDS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                    children: [
                      _pdfTableCell('Date', bold: true),
                      _pdfTableCell('Harvested Quantity', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Harvest Labor / Cost', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Notes', bold: true),
                    ],
                  ),
                  ...harvests.map((r) => pw.TableRow(
                    children: [
                      _pdfTableCell('${r.date.day}/${r.date.month}/${r.date.year}'),
                      _pdfTableCell(r.formattedQuantityWithUnit, bold: true, align: pw.TextAlign.right),
                      _pdfTableCell(r.cost != null ? _formatMoney(r.cost!) : '-', align: pw.TextAlign.right),
                      _pdfTableCell(r.notes ?? '-'),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Losses Table
            if (losses.isNotEmpty) ...[
              pw.Text(
                'LOSSES & DAMAGES RECORDS (Added to Production Cost)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red100),
                    children: [
                      _pdfTableCell('Date', bold: true),
                      _pdfTableCell('Reason / Description', bold: true),
                      _pdfTableCell('Quantity (if any)', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('Money Wasted / Loss Cost', bold: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...losses.map((r) => pw.TableRow(
                    children: [
                      _pdfTableCell('${r.date.day}/${r.date.month}/${r.date.year}'),
                      _pdfTableCell(r.lossReason ?? (r.notes ?? '-')),
                      _pdfTableCell(r.quantity > 0 ? r.formattedQuantityWithUnit : '-', align: pw.TextAlign.right),
                      _pdfTableCell(r.cost != null ? _formatMoney(r.cost!) : '-', bold: true, align: pw.TextAlign.right, color: PdfColors.red900),
                    ],
                  )),
                ],
              ),
            ],
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'crop_production_${plan.cropName.toLowerCase().replaceAll(' ', '_')}.pdf',
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

class AddProductionRecordDialog extends StatefulWidget {
  final CropPlan plan;
  final List<ProductionRecord> existingRecords;
  final VoidCallback onRecordAdded;

  const AddProductionRecordDialog({
    super.key,
    required this.plan,
    required this.existingRecords,
    required this.onRecordAdded,
  });

  @override
  State<AddProductionRecordDialog> createState() => _AddProductionRecordDialogState();
}

class _AddProductionRecordDialogState extends State<AddProductionRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalValueController = TextEditingController();
  final _buyerController = TextEditingController();
  final _buyerContactController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _lossReasonController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  String _recordType = 'harvest';
  late String _unit;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  final _service = CropManagementService();

  final List<Map<String, dynamic>> _recordTypes = [
    {'value': 'harvest', 'label': 'Harvest', 'icon': Icons.agriculture, 'color': Colors.orange},
    {'value': 'sale', 'label': 'Crop Sale', 'icon': Icons.payments_outlined, 'color': Colors.green},
    {'value': 'other_sale', 'label': 'Other Sales', 'icon': Icons.storefront, 'color': Colors.teal},
    {'value': 'loss', 'label': 'Loss/Damage', 'icon': Icons.warning_amber_rounded, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    final harvestRecords = widget.existingRecords.where((r) => r.isHarvest).toList();
    if (harvestRecords.isNotEmpty) {
      _unit = harvestRecords.first.unit;
    } else {
      _unit = 'kg';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _totalValueController.dispose();
    _buyerController.dispose();
    _buyerContactController.dispose();
    _itemDescriptionController.dispose();
    _lossReasonController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
      final pricePerUnit = double.tryParse(_priceController.text.trim());
      final totalValue = double.tryParse(_totalValueController.text.trim());
      final cost = double.tryParse(_costController.text.trim());

      String? notesText = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
      if (_recordType == 'other_sale' && _itemDescriptionController.text.trim().isNotEmpty) {
        final itemDesc = _itemDescriptionController.text.trim();
        notesText = notesText != null ? '$itemDesc • $notesText' : itemDesc;
      }

      final record = ProductionRecord(
        id: '',
        farmerId: widget.plan.farmerId,
        cropPlanId: widget.plan.id,
        recordType: _recordType,
        date: _date,
        quantity: quantity,
        unit: _unit,
        pricePerUnit: pricePerUnit,
        totalValue: totalValue,
        buyer: _buyerController.text.trim().isNotEmpty ? _buyerController.text.trim() : null,
        buyerContact: _buyerContactController.text.trim().isNotEmpty ? _buyerContactController.text.trim() : null,
        lossReason: _lossReasonController.text.trim().isNotEmpty ? _lossReasonController.text.trim() : null,
        cost: cost,
        notes: notesText,
        createdAt: DateTime.now(),
      );

      await _service.createProductionRecord(record);
      widget.onRecordAdded();

      if (mounted) {
        Navigator.pop(context);
        String successMessage = 'Production record added successfully!';
        if (_recordType == 'sale') {
          successMessage = 'Crop sale recorded and deducted from harvest stock!';
        } else if (_recordType == 'other_sale') {
          successMessage = 'Other sale recorded into total sales!';
        } else if (_recordType == 'loss') {
          successMessage = 'Loss/damage recorded into production cost!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
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
    final isCropSale = _recordType == 'sale';
    final isOtherSale = _recordType == 'other_sale';
    final isSale = isCropSale || isOtherSale;
    final isLoss = _recordType == 'loss';
    final isHarvest = _recordType == 'harvest';

    final unitSummaries = UnitProductionSummary.groupRecords(widget.existingRecords);
    final selectedSummary = unitSummaries[_unit.toLowerCase()];
    final harvested = selectedSummary?.harvested ?? 0.0;
    final available = selectedSummary?.remainingStock ?? 0.0;

    // Available units list
    final defaultUnits = ['kg', 'tons', 'bags', 'cobs', 'bunches', 'liters', 'units'];
    final existingUnits = widget.existingRecords.map((r) => r.unit.trim()).where((u) => u.isNotEmpty).toList();
    final allUnits = {...defaultUnits, ...existingUnits, _unit}.toList();

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
                  Icon(Icons.shopping_cart_outlined, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Add Production Record',
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
                        'Record Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recordTypes.map((type) {
                          final isSelected = _recordType == type['value'];
                          return ChoiceChip(
                            avatar: Icon(
                              type['icon'] as IconData,
                              size: 18,
                              color: isSelected ? Colors.white : type['color'] as Color,
                            ),
                            label: Text(type['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _recordType = type['value'] as String);
                              }
                            },
                            selectedColor: type['color'] as Color,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today, color: Colors.green.shade700),
                        title: const Text('Date *'),
                        subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                        trailing: TextButton(
                          onPressed: _selectDate,
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Other Sales: Description of item / surplus input sold ──
                      if (isOtherSale) ...[
                        TextFormField(
                          controller: _itemDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Item Sold / Description *',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            hintText: 'e.g. Surplus fertilizer, Extra seeds, Stalks/Hay, Equipment hire',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (isOtherSale && (v == null || v.trim().isEmpty)) {
                              return 'Enter description of item or surplus sold';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Loss / Damage: Reason for loss & wasted cost ──
                      if (isLoss) ...[
                        TextFormField(
                          controller: _lossReasonController,
                          decoration: const InputDecoration(
                            labelText: 'Loss / Damage Reason or Description *',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                            hintText: 'e.g., Petrol wasted, Tractor repair, Theft, Pests, Spoilage',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (isLoss && (v == null || v.trim().isEmpty)) {
                              return 'Enter reason or description of loss/damage';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _costController,
                          decoration: const InputDecoration(
                            labelText: 'Money Wasted / Loss Cost *',
                            prefixIcon: Icon(Icons.payments_outlined),
                            hintText: 'Financial cost wasted (contributes to production cost)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (isLoss) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter money wasted / loss amount';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) {
                                return 'Enter a valid positive amount';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Quantity & Unit Row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: isCropSale
                                    ? 'Quantity to Sell *'
                                    : (isHarvest
                                        ? 'Harvest Quantity *'
                                        : (isOtherSale ? 'Quantity Sold *' : 'Quantity (Optional)')),
                                prefixIcon: const Icon(Icons.scale_outlined),
                                helperText: isCropSale
                                    ? (harvested > 0
                                        ? 'Available: ${UnitProductionSummary.formatNum(available)} $_unit'
                                        : 'No $_unit harvest in stock')
                                    : null,
                                helperStyle: TextStyle(
                                  color: isCropSale
                                      ? (available > 0 ? Colors.green.shade800 : Colors.red.shade700)
                                      : null,
                                  fontWeight: isCropSale ? FontWeight.w600 : null,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (!isLoss && text.isEmpty) {
                                  return 'Enter quantity';
                                }
                                if (text.isNotEmpty) {
                                  final qty = double.tryParse(text);
                                  if (qty == null || qty <= 0) {
                                    return 'Enter a valid quantity > 0';
                                  }
                                  if (isCropSale) {
                                    if (harvested <= 0) {
                                      return 'No $_unit harvested. Harvest first!';
                                    }
                                    if (qty > available) {
                                      return 'Cannot sell ${UnitProductionSummary.formatNum(qty)} $_unit. Only ${UnitProductionSummary.formatNum(available)} in stock.';
                                    }
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _unit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              items: allUnits
                                  .map((unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _unit = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Sales Pricing Fields (Crop Sale & Other Sales) ──
                      if (isSale) ...[
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price per Unit',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalValueController,
                          decoration: const InputDecoration(
                            labelText: 'Total Sale Revenue *',
                            prefixIcon: Icon(Icons.calculate_outlined),
                            helperText: 'Leave empty to calculate: Quantity × Price/Unit',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final priceText = _priceController.text.trim();
                            final totalText = v?.trim() ?? '';
                            if (priceText.isEmpty && totalText.isEmpty) {
                              return 'Enter either Price per Unit or Total Sale Revenue';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _buyerController,
                          decoration: const InputDecoration(
                            labelText: 'Buyer Name (Optional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _buyerContactController,
                          decoration: const InputDecoration(
                            labelText: 'Buyer Contact (Optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Harvest Cost (Optional for harvest record) ──
                      if (isHarvest) ...[
                        TextFormField(
                          controller: _costController,
                          decoration: const InputDecoration(
                            labelText: 'Harvest Labor / Direct Cost – Optional',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCropSale
                                ? Colors.green.shade700
                                : (isOtherSale
                                    ? Colors.teal.shade700
                                    : (isLoss ? Colors.red.shade700 : Colors.orange.shade800)),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isCropSale
                                      ? 'Record Crop Sale'
                                      : (isOtherSale
                                          ? 'Record Other Sale'
                                          : (isLoss ? 'Save Loss & Production Cost' : 'Record Harvest')),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
