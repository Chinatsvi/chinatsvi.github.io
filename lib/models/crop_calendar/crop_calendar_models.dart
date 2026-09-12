import 'package:cloud_firestore/cloud_firestore.dart';

enum CropCategory {
  vegetable,
  rootAndTuber,
  herb,
}

enum MaturityType {
  early,
  medium,
  late,
  custom,
}

enum ProductionSystem {
  openField,
  greenhouse,
  shadeNet,
  irrigated,
  rainFed,
  containerGarden,
}

enum WaterSource {
  irrigated,
  rainFed,
  limitedIrrigation,
}

enum ConfidenceLevel {
  high,
  moderate,
  low,
}

enum WindowType {
  main,
  secondary,
  restrictedOrRisky,
}

enum StageType {
  planting,
  establishment,
  vegetative,
  weeding,
  fertilizing,
  flowering,
  fruitDevelopment,
  harvesting,
}

class CropVariety {
  final String id;
  final String name;
  final MaturityType maturityType;
  final int maturityDaysMin;
  final int maturityDaysMax;
  final String? description;
  final String? source;

  const CropVariety({
    required this.id,
    required this.name,
    required this.maturityType,
    required this.maturityDaysMin,
    required this.maturityDaysMax,
    this.description,
    this.source,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'maturityType': maturityType.name,
        'maturityDaysMin': maturityDaysMin,
        'maturityDaysMax': maturityDaysMax,
        'description': description,
        'source': source,
      };

  factory CropVariety.fromMap(Map<String, dynamic> map) {
    return CropVariety(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      maturityType: MaturityType.values.firstWhere(
        (e) => e.name == map['maturityType'],
        orElse: () => MaturityType.medium,
      ),
      maturityDaysMin: (map['maturityDaysMin'] as num?)?.toInt() ?? 60,
      maturityDaysMax: (map['maturityDaysMax'] as num?)?.toInt() ?? 90,
      description: map['description'],
      source: map['source'],
    );
  }
}

class StageMonitoringItem {
  final String title;
  final String detail;
  final bool isWarning;

  const StageMonitoringItem({
    required this.title,
    required this.detail,
    this.isWarning = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'detail': detail,
        'isWarning': isWarning,
      };

  factory StageMonitoringItem.fromMap(Map<String, dynamic> map) {
    return StageMonitoringItem(
      title: map['title'] ?? '',
      detail: map['detail'] ?? '',
      isWarning: map['isWarning'] ?? false,
    );
  }
}

class GrowthStage {
  final String id;
  final String name;
  final StageType type;
  final int startDayOffset; // Days from planting
  final int endDayOffset;
  final String title;
  final String description;
  final String whyItMatters;
  final List<StageMonitoringItem> whatToMonitor;
  final String? nutrientGuidance;
  final String? weedingGuidance;
  final String? warnings;
  final String? sourceReference;

  const GrowthStage({
    required this.id,
    required this.name,
    required this.type,
    required this.startDayOffset,
    required this.endDayOffset,
    required this.title,
    required this.description,
    required this.whyItMatters,
    required this.whatToMonitor,
    this.nutrientGuidance,
    this.weedingGuidance,
    this.warnings,
    this.sourceReference,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'startDayOffset': startDayOffset,
        'endDayOffset': endDayOffset,
        'title': title,
        'description': description,
        'whyItMatters': whyItMatters,
        'whatToMonitor': whatToMonitor.map((e) => e.toMap()).toList(),
        'nutrientGuidance': nutrientGuidance,
        'weedingGuidance': weedingGuidance,
        'warnings': warnings,
        'sourceReference': sourceReference,
      };

  factory GrowthStage.fromMap(Map<String, dynamic> map) {
    return GrowthStage(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: StageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StageType.vegetative,
      ),
      startDayOffset: (map['startDayOffset'] as num?)?.toInt() ?? 0,
      endDayOffset: (map['endDayOffset'] as num?)?.toInt() ?? 14,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      whyItMatters: map['whyItMatters'] ?? '',
      whatToMonitor: (map['whatToMonitor'] as List<dynamic>?)
              ?.map((e) =>
                  StageMonitoringItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      nutrientGuidance: map['nutrientGuidance'],
      weedingGuidance: map['weedingGuidance'],
      warnings: map['warnings'],
      sourceReference: map['sourceReference'],
    );
  }
}

class HorticulturalCrop {
  final String id;
  final String name;
  final String scientificName;
  final CropCategory category;
  final String iconEmoji;
  final String generalDescription;
  final int standardMaturityDaysMin;
  final int standardMaturityDaysMax;
  final double optimalTempMin; // °C
  final double optimalTempMax;
  final double frostToleranceScore; // 0 = very sensitive, 1 = tolerant
  final String waterRequirement; // Low, Moderate, High
  final String soilPhRange; // e.g. "6.0 - 6.8"
  final List<CropVariety> varieties;
  final List<GrowthStage> standardStages;
  final String defaultDataSource;

  const HorticulturalCrop({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.iconEmoji,
    required this.generalDescription,
    required this.standardMaturityDaysMin,
    required this.standardMaturityDaysMax,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.frostToleranceScore,
    required this.waterRequirement,
    required this.soilPhRange,
    required this.varieties,
    required this.standardStages,
    required this.defaultDataSource,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'category': category.name,
        'iconEmoji': iconEmoji,
        'generalDescription': generalDescription,
        'standardMaturityDaysMin': standardMaturityDaysMin,
        'standardMaturityDaysMax': standardMaturityDaysMax,
        'optimalTempMin': optimalTempMin,
        'optimalTempMax': optimalTempMax,
        'frostToleranceScore': frostToleranceScore,
        'waterRequirement': waterRequirement,
        'soilPhRange': soilPhRange,
        'varieties': varieties.map((e) => e.toMap()).toList(),
        'standardStages': standardStages.map((e) => e.toMap()).toList(),
        'defaultDataSource': defaultDataSource,
      };

  factory HorticulturalCrop.fromMap(Map<String, dynamic> map) {
    return HorticulturalCrop(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      category: CropCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => CropCategory.vegetable,
      ),
      iconEmoji: map['iconEmoji'] ?? '🌱',
      generalDescription: map['generalDescription'] ?? '',
      standardMaturityDaysMin:
          (map['standardMaturityDaysMin'] as num?)?.toInt() ?? 60,
      standardMaturityDaysMax:
          (map['standardMaturityDaysMax'] as num?)?.toInt() ?? 90,
      optimalTempMin: (map['optimalTempMin'] as num?)?.toDouble() ?? 18.0,
      optimalTempMax: (map['optimalTempMax'] as num?)?.toDouble() ?? 28.0,
      frostToleranceScore:
          (map['frostToleranceScore'] as num?)?.toDouble() ?? 0.0,
      waterRequirement: map['waterRequirement'] ?? 'Moderate',
      soilPhRange: map['soilPhRange'] ?? '6.0 - 6.8',
      varieties: (map['varieties'] as List<dynamic>?)
              ?.map((e) => CropVariety.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      standardStages: (map['standardStages'] as List<dynamic>?)
              ?.map((e) => GrowthStage.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      defaultDataSource: map['defaultDataSource'] ?? 'National Agronomic Guidelines',
    );
  }
}

class LocationAgroProfile {
  final String country;
  final String countryCode; // e.g. "ZW", "ZA", "KE", "NG"
  final String region; // e.g. "Masvingo", "Limpopo", "Nakuru"
  final String district; // e.g. "Masvingo Rural", "Polokwane", "Naivasha"
  final String climateZone; // e.g. "Highveld", "Lowveld", "Middleveld", "Subtropical", "Tropical Highland", "Arid"
  final double latitude;
  final double longitude;
  final int? elevationMeters;
  final bool isSouthernHemisphere;
  final List<int> frostRiskMonths; // 1-12 (e.g. [5, 6, 7] for May-July in Southern Africa)
  final List<int> wetSeasonMonths; // 1-12 (e.g. [11, 12, 1, 2, 3])
  final List<int> hotSeasonMonths; // 1-12 (e.g. [10, 11, 12, 1, 2])
  final String seasonalNotes;

  const LocationAgroProfile({
    required this.country,
    required this.countryCode,
    required this.region,
    required this.district,
    required this.climateZone,
    required this.latitude,
    required this.longitude,
    this.elevationMeters,
    required this.isSouthernHemisphere,
    required this.frostRiskMonths,
    required this.wetSeasonMonths,
    required this.hotSeasonMonths,
    required this.seasonalNotes,
  });

  String get displayName => '$district, $region, $country';
  String get shortName => '$district, $region';

  Map<String, dynamic> toMap() => {
        'country': country,
        'countryCode': countryCode,
        'region': region,
        'district': district,
        'climateZone': climateZone,
        'latitude': latitude,
        'longitude': longitude,
        'elevationMeters': elevationMeters,
        'isSouthernHemisphere': isSouthernHemisphere,
        'frostRiskMonths': frostRiskMonths,
        'wetSeasonMonths': wetSeasonMonths,
        'hotSeasonMonths': hotSeasonMonths,
        'seasonalNotes': seasonalNotes,
      };

  factory LocationAgroProfile.fromMap(Map<String, dynamic> map) {
    return LocationAgroProfile(
      country: map['country'] ?? '',
      countryCode: map['countryCode'] ?? '',
      region: map['region'] ?? '',
      district: map['district'] ?? '',
      climateZone: map['climateZone'] ?? 'Temperate',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      elevationMeters: (map['elevationMeters'] as num?)?.toInt(),
      isSouthernHemisphere: map['isSouthernHemisphere'] ?? true,
      frostRiskMonths: List<int>.from(map['frostRiskMonths'] ?? []),
      wetSeasonMonths: List<int>.from(map['wetSeasonMonths'] ?? []),
      hotSeasonMonths: List<int>.from(map['hotSeasonMonths'] ?? []),
      seasonalNotes: map['seasonalNotes'] ?? '',
    );
  }
}

class PlantingWindow {
  final int startMonth; // 1-12
  final int endMonth; // 1-12
  final WindowType windowType;
  final String label; // e.g. "Main Planting Window", "Winter Irrigated Window"
  final String periodDescription; // e.g. "September – November"
  final String rationale;
  final ConfidenceLevel confidence;
  final String? sourceReference;

  const PlantingWindow({
    required this.startMonth,
    required this.endMonth,
    required this.windowType,
    required this.label,
    required this.periodDescription,
    required this.rationale,
    required this.confidence,
    this.sourceReference,
  });

  Map<String, dynamic> toMap() => {
        'startMonth': startMonth,
        'endMonth': endMonth,
        'windowType': windowType.name,
        'label': label,
        'periodDescription': periodDescription,
        'rationale': rationale,
        'confidence': confidence.name,
        'sourceReference': sourceReference,
      };

  factory PlantingWindow.fromMap(Map<String, dynamic> map) {
    return PlantingWindow(
      startMonth: (map['startMonth'] as num?)?.toInt() ?? 1,
      endMonth: (map['endMonth'] as num?)?.toInt() ?? 12,
      windowType: WindowType.values.firstWhere(
        (e) => e.name == map['windowType'],
        orElse: () => WindowType.main,
      ),
      label: map['label'] ?? '',
      periodDescription: map['periodDescription'] ?? '',
      rationale: map['rationale'] ?? '',
      confidence: ConfidenceLevel.values.firstWhere(
        (e) => e.name == map['confidence'],
        orElse: () => ConfidenceLevel.moderate,
      ),
      sourceReference: map['sourceReference'],
    );
  }
}

class ClimateRiskAlert {
  final String title;
  final String description;
  final String severity; // info, warning, danger
  final String iconEmoji;

  const ClimateRiskAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.iconEmoji,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'severity': severity,
        'iconEmoji': iconEmoji,
      };

  factory ClimateRiskAlert.fromMap(Map<String, dynamic> map) {
    return ClimateRiskAlert(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'warning',
      iconEmoji: map['iconEmoji'] ?? '⚠️',
    );
  }
}

class CropTimelineMilestone {
  final GrowthStage stage;
  final DateTime estimatedStartDate;
  final DateTime estimatedEndDate;
  final String dateDisplay;
  final bool isCurrent;
  final bool isCompleted;

  const CropTimelineMilestone({
    required this.stage,
    required this.estimatedStartDate,
    required this.estimatedEndDate,
    required this.dateDisplay,
    this.isCurrent = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'stage': stage.toMap(),
        'estimatedStartDate': estimatedStartDate.toIso8601String(),
        'estimatedEndDate': estimatedEndDate.toIso8601String(),
        'dateDisplay': dateDisplay,
        'isCurrent': isCurrent,
        'isCompleted': isCompleted,
      };

  factory CropTimelineMilestone.fromMap(Map<String, dynamic> map) {
    return CropTimelineMilestone(
      stage: GrowthStage.fromMap(Map<String, dynamic>.from(map['stage'])),
      estimatedStartDate: DateTime.parse(map['estimatedStartDate']),
      estimatedEndDate: DateTime.parse(map['estimatedEndDate']),
      dateDisplay: map['dateDisplay'] ?? '',
      isCurrent: map['isCurrent'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class CropRecommendationResult {
  final HorticulturalCrop crop;
  final CropVariety? selectedVariety;
  final LocationAgroProfile location;
  final ProductionSystem productionSystem;
  final WaterSource waterSource;
  final DateTime plantingDate;
  final PlantingWindow recommendedWindow;
  final List<PlantingWindow> allWindows;
  final ConfidenceLevel confidence;
  final String confidenceExplanation;
  final List<String> recommendationFactors;
  final List<ClimateRiskAlert> riskAlerts;
  final List<CropTimelineMilestone> timelineMilestones;
  final DateTime estimatedHarvestStart;
  final DateTime estimatedHarvestEnd;
  final String harvestWindowDisplay;
  final String dataSources;

  const CropRecommendationResult({
    required this.crop,
    this.selectedVariety,
    required this.location,
    required this.productionSystem,
    required this.waterSource,
    required this.plantingDate,
    required this.recommendedWindow,
    required this.allWindows,
    required this.confidence,
    required this.confidenceExplanation,
    required this.recommendationFactors,
    required this.riskAlerts,
    required this.timelineMilestones,
    required this.estimatedHarvestStart,
    required this.estimatedHarvestEnd,
    required this.harvestWindowDisplay,
    required this.dataSources,
  });
}

class SavedCropCalendar {
  final String id;
  final String userId;
  final String cropId;
  final String cropName;
  final String cropEmoji;
  final String? varietyName;
  final LocationAgroProfile location;
  final DateTime plantingDate;
  final ProductionSystem productionSystem;
  final WaterSource waterSource;
  final double? fieldArea;
  final String areaUnit; // "Hectares", "Acres", "sq metres"
  final String currency; // "$", "R", "ZiG", "KSh", etc.
  final bool remindersEnabled;
  final DateTime createdAt;
  final DateTime estimatedHarvestStart;
  final DateTime estimatedHarvestEnd;
  final List<CropTimelineMilestone> milestones;
  final String confidence;
  final String? notes;

  const SavedCropCalendar({
    required this.id,
    required this.userId,
    required this.cropId,
    required this.cropName,
    required this.cropEmoji,
    this.varietyName,
    required this.location,
    required this.plantingDate,
    required this.productionSystem,
    required this.waterSource,
    this.fieldArea,
    this.areaUnit = 'Hectares',
    this.currency = r'$',
    this.remindersEnabled = true,
    required this.createdAt,
    required this.estimatedHarvestStart,
    required this.estimatedHarvestEnd,
    required this.milestones,
    required this.confidence,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'cropId': cropId,
        'cropName': cropName,
        'cropEmoji': cropEmoji,
        'varietyName': varietyName,
        'location': location.toMap(),
        'plantingDate': Timestamp.fromDate(plantingDate),
        'productionSystem': productionSystem.name,
        'waterSource': waterSource.name,
        'fieldArea': fieldArea,
        'areaUnit': areaUnit,
        'currency': currency,
        'remindersEnabled': remindersEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'estimatedHarvestStart': Timestamp.fromDate(estimatedHarvestStart),
        'estimatedHarvestEnd': Timestamp.fromDate(estimatedHarvestEnd),
        'milestones': milestones.map((e) => e.toMap()).toList(),
        'confidence': confidence,
        'notes': notes,
      };

  factory SavedCropCalendar.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SavedCropCalendar(
      id: doc.id,
      userId: map['userId'] ?? '',
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      cropEmoji: map['cropEmoji'] ?? '🌱',
      varietyName: map['varietyName'],
      location: LocationAgroProfile.fromMap(
          Map<String, dynamic>.from(map['location'] ?? {})),
      plantingDate: (map['plantingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productionSystem: ProductionSystem.values.firstWhere(
        (e) => e.name == map['productionSystem'],
        orElse: () => ProductionSystem.openField,
      ),
      waterSource: WaterSource.values.firstWhere(
        (e) => e.name == map['waterSource'],
        orElse: () => WaterSource.irrigated,
      ),
      fieldArea: (map['fieldArea'] as num?)?.toDouble(),
      areaUnit: map['areaUnit'] ?? 'Hectares',
      currency: map['currency'] ?? r'$',
      remindersEnabled: map['remindersEnabled'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedHarvestStart:
          (map['estimatedHarvestStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedHarvestEnd:
          (map['estimatedHarvestEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      milestones: (map['milestones'] as List<dynamic>?)
              ?.map((e) =>
                  CropTimelineMilestone.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      confidence: map['confidence'] ?? 'moderate',
      notes: map['notes'],
    );
  }

  SavedCropCalendar copyWith({
    String? id,
    String? userId,
    String? cropId,
    String? cropName,
    String? cropEmoji,
    String? varietyName,
    LocationAgroProfile? location,
    DateTime? plantingDate,
    ProductionSystem? productionSystem,
    WaterSource? waterSource,
    double? fieldArea,
    String? areaUnit,
    String? currency,
    bool? remindersEnabled,
    DateTime? createdAt,
    DateTime? estimatedHarvestStart,
    DateTime? estimatedHarvestEnd,
    List<CropTimelineMilestone>? milestones,
    String? confidence,
    String? notes,
  }) {
    return SavedCropCalendar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      cropEmoji: cropEmoji ?? this.cropEmoji,
      varietyName: varietyName ?? this.varietyName,
      location: location ?? this.location,
      plantingDate: plantingDate ?? this.plantingDate,
      productionSystem: productionSystem ?? this.productionSystem,
      waterSource: waterSource ?? this.waterSource,
      fieldArea: fieldArea ?? this.fieldArea,
      areaUnit: areaUnit ?? this.areaUnit,
      currency: currency ?? this.currency,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      createdAt: createdAt ?? this.createdAt,
      estimatedHarvestStart: estimatedHarvestStart ?? this.estimatedHarvestStart,
      estimatedHarvestEnd: estimatedHarvestEnd ?? this.estimatedHarvestEnd,
      milestones: milestones ?? this.milestones,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }
}
