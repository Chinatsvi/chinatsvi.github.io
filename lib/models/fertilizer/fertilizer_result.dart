import 'package:flutter/foundation.dart';
import 'fertilizer_recommendation.dart';
import 'fertilizer_source.dart';

@immutable
class FertilizerProductCalculationItem {
  final String productName;
  final String formulaGrade;
  final String stage;
  final double ratePerHa;
  final double ratePerHaMin;
  final double ratePerHaMax;
  final String rateUnit; // 'kg/ha', 'L/ha'
  final double totalQuantityRequired; // Exact decimal required for field
  final double packageSize; // e.g. 50 kg
  final String packageUnit; // 'kg', 'L'
  final double exactPackagesNeeded; // e.g. 5.5
  final int wholePackagesToPurchase; // e.g. 6
  final String applicationMethod;
  final String timingGuidance;
  final String? manufacturer;

  const FertilizerProductCalculationItem({
    required this.productName,
    required this.formulaGrade,
    required this.stage,
    required this.ratePerHa,
    this.ratePerHaMin = 0.0,
    this.ratePerHaMax = 0.0,
    this.rateUnit = 'kg/ha',
    required this.totalQuantityRequired,
    required this.packageSize,
    this.packageUnit = 'kg',
    required this.exactPackagesNeeded,
    required this.wholePackagesToPurchase,
    required this.applicationMethod,
    required this.timingGuidance,
    this.manufacturer,
  });

  String get rateDisplay {
    if (ratePerHaMin > 0 && ratePerHaMax > 0 && ratePerHaMin != ratePerHaMax) {
      return '${ratePerHaMin.toStringAsFixed(0)}–${ratePerHaMax.toStringAsFixed(0)} $rateUnit';
    }
    return '${ratePerHa.toStringAsFixed(0)} $rateUnit';
  }

  String get purchaseSummary {
    return '$wholePackagesToPurchase × ${packageSize.toStringAsFixed(0)}$packageUnit bags (${totalQuantityRequired.toStringAsFixed(1)} $packageUnit needed)';
  }
}

@immutable
class FertilizerNutrientSummary {
  final double nKgPerHa;
  final double p2o5KgPerHa;
  final double k2oKgPerHa;
  final double sKgPerHa;
  final double caKgPerHa;
  final double mgKgPerHa;

  const FertilizerNutrientSummary({
    required this.nKgPerHa,
    required this.p2o5KgPerHa,
    required this.k2oKgPerHa,
    this.sKgPerHa = 0.0,
    this.caKgPerHa = 0.0,
    this.mgKgPerHa = 0.0,
  });
}

@immutable
class FertilizerCalculationResult {
  final bool hasVerifiedData;
  final String? unverifiedReason;

  final String cropName;
  final String cropCategory;
  final String locationDisplayName;
  final String stageName;
  final String productionSystem;

  final double fieldSizeInput;
  final String fieldUnitInput;
  final double normalizedHectares;

  final RecommendationConfidence confidence;
  final FertilizerNutrientSummary nutrients;
  final List<FertilizerProductCalculationItem> products;
  final List<String> agronomicGuidance;
  final String? soilAdjustmentSummary;
  final FertilizerSource? source;
  final String disclaimer;

  const FertilizerCalculationResult({
    required this.hasVerifiedData,
    this.unverifiedReason,
    required this.cropName,
    required this.cropCategory,
    required this.locationDisplayName,
    required this.stageName,
    required this.productionSystem,
    required this.fieldSizeInput,
    required this.fieldUnitInput,
    required this.normalizedHectares,
    required this.confidence,
    required this.nutrients,
    required this.products,
    required this.agronomicGuidance,
    this.soilAdjustmentSummary,
    this.source,
    required this.disclaimer,
  });

  static FertilizerCalculationResult unverified({
    required String cropName,
    required String locationDisplayName,
    required String stageName,
    required String unverifiedReason,
  }) {
    return FertilizerCalculationResult(
      hasVerifiedData: false,
      unverifiedReason: unverifiedReason,
      cropName: cropName,
      cropCategory: '',
      locationDisplayName: locationDisplayName,
      stageName: stageName,
      productionSystem: '',
      fieldSizeInput: 0,
      fieldUnitInput: 'Hectares',
      normalizedHectares: 0,
      confidence: RecommendationConfidence.incomplete,
      nutrients: const FertilizerNutrientSummary(
        nKgPerHa: 0,
        p2o5KgPerHa: 0,
        k2oKgPerHa: 0,
      ),
      products: const [],
      agronomicGuidance: const [],
      disclaimer: '',
    );
  }
}
