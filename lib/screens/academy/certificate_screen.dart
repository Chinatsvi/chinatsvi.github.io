import 'package:barcode/barcode.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../models/academy/certificate_model.dart';
import '../../../services/academy/academy_certificate_pdf_service.dart';
import '../../../widgets/ads/farm_banner_ad.dart';
import '../../../widgets/ads/farm_interstitial_ad.dart';

class CertificateScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateScreen({super.key, required this.certificate});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  static const Color _darkGreen = Color(0xFF0D3829);
  static const Color _primaryGreen = Color(0xFF1B4D3E);
  static const Color _gold = Color(0xFFC5A059);
  static const Color _goldDark = Color(0xFF997733);
  static const Color _lightGold = Color(0xFFFDF8ED);
  static const Color _lightGreen = Color(0xFFEBF5EE);
  static const Color _certBg = Color(0xFFFCFAF5);

  @override
  void initState() {
    super.initState();
    FarmInterstitialAd.preload();
  }

  @override
  Widget build(BuildContext context) {
    final certificate = widget.certificate;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && currentUserId == certificate.userId;

    final dateFormatted =
        DateFormat('MMMM d, yyyy').format(certificate.issuedAt);
    final gradeLabel = certificate.scorePercentage >= 90
        ? 'Distinction'
        : (certificate.scorePercentage >= 75 ? 'Merit' : 'Pass');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      bottomNavigationBar: const FarmBannerAd(),
      appBar: AppBar(
        title: const Text(
          'Official Certificate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Verify Credential',
            onPressed: () => _showVerificationDialog(context),
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share Certificate',
              onPressed: () => _handleShareCertificate(context),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: () => _handleDownloadCertificate(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            // Status banner for visitors vs owner
            _buildStatusHeader(isOwner),

            const SizedBox(height: 10),

            // Certificate Landscape / Full Width Card
            _buildCertificateCard(certificate, dateFormatted, gradeLabel),

            const SizedBox(height: 18),

            // Action Buttons
            _buildActionButtons(isOwner),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isOwner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOwner ? _lightGreen : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOwner
              ? _primaryGreen.withValues(alpha: 0.3)
              : Colors.blue.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOwner ? Icons.verified : Icons.shield_outlined,
            color: isOwner ? _primaryGreen : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOwner
                  ? 'Official AgriBase Academy Credential. Tap Download to save your high-resolution A4 document.'
                  : 'Verified AgriBase Academy Credential. Issued to the certified agricultural professional below.',
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(
    CertificateModel cert,
    String dateFormatted,
    String gradeLabel,
  ) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _darkGreen, width: 3.5),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: _certBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _gold, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background watermark
              Opacity(
                opacity: 0.04,
                child: Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _darkGreen, width: 7),
                    ),
                    child: const Center(
                      child: Text(
                        'AGRIBASE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _darkGreen,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Foreground content
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Top Header Bar (Academy Brand + Certificate ID Badge + Visible QR Code)
                  _buildHeaderBar(cert),

                  const SizedBox(height: 14),

                  // 2. Certificate Title Section (Clean, non-overlapping)
                  _buildTitleSection(),

                  const SizedBox(height: 8),

                  // 3. Presentation text
                  const Text(
                    'This certificate is proudly presented to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5548),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Student Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      cert.userName.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Color(0xFF111827),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Gold divider under name
                  Container(
                    width: 220,
                    height: 1.5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _gold,
                          _goldDark,
                          _gold,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. Fulfillment text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'for successfully completing the approved agricultural curriculum for',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF4B5548),
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 6. Course Title Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      border: Border.all(color: _primaryGreen.withValues(alpha: 0.6), width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cert.courseTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: _darkGreen,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. Academic Metrics & Completion
                  _buildMetricsSection(cert, dateFormatted, gradeLabel),

                  const SizedBox(height: 16),

                  // 8. Signatures & Official Seal
                  _buildSignatureAndSealRow(cert),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(CertificateModel cert) {
    final qrData = 'https://agribased.com/verify?id=${cert.certificateNumber}';
    final qrSvg = Barcode.qrCode().toSvg(qrData, width: 38, height: 38);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Academy Crest and Name
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _darkGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 1.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school,
                    color: _gold,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AGRIBASE FARMING ACADEMY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _darkGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Excellence in Agricultural Education',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: _goldDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Verified Certificate ID Badge + Visible QR Code
        GestureDetector(
          onTap: () => _showVerificationDialog(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  border: Border.all(color: _primaryGreen.withValues(alpha: 0.5), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CERTIFICATE ID',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF4B5548),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      cert.certificateNumber,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _gold, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SvgPicture.string(
                  qrSvg,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    Widget buildFlourishLine() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 1.2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _gold],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.star, size: 12, color: _gold),
          ),
          Container(
            width: 50,
            height: 1.2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_gold, Colors.transparent],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildFlourishLine(),
        const SizedBox(height: 4),
        const Text(
          'CERTIFICATE OF',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.5,
            color: _darkGreen,
            fontFamily: 'serif',
          ),
        ),
        const Text(
          'COMPLETION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: _darkGreen,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 4),
        buildFlourishLine(),
      ],
    );
  }

  Widget _buildMetricsSection(
    CertificateModel cert,
    String dateFormatted,
    String gradeLabel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            'Completion Date: $dateFormatted',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5548),
            ),
          ),
          const Text(
            '•',
            style: TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.bold),
          ),
          Text(
            'Academic Grade: ${cert.scorePercentage}% ($gradeLabel)',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureAndSealRow(CertificateModel cert) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left: Instructor Signature
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 3),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black54, width: 1.0),
                  ),
                ),
                child: Text(
                  cert.instructorName ?? 'Dr. E. Chinatsvi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Instructor / Academy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 7.5, color: Color(0xFF4B5548), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Center: 3D Official Gold Seal
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => _showVerificationDialog(context),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lightGold,
                  border: Border.all(color: _gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AGRIBASE',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: _darkGreen,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      width: 26,
                      height: 0.8,
                      color: _gold,
                    ),
                    const Text(
                      'OFFICIAL\nSEAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 5.5,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '★ ★ ★',
                      style: TextStyle(
                        fontSize: 4.5,
                        color: _darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Right: Academy Director Signature
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 3),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black54, width: 1.0),
                  ),
                ),
                child: const Text(
                  'Academy Director',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'AgriBase Farming Academy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 7.5, color: Color(0xFF4B5548), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isOwner) {
    if (isOwner) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                'Download / Print Official PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _handleDownloadCertificate(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share PDF'),
                  onPressed: () => _handleShareCertificate(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: _darkGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.verified, size: 18),
                  label: const Text('Verify Seal'),
                  onPressed: () => _showVerificationDialog(context),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.verified_user),
          label: const Text(
            'Verify Credential Online',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () => _showVerificationDialog(context),
        ),
      );
    }
  }

  void _handleDownloadCertificate(BuildContext context) {
    FarmInterstitialAd.show(
      context: context,
      screenKey: 'academy_certificate_pdf',
      force: true,
      onDone: () => _downloadCertificate(context),
    );
  }

  void _handleShareCertificate(BuildContext context) {
    FarmInterstitialAd.show(
      context: context,
      screenKey: 'academy_certificate_pdf',
      force: true,
      onDone: () => _shareCertificate(context),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    final cert = widget.certificate;
    final dateFormatted = DateFormat('MMMM d, yyyy').format(cert.issuedAt);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: _primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Certificate Verified',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AgriBase Farming Academy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: Active & Authenticated ✅',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Certificate ID', cert.certificateNumber, canCopy: true),
            _infoRow('Recipient', cert.userName),
            _infoRow('Course', cert.courseTitle),
            _infoRow('Date Issued', dateFormatted),
            _infoRow('Score', '${cert.scorePercentage}%'),
            _infoRow('Instructor', cert.instructorName ?? 'Dr. E. Chinatsvi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Certificate ID copied!'), duration: Duration(seconds: 1)),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.copy, size: 14, color: _primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing certificate PDF...')),
      );
      await AcademyCertificatePdfService.instance
          .printOrDownloadCertificate(widget.certificate);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareCertificate(BuildContext context) async {
    try {
      await AcademyCertificatePdfService.instance.shareCertificate(widget.certificate);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing certificate: $e')),
        );
      }
    }
  }
}

