import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_rewarded_ad.dart';

import '../../models/fertilizer/fertilizer_crop.dart';
import '../../models/fertilizer/fertilizer_location.dart';
import '../../models/fertilizer/fertilizer_recommendation.dart';
import '../../models/fertilizer/fertilizer_result.dart';
import '../../models/fertilizer/soil_test_data.dart';
import '../../services/fertilizer/fertilizer_recommendation_engine.dart';
import '../../services/fertilizer/fertilizer_repository.dart';
import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

class FertilizerCalculator extends StatefulWidget {
  const FertilizerCalculator({super.key});

  @override
  State<FertilizerCalculator> createState() => _FertilizerCalculatorState();
}

class _FertilizerCalculatorState extends State<FertilizerCalculator> {
  final FertilizerRepository _repository = FertilizerRepository();
  final FertilizerRecommendationEngine _engine =
      FertilizerRecommendationEngine();

  bool _isLoading = true;
  bool _isLocating = false;

  // Repositories Data
  List<FertilizerCountry> _countries = [];
  List<FertilizerCrop> _crops = [];

  // Form selections
  FertilizerCountry? _selectedCountry;
  String? _selectedRegion;
  final TextEditingController _districtController = TextEditingController();

  CropCategory _selectedCategory = CropCategory.fieldCrop;
  FertilizerCrop? _selectedCrop;
  String? _selectedStage;
  String _selectedProductionSystem = 'Rain-fed';

  final TextEditingController _fieldSizeController = TextEditingController();
  String _fieldUnit = 'Hectares';

  final TextEditingController _yieldTargetController = TextEditingController();

  // Soil Test parameters
  bool _hasSoilTest = false;
  final TextEditingController _soilPhController = TextEditingController();
  final TextEditingController _soilNController = TextEditingController();
  final TextEditingController _soilPController = TextEditingController();
  final TextEditingController _soilKController = TextEditingController();
  final TextEditingController _soilOmController = TextEditingController();

  // Calculation Output
  FertilizerCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _districtController.dispose();
    _fieldSizeController.dispose();
    _yieldTargetController.dispose();
    _soilPhController.dispose();
    _soilNController.dispose();
    _soilPController.dispose();
    _soilKController.dispose();
    _soilOmController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final countries = await _repository.getCountries();
      final crops = await _repository.getCrops();

      if (mounted) {
        setState(() {
          _countries = countries;
          _crops = crops;

          // Default country Zimbabwe or first country in catalog
          _selectedCountry = _countries.firstWhere(
            (c) => c.code == 'ZW',
            orElse: () => _countries.first,
          );
          _selectedRegion = _selectedCountry?.regions.isNotEmpty == true
              ? _selectedCountry!.regions.first
              : null;
          _fieldUnit = _selectedCountry?.defaultAreaUnit ?? 'Hectares';

          // Default crop
          _filteredCrops;
          if (_crops.isNotEmpty) {
            _selectedCrop = _crops.firstWhere(
              (c) => c.id == 'crop_maize',
              orElse: () => _crops.first,
            );
            if (_selectedCrop!.defaultStages.isNotEmpty) {
              _selectedStage = _selectedCrop!.defaultStages.first;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FertilizerCrop> get _filteredCrops =>
      _crops.where((c) => c.category == _selectedCategory).toList();

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location services.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please select manually.'),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final isoCode = place.isoCountryCode?.toUpperCase();
        final adminArea = place.administrativeArea;
        final locality = place.locality ?? place.subAdministrativeArea;

        setState(() {
          if (isoCode != null) {
            try {
              final matchedCountry = _countries.firstWhere(
                (c) =>
                    c.code.toUpperCase() == isoCode ||
                    c.name.toLowerCase() == (place.country ?? '').toLowerCase(),
              );
              _selectedCountry = matchedCountry;
              _fieldUnit = matchedCountry.defaultAreaUnit;

              // Match region
              if (adminArea != null && matchedCountry.regions.isNotEmpty) {
                try {
                  _selectedRegion = matchedCountry.regions.firstWhere(
                    (r) => r.toLowerCase().contains(adminArea.toLowerCase()),
                  );
                } catch (_) {
                  _selectedRegion = matchedCountry.regions.first;
                }
              }
            } catch (_) {}
          }
          if (locality != null && locality.isNotEmpty) {
            _districtController.text = locality;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location detected: ${place.country ?? ''}, ${adminArea ?? ''} ✅',
              ),
              backgroundColor: farmGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not obtain GPS location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onCropChanged(FertilizerCrop? newCrop) {
    if (newCrop == null) return;
    setState(() {
      _selectedCrop = newCrop;
      if (newCrop.defaultStages.isNotEmpty) {
        _selectedStage = newCrop.defaultStages.first;
      } else {
        _selectedStage = null;
      }
      if (!newCrop.supportedProductionSystems.contains(_selectedProductionSystem)) {
        _selectedProductionSystem = newCrop.supportedProductionSystems.isNotEmpty
            ? newCrop.supportedProductionSystems.first
            : 'Rain-fed';
      }
      if (newCrop.requiresYieldTarget &&
          newCrop.defaultYieldTarget > 0 &&
          _yieldTargetController.text.isEmpty) {
        _yieldTargetController.text =
            newCrop.defaultYieldTarget.toStringAsFixed(0);
      }
    });
  }

  Future<void> _calculate() async {
    dismissCalculatorKeyboard();

    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop')),
      );
      return;
    }

    if (_selectedStage == null || _selectedStage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an application stage')),
      );
      return;
    }

    final fieldSize = farmNumber(_fieldSizeController);
    if (fieldSize == null || fieldSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid field size')),
      );
      return;
    }

    final soilTest = SoilTestData(
      hasSoilTest: _hasSoilTest,
      ph: farmNumber(_soilPhController),
      nitrogenPpm: farmNumber(_soilNController),
      phosphorusPpm: farmNumber(_soilPController),
      potassiumPpm: farmNumber(_soilKController),
      organicMatterPercent: farmNumber(_soilOmController),
    );

    final result = await _engine.calculateRecommendation(
      crop: _selectedCrop!,
      stageName: _selectedStage!,
      countryCode: _selectedCountry?.code ?? 'GLOBAL',
      countryName: _selectedCountry?.name ?? 'Global',
      regionName: _selectedRegion,
      districtName: _districtController.text.trim(),
      productionSystem: _selectedProductionSystem,
      fieldSize: fieldSize,
      fieldUnit: _fieldUnit,
      soilTest: soilTest,
      targetYield: farmNumber(_yieldTargetController),
    );

    setState(() {
      _result = result;
    });

    if (result.hasVerifiedData) {
      final summaryProduct = result.products.isNotEmpty
          ? result.products
              .map((p) => '${p.productName}: ${p.purchaseSummary}')
              .join(' | ')
          : 'Nutrient targets calculated';

      unawaited(
        FarmCalculatorHistoryService.save(
          calculatorType: 'fertilizer',
          title: 'Fertilizer: ${result.cropName}',
          inputs: {
            'Crop': result.cropName,
            'Stage': result.stageName,
            'Location': result.locationDisplayName,
            'Field Size': '${result.fieldSizeInput} ${result.fieldUnitInput}',
            'Mode': result.confidence.badgeLabel,
          },
          result: summaryProduct,
          details:
              'Nutrients: N ${result.nutrients.nKgPerHa.toStringAsFixed(0)} kg/ha, P₂O₅ ${result.nutrients.p2o5KgPerHa.toStringAsFixed(0)} kg/ha, K₂O ${result.nutrients.k2oKgPerHa.toStringAsFixed(0)} kg/ha.',
        ),
      );
    }
  }

  Future<void> _exportPdfReport() async {
    if (_result == null || !_result!.hasVerifiedData) return;

    final document = pw.Document();
    final res = _result!;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'AgriBase Farm Works',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    res.confidence.badgeLabel,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
              ],
            ),
            pw.Text(
              '${res.cropName.toUpperCase()} FERTILIZER RECOMMENDATION',
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
          // Agronomic Header Card
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FARM & CROP PARAMETERS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Location: ${res.locationDisplayName}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Crop: ${res.cropName}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Stage: ${res.stageName}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Field Area: ${res.fieldSizeInput} ${res.fieldUnitInput} (${res.normalizedHectares.toStringAsFixed(2)} ha)',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Nutrient Targets
          pw.Text(
            'AGRONOMIC NUTRIENT TARGETS (PER HECTARE)',
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
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Nitrogen (N)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Phosphate (P2O5)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Potash (K2O)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Sulfur (S)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${res.nutrients.nKgPerHa.toStringAsFixed(1)} kg/ha', style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${res.nutrients.p2o5KgPerHa.toStringAsFixed(1)} kg/ha', style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${res.nutrients.k2oKgPerHa.toStringAsFixed(1)} kg/ha', style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${res.nutrients.sKgPerHa.toStringAsFixed(1)} kg/ha', style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Recommended Fertilizer Products
          pw.Text(
            'RECOMMENDED FERTILIZER PRODUCTS & APPLICATION SCHEDULE',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 6),
          ...res.products.map(
            (p) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        p.productName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.Text(
                        'Grade: ${p.formulaGrade}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Application Rate: ${p.rateDisplay} | Total Field Need: ${p.totalQuantityRequired.toStringAsFixed(1)} ${p.packageUnit}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Purchase: ${p.purchaseSummary}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Method: ${p.applicationMethod}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  pw.Text(
                    'Timing: ${p.timingGuidance}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 12),

          // Soil Test Adjustment Notes (if any)
          if (res.soilAdjustmentSummary != null) ...[
            pw.Text(
              'SOIL-TEST ADJUSTMENTS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(res.soilAdjustmentSummary!, style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 12),
          ],

          // Source Citation & Disclaimer
          if (res.source != null) ...[
            pw.Text(
              'VERIFIED AGRONOMIC SOURCE',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${res.source!.organization} (${res.source!.year}): "${res.source!.title}"',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 8),
          ],

          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Text(
            res.disclaimer,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename:
          'fertilizer_${res.cropName.toLowerCase().replaceAll(' ', '_')}_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: farmGreen)),
      );
    }

    final hasParentScaffold = Scaffold.maybeOf(context) != null;

    final content = GestureDetector(
      onTap: dismissCalculatorKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStep1Location(),
                  const SizedBox(height: 14),
                  _buildStep2CropSelection(),
                  const SizedBox(height: 14),
                  _buildStep3CropStage(),
                  const SizedBox(height: 14),
                  _buildStep4ProductionSystem(),
                  const SizedBox(height: 14),
                  _buildStep5FieldArea(),
                  const SizedBox(height: 14),
                  _buildStep6SoilTest(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate, size: 22),
                    label: const Text(
                      'CALCULATE FERTILIZER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: farmGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _buildResultSection(),
                  ],
                  const SizedBox(height: 20),
                  const FarmCalculatorHistory(calculatorType: 'fertilizer'),
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
          title: const Text('Fertilizer Recommendation'),
          backgroundColor: farmGreen,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: farmLightGreen,
          child: Icon(Icons.science, color: farmGreen, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fertilizer Recommendation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: farmGreen,
                ),
              ),
              Text(
                'Location-aware agronomic nutrient & fertilizer decision support.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: LOCATION
  // ---------------------------------------------------------------------------
  Widget _buildStep1Location() {
    return _buildSectionCard(
      stepNumber: '1',
      title: 'Where is your farm?',
      icon: Icons.location_on,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _isLocating ? null : _detectLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: farmGreen,
                    ),
                  )
                : const Icon(Icons.my_location, color: farmGreen),
            label: Text(
              _isLocating ? 'Detecting Location...' : 'USE MY LOCATION (GPS)',
              style: const TextStyle(
                color: farmGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: farmGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FertilizerCountry>(
            initialValue: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _countries.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text('${c.flagEmoji}  ${c.name}'),
              );
            }).toList(),
            onChanged: (country) {
              if (country == null) return;
              setState(() {
                _selectedCountry = country;
                _fieldUnit = country.defaultAreaUnit;
                _selectedRegion = country.regions.isNotEmpty
                    ? country.regions.first
                    : null;
              });
            },
          ),
          if (_selectedCountry != null &&
              _selectedCountry!.regions.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region / Province / Agro-Zone',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _selectedCountry!.regions.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedRegion = val),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'District / County / Farm Name (Optional)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: CROP SELECTION
  // ---------------------------------------------------------------------------
  Widget _buildStep2CropSelection() {
    return _buildSectionCard(
      stepNumber: '2',
      title: 'What are you growing?',
      icon: Icons.grass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CropCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${cat.emoji} ${cat.displayName}'),
                    selected: isSelected,
                    selectedColor: farmLightGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? farmGreen : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                          final filtered = _filteredCrops;
                          if (filtered.isNotEmpty) {
                            _onCropChanged(filtered.first);
                          }
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<FertilizerCrop>(
            initialValue: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Select Crop',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _filteredCrops.map((crop) {
              return DropdownMenuItem(
                value: crop,
                child: Row(
                  children: [
                    Text(crop.iconEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(crop.name, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: _onCropChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: CROP STAGE
  // ---------------------------------------------------------------------------
  Widget _buildStep3CropStage() {
    final stages = _selectedCrop?.defaultStages ??
        ['Basal / Planting', 'Top Dressing', 'All Season Total'];

    return _buildSectionCard(
      stepNumber: '3',
      title: 'What stage is the crop?',
      icon: Icons.timeline,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStage,
        decoration: const InputDecoration(
          labelText: 'Crop Growth / Application Stage',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: stages.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Text(s, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: (stage) => setState(() => _selectedStage = stage),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: PRODUCTION SYSTEM & YIELD
  // ---------------------------------------------------------------------------
  Widget _buildStep4ProductionSystem() {
    final systems = _selectedCrop?.supportedProductionSystems ??
        ['Rain-fed', 'Irrigated'];

    return _buildSectionCard(
      stepNumber: '4',
      title: 'How is the crop grown?',
      icon: Icons.water_drop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: systems.map((sys) {
              final isSelected = sys == _selectedProductionSystem;
              return ChoiceChip(
                label: Text(sys),
                selected: isSelected,
                selectedColor: farmLightGreen,
                labelStyle: TextStyle(
                  color: isSelected ? farmGreen : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedProductionSystem = sys);
                  }
                },
              );
            }).toList(),
          ),
          if (_selectedCrop?.requiresYieldTarget == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _yieldTargetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    'Expected / Target Yield (${_selectedCrop!.yieldUnit})',
                hintText: 'e.g. ${_selectedCrop!.defaultYieldTarget}',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 5: FIELD AREA
  // ---------------------------------------------------------------------------
  Widget _buildStep5FieldArea() {
    return _buildSectionCard(
      stepNumber: '5',
      title: 'How large is your field?',
      icon: Icons.square_foot,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _fieldSizeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Field Size',
                hintText: 'e.g. 2',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _fieldUnit,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Hectares', child: Text('Hectares')),
                DropdownMenuItem(value: 'Acres', child: Text('Acres')),
                DropdownMenuItem(
                  value: 'Square metres',
                  child: Text('Sq Metres (m²)'),
                ),
                DropdownMenuItem(
                  value: 'Square feet',
                  child: Text('Sq Feet (ft²)'),
                ),
              ],
              onChanged: (u) => setState(() => _fieldUnit = u ?? 'Hectares'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 6: SOIL TEST
  // ---------------------------------------------------------------------------
  Widget _buildStep6SoilTest() {
    return _buildSectionCard(
      stepNumber: '6',
      title: 'Do you have a soil test?',
      icon: Icons.biotech,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _hasSoilTest = false),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        !_hasSoilTest ? farmLightGreen : Colors.transparent,
                    side: BorderSide(
                      color: !_hasSoilTest ? farmGreen : Colors.grey.shade300,
                      width: !_hasSoilTest ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'No Soil Test (General)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          !_hasSoilTest ? FontWeight.bold : FontWeight.normal,
                      color: !_hasSoilTest ? farmGreen : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _hasSoilTest = true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        _hasSoilTest ? farmLightGreen : Colors.transparent,
                    side: BorderSide(
                      color: _hasSoilTest ? farmGreen : Colors.grey.shade300,
                      width: _hasSoilTest ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'I Have a Soil Test',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          _hasSoilTest ? FontWeight.bold : FontWeight.normal,
                      color: _hasSoilTest ? farmGreen : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_hasSoilTest) ...[
            const SizedBox(height: 14),
            Text(
              'Enter available laboratory values (optional fields):',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soilPhController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Soil pH',
                      hintText: 'e.g. 5.8',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _soilPController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Available P (ppm)',
                      hintText: 'e.g. 15',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soilKController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Exch. K (ppm)',
                      hintText: 'e.g. 120',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _soilOmController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Organic Matter %',
                      hintText: 'e.g. 2.5',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESULT DISPLAY SECTION
  // ---------------------------------------------------------------------------
  Widget _buildResultSection() {
    final res = _result!;

    if (!res.hasVerifiedData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade400, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No Verified Recommendation Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              res.unverifiedReason ??
                  'An appropriate verified recommendation is not currently available for the selected conditions. Please consult a qualified agricultural advisor or use a locally verified recommendation.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: farmLightGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedCrop?.iconEmoji ?? '🌱'} ${res.cropName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: farmGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: res.confidence ==
                                RecommendationConfidence.verified
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        res.confidence.badgeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${res.locationDisplayName} • ${res.stageName} • ${res.fieldSizeInput} ${res.fieldUnitInput}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nutrients Grid
                const Text(
                  'NUTRIENT REQUIREMENT (PER HECTARE)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: farmGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientStat(
                        'N',
                        res.nutrients.nKgPerHa.toStringAsFixed(0),
                        'kg/ha',
                      ),
                      _buildNutrientStat(
                        'P₂O₅',
                        res.nutrients.p2o5KgPerHa.toStringAsFixed(0),
                        'kg/ha',
                      ),
                      _buildNutrientStat(
                        'K₂O',
                        res.nutrients.k2oKgPerHa.toStringAsFixed(0),
                        'kg/ha',
                      ),
                      if (res.nutrients.sKgPerHa > 0)
                        _buildNutrientStat(
                          'S',
                          res.nutrients.sKgPerHa.toStringAsFixed(0),
                          'kg/ha',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Products Card
                const Text(
                  'RECOMMENDED FERTILIZER PRODUCTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: farmGreen,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...res.products.map(
                  (product) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              color: farmGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.productName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: farmLightGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.formulaGrade,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: farmGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommended Rate:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    product.rateDisplay,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Field Requirement:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${product.totalQuantityRequired.toStringAsFixed(1)} ${product.packageUnit}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: farmGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: farmLightGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: farmGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Purchase: ${product.purchaseSummary}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: farmGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Method: ${product.applicationMethod}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Timing: ${product.timingGuidance}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Soil adjustment notes
                if (res.soilAdjustmentSummary != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.blue.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Soil Test Feedback',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          res.soilAdjustmentSummary!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Agronomic Tips
                if (res.agronomicGuidance.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...res.agronomicGuidance.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Verified Source
                if (res.source != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Source: ${res.source!.organization} (${res.source!.year}) • ${res.source!.title}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                // Disclaimer
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    res.disclaimer,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),

                const SizedBox(height: 16),
                FarmRewardedAdButton(
                  label: 'Watch Ad & Export Recommendation PDF',
                  icon: Icons.picture_as_pdf,
                  color: farmGreen,
                  onRewarded: _exportPdfReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientStat(String symbol, String val, String unit) {
    return Column(
      children: [
        Text(
          symbol,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: farmGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION CARD WRAPPER
  // ---------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
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
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: farmGreen,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: farmGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
