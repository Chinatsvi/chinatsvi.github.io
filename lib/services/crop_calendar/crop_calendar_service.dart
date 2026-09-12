import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../../models/crop_calendar/crop_calendar_models.dart';
import '../../data/crop_calendar/horticultural_crops_data.dart';
import '../../data/crop_calendar/regional_agro_zones_data.dart';

class CropCalendarService {
  static final CropCalendarService _instance = CropCalendarService._internal();
  factory CropCalendarService() => _instance;
  CropCalendarService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cached lists
  List<HorticulturalCrop> _cachedCrops = [];
  List<LocationAgroProfile> _cachedLocations = [];

  // ==========================================
  // 1. CROPS DATA RETRIEVAL
  // ==========================================
  Future<List<HorticulturalCrop>> getHorticulturalCrops() async {
    if (_cachedCrops.isNotEmpty) return _cachedCrops;

    try {
      // Try to fetch remote crops from Firestore if online
      final snapshot = await _firestore
          .collection('crop_calendar_crops')
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isNotEmpty) {
        _cachedCrops = snapshot.docs
            .map((doc) => HorticulturalCrop.fromMap(doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('ℹ️ [CROP_CALENDAR] Using bundled crop dataset: $e');
    }

    if (_cachedCrops.isEmpty) {
      _cachedCrops = HorticulturalCropsData.getAllCrops();
    }
    return _cachedCrops;
  }

  // ==========================================
  // 2. LOCATION PROFILES & GEOLOCATION
  // ==========================================
  List<LocationAgroProfile> getAvailableLocations() {
    if (_cachedLocations.isEmpty) {
      _cachedLocations = RegionalAgroZonesData.getAllPresetLocations();
    }
    return _cachedLocations;
  }

  Future<LocationAgroProfile?> detectCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Reverse geocode
      String country = 'Unknown';
      String countryCode = 'GEN';
      String region = 'Detected Region';
      String district = 'Detected Area';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          country = p.country ?? 'Unknown';
          countryCode = p.isoCountryCode ?? 'GEN';
          region = p.administrativeArea ?? p.subAdministrativeArea ?? 'Region';
          district = p.locality ?? p.subLocality ?? region;
        }
      } catch (e) {
        debugPrint('⚠️ [CROP_CALENDAR] Geocoding reverse lookup error: $e');
      }

      // Match against known agro-ecological presets
      final matchedPreset = findClosestPreset(
        position.latitude,
        position.longitude,
        countryName: country,
      );

      if (matchedPreset != null) {
        return LocationAgroProfile(
          country: country.isNotEmpty && country != 'Unknown'
              ? country
              : matchedPreset.country,
          countryCode: countryCode != 'GEN'
              ? countryCode
              : matchedPreset.countryCode,
          region: region.isNotEmpty && region != 'Detected Region'
              ? region
              : matchedPreset.region,
          district: district.isNotEmpty && district != 'Detected Area'
              ? district
              : matchedPreset.district,
          climateZone: matchedPreset.climateZone,
          latitude: position.latitude,
          longitude: position.longitude,
          elevationMeters: matchedPreset.elevationMeters,
          isSouthernHemisphere: position.latitude < 0,
          frostRiskMonths: matchedPreset.frostRiskMonths,
          wetSeasonMonths: matchedPreset.wetSeasonMonths,
          hotSeasonMonths: matchedPreset.hotSeasonMonths,
          seasonalNotes: matchedPreset.seasonalNotes,
        );
      }

      // If no exact preset matched, generate a hemisphere-calibrated profile
      final isSouth = position.latitude < 0;
      if (isSouth) {
        return RegionalAgroZonesData.getDefaultSouthernHemisphereProfile(
          country: country,
          region: region,
          district: district,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        return RegionalAgroZonesData.getDefaultNorthernHemisphereProfile(
          country: country,
          region: region,
          district: district,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [CROP_CALENDAR] GPS detection error: $e');
      return null;
    }
  }

  LocationAgroProfile? findClosestPreset(
    double lat,
    double lng, {
    String? countryName,
  }) {
    final presets = getAvailableLocations();
    LocationAgroProfile? closest;
    double minDistance = double.infinity;

    for (final preset in presets) {
      if (countryName != null &&
          countryName.isNotEmpty &&
          countryName.toLowerCase() == preset.country.toLowerCase()) {
        final dist = _calculateDistance(lat, lng, preset.latitude, preset.longitude);
        if (dist < minDistance) {
          minDistance = dist;
          closest = preset;
        }
      }
    }

    if (closest != null && minDistance < 500) {
      return closest;
    }

    // General fallback across all presets
    for (final preset in presets) {
      final dist = _calculateDistance(lat, lng, preset.latitude, preset.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closest = preset;
      }
    }

    if (minDistance < 600) {
      return closest;
    }
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // km
  }

  // ==========================================
  // 3. MULTI-FACTOR RECOMMENDATION ENGINE
  // ==========================================
  CropRecommendationResult generateRecommendation({
    required HorticulturalCrop crop,
    CropVariety? variety,
    required LocationAgroProfile location,
    required ProductionSystem productionSystem,
    required WaterSource waterSource,
    required DateTime plantingDate,
    String? soilType,
    bool soilTestAvailable = false,
  }) {
    final isSouthern = location.isSouthernHemisphere;
    final isProtected = productionSystem == ProductionSystem.greenhouse ||
        productionSystem == ProductionSystem.shadeNet;
    final isIrrigated = waterSource == WaterSource.irrigated;
    final isRainFed = waterSource == WaterSource.rainFed;

    // 1. Calculate Planting Windows
    final List<PlantingWindow> allWindows = _calculatePlantingWindows(
      crop: crop,
      location: location,
      productionSystem: productionSystem,
      waterSource: waterSource,
    );

    // Identify primary recommended window
    final recommendedWindow = allWindows.firstWhere(
      (w) => w.windowType == WindowType.main,
      orElse: () => allWindows.first,
    );

    // 2. Determine Variety & Maturity Days
    final activeVariety = variety ??
        (crop.varieties.isNotEmpty ? crop.varieties.first : null);

    final int maturityMin = activeVariety != null
        ? activeVariety.maturityDaysMin
        : crop.standardMaturityDaysMin;
    final int maturityMax = activeVariety != null
        ? activeVariety.maturityDaysMax
        : crop.standardMaturityDaysMax;

    // 3. Calculate Estimated Timeline Milestones
    final List<CropTimelineMilestone> milestones = _generateMilestones(
      crop: crop,
      plantingDate: plantingDate,
      maturityMin: maturityMin,
      maturityMax: maturityMax,
      productionSystem: productionSystem,
    );

    // 4. Calculate Estimated Harvest Dates
    final estimatedHarvestStart =
        plantingDate.add(Duration(days: maturityMin));
    final estimatedHarvestEnd =
        plantingDate.add(Duration(days: maturityMax));
    final DateFormat formatter = DateFormat('d MMMM yyyy');
    final String harvestWindowDisplay =
        '${formatter.format(estimatedHarvestStart)} – ${formatter.format(estimatedHarvestEnd)}';

    // 5. Evaluate Climate Safety & Risk Alerts
    final List<ClimateRiskAlert> riskAlerts = [];
    final plantingMonth = plantingDate.month;

    // Frost risk check
    if (location.frostRiskMonths.contains(plantingMonth) &&
        crop.frostToleranceScore < 0.3 &&
        !isProtected) {
      riskAlerts.add(
        const ClimateRiskAlert(
          title: 'High Frost Risk for Sensitive Crop',
          description:
              'Open field planting during this cool period exposes sensitive vegetative growth to severe frost damage. Consider frost cover, planting in a frost-free microclimate, or delaying until spring.',
          severity: 'danger',
          iconEmoji: '🥶',
        ),
      );
    }

    // Extreme heat during establishment/flowering
    if (location.hotSeasonMonths.contains(plantingMonth) &&
        crop.optimalTempMax < 28.0 &&
        !isProtected) {
      riskAlerts.add(
        ClimateRiskAlert(
          title: 'High Heat Stress / Flower Drop Risk',
          description:
              '${crop.name} is sensitive to sustained temperatures above ${crop.optimalTempMax.toInt()}°C. High heat may cause blossom drop or premature bolting. Shade cloth or frequent light misting is recommended.',
          severity: 'warning',
          iconEmoji: '☀️',
        ),
      );
    }

    // Rain-fed vs Dry season mismatch
    if (isRainFed && !location.wetSeasonMonths.contains(plantingMonth)) {
      riskAlerts.add(
        const ClimateRiskAlert(
          title: 'Rainfall Deficit Warning (Rain-Fed)',
          description:
              'This planting date falls outside the reliable seasonal rainfall period. Planting without supplemental irrigation carries a high risk of crop failure.',
          severity: 'danger',
          iconEmoji: '⚠️',
        ),
      );
    } else if (isRainFed) {
      riskAlerts.add(
        const ClimateRiskAlert(
          title: 'Rainfall Dependency Alert',
          description:
              'This planting period depends heavily on reliable rainfall. Confirm adequate soil moisture profile and check local mid-season dry spell patterns before sowing.',
          severity: 'warning',
          iconEmoji: '🌧️',
        ),
      );
    }

    if (isIrrigated) {
      riskAlerts.add(
        const ClimateRiskAlert(
          title: 'Irrigation Management Note',
          description:
              'Irrigation provides production flexibility, but crop thermal suitability, humidity, and disease pressure must still be monitored.',
          severity: 'info',
          iconEmoji: '💧',
        ),
      );
    }

    // Soil disclaimer
    if (!soilTestAvailable) {
      riskAlerts.add(
        const ClimateRiskAlert(
          title: 'Soil Test Advisory',
          description:
              'Soil conditions were not provided. For accurate fertilizer rates and pH balance, consider obtaining a certified soil laboratory test.',
          severity: 'info',
          iconEmoji: '🧪',
        ),
      );
    }

    // 6. Compute Confidence Rating
    ConfidenceLevel confidence = ConfidenceLevel.high;
    String confidenceExplanation = '';

    final hasDetailedProfile = location.countryCode != 'GEN_SH' &&
        location.countryCode != 'GEN_NH';

    if (hasDetailedProfile && variety != null) {
      confidence = ConfidenceLevel.high;
      confidenceExplanation =
          'High confidence: Recommendation is calculated from calibrated regional agro-ecological zone data, crop temperature thresholds, and specific variety maturity parameters.';
    } else if (hasDetailedProfile) {
      confidence = ConfidenceLevel.moderate;
      confidenceExplanation =
          'Moderate confidence: Recommendation is based on regional agro-ecological data and general crop maturity ranges. Variety-specific timing may vary by ±7–14 days.';
    } else {
      confidence = ConfidenceLevel.low;
      confidenceExplanation =
          'Low confidence: Recommendation is based on general hemisphere climate models. Check local extension advice, seed supplier guides, and current field microclimates before making major planting decisions.';
    }

    // 7. Compile Recommendation Factors ("Why am I seeing this?")
    final List<String> factors = [
      '📍 Location: ${location.displayName} (${location.climateZone})',
      '🌍 Climate & Hemisphere: ${isSouthern ? "Southern Hemisphere" : "Northern Hemisphere"} seasonal cycle',
      '🌡️ Thermal Suitability: Optimal temperature range ${crop.optimalTempMin.toInt()}°C – ${crop.optimalTempMax.toInt()}°C',
      '🌱 Crop & Variety: ${crop.name} (${activeVariety != null ? activeVariety.name : "General maturity range"})',
      '🏗️ Production System: ${_getProductionSystemDisplay(productionSystem)}',
      '💧 Water Availability: ${_getWaterSourceDisplay(waterSource)}',
      '📅 Planned Planting Date: ${DateFormat('d MMMM yyyy').format(plantingDate)}',
    ];

    return CropRecommendationResult(
      crop: crop,
      selectedVariety: activeVariety,
      location: location,
      productionSystem: productionSystem,
      waterSource: waterSource,
      plantingDate: plantingDate,
      recommendedWindow: recommendedWindow,
      allWindows: allWindows,
      confidence: confidence,
      confidenceExplanation: confidenceExplanation,
      recommendationFactors: factors,
      riskAlerts: riskAlerts,
      timelineMilestones: milestones,
      estimatedHarvestStart: estimatedHarvestStart,
      estimatedHarvestEnd: estimatedHarvestEnd,
      harvestWindowDisplay: harvestWindowDisplay,
      dataSources: crop.defaultDataSource,
    );
  }

  // ==========================================
  // 4. PLANTING WINDOW CALCULATOR
  // ==========================================
  List<PlantingWindow> _calculatePlantingWindows({
    required HorticulturalCrop crop,
    required LocationAgroProfile location,
    required ProductionSystem productionSystem,
    required WaterSource waterSource,
  }) {
    final List<PlantingWindow> windows = [];
    final isSouth = location.isSouthernHemisphere;
    final isCoolCrop = crop.optimalTempMax <= 24.0;
    final isWarmCrop = crop.optimalTempMin >= 18.0;
    final hasFrost = location.frostRiskMonths.isNotEmpty;
    final isProtected = productionSystem == ProductionSystem.greenhouse;

    if (isSouth) {
      // Southern Africa (e.g. Zimbabwe, South Africa, Zambia, Malawi)
      if (isWarmCrop && !isProtected) {
        // Warm-loving crops (Tomato, Pepper, Cucumber, Okra, Sweet Corn, Butternut)
        if (hasFrost) {
          windows.add(
            const PlantingWindow(
              startMonth: 8,
              endMonth: 11,
              windowType: WindowType.main,
              label: 'Main Spring / Early Summer Window',
              periodDescription: 'August – November',
              rationale:
                  'Ideal warming soil temperatures post-frost risk, maximizing vegetative growth prior to peak late-summer disease pressure.',
              confidence: ConfidenceLevel.high,
            ),
          );
          windows.add(
            const PlantingWindow(
              startMonth: 12,
              endMonth: 2,
              windowType: WindowType.secondary,
              label: 'Secondary Summer Window',
              periodDescription: 'December – February',
              rationale:
                  'High humidity and heavy rains increase fungal foliar risks. Requires strict preventative fungicide regime.',
              confidence: ConfidenceLevel.moderate,
            ),
          );
          windows.add(
            const PlantingWindow(
              startMonth: 5,
              endMonth: 7,
              windowType: WindowType.restrictedOrRisky,
              label: 'High Frost Risk Period',
              periodDescription: 'May – July',
              rationale:
                  'Sub-zero winter temperatures cause severe tissue freeze in open field plantings.',
              confidence: ConfidenceLevel.high,
            ),
          );
        } else {
          // Lowveld / Frost free (e.g. Chiredzi, Tzaneen, Coastal KZN, Mozambique)
          windows.add(
            const PlantingWindow(
              startMonth: 3,
              endMonth: 6,
              windowType: WindowType.main,
              label: 'Winter Irrigated Prime Window',
              periodDescription: 'March – June',
              rationale:
                  'Frost-free lowveld areas produce the highest quality tomatoes and peppers in dry, sunny winter months under irrigation.',
              confidence: ConfidenceLevel.high,
            ),
          );
          windows.add(
            const PlantingWindow(
              startMonth: 8,
              endMonth: 11,
              windowType: WindowType.secondary,
              label: 'Spring Window',
              periodDescription: 'August – November',
              rationale:
                  'Very hot summer conditions require high irrigation capacity and sunscald management.',
              confidence: ConfidenceLevel.moderate,
            ),
          );
        }
      } else if (isCoolCrop && !isProtected) {
        // Cool crops (Cabbage, Broccoli, Peas, Onion, Carrot, Beetroot, Spinach, Rape)
        windows.add(
          const PlantingWindow(
            startMonth: 2,
            endMonth: 6,
            windowType: WindowType.main,
            label: 'Main Autumn / Winter Window',
            periodDescription: 'February – June',
            rationale:
                'Cool night temperatures suppress brassica insect pests (DBM) and encourage compact heads, sweet root bulking, and disease suppression.',
            confidence: ConfidenceLevel.high,
          ),
        );
        windows.add(
          const PlantingWindow(
            startMonth: 7,
            endMonth: 9,
            windowType: WindowType.secondary,
            label: 'Early Spring Window',
            periodDescription: 'July – September',
            rationale:
                'Fast-maturing varieties perform well before extreme summer heat causes bolting or bitterness.',
            confidence: ConfidenceLevel.moderate,
          ),
        );
      } else {
        // Greenhouse or all-season
        windows.add(
          const PlantingWindow(
            startMonth: 1,
            endMonth: 12,
            windowType: WindowType.main,
            label: 'Year-Round Controlled Window',
            periodDescription: 'January – December (Protected)',
            rationale:
                'Greenhouse climate control buffers against cold snaps and heavy rains, permitting continuous succession planting.',
            confidence: ConfidenceLevel.high,
          ),
        );
      }
    } else {
      // Northern Hemisphere / Equatorial (e.g. Kenya, Nigeria, Ghana)
      if (location.wetSeasonMonths.length > 4 &&
          location.wetSeasonMonths.contains(4) &&
          location.wetSeasonMonths.contains(10)) {
        // Bimodal Equatorial (Kenya, Southern Ghana, SW Nigeria)
        windows.add(
          const PlantingWindow(
            startMonth: 3,
            endMonth: 5,
            windowType: WindowType.main,
            label: 'Long Rains Planting Window',
            periodDescription: 'March – May',
            rationale: 'Primary rainy season offering maximum natural soil moisture.',
            confidence: ConfidenceLevel.high,
          ),
        );
        windows.add(
          const PlantingWindow(
            startMonth: 9,
            endMonth: 11,
            windowType: WindowType.secondary,
            label: 'Short Rains Window',
            periodDescription: 'September – November',
            rationale: 'Secondary rainy season ideal for rapid-cycle horticultural crops.',
            confidence: ConfidenceLevel.high,
          ),
        );
      } else {
        // Standard Northern single wet season (Northern Nigeria, Sahel)
        windows.add(
          const PlantingWindow(
            startMonth: 5,
            endMonth: 7,
            windowType: WindowType.main,
            label: 'Main Wet Season Window',
            periodDescription: 'May – July',
            rationale: 'Summer monsoon rains support open field production.',
            confidence: ConfidenceLevel.moderate,
          ),
        );
        windows.add(
          const PlantingWindow(
            startMonth: 10,
            endMonth: 2,
            windowType: WindowType.secondary,
            label: 'Dry Season Fadama / Irrigated Window',
            periodDescription: 'October – February',
            rationale: 'Cool dry Harmattan months produce premium disease-free vegetable crops under irrigation.',
            confidence: ConfidenceLevel.high,
          ),
        );
      }
    }

    if (windows.isEmpty) {
      windows.add(
        const PlantingWindow(
          startMonth: 8,
          endMonth: 11,
          windowType: WindowType.main,
          label: 'Estimated Regional Window',
          periodDescription: 'August – November',
          rationale: 'General seasonal recommendation.',
          confidence: ConfidenceLevel.moderate,
        ),
      );
    }

    return windows;
  }

  // ==========================================
  // 5. MILESTONE GENERATOR
  // ==========================================
  List<CropTimelineMilestone> _generateMilestones({
    required HorticulturalCrop crop,
    required DateTime plantingDate,
    required int maturityMin,
    required int maturityMax,
    required ProductionSystem productionSystem,
  }) {
    final List<CropTimelineMilestone> milestones = [];
    final DateFormat formatter = DateFormat('d MMM yyyy');

    // If crop has predefined standard stages, scale offsets according to variety maturity
    final double scalingFactor =
        maturityMin / max(1, crop.standardMaturityDaysMin);

    for (final stage in crop.standardStages) {
      final int scaledStart = (stage.startDayOffset * scalingFactor).round();
      final int scaledEnd = (stage.endDayOffset * scalingFactor).round();

      final stageStartDate = plantingDate.add(Duration(days: scaledStart));
      final stageEndDate = plantingDate.add(Duration(days: scaledEnd));

      final now = DateTime.now();
      final isCompleted = stageEndDate.isBefore(now);
      final isCurrent = !isCompleted &&
          (stageStartDate.isBefore(now) ||
              stageStartDate.difference(now).inDays == 0);

      final String dateDisplay = scaledStart == scaledEnd
          ? formatter.format(stageStartDate)
          : '${DateFormat('d MMM').format(stageStartDate)} – ${formatter.format(stageEndDate)}';

      milestones.add(
        CropTimelineMilestone(
          stage: stage,
          estimatedStartDate: stageStartDate,
          estimatedEndDate: stageEndDate,
          dateDisplay: dateDisplay,
          isCurrent: isCurrent,
          isCompleted: isCompleted,
        ),
      );
    }

    return milestones;
  }

  // ==========================================
  // 6. SAVED CROP CALENDARS (FIRESTORE + CACHE)
  // ==========================================
  Future<void> saveCropPlan(SavedCropCalendar plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? plan.userId;

      await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('crop_calendars')
          .doc(plan.id)
          .set(plan.toMap());
      debugPrint('✅ [CROP_CALENDAR] Plan ${plan.id} saved to Firestore');
    } catch (e) {
      debugPrint('⚠️ [CROP_CALENDAR] Error saving to Firestore: $e');
    }
  }

  Stream<List<SavedCropCalendar>> getSavedCropPlans(String userId) {
    return _firestore
        .collection('farmers')
        .doc(userId)
        .collection('crop_calendars')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedCropCalendar.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteCropPlan(String userId, String planId) async {
    try {
      await _firestore
          .collection('farmers')
          .doc(userId)
          .collection('crop_calendars')
          .doc(planId)
          .delete();
    } catch (e) {
      debugPrint('⚠️ [CROP_CALENDAR] Error deleting plan: $e');
    }
  }

  String _getProductionSystemDisplay(ProductionSystem system) {
    switch (system) {
      case ProductionSystem.openField:
        return 'Open Field';
      case ProductionSystem.greenhouse:
        return 'Greenhouse / Poly Tunnel';
      case ProductionSystem.shadeNet:
        return 'Shade Netting';
      case ProductionSystem.containerGarden:
        return 'Container / Home Garden';
      default:
        return 'Standard Field';
    }
  }

  String _getWaterSourceDisplay(WaterSource water) {
    switch (water) {
      case WaterSource.irrigated:
        return 'Full Irrigation';
      case WaterSource.limitedIrrigation:
        return 'Supplementary / Limited Irrigation';
      case WaterSource.rainFed:
        return 'Rain-Fed (Dependent on Rainfall)';
    }
  }
}
