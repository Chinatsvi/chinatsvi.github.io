import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/academy/certificate_model.dart';

class AcademyCertificatePdfService {
  static final AcademyCertificatePdfService instance =
      AcademyCertificatePdfService._internal();
  AcademyCertificatePdfService._internal();

  static final PdfColor _darkGreen = PdfColor.fromHex('#0D3829');
  static final PdfColor _primaryGreen = PdfColor.fromHex('#1B4D3E');
  static final PdfColor _gold = PdfColor.fromHex('#C5A059');
  static final PdfColor _lightGold = PdfColor.fromHex('#FDF8ED');
  static final PdfColor _lightGreen = PdfColor.fromHex('#EBF5EE');
  static final PdfColor _textDark = PdfColor.fromHex('#1F2421');
  static final PdfColor _textMuted = PdfColor.fromHex('#4B5548');

  /// Generate high quality A4 Portrait (Vertical) PDF certificate
  Future<Uint8List> generateCertificatePdf(CertificateModel cert) async {
    final pdf = pw.Document(
      title: 'Certificate_${cert.certificateNumber}',
      author: 'AgriBase Farming Academy',
    );

    final dateFormatted = DateFormat('MMMM d, yyyy').format(cert.issuedAt);
    final gradeLabel = cert.scorePercentage >= 90
        ? 'Distinction'
        : (cert.scorePercentage >= 75 ? 'Merit' : 'Pass');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _darkGreen, width: 3.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  // Subtle Watermark Background
                  pw.Opacity(
                    opacity: 0.04,
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 220,
                            height: 220,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: _darkGreen, width: 9),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'AGRIBASE',
                                style: pw.TextStyle(
                                  fontSize: 32,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _darkGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Content Layout (Vertical / Portrait)
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // 1. Top Header Bar (Academy Crest & Name + ID & QR Code)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Academy Crest and Name
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 36,
                                height: 36,
                                decoration: pw.BoxDecoration(
                                  color: _darkGreen,
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(color: _gold, width: 1.5),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    '🌱',
                                    style: const pw.TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'AGRIBASE FARMING ACADEMY',
                                    style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: _darkGreen,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'Excellence in Agricultural Education',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: _gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Certificate ID & QR Code
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: _lightGreen,
                                  border: pw.Border.all(color: _primaryGreen, width: 1),
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      'CERTIFICATE ID',
                                      style: pw.TextStyle(
                                        fontSize: 6.5,
                                        fontWeight: pw.FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: _textMuted,
                                      ),
                                    ),
                                    pw.Text(
                                      cert.certificateNumber,
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Container(
                                width: 34,
                                height: 34,
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  border: pw.Border.all(color: _gold, width: 1),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: 'https://agribased.com/verify?id=${cert.certificateNumber}',
                                  drawText: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 18),

                      // 2. Main Title Section
                      pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(width: 70, height: 1.2, color: _gold),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                                child: pw.Text(
                                  '★',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: _gold,
                                  ),
                                ),
                              ),
                              pw.Container(width: 70, height: 1.2, color: _gold),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'CERTIFICATE OF',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 4.0,
                              color: _darkGreen,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'COMPLETION',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 4.5,
                              color: _darkGreen,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(width: 70, height: 1.2, color: _gold),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                                child: pw.Text(
                                  '★',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: _gold,
                                  ),
                                ),
                              ),
                              pw.Container(width: 70, height: 1.2, color: _gold),
                            ],
                          ),
                          pw.SizedBox(height: 16),
                          pw.Text(
                            'This certificate is proudly presented to',
                            style: pw.TextStyle(
                              fontSize: 11.5,
                              fontStyle: pw.FontStyle.italic,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 12),

                      // 3. Recipient Name
                      pw.Column(
                        children: [
                          pw.Text(
                            cert.userName.toUpperCase(),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 23,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.8,
                              color: _textDark,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            width: 280,
                            height: 1.5,
                            color: _gold,
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 16),

                      // 4. Course Details
                      pw.Column(
                        children: [
                          pw.Text(
                            'for successfully completing the approved agricultural curriculum for',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _lightGreen,
                              border: pw.Border.all(color: _primaryGreen, width: 1.2),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Text(
                              cert.courseTitle.toUpperCase(),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1.0,
                                color: _darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 14),

                      // 5. Academic Metrics (Date & Score)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Completion Date: $dateFormatted',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _textMuted,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                            child: pw.Text(
                              '•',
                              style: pw.TextStyle(fontSize: 12, color: _gold),
                            ),
                          ),
                          pw.Text(
                            'Academic Grade: ${cert.scorePercentage}% ($gradeLabel)',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 24),

                      // 6. Signatures & Official Verification Seal
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Left: Instructor Signature
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 140,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: PdfColors.grey700,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  cert.instructorName ?? 'Dr. E. Chinatsvi',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Instructor / Academy',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),

                          // Center: Official 3D-styled Seal
                          pw.Container(
                            width: 62,
                            height: 62,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: _lightGold,
                              border: pw.Border.all(color: _gold, width: 2),
                            ),
                            child: pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'AGRIBASE',
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: _darkGreen,
                                    ),
                                  ),
                                  pw.Container(
                                    margin: const pw.EdgeInsets.symmetric(vertical: 1.5),
                                    width: 32,
                                    height: 0.8,
                                    color: _gold,
                                  ),
                                  pw.Text(
                                    'OFFICIAL\nSEAL',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _gold,
                                    ),
                                  ),
                                  pw.Text(
                                    '★ ★ ★',
                                    style: pw.TextStyle(
                                      fontSize: 4.5,
                                      color: _darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right: Academy Director Signature
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 140,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: PdfColors.grey700,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  'Academy Director',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'AgriBase Farming Academy',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Save PDF
  Future<void> printOrDownloadCertificate(CertificateModel cert) async {
    final bytes = await generateCertificatePdf(cert);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Certificate_${cert.certificateNumber}.pdf',
    );
  }

  /// Share PDF
  Future<void> shareCertificate(CertificateModel cert) async {
    final bytes = await generateCertificatePdf(cert);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Certificate_${cert.certificateNumber}.pdf',
    );
  }
}
