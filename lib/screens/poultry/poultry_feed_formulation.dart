import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_interstitial_ad.dart';
import '../../models/poultry/poultry_feed_formulation.dart';

class SmartFeedFormulationScreen extends StatefulWidget {
  final String? batchId;
  const SmartFeedFormulationScreen({super.key, this.batchId});

  @override
  State<SmartFeedFormulationScreen> createState() =>
      _SmartFeedFormulationScreenState();
}

class _SmartFeedFormulationScreenState
    extends State<SmartFeedFormulationScreen> {
  bool _isLoading = true;
  bool _isCalculating = false;

  StreamSubscription? _batchSub;

  // Poultry data from registration and growth tracker
  String _poultryType = 'broiler';
  int _birdCount = 0; // Default to 0 until we load real data
  int _ageWeeks = 0; // Default to 0 weeks (day-old chicks)
  int _ageDays = 0; // Track days for more accuracy
  String _batchName = 'My Batch';

  // Farmer selects available feeds
  List<String> _selectedFeeds = [];
  FeedResult? _feedResult;

  @override
  void initState() {
    super.initState();
    FarmInterstitialAd.preload();
    _loadPoultryData();
  }

  @override
  void dispose() {
    _batchSub?.cancel();
    super.dispose();
  }

  /// Load poultry data from registration and growth tracker
  Future<void> _loadPoultryData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _batchSub?.cancel();

    // If a specific batchId is provided, listen to that document only
    if (widget.batchId != null) {
      final bid = widget.batchId!;
      _batchSub = FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(bid)
          .snapshots()
          .listen((docSnap) async {
        try {
          if (docSnap.exists) {
            final batch = docSnap.data() as Map<String, dynamic>;
            final batchId = docSnap.id;

            debugPrint('🐔 [stream] Loading batch data (by id): ${batch['name']}');

            final mortalitySnapshot = await FirebaseFirestore.instance
                .collection('poultry_mortality_records')
                .where('batchId', isEqualTo: batchId)
                .get();
            final exitSnapshot = await FirebaseFirestore.instance
                .collection('poultry_exit_records')
                .where('batchId', isEqualTo: batchId)
                .get();

            final initialCount = batch['initialCount'] ?? batch['count'] ?? 0;
            final currentCountFromBatch =
                batch['currentCount'] ?? initialCount;

            final totalDeaths = mortalitySnapshot.docs.fold<int>(0, (sum, d) {
              return sum + ((d.data()['deaths'] ?? 0) as int);
            });

            final totalExits = exitSnapshot.docs.fold<int>(0, (sum, d) {
              return sum + ((d.data()['quantity'] ?? 0) as int);
            });

            int actualCurrentCount;
            if (currentCountFromBatch > 0) {
              actualCurrentCount = currentCountFromBatch;
            } else {
              actualCurrentCount = initialCount - totalDeaths - totalExits;
            }
            actualCurrentCount = actualCurrentCount < 0
                ? 0
                : actualCurrentCount;

            DateTime? startDate;
            final sd = batch['startDate'];
            if (sd is Timestamp)
              startDate = sd.toDate();
            else if (sd is String) startDate = DateTime.tryParse(sd);

            // Use the real elapsed time from the batch start date as the
            // source of truth. If startDate is missing, fall back to the
            // registration snapshot stored in ageWeeks.
            int actualAgeWeeks = 0;
            int actualAgeDays = 0;
            final ageWeeksAtRegistration = batch['ageWeeks'] != null
                ? (batch['ageWeeks'] as num).toInt()
                : 0;

            if (startDate != null) {
              actualAgeDays = DateTime.now().difference(startDate).inDays;
              actualAgeWeeks = actualAgeDays ~/ 7;
            } else {
              actualAgeWeeks = ageWeeksAtRegistration;
              actualAgeDays = actualAgeWeeks * 7;
            }

            if (mounted) setState(() {
              _poultryType = batch['purpose'] ?? batch['breed'] ?? 'broiler';
              _birdCount = actualCurrentCount;
              _ageWeeks = actualAgeWeeks >= 0 ? actualAgeWeeks : 0;
              _ageDays = actualAgeDays;
              _batchName = batch['name'] ?? 'My Batch';
              _isLoading = false;
            });
          } else {
            // No batch doc for provided id - fall back to animals
            debugPrint(
              '[stream] No poultry batch found for id $bid - falling back to animals',
            );
            final animalsSnap = await FirebaseFirestore.instance
                .collection('farmers')
                .doc(user.uid)
                .collection('animals')
                .where('species', isEqualTo: 'poultry')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();

            if (animalsSnap.docs.isNotEmpty) {
              final a = animalsSnap.docs.first.data();
              DateTime? aCreated;
              final ca = a['createdAt'];
              if (ca is Timestamp)
                aCreated = ca.toDate();
              else if (ca is String) aCreated = DateTime.tryParse(ca);

              final initial = (a['initialFlockSize'] ?? 0) as int;
              final actualAgeDays = aCreated != null
                  ? DateTime.now().difference(aCreated).inDays
                  : 0;
              final actualAgeWeeks = actualAgeDays ~/ 7;

              if (mounted) setState(() {
                _poultryType = a['purpose'] ?? a['breed'] ?? 'broiler';
                _birdCount = initial;
                _ageWeeks = actualAgeWeeks;
                _ageDays = actualAgeDays;
                _batchName = a['breed'] ?? 'My Batch';
                _isLoading = false;
              });
            } else {
              if (mounted) setState(() {
                _isLoading = false;
              });
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading poultry data (stream by id): $e');
          if (mounted) setState(() => _isLoading = false);
        }
      });
      return;
    }

    // Default behaviour: load most recent batch for the user (legacy)
    _batchSub = FirebaseFirestore.instance
        .collection('poultry_batches')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
      try {
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          final batch = doc.data();
          final batchId = doc.id;

          debugPrint('🐔 [stream] Loading batch data: ${batch['name']}');

          final mortalitySnapshot = await FirebaseFirestore.instance
              .collection('poultry_mortality_records')
              .where('batchId', isEqualTo: batchId)
              .get();
          final exitSnapshot = await FirebaseFirestore.instance
              .collection('poultry_exit_records')
              .where('batchId', isEqualTo: batchId)
              .get();

          final initialCount = batch['initialCount'] ?? batch['count'] ?? 0;
          final currentCountFromBatch =
              batch['currentCount'] ?? initialCount;

          final totalDeaths = mortalitySnapshot.docs.fold<int>(0, (sum, d) {
            return sum + ((d.data()['deaths'] ?? 0) as int);
          });

          final totalExits = exitSnapshot.docs.fold<int>(0, (sum, d) {
            return sum + ((d.data()['quantity'] ?? 0) as int);
          });

          int actualCurrentCount;
          if (currentCountFromBatch > 0) {
            actualCurrentCount = currentCountFromBatch;
          } else {
            actualCurrentCount = initialCount - totalDeaths - totalExits;
          }
          actualCurrentCount = actualCurrentCount < 0
              ? 0
              : actualCurrentCount;

          DateTime? startDate;
          final sd = batch['startDate'];
          if (sd is Timestamp)
            startDate = sd.toDate();
          else if (sd is String) startDate = DateTime.tryParse(sd);

          int actualAgeWeeks = 0;
          int actualAgeDays = 0;
          final ageWeeksAtRegistration = batch['ageWeeks'] != null
              ? (batch['ageWeeks'] as num).toInt()
              : 0;

          if (startDate != null) {
            actualAgeDays = DateTime.now().difference(startDate).inDays;
            actualAgeWeeks = actualAgeDays ~/ 7;
          } else {
            actualAgeWeeks = ageWeeksAtRegistration;
            actualAgeDays = actualAgeWeeks * 7;
          }

          if (mounted) setState(() {
            _poultryType = batch['purpose'] ?? batch['breed'] ?? 'broiler';
            _birdCount = actualCurrentCount;
            _ageWeeks = actualAgeWeeks >= 0 ? actualAgeWeeks : 0;
            _ageDays = actualAgeDays;
            _batchName = batch['name'] ?? 'My Batch';
            _isLoading = false;
          });
        } else {
          debugPrint(
            '[stream] No poultry batch found for user - falling back to animals',
          );

          final animalsSnap = await FirebaseFirestore.instance
              .collection('farmers')
              .doc(user.uid)
              .collection('animals')
              .where('species', isEqualTo: 'poultry')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (animalsSnap.docs.isNotEmpty) {
            final a = animalsSnap.docs.first.data();
            DateTime? aCreated;
            final ca = a['createdAt'];
            if (ca is Timestamp)
              aCreated = ca.toDate();
            else if (ca is String) aCreated = DateTime.tryParse(ca);

            final initial = (a['initialFlockSize'] ?? 0) as int;
            final actualAgeDays = aCreated != null
                ? DateTime.now().difference(aCreated).inDays
                : 0;
            final actualAgeWeeks = actualAgeDays ~/ 7;

            if (mounted) setState(() {
              _poultryType = a['purpose'] ?? a['breed'] ?? 'broiler';
              _birdCount = initial;
              _ageWeeks = actualAgeWeeks;
              _ageDays = actualAgeDays;
              _batchName = a['breed'] ?? 'My Batch';
              _isLoading = false;
            });
          } else {
            if (mounted) setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ Error loading poultry data (stream): $e');
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _toggleFeed(FeedIngredient feed, bool? value) {
    if (value != true) {
      setState(() {
        _selectedFeeds.remove(feed.name);
        _feedResult = null;
      });
      return;
    }

    final selectedFromSameCategory = _selectedFeeds.any((feedName) {
      return SmartFeedCalculator.getIngredient(feedName)?.category ==
          feed.category;
    });
    if (selectedFromSameCategory) {
      final categoryName = feed.category == FeedCategory.energy
          ? 'energy'
          : 'protein';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select only 1 $categoryName source. Remove the current one first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedFeeds.add(feed.name);
      _feedResult = null;
    });
  }

  /// Calculate smart feed formulation
  void _calculateFeed() {
    // Validate selection before calculation
    final validationError = SmartFeedCalculator.validateSelection(
      _selectedFeeds,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(validationError)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    if (_birdCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No birds found in this batch. Update your batch records.',
          ),
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);
    try {
      final result = SmartFeedCalculator.formulateSmartFeed(
        availableFeeds: _selectedFeeds,
        feedType: _poultryType,
        ageWeeks: _ageWeeks,
        totalBirds: _birdCount,
      );

      setState(() {
        _feedResult = result;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _handleExportPdf() {
    FarmInterstitialAd.show(
      context: context,
      screenKey: 'feed_formulation_pdf',
      force: true,
      onDone: () => _exportPdf(),
    );
  }

  Future<void> _exportPdf() async {
    if (_feedResult == null) return;
    try {
      final result = _feedResult!;
      final totalDailyFeed = result.mixKg.values.fold(0.0, (sum, kg) => sum + kg);
      final doc = pw.Document();

      final calciumPercent = result.feedType.toLowerCase().contains('layer') ? 3.5 : 1.0;
      final calciumDailyKg = totalDailyFeed * (calciumPercent / 100.0);
      final calcium100Kg = 100.0 * (calciumPercent / 100.0);

      final saltLowerPct = 0.3;
      final saltUpperPct = 0.5;
      final saltDailyLowerKg = totalDailyFeed * (saltLowerPct / 100.0);
      final saltDailyUpperKg = totalDailyFeed * (saltUpperPct / 100.0);

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
                    'AgriBase Poultry Nutrition',
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
                'Feed Formulation Recipe & Mixing Guide',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Batch: $_batchName | Type: ${_poultryType.toUpperCase()} | Flock Size: $_birdCount birds | Age: $_ageWeeks weeks (${_ageDays > 0 ? "$_ageDays days" : ""})',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.green800, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => [
            // KPI Nutrition Summary Cards
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
                  _pdfKpiStat('Daily Feed Needed', '${totalDailyFeed.toStringAsFixed(1)} kg', color: PdfColors.green900),
                  _pdfKpiStat('Feed Stage', result.feedType),
                  _pdfKpiStat('Achieved Protein', '${result.achievedProtein}%', color: PdfColors.green900),
                  _pdfKpiStat('Total Flock Size', '$_birdCount birds'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Ingredients Mixing Table
            pw.Text(
              'INGREDIENT MIX RATIOS & QUANTITIES',
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
                    _pdfTableCell('Ingredient', bold: true),
                    _pdfTableCell('Category', bold: true),
                    _pdfTableCell('Protein %', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Daily Quantity (kg)', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Diet Ratio (%)', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Per 100kg Mix (kg)', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...result.mixKg.entries.map((entry) {
                  final ingredient = SmartFeedCalculator.getIngredient(entry.key);
                  final ratioPct = totalDailyFeed > 0 ? (entry.value / totalDailyFeed * 100) : 0.0;
                  final per100kg = (ratioPct).toStringAsFixed(1);
                  final isEnergy = ingredient?.category == FeedCategory.energy;

                  return pw.TableRow(
                    children: [
                      _pdfTableCell(entry.key, bold: true),
                      _pdfTableCell(
                        isEnergy ? 'Energy Source' : 'Protein Source',
                        color: isEnergy ? PdfColors.amber900 : PdfColors.green900,
                      ),
                      _pdfTableCell('${ingredient?.protein ?? 0}%', align: pw.TextAlign.right),
                      _pdfTableCell('${entry.value} kg', bold: true, align: pw.TextAlign.right),
                      _pdfTableCell('${ratioPct.toStringAsFixed(1)}%', align: pw.TextAlign.right),
                      _pdfTableCell('$per100kg kg', align: pw.TextAlign.right),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfTableCell('TOTAL DAILY MIX', bold: true),
                    _pdfTableCell(''),
                    _pdfTableCell('${result.achievedProtein}%', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('${totalDailyFeed.toStringAsFixed(1)} kg', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('100.0%', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('100.0 kg', bold: true, align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Supplementary Additives & Minerals Table
            pw.Text(
              'ESSENTIAL SUPPLEMENTS & MINERAL ADDITIVES',
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
                    _pdfTableCell('Supplement', bold: true),
                    _pdfTableCell('Daily Amount for Flock', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Per 100kg Mix', bold: true, align: pw.TextAlign.right),
                    _pdfTableCell('Notes / Sourcing', bold: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Calcium Source', bold: true),
                    _pdfTableCell('~${calciumDailyKg.toStringAsFixed(2)} kg', align: pw.TextAlign.right),
                    _pdfTableCell('${calcium100Kg.toStringAsFixed(1)} kg', align: pw.TextAlign.right),
                    _pdfTableCell('Clean crushed eggshells or agricultural limestone for bone/eggshell strength'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Common Salt (NaCl)', bold: true),
                    _pdfTableCell('${saltDailyLowerKg.toStringAsFixed(3)} - ${saltDailyUpperKg.toStringAsFixed(3)} kg', align: pw.TextAlign.right),
                    _pdfTableCell('0.3 - 0.5 kg', align: pw.TextAlign.right),
                    _pdfTableCell('Standard fine salt for electrolyte and hydration balance'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfTableCell('Vitamin & Mineral Premix', bold: true),
                    _pdfTableCell('As per label', align: pw.TextAlign.right),
                    _pdfTableCell('0.25 - 0.5 kg', align: pw.TextAlign.right),
                    _pdfTableCell('Commercial poultry starter/grower/layer premix according to manufacturer directions'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Mixing & Feeding Instructions
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
                  pw.Text(
                    'Standard Operating Procedures & Feeding Protocol',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '1. Grind coarse grains (e.g. yellow maize) to appropriate particle size suitable for flock age.\n2. Thoroughly pre-mix small quantity ingredients (premix, salt, calcium) with a small portion of bran/maize before blending into the bulk mix.\n3. Blend all energy and protein components evenly until uniform consistency is achieved.\n4. Feed fresh daily and keep feeding troughs clean to prevent fungal contamination.\n5. Ensure clean, cool, fresh drinking water is accessible 24/7.',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900, lineSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'feed_recipe_${_poultryType.toLowerCase()}_${_ageWeeks}w.pdf',
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poultry Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Poultry Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _loadPoultryData,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh poultry data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('🐔 Batch: $_batchName'),
                    Text('📊 Type: ${_poultryType.toUpperCase()}'),
                    Text('🔢 Birds: $_birdCount'),
                    Text('📅 Age: $_ageWeeks weeks ($_ageDays days)'),
                    Text(
                      '🎯 Required Protein: ${SmartFeedCalculator.getRequiredProtein(feedType: _poultryType, ageWeeks: _ageWeeks).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Feed Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What Feeds Do You Have?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select exactly 1 Energy source + 1 Protein source. To change a feed, remove the current one first.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Energy Sources Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ENERGY SOURCES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Low protein feeds that provide energy:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...SmartFeedCalculator.energySources.map((feed) {
                      final isSelected = _selectedFeeds.contains(feed.name);
                      return CheckboxListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Text(
                              feed.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(feed.name),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${feed.protein}% protein',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (value) => _toggleFeed(feed, value),
                      );
                    }).toList(),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Protein Sources Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PROTEIN SOURCES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'High protein feeds for growth:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...SmartFeedCalculator.proteinSources.map((feed) {
                      final isSelected = _selectedFeeds.contains(feed.name);
                      return CheckboxListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Text(
                              feed.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(feed.name),
                            const Spacer(),
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
                                '${feed.protein}% protein',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (value) => _toggleFeed(feed, value),
                      );
                    }).toList(),

                    // Show current selection summary
                    if (_selectedFeeds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Selection:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: _selectedFeeds.map((feedName) {
                                final feed = SmartFeedCalculator.getIngredient(
                                  feedName,
                                );
                                final isEnergy =
                                    feed?.category == FeedCategory.energy;
                                return Chip(
                                  label: Text(
                                    feedName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: isEnergy
                                      ? Colors.amber.shade100
                                      : Colors.green.shade100,
                                  side: BorderSide(
                                    color: isEnergy
                                        ? Colors.amber.shade300
                                        : Colors.green.shade300,
                                  ),
                                  avatar: Text(feed?.icon ?? '🌾'),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calculateFeed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isCalculating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Calculating...'),
                        ],
                      )
                    : const Text(
                        '🧮 Calculate Feed Mix',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (_feedResult != null) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final result = _feedResult!;
    final totalFeed = result.mixKg.values.fold(0.0, (sum, kg) => sum + kg);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Feed Mix Recipe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _handleExportPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.green, size: 26),
                  tooltip: 'Watch Ad & Export PDF Recipe',
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'For ${result.totalBirds} birds (${result.feedType}, ${result.ageWeeks} weeks)',
            ),
            Text('Daily feed needed: ${totalFeed.toStringAsFixed(1)} kg'),
            Text('Achieved protein: ${result.achievedProtein}%'),

            const SizedBox(height: 16),
            const Text(
              'Mix these quantities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...result.mixKg.entries.map((entry) {
              final ingredient = SmartFeedCalculator.getIngredient(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      ingredient?.icon ?? '🌾',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Builder(builder: (context) {
                // Calculate totals for additional instructions
                final calciumPercent = result.feedType.toLowerCase().contains('layer') ? 3.5 : 1.0;
                final calciumKg = totalFeed * (calciumPercent / 100.0);
                final saltLowerPct = 0.3;
                final saltUpperPct = 0.5;
                final saltLowerKg = totalFeed * (saltLowerPct / 100.0);
                final saltUpperKg = totalFeed * (saltUpperPct / 100.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Mix all ingredients thoroughly'),
                    const Text('2. Feed to birds fresh daily'),
                    const Text('3. Store remaining feed in a dry place'),
                    const Text('4. Clean feeding troughs regularly'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Supplementary Additions (guidance):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('• Calcium source (limestone or crushed eggshells): add approximately ${calciumKg.toStringAsFixed(2)} kg (${calciumPercent.toStringAsFixed(1)}% of total daily feed). Use crushed clean eggshells or agricultural limestone as a calcium source.'),
                    const SizedBox(height: 6),
                    const Text('• Vitamin & Mineral Premix: follow the manufacturer\'s instructions on the premix label. Add according to the premix dosage (do not guess; premix concentration varies by brand).'),
                    const SizedBox(height: 6),
                    Text('• Salt: add between ${saltLowerPct.toStringAsFixed(1)}% and ${saltUpperPct.toStringAsFixed(1)}% of total feed daily — about ${saltLowerKg.toStringAsFixed(3)} kg to ${saltUpperKg.toStringAsFixed(3)} kg for this mix.'),
                    const SizedBox(height: 6),
                    const Text('• Clean water: always provide fresh, clean drinking water at all times; ensure troughs are clean and water is accessible.'),
                    const SizedBox(height: 6),
                    const Text('Notes: These are general guidelines. Adjust according to flock requirements and veterinary/nutritionist advice.'),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            // Thin visible Ad-supported PDF Export Banner
            InkWell(
              onTap: _handleExportPdf,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        'Watch Ad & Export Feed Recipe PDF',
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
            const SizedBox(height: 16),
            const FarmNativeAd(),
          ],
        ),
      ),
    );
  }
}
