import '../../models/fertilizer/fertilizer_crop.dart';
import '../../models/fertilizer/fertilizer_product.dart';
import '../../models/fertilizer/fertilizer_recommendation.dart';
import '../../models/fertilizer/fertilizer_result.dart';
import '../../models/fertilizer/fertilizer_source.dart';
import '../../models/fertilizer/soil_test_data.dart';
import 'fertilizer_repository.dart';

class FertilizerRecommendationEngine {
  final FertilizerRepository _repository;

  FertilizerRecommendationEngine({FertilizerRepository? repository})
      : _repository = repository ?? FertilizerRepository();

  /// Converts any agricultural unit to Hectares
  static double normalizeToHectares(double area, String unit) {
    if (area <= 0) return 0.0;
    switch (unit.toLowerCase().trim()) {
      case 'acres':
      case 'acre':
        return area * 0.40468564224;
      case 'square metres':
      case 'square meters':
      case 'sqm':
      case 'm2':
      case 'm²':
        return area / 10000.0;
      case 'square feet':
      case 'sq ft':
      case 'sqft':
      case 'ft2':
      case 'ft²':
        return area * 0.00009290304 / 10.0; // 1 sq ft = 0.000009290304 ha
      case 'hectares':
      case 'hectare':
      case 'ha':
      default:
        return area;
    }
  }

  /// Evaluates and generates a verified fertilizer recommendation
  Future<FertilizerCalculationResult> calculateRecommendation({
    required FertilizerCrop crop,
    required String stageName,
    required String countryCode,
    required String countryName,
    String? regionName,
    String? districtName,
    required String productionSystem,
    required double fieldSize,
    required String fieldUnit,
    required SoilTestData soilTest,
    double? targetYield,
  }) async {
    final locationParts = [
      if (districtName != null && districtName.isNotEmpty) districtName,
      if (regionName != null && regionName.isNotEmpty) regionName,
      countryName,
    ];
    final locationDisplayName = locationParts.join(', ');

    if (fieldSize <= 0) {
      return FertilizerCalculationResult.unverified(
        cropName: crop.name,
        locationDisplayName: locationDisplayName,
        stageName: stageName,
        unverifiedReason: 'Please enter a valid field size greater than zero.',
      );
    }

    final normalizedHectares = normalizeToHectares(fieldSize, fieldUnit);

    // Fetch all recommendations
    final allRecommendations = await _repository.getRecommendations();

    // 1. Find matching recommendations for this crop and stage
    final matchingRules = allRecommendations.where((r) {
      final cropMatches = r.cropId == crop.id ||
          r.cropName.toLowerCase() == crop.name.toLowerCase();
      final stageMatches = r.stageName.toLowerCase() == stageName.toLowerCase() ||
          r.stageName.toLowerCase().contains(stageName.toLowerCase()) ||
          stageName.toLowerCase().contains(r.stageName.toLowerCase());
      return cropMatches && stageMatches;
    }).toList();

    if (matchingRules.isEmpty) {
      return FertilizerCalculationResult.unverified(
        cropName: crop.name,
        locationDisplayName: locationDisplayName,
        stageName: stageName,
        unverifiedReason:
            'An appropriate verified recommendation is not currently available for ${crop.name} at "$stageName" in $locationDisplayName. Please consult a qualified agricultural advisor or use a locally verified recommendation.',
      );
    }

    // 2. Select best matching rule based on location hierarchy
    FertilizerRecommendation? selectedRule;

    final codeUpper = countryCode.toUpperCase();

    // Priority A: Region-specific match
    if (regionName != null && regionName.isNotEmpty) {
      try {
        selectedRule = matchingRules.firstWhere((r) =>
            r.countryCode.toUpperCase() == codeUpper &&
            r.regionName != null &&
            r.regionName!.isNotEmpty &&
            (r.regionName!.toLowerCase().contains(regionName.toLowerCase()) ||
                regionName.toLowerCase().contains(r.regionName!.toLowerCase())));
      } catch (_) {}
    }

    // Priority B: Country-level match
    if (selectedRule == null) {
      try {
        selectedRule = matchingRules.firstWhere(
          (r) => r.countryCode.toUpperCase() == codeUpper,
        );
      } catch (_) {}
    }

    // Priority C: Global general benchmark
    if (selectedRule == null) {
      try {
        selectedRule = matchingRules.firstWhere(
          (r) => r.countryCode.toUpperCase() == 'GLOBAL',
        );
      } catch (_) {}
    }

    // If still no rule matched
    if (selectedRule == null) {
      return FertilizerCalculationResult.unverified(
        cropName: crop.name,
        locationDisplayName: locationDisplayName,
        stageName: stageName,
        unverifiedReason:
            'No verified recommendation for ${crop.name} in $countryName. We do not manufacture unverified rates. Please consult your local extension officer.',
      );
    }

    // 3. Fetch products and sources
    final localProducts =
        await _repository.getProducts(countryCode: countryCode);
    final FertilizerSource? source =
        await _repository.getSourceById(selectedRule.sourceId);

    // 4. Calculate Nutrients & Soil Test Adjustments
    double nRate = selectedRule.nKgPerHaRec;
    double pRate = selectedRule.p2o5KgPerHaRec;
    double kRate = selectedRule.k2oKgPerHaRec;
    double sRate = selectedRule.sKgPerHaRec;
    double caRate = selectedRule.caKgPerHaRec;
    double mgRate = selectedRule.mgKgPerHaRec;

    final List<String> soilNotes = [];
    RecommendationConfidence finalConfidence = selectedRule.confidence;

    if (soilTest.hasSoilTest) {
      finalConfidence = RecommendationConfidence.soilTestBased;

      // pH guidance
      if (soilTest.ph != null) {
        if (soilTest.ph! < 5.2) {
          soilNotes.add(
            'Soil pH is strongly acidic (${soilTest.ph!.toStringAsFixed(1)}). Lime application (500–1000 kg/ha Agricultural Lime) is recommended to unlock phosphorus availability and prevent aluminum toxicity.',
          );
        } else if (soilTest.ph! > 7.8) {
          soilNotes.add(
            'Soil pH is alkaline/calcareous (${soilTest.ph!.toStringAsFixed(1)}). Phosphorus and micronutrient (Zn, Fe) availability may be restricted.',
          );
        }
      }

      // Available Phosphorus adjustment (Bray-1 / Mehlich-3)
      if (soilTest.phosphorusPpm != null) {
        if (soilTest.phosphorusPpm! < 10) {
          pRate *= 1.25; // Increase 25% for low P soil
          soilNotes.add(
            'Available P is Low (${soilTest.phosphorusPpm!.toStringAsFixed(0)} ppm). Phosphate requirement increased by +25% for soil build-up.',
          );
        } else if (soilTest.phosphorusPpm! > 30) {
          pRate *= 0.65; // Decrease 35% for high P soil
          soilNotes.add(
            'Available P is High (${soilTest.phosphorusPpm!.toStringAsFixed(0)} ppm). Phosphate rate reduced by -35% to optimize efficiency.',
          );
        }
      }

      // Exchangeable Potassium adjustment
      if (soilTest.potassiumPpm != null) {
        if (soilTest.potassiumPpm! < 80) {
          kRate *= 1.25;
          soilNotes.add(
            'Exchangeable K is Low (${soilTest.potassiumPpm!.toStringAsFixed(0)} ppm). Potash requirement increased by +25%.',
          );
        } else if (soilTest.potassiumPpm! > 220) {
          kRate *= 0.70;
          soilNotes.add(
            'Exchangeable K is High (${soilTest.potassiumPpm!.toStringAsFixed(0)} ppm). Potash requirement reduced by -30%.',
          );
        }
      }

      // Organic matter credit
      if (soilTest.organicMatterPercent != null &&
          soilTest.organicMatterPercent! >= 3.5) {
        final credit = 15.0;
        nRate = (nRate - credit).clamp(0.0, 999.0);
        soilNotes.add(
          'High Organic Matter (${soilTest.organicMatterPercent!.toStringAsFixed(1)}%). Mineral nitrogen credit of $credit kg N/ha applied.',
        );
      }
    }

    // 5. Build Product Calculation Items
    final List<FertilizerProductCalculationItem> productItems = [];

    if (selectedRule.splitRules.isNotEmpty) {
      // Multi-product / Split application program
      for (final split in selectedRule.splitRules) {
        FertilizerProduct? product;
        try {
          product = localProducts.firstWhere(
            (p) =>
                p.id == split.preferredProductId ||
                p.name.toLowerCase() ==
                    (split.preferredProductName ?? '').toLowerCase(),
          );
        } catch (_) {
          product = FertilizerProduct(
            id: split.preferredProductId,
            name: split.preferredProductName ?? 'Recommended Compound',
            packageSize: 50.0,
            packageUnit: 'kg',
          );
        }

        final double splitFraction = (split.percentageOfTotal / 100.0).clamp(0.05, 1.0);
        final double splitRatePerHa = selectedRule.rateKgPerHaRec * splitFraction;
        final double totalKg = splitRatePerHa * normalizedHectares;
        final double exactBags = totalKg / product.packageSize;
        final int wholeBags = exactBags.ceil();

        productItems.add(
          FertilizerProductCalculationItem(
            productName: product.name,
            formulaGrade: product.formulaGrade,
            stage: split.stageName,
            ratePerHa: splitRatePerHa,
            ratePerHaMin: selectedRule.rateKgPerHaMin * splitFraction,
            ratePerHaMax: selectedRule.rateKgPerHaMax * splitFraction,
            rateUnit: selectedRule.rateUnit,
            totalQuantityRequired: totalKg,
            packageSize: product.packageSize,
            packageUnit: product.packageUnit,
            exactPackagesNeeded: exactBags,
            wholePackagesToPurchase: wholeBags,
            applicationMethod: split.applicationMethod,
            timingGuidance: split.timing,
            manufacturer: product.manufacturer,
          ),
        );
      }
    } else {
      // Single Stage / Product Recommendation
      FertilizerProduct? product;
      if (selectedRule.preferredProductId != null) {
        try {
          product = localProducts.firstWhere(
            (p) => p.id == selectedRule!.preferredProductId,
          );
        } catch (_) {}
      }
      if (product == null && selectedRule.preferredProductName != null) {
        try {
          product = localProducts.firstWhere(
            (p) => p.name
                .toLowerCase()
                .contains(selectedRule!.preferredProductName!.toLowerCase()),
          );
        } catch (_) {}
      }
      product ??= localProducts.isNotEmpty
          ? localProducts.first
          : FertilizerProduct(
              id: 'generic_product',
              name: selectedRule.preferredProductName ?? 'Standard Fertilizer Product',
              packageSize: 50.0,
              packageUnit: 'kg',
            );

      final double ratePerHa = selectedRule.rateKgPerHaRec;
      final double totalKg = ratePerHa * normalizedHectares;
      final double exactBags = totalKg / product.packageSize;
      final int wholeBags = exactBags.ceil();

      productItems.add(
        FertilizerProductCalculationItem(
          productName: product.name,
          formulaGrade: product.formulaGrade,
          stage: selectedRule.stageName,
          ratePerHa: ratePerHa,
          ratePerHaMin: selectedRule.rateKgPerHaMin,
          ratePerHaMax: selectedRule.rateKgPerHaMax,
          rateUnit: selectedRule.rateUnit,
          totalQuantityRequired: totalKg,
          packageSize: product.packageSize,
          packageUnit: product.packageUnit,
          exactPackagesNeeded: exactBags,
          wholePackagesToPurchase: wholeBags,
          applicationMethod: selectedRule.applicationMethod,
          timingGuidance: selectedRule.timingGuidance,
          manufacturer: product.manufacturer,
        ),
      );
    }

    const disclaimer =
        'Important: This recommendation is based on available agronomic guidance for the selected crop, location, production system and available information. Actual fertilizer requirements can vary with soil fertility, crop variety, yield target, weather and management practices. A soil test provides a more accurate basis for fertilizer decisions. Follow local agricultural extension or qualified agronomic advice where available.';

    return FertilizerCalculationResult(
      hasVerifiedData: true,
      cropName: crop.name,
      cropCategory: crop.category.displayName,
      locationDisplayName: locationDisplayName,
      stageName: stageName,
      productionSystem: productionSystem,
      fieldSizeInput: fieldSize,
      fieldUnitInput: fieldUnit,
      normalizedHectares: normalizedHectares,
      confidence: finalConfidence,
      nutrients: FertilizerNutrientSummary(
        nKgPerHa: nRate,
        p2o5KgPerHa: pRate,
        k2oKgPerHa: kRate,
        sKgPerHa: sRate,
        caKgPerHa: caRate,
        mgKgPerHa: mgRate,
      ),
      products: productItems,
      agronomicGuidance: selectedRule.agronomicTips,
      soilAdjustmentSummary:
          soilNotes.isNotEmpty ? soilNotes.join('\n\n') : null,
      source: source,
      disclaimer: disclaimer,
    );
  }
}
