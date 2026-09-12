import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';

import 'farm_calculator_history.dart';

const farmGreen = Color(0xFF2E7D32);
const farmLightGreen = Color(0xFFE8F5E9);

class FarmCalculatorLayout extends StatelessWidget {
  final String calculatorType;
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> fields;
  final String? result;
  final String? resultDetails;
  final String? note;
  final VoidCallback? onExport;
  final String exportLabel;

  const FarmCalculatorLayout({
    super.key,
    required this.calculatorType,
    required this.title,
    required this.description,
    required this.icon,
    required this.fields,
    required this.result,
    required this.resultDetails,
    this.note,
    required this.onExport,
    required this.exportLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasParentScaffold = Scaffold.maybeOf(context) != null;

    final content = GestureDetector(
      onTap: dismissCalculatorKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: farmLightGreen,
                        child: Icon(
                          icon,
                          color: farmGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: farmGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.green.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: fields,
                      ),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: farmLightGreen,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: farmGreen,
                            ),
                          ),
                          if (resultDetails != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              resultDetails!,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onExport != null) ...[
                      const SizedBox(height: 16),
                      FarmRewardedAdButton(
                        label: exportLabel,
                        icon: Icons.picture_as_pdf,
                        color: farmGreen,
                        onRewarded: onExport!,
                      ),
                    ],
                  ],
                  FarmCalculatorHistory(calculatorType: calculatorType),
                ],
              ),
            ),
          ),
          const FarmBannerAd(),
        ],
      ),
    );

    if (!hasParentScaffold) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: farmGreen,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }
}

class FarmField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const FarmField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: farmGreen, width: 2),
          ),
        ),
      ),
    );
  }
}

double? farmNumber(TextEditingController controller) =>
    double.tryParse(controller.text.trim());

String farmFormatNumber(num value) =>
    NumberFormat('#,##0.##', 'en_US').format(value).replaceAll(',', ' ');

void dismissCalculatorKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

ButtonStyle farmButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: farmGreen,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

Future<void> exportFarmReport(
  String title,
  Map<String, String> inputs,
  String result,
  String? details,
) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AgriBase Farm Works',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.green200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CALCULATION RESULT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                result,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              if (details != null) ...[
                pw.SizedBox(height: 6),
                pw.Text(details),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'INPUTS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: inputs.entries
              .map(
                (entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        entry.key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(entry.value),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'This report was generated by AgriBase Farm Works.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    ),
  );
  await Printing.sharePdf(
    bytes: await document.save(),
    filename:
        '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.pdf',
  );
}
