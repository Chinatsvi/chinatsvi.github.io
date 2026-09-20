/**
 * AgriBase Crop Calendar Calculation & Recommendation Engine
 * Ported from AgriBase Flutter App (CropCalendarService)
 */

const CropCalendarEngine = {
  // 1. Calculate Planting Windows
  calculatePlantingWindows: function(crop, location, productionSystem, waterSource) {
    const windows = [];
    const isSouth = location.isSouthernHemisphere;
    const isCoolCrop = crop.optimalTempMax <= 24.0;
    const isWarmCrop = crop.optimalTempMin >= 18.0;
    const hasFrost = location.frostRiskMonths && location.frostRiskMonths.length > 0;
    const isProtected = productionSystem === 'greenhouse' || productionSystem === 'shadeNet';

    if (isSouth) {
      if (isWarmCrop && !isProtected) {
        if (hasFrost) {
          windows.push({
            startMonth: 8,
            endMonth: 11,
            windowType: 'main',
            label: 'Main Spring / Early Summer Window',
            periodDescription: 'August – November',
            rationale: 'Ideal warming soil temperatures post-frost risk, maximizing vegetative growth prior to peak late-summer disease pressure.',
            confidence: 'high'
          });
          windows.push({
            startMonth: 12,
            endMonth: 2,
            windowType: 'secondary',
            label: 'Secondary Summer Window',
            periodDescription: 'December – February',
            rationale: 'High humidity and heavy rains increase fungal foliar risks. Requires strict preventative fungicide regime.',
            confidence: 'moderate'
          });
          windows.push({
            startMonth: 5,
            endMonth: 7,
            windowType: 'restrictedOrRisky',
            label: 'High Frost Risk Period',
            periodDescription: 'May – July',
            rationale: 'Sub-zero winter temperatures cause severe tissue freeze in open field plantings.',
            confidence: 'high'
          });
        } else {
          windows.push({
            startMonth: 3,
            endMonth: 6,
            windowType: 'main',
            label: 'Winter Irrigated Prime Window',
            periodDescription: 'March – June',
            rationale: 'Frost-free lowveld areas produce the highest quality tomatoes and peppers in dry, sunny winter months under irrigation.',
            confidence: 'high'
          });
          windows.push({
            startMonth: 8,
            endMonth: 11,
            windowType: 'secondary',
            label: 'Spring Window',
            periodDescription: 'August – November',
            rationale: 'Very hot summer conditions require high irrigation capacity and sunscald management.',
            confidence: 'moderate'
          });
        }
      } else if (isCoolCrop && !isProtected) {
        windows.push({
          startMonth: 2,
          endMonth: 6,
          windowType: 'main',
          label: 'Main Autumn / Winter Window',
          periodDescription: 'February – June',
          rationale: 'Cool night temperatures suppress brassica insect pests (DBM) and encourage compact heads, sweet root bulking, and disease suppression.',
          confidence: 'high'
        });
        windows.push({
          startMonth: 7,
          endMonth: 9,
          windowType: 'secondary',
          label: 'Early Spring Window',
          periodDescription: 'July – September',
          rationale: 'Fast-maturing varieties perform well before extreme summer heat causes bolting or bitterness.',
          confidence: 'moderate'
        });
      } else {
        windows.push({
          startMonth: 1,
          endMonth: 12,
          windowType: 'main',
          label: 'Year-Round Controlled Window',
          periodDescription: 'January – December (Protected)',
          rationale: 'Greenhouse climate control buffers against cold snaps and heavy rains, permitting continuous succession planting.',
          confidence: 'high'
        });
      }
    } else {
      // Equatorial / Northern Hemisphere
      if (location.wetSeasonMonths && location.wetSeasonMonths.length > 4 && location.wetSeasonMonths.includes(4) && location.wetSeasonMonths.includes(10)) {
        windows.push({
          startMonth: 3,
          endMonth: 5,
          windowType: 'main',
          label: 'Long Rains Planting Window',
          periodDescription: 'March – May',
          rationale: 'Primary rainy season offering maximum natural soil moisture.',
          confidence: 'high'
        });
        windows.push({
          startMonth: 9,
          endMonth: 11,
          windowType: 'secondary',
          label: 'Short Rains Window',
          periodDescription: 'September – November',
          rationale: 'Secondary rainy season ideal for rapid-cycle horticultural crops.',
          confidence: 'high'
        });
      } else {
        windows.push({
          startMonth: 5,
          endMonth: 7,
          windowType: 'main',
          label: 'Main Wet Season Window',
          periodDescription: 'May – July',
          rationale: 'Summer monsoon rains support open field production.',
          confidence: 'moderate'
        });
        windows.push({
          startMonth: 10,
          endMonth: 2,
          windowType: 'secondary',
          label: 'Dry Season Fadama / Irrigated Window',
          periodDescription: 'October – February',
          rationale: 'Cool dry Harmattan months produce premium disease-free vegetable crops under irrigation.',
          confidence: 'high'
        });
      }
    }

    if (windows.length === 0) {
      windows.push({
        startMonth: 8,
        endMonth: 11,
        windowType: 'main',
        label: 'Estimated Regional Window',
        periodDescription: 'August – November',
        rationale: 'General seasonal recommendation.',
        confidence: 'moderate'
      });
    }

    return windows;
  },

  // 2. Generate Milestones
  generateMilestones: function(crop, plantingDateObj, maturityMin, maturityMax) {
    const milestones = [];
    const standardMin = Math.max(1, crop.standardMaturityDaysMin);
    const scalingFactor = maturityMin / standardMin;
    const now = new Date();

    (crop.standardStages || []).forEach(stage => {
      const scaledStart = Math.round(stage.startDayOffset * scalingFactor);
      const scaledEnd = Math.round(stage.endDayOffset * scalingFactor);

      const stageStartDate = new Date(plantingDateObj.getTime() + scaledStart * 86400000);
      const stageEndDate = new Date(plantingDateObj.getTime() + scaledEnd * 86400000);

      const isCompleted = stageEndDate < now;
      const isCurrent = !isCompleted && (stageStartDate <= now || Math.abs(stageStartDate - now) < 86400000);

      const formatDate = d => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
      const formatDateShort = d => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });

      const dateDisplay = scaledStart === scaledEnd
        ? formatDate(stageStartDate)
        : `${formatDateShort(stageStartDate)} – ${formatDate(stageEndDate)}`;

      milestones.push({
        stage: stage,
        estimatedStartDate: stageStartDate,
        estimatedEndDate: stageEndDate,
        dateDisplay: dateDisplay,
        isCurrent: isCurrent,
        isCompleted: isCompleted
      });
    });

    return milestones;
  },

  // 3. Evaluate Climate Risk Alerts
  evaluateClimateRisks: function(crop, location, productionSystem, waterSource, plantingDateObj, soilTestAvailable) {
    const alerts = [];
    const plantingMonth = plantingDateObj.getMonth() + 1; // 1-12
    const isProtected = productionSystem === 'greenhouse' || productionSystem === 'shadeNet';
    const isRainFed = waterSource === 'rainFed';
    const isIrrigated = waterSource === 'irrigated';

    // Frost risk
    if (location.frostRiskMonths && location.frostRiskMonths.includes(plantingMonth) && crop.frostToleranceScore < 0.3 && !isProtected) {
      alerts.push({
        title: 'High Frost Risk for Sensitive Crop',
        description: 'Open field planting during this cool period exposes sensitive vegetative growth to severe frost damage. Consider frost cover, planting in a frost-free microclimate, or delaying until spring.',
        severity: 'danger',
        iconEmoji: '🥶'
      });
    }

    // Heat stress
    if (location.hotSeasonMonths && location.hotSeasonMonths.includes(plantingMonth) && crop.optimalTempMax < 28.0 && !isProtected) {
      alerts.push({
        title: 'High Heat Stress / Flower Drop Risk',
        description: `${crop.name} is sensitive to sustained temperatures above ${Math.round(crop.optimalTempMax)}°C. High heat may cause blossom drop or premature bolting. Shade cloth or frequent light misting is recommended.`,
        severity: 'warning',
        iconEmoji: '☀️'
      });
    }

    // Rainfall deficit
    if (isRainFed && location.wetSeasonMonths && !location.wetSeasonMonths.includes(plantingMonth)) {
      alerts.push({
        title: 'Rainfall Deficit Warning (Rain-Fed)',
        description: 'This planting date falls outside the reliable seasonal rainfall period. Planting without supplemental irrigation carries a high risk of crop failure.',
        severity: 'danger',
        iconEmoji: '⚠️'
      });
    } else if (isRainFed) {
      alerts.push({
        title: 'Rainfall Dependency Alert',
        description: 'This planting period depends heavily on reliable rainfall. Confirm adequate soil moisture profile and check local mid-season dry spell patterns before sowing.',
        severity: 'warning',
        iconEmoji: '🌧️'
      });
    }

    if (isIrrigated) {
      alerts.push({
        title: 'Irrigation Management Note',
        description: 'Irrigation provides production flexibility, but crop thermal suitability, humidity, and disease pressure must still be monitored.',
        severity: 'info',
        iconEmoji: '💧'
      });
    }

    if (!soilTestAvailable) {
      alerts.push({
        title: 'Soil Test Advisory',
        description: 'Soil conditions were not provided. For accurate fertilizer rates and pH balance, consider obtaining a certified soil laboratory test.',
        severity: 'info',
        iconEmoji: '🧪'
      });
    }

    return alerts;
  },

  // 4. Multi-Factor Recommendation Engine
  generateRecommendation: function(params) {
    const crop = params.crop;
    const variety = params.variety || (crop.varieties && crop.varieties.length > 0 ? crop.varieties[0] : null);
    const location = params.location;
    const productionSystem = params.productionSystem || 'openField';
    const waterSource = params.waterSource || 'irrigated';
    const plantingDateObj = params.plantingDate instanceof Date ? params.plantingDate : new Date(params.plantingDate);
    const soilTestAvailable = !!params.soilTestAvailable;

    // 1. Planting Windows
    const allWindows = this.calculatePlantingWindows(crop, location, productionSystem, waterSource);
    const recommendedWindow = allWindows.find(w => w.windowType === 'main') || allWindows[0];

    // 2. Maturity Days
    const maturityMin = variety ? variety.maturityDaysMin : crop.standardMaturityDaysMin;
    const maturityMax = variety ? variety.maturityDaysMax : crop.standardMaturityDaysMax;

    // 3. Milestones
    const milestones = this.generateMilestones(crop, plantingDateObj, maturityMin, maturityMax);

    // 4. Harvest Dates
    const harvestStart = new Date(plantingDateObj.getTime() + maturityMin * 86400000);
    const harvestEnd = new Date(plantingDateObj.getTime() + maturityMax * 86400000);

    const formatDate = d => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
    const harvestWindowDisplay = `${formatDate(harvestStart)} – ${formatDate(harvestEnd)}`;

    // 5. Risk Alerts
    const riskAlerts = this.evaluateClimateRisks(crop, location, productionSystem, waterSource, plantingDateObj, soilTestAvailable);

    // 6. Confidence Level
    let confidence = 'high';
    let confidenceExplanation = '';
    const hasDetailedProfile = location.countryCode !== 'GEN_SH' && location.countryCode !== 'GEN_NH';

    if (hasDetailedProfile && variety) {
      confidence = 'high';
      confidenceExplanation = 'High confidence: Recommendation is calculated from calibrated regional agro-ecological zone data, crop temperature thresholds, and specific variety maturity parameters.';
    } else if (hasDetailedProfile) {
      confidence = 'moderate';
      confidenceExplanation = 'Moderate confidence: Recommendation is based on regional agro-ecological data and general crop maturity ranges. Variety-specific timing may vary by ±7–14 days.';
    } else {
      confidence = 'low';
      confidenceExplanation = 'Low confidence: Recommendation is based on general hemisphere climate models. Check local extension advice, seed supplier guides, and current field microclimates before making major planting decisions.';
    }

    // 7. Factors
    const factors = [
      `📍 Location: ${location.district || location.region}, ${location.country} (${location.climateZone})`,
      `🌍 Climate & Hemisphere: ${location.isSouthernHemisphere ? 'Southern Hemisphere' : 'Northern Hemisphere'} seasonal cycle`,
      `🌡️ Thermal Suitability: Optimal temperature range ${Math.round(crop.optimalTempMin)}°C – ${Math.round(crop.optimalTempMax)}°C`,
      `🌱 Crop & Variety: ${crop.name} (${variety ? variety.name : 'General maturity range'})`,
      `🏗️ Production System: ${productionSystem === 'greenhouse' ? 'Greenhouse / Poly Tunnel' : productionSystem === 'shadeNet' ? 'Shade Netting' : 'Open Field'}`,
      `💧 Water Availability: ${waterSource === 'irrigated' ? 'Full Irrigation' : waterSource === 'rainFed' ? 'Rain-Fed' : 'Limited Irrigation'}`,
      `📅 Planned Planting Date: ${formatDate(plantingDateObj)}`
    ];

    return {
      crop: crop,
      selectedVariety: variety,
      location: location,
      productionSystem: productionSystem,
      waterSource: waterSource,
      plantingDate: plantingDateObj,
      recommendedWindow: recommendedWindow,
      allWindows: allWindows,
      confidence: confidence,
      confidenceExplanation: confidenceExplanation,
      recommendationFactors: factors,
      riskAlerts: riskAlerts,
      timelineMilestones: milestones,
      estimatedHarvestStart: harvestStart,
      estimatedHarvestEnd: harvestEnd,
      harvestWindowDisplay: harvestWindowDisplay,
      dataSources: crop.defaultDataSource
    };
  },

  // Local Storage Saved Plans
  getSavedCropPlans: function() {
    try {
      const data = localStorage.getItem('agribase_saved_crop_plans');
      return data ? JSON.parse(data) : [];
    } catch (e) {
      return [];
    }
  },

  saveCropPlan: function(plan) {
    try {
      const plans = this.getSavedCropPlans();
      const existingIndex = plans.findIndex(p => p.id === plan.id);
      if (existingIndex >= 0) {
        plans[existingIndex] = plan;
      } else {
        plans.unshift(plan);
      }
      localStorage.setItem('agribase_saved_crop_plans', JSON.stringify(plans));
      return true;
    } catch (e) {
      console.error('Error saving plan to localStorage:', e);
      return false;
    }
  },

  deleteSavedCropPlan: function(planId) {
    try {
      const plans = this.getSavedCropPlans().filter(p => p.id !== planId);
      localStorage.setItem('agribase_saved_crop_plans', JSON.stringify(plans));
      return true;
    } catch (e) {
      return false;
    }
  }
};

if (typeof window !== 'undefined') {
  window.CropCalendarEngine = CropCalendarEngine;
}
