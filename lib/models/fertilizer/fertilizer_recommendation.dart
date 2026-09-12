import 'package:flutter/foundation.dart';

enum RecommendationConfidence {
  verified,
  general,
  soilTestBased,
  locationBased,
  incomplete,
  requiresReview,
}

extension RecommendationConfidenceExtension on RecommendationConfidence {
  String get displayName {
    switch (this) {
      case RecommendationConfidence.verified:
        return 'Verified Recommendation';
      case RecommendationConfidence.general:
        return 'General Agronomic Guidance';
      case RecommendationConfidence.soilTestBased:
        return 'Soil-Test-Adjusted';
      case RecommendationConfidence.locationBased:
        return 'Location-Specific';
      case RecommendationConfidence.incomplete:
        return 'Incomplete Data';
      case RecommendationConfidence.requiresReview:
        return 'Under Review';
    }
  }

  String get badgeLabel {
    switch (this) {
      case RecommendationConfidence.verified:
        return 'VERIFIED';
      case RecommendationConfidence.general:
        return 'GENERAL';
      case RecommendationConfidence.soilTestBased:
        return 'SOIL-TEST-BASED';
      case RecommendationConfidence.locationBased:
        return 'LOCATION-BASED';
      case RecommendationConfidence.incomplete:
        return 'INCOMPLETE';
      case RecommendationConfidence.requiresReview:
        return 'REQUIRES REVIEW';
    }
  }
}

@immutable
class SplitApplicationRule {
  final String stageName;
  final String timing;
  final double percentageOfTotal; // e.g. 50 for 50%
  final String preferredProductId;
  final String? preferredProductName;
  final String applicationMethod;

  const SplitApplicationRule({
    required this.stageName,
    required this.timing,
    required this.percentageOfTotal,
    required this.preferredProductId,
    this.preferredProductName,
    this.applicationMethod = 'Side dress along rows',
  });

  Map<String, dynamic> toMap() => {
        'stageName': stageName,
        'timing': timing,
        'percentageOfTotal': percentageOfTotal,
        'preferredProductId': preferredProductId,
        'preferredProductName': preferredProductName,
        'applicationMethod': applicationMethod,
      };

  factory SplitApplicationRule.fromMap(Map<String, dynamic> map) {
    return SplitApplicationRule(
      stageName: map['stageName'] ?? '',
      timing: map['timing'] ?? '',
      percentageOfTotal:
          (map['percentageOfTotal'] as num?)?.toDouble() ?? 50.0,
      preferredProductId: map['preferredProductId'] ?? '',
      preferredProductName: map['preferredProductName'],
      applicationMethod:
          map['applicationMethod'] ?? 'Side dress along rows',
    );
  }
}

@immutable
class FertilizerRecommendation {
  final String id;
  final String cropId;
  final String cropName;
  final String stageName; // e.g. 'Basal / Planting', 'Top Dressing', 'Full Season'
  final String countryCode; // ISO Code or 'GLOBAL'
  final String countryName;
  final String? regionName; // Province, State, Natural Region
  final String? agroEcologicalZone;
  final String productionSystem; // 'Rain-fed', 'Irrigated', 'Greenhouse', 'Any'
  final RecommendationConfidence confidence;

  // Nutrient requirements per hectare (kg/ha)
  final double nKgPerHaMin;
  final double nKgPerHaRec;
  final double nKgPerHaMax;

  final double p2o5KgPerHaMin;
  final double p2o5KgPerHaRec;
  final double p2o5KgPerHaMax;

  final double k2oKgPerHaMin;
  final double k2oKgPerHaRec;
  final double k2oKgPerHaMax;

  final double sKgPerHaRec;
  final double caKgPerHaRec;
  final double mgKgPerHaRec;

  // Fertilizer product matching
  final String? preferredProductId;
  final String? preferredProductName;
  final double rateKgPerHaMin;
  final double rateKgPerHaRec;
  final double rateKgPerHaMax;
  final String rateUnit; // 'kg/ha', 'L/ha'

  // Application instructions
  final String applicationMethod;
  final String timingGuidance;
  final List<String> agronomicTips;
  final List<SplitApplicationRule> splitRules;

  // Traceability & Metadata
  final String sourceId;
  final int version;
  final bool active;

  const FertilizerRecommendation({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.stageName,
    this.countryCode = 'GLOBAL',
    this.countryName = 'Global',
    this.regionName,
    this.agroEcologicalZone,
    this.productionSystem = 'Any',
    this.confidence = RecommendationConfidence.verified,
    this.nKgPerHaMin = 0.0,
    required this.nKgPerHaRec,
    this.nKgPerHaMax = 0.0,
    this.p2o5KgPerHaMin = 0.0,
    required this.p2o5KgPerHaRec,
    this.p2o5KgPerHaMax = 0.0,
    this.k2oKgPerHaMin = 0.0,
    required this.k2oKgPerHaRec,
    this.k2oKgPerHaMax = 0.0,
    this.sKgPerHaRec = 0.0,
    this.caKgPerHaRec = 0.0,
    this.mgKgPerHaRec = 0.0,
    this.preferredProductId,
    this.preferredProductName,
    this.rateKgPerHaMin = 0.0,
    required this.rateKgPerHaRec,
    this.rateKgPerHaMax = 0.0,
    this.rateUnit = 'kg/ha',
    this.applicationMethod = 'Banded at planting or side-dressed',
    this.timingGuidance = 'Apply according to recommended growth stage.',
    this.agronomicTips = const [],
    this.splitRules = const [],
    required this.sourceId,
    this.version = 1,
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cropId': cropId,
        'cropName': cropName,
        'stageName': stageName,
        'countryCode': countryCode,
        'countryName': countryName,
        'regionName': regionName,
        'agroEcologicalZone': agroEcologicalZone,
        'productionSystem': productionSystem,
        'confidence': confidence.name,
        'nKgPerHaMin': nKgPerHaMin,
        'nKgPerHaRec': nKgPerHaRec,
        'nKgPerHaMax': nKgPerHaMax,
        'p2o5KgPerHaMin': p2o5KgPerHaMin,
        'p2o5KgPerHaRec': p2o5KgPerHaRec,
        'p2o5KgPerHaMax': p2o5KgPerHaMax,
        'k2oKgPerHaMin': k2oKgPerHaMin,
        'k2oKgPerHaRec': k2oKgPerHaRec,
        'k2oKgPerHaMax': k2oKgPerHaMax,
        'sKgPerHaRec': sKgPerHaRec,
        'caKgPerHaRec': caKgPerHaRec,
        'mgKgPerHaRec': mgKgPerHaRec,
        'preferredProductId': preferredProductId,
        'preferredProductName': preferredProductName,
        'rateKgPerHaMin': rateKgPerHaMin,
        'rateKgPerHaRec': rateKgPerHaRec,
        'rateKgPerHaMax': rateKgPerHaMax,
        'rateUnit': rateUnit,
        'applicationMethod': applicationMethod,
        'timingGuidance': timingGuidance,
        'agronomicTips': agronomicTips,
        'splitRules': splitRules.map((e) => e.toMap()).toList(),
        'sourceId': sourceId,
        'version': version,
        'active': active,
      };

  factory FertilizerRecommendation.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    return FertilizerRecommendation(
      id: id ?? map['id'] ?? '',
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      stageName: map['stageName'] ?? '',
      countryCode: map['countryCode'] ?? 'GLOBAL',
      countryName: map['countryName'] ?? 'Global',
      regionName: map['regionName'],
      agroEcologicalZone: map['agroEcologicalZone'],
      productionSystem: map['productionSystem'] ?? 'Any',
      confidence: RecommendationConfidence.values.firstWhere(
        (e) => e.name == map['confidence'],
        orElse: () => RecommendationConfidence.general,
      ),
      nKgPerHaMin: (map['nKgPerHaMin'] as num?)?.toDouble() ?? 0.0,
      nKgPerHaRec: (map['nKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      nKgPerHaMax: (map['nKgPerHaMax'] as num?)?.toDouble() ?? 0.0,
      p2o5KgPerHaMin: (map['p2o5KgPerHaMin'] as num?)?.toDouble() ?? 0.0,
      p2o5KgPerHaRec: (map['p2o5KgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      p2o5KgPerHaMax: (map['p2o5KgPerHaMax'] as num?)?.toDouble() ?? 0.0,
      k2oKgPerHaMin: (map['k2oKgPerHaMin'] as num?)?.toDouble() ?? 0.0,
      k2oKgPerHaRec: (map['k2oKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      k2oKgPerHaMax: (map['k2oKgPerHaMax'] as num?)?.toDouble() ?? 0.0,
      sKgPerHaRec: (map['sKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      caKgPerHaRec: (map['caKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      mgKgPerHaRec: (map['mgKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      preferredProductId: map['preferredProductId'],
      preferredProductName: map['preferredProductName'],
      rateKgPerHaMin: (map['rateKgPerHaMin'] as num?)?.toDouble() ?? 0.0,
      rateKgPerHaRec: (map['rateKgPerHaRec'] as num?)?.toDouble() ?? 0.0,
      rateKgPerHaMax: (map['rateKgPerHaMax'] as num?)?.toDouble() ?? 0.0,
      rateUnit: map['rateUnit'] ?? 'kg/ha',
      applicationMethod: map['applicationMethod'] ?? 'Banded or side-dressed',
      timingGuidance:
          map['timingGuidance'] ?? 'Apply according to crop growth stage.',
      agronomicTips: List<String>.from(map['agronomicTips'] ?? []),
      splitRules: (map['splitRules'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SplitApplicationRule.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          const [],
      sourceId: map['sourceId'] ?? '',
      version: (map['version'] as num?)?.toInt() ?? 1,
      active: map['active'] ?? true,
    );
  }
}
