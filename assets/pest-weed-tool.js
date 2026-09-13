// Pest & Weed Control Timing & Chemical Selection Decision Tool - JavaScript Logic
// Field Scouting Calculator, Economic Threshold Checker, and Knapsack Spray Prescription Engine
// Built for farmers with simple English, term explanations, and safety guidance

const sprayState = {
  currentStep: 0,
  totalSteps: 6,
  
  crop: {
    type: 'maize', // maize, tomato, cabbage, onion, potato, beans, wheat
    name: 'Maize / Corn',
    stage: 'vegetative' // seedling, vegetative, flowering, maturity
  },
  
  targetProblem: 'pest', // pest, weed, disease
  
  scouting: {
    totalPlantsScouted: 50,
    infestedPlantsCount: 12, // e.g. plants showing live caterpillars or disease
    infestationPercent: 24,
    weedDensity: 'medium', // low_scattered, medium_active, heavy_choking
    weedStage: 'young_2_to_4_leaves' // young_2_to_4_leaves, mature_flowering, pre_emergence
  },
  
  weatherConditions: {
    windSpeed: 'calm', // calm, breezy, strong_wind
    rainForecast: 'dry_next_6_hours', // rain_within_2_hours, rain_within_4_hours, dry_next_6_hours
    timeOfDay: 'cool_morning_evening', // cool_morning_evening, hot_midday_sun
    soilMoisture: 'moist' // moist, bone_dry, waterlogged
  },
  
  equipment: {
    sprayerType: 'knapsack_15l', // knapsack_15l, knapsack_16l, boom_sprayer
    nozzleType: 'cone', // cone (for insecticides/fungicides), flat_fan (for herbicides)
    hasProtectiveGear: 'yes' // yes, no
  },
  
  results: {
    sprayDecision: 'SPRAY TODAY', // SPRAY TODAY, WAIT & MONITOR, DO NOT SPRAY
    decisionReason: '',
    thresholdStatus: '',
    
    recommendedChemical: {
      tradeName: '',
      activeIngredient: '',
      type: '',
      toxicityBand: 'Green / Blue (Low Toxicity)',
      dosePer15LKnapsack: '',
      phi: '',
      applicationNotes: ''
    },
    
    organicAlternative: '',
    spraySafetyRules: [],
    scoutingSummary: {},
    termsExplained: []
  }
};

const pestWeedDatabase = {
  maize: {
    pest: {
      targetName: 'Fall Armyworm & Stalk Borer',
      economicThreshold: 20, // 20% of plants showing active young larvae
      thresholdText: 'Spray when more than 20% of scouted maize plants (e.g. 10 out of 50) have small live caterpillars in the funnel/whorl.',
      chemical: {
        tradeName: 'Coragen 200 SC or Belt Expert',
        activeIngredient: 'Chlorantraniliprole (200 g/L) or Flubendiamide',
        type: 'Selective Systemic Larvicide (Diamide group)',
        toxicityBand: 'Green Band (Caution — Low toxicity to mammals)',
        dosePer15LKnapsack: '3 to 4 ml per 15L backpack knapsack',
        phi: '14 days',
        applicationNotes: 'Direct the spray nozzle straight down into the leaf funnel (whorl) of each plant. Spray late afternoon when caterpillars come up to feed.'
      },
      organic: 'Place a small pinch of clean dry wood ash or fine sand directly into each plant funnel. Intercrop with desmodium (push-pull method).'
    },
    weed: {
      targetName: 'Annual Grasses & Broadleaf Weeds in Maize',
      thresholdText: 'The critical weed-free period for maize is the first 4 to 6 weeks. Weeds taller than 10cm rob 40% of fertilizer.',
      preEmergenceChemical: {
        tradeName: 'Atrazine 500 SC + S-Metolachlor (e.g. Primagram Gold)',
        activeIngredient: 'Atrazine + S-Metolachlor',
        type: 'Selective Pre-Emergence Soil Herbicide',
        toxicityBand: 'Blue Band (Caution)',
        dosePer15LKnapsack: '150 to 200 ml per 15L water',
        phi: 'N/A (Applied at planting)',
        applicationNotes: 'Spray within 48 hours after planting BEFORE maize and weeds emerge. MUST be sprayed on moist soil for the chemical barrier to activate.'
      },
      postEmergenceChemical: {
        tradeName: 'Nicosulfuron 40 SC (e.g. Accent / Stellar Star)',
        activeIngredient: 'Nicosulfuron (Selective Grass Killer in Maize)',
        type: 'Selective Post-Emergence Herbicide',
        toxicityBand: 'Green Band',
        dosePer15LKnapsack: '40 to 50 ml per 15L water',
        phi: '45 days',
        applicationNotes: 'Spray when maize has 2 to 6 leaves and grass weeds are young (2-3 leaves). Kills grasses without harming maize plants.'
      },
      organic: 'Shallow hoe weeding when weeds are small (2-leaf stage). Never let weeds set seeds.'
    }
  },
  tomato: {
    pest: {
      targetName: 'Tuta Absoluta (Tomato Leafminer) & Red Spider Mite',
      economicThreshold: 10, // 10% infested or 3 active mines per leaf
      thresholdText: 'Spray when more than 10% of plants show fresh translucent leaf mines or when pheromone delta traps catch > 5 moths per day.',
      chemical: {
        tradeName: 'Ampligo 150 ZC or Proclaim 5 SG',
        activeIngredient: 'Chlorantraniliprole + Lambda-cyhalothrin OR Emamectin Benzoate',
        type: 'Translaminar Caterpillar & Leafminer Insecticide',
        toxicityBand: 'Blue Band (Warning)',
        dosePer15LKnapsack: '10 to 12 ml per 15L water',
        phi: '3 days',
        applicationNotes: 'Ensure thorough coverage of both upper and lower leaf surfaces. Add 5ml of an agricultural wetting agent (sticker) to penetrate waxy foliage.'
      },
      organic: 'Install yellow sticky traps (1 trap per 50m²) and pheromone delta traps to capture adult moths.'
    },
    weed: {
      targetName: 'Weeds in Tomato Beds',
      thresholdText: 'Keep tomato beds completely weed-free during early establishment (first 4 weeks after transplanting).',
      postEmergenceChemical: {
        tradeName: 'Metribuzin 70 WP (e.g. Sencor)',
        activeIngredient: 'Metribuzin',
        type: 'Selective Post-Emergence Broadleaf Herbicide for Tomatoes',
        toxicityBand: 'Blue Band',
        dosePer15LKnapsack: '15 to 20 grams per 15L water',
        phi: '30 days',
        applicationNotes: 'Apply ONLY once tomato transplants are well-established with strong root systems (2-3 weeks after transplanting). Do NOT spray on sandy soil during hot sun.'
      },
      organic: 'Apply a 5cm thick layer of clean, dry grass mulch between tomato rows to block weed germination and conserve moisture.'
    }
  },
  cabbage: {
    pest: {
      targetName: 'Diamondback Moth (DBM Caterpillars) & Aphids',
      economicThreshold: 15, // 15% infested
      thresholdText: 'Spray when more than 15% of cabbage plants have small green wriggling caterpillars under leaves or aphids clustered on growing tips.',
      chemical: {
        tradeName: 'Bacillus thuringiensis (Bt - Dipel) or Spinetoram (Radiant)',
        activeIngredient: 'Biological Bt or Spinetoram',
        type: 'Targeted Bio-Insecticide',
        toxicityBand: 'Green Band (Extremely safe to humans and bees)',
        dosePer15LKnapsack: '15 to 20 grams/ml per 15L water + 5ml Sticker',
        phi: '1 day',
        applicationNotes: 'Cabbage leaves have a slippery waxy coat. You MUST add a wetting agent/sticker, otherwise spray droplets roll off onto the ground.'
      },
      organic: 'Intercrop cabbage with pungent garlic or coriander to repel egg-laying moths. Spray botanical neem oil or hot chili-soap spray.'
    },
    weed: {
      targetName: 'Weeds in Brassica Crops',
      thresholdText: 'Weed aggressively before cabbages form a closed canopy.',
      postEmergenceChemical: {
        tradeName: 'Fluazifop-P-Butyl (e.g. Fusilade Forte)',
        activeIngredient: 'Fluazifop-P-Butyl',
        type: 'Selective Grass Killer in Broadleaf Crops',
        toxicityBand: 'Green Band',
        dosePer15LKnapsack: '30 to 40 ml per 15L water',
        phi: '21 days',
        applicationNotes: 'Kills annual and perennial grasses completely without causing any injury to broadleaf cabbage, kale, or rape plants.'
      },
      organic: 'Hand-hoeing between ridges during cool morning hours.'
    }
  },
  onion: {
    pest: {
      targetName: 'Onion Thrips (Thrips tabaci)',
      economicThreshold: 10,
      thresholdText: 'Spray when you count more than 5 to 10 tiny crawling thrips deep in the leaf sheaths/necks of a single onion plant.',
      chemical: {
        tradeName: 'Acetamiprid 20 SP or Delegate 250 WG',
        activeIngredient: 'Acetamiprid or Spinetoram',
        type: 'Systemic / Translaminar Thripicide',
        toxicityBand: 'Blue Band',
        dosePer15LKnapsack: '6 to 8 grams per 15L water + Sticker',
        phi: '7 days',
        applicationNotes: 'Spray with high pressure directing the cone nozzle straight into the tight leaf crotches where thrips hide.'
      },
      organic: 'Overhead sprinkler irrigation in dry weather to disturb and drown thrips in leaf crotches.'
    },
    weed: {
      targetName: 'Broadleaf and Grass Weeds in Onions',
      thresholdText: 'Onions have thin tubular leaves that cast zero shade, allowing weeds to easily overrun the crop.',
      postEmergenceChemical: {
        tradeName: 'Oxyfluorfen 240 EC (e.g. Goal / Gallant)',
        activeIngredient: 'Oxyfluorfen',
        type: 'Selective Post-Emergence Herbicide for Alliums',
        toxicityBand: 'Blue Band',
        dosePer15LKnapsack: '15 to 20 ml per 15L water',
        phi: '30 days',
        applicationNotes: 'Apply ONLY when onions have at least 3 to 4 true leaves and a thick waxy leaf coat. Spray on dry foliage.'
      },
      organic: 'Frequent shallow hand-pulling around onion bulbs to avoid disturbing shallow root networks.'
    }
  },
  beans: {
    pest: {
      targetName: 'Bean Stem Maggot (Bean Fly) & Aphids',
      economicThreshold: 10,
      thresholdText: 'Early seedling protection is critical. Spray if seedling stems show cracking or yellowing at the soil line.',
      chemical: {
        tradeName: 'Dimethoate 40 EC or Imidacloprid 200 SL',
        activeIngredient: 'Dimethoate or Imidacloprid',
        type: 'Systemic Insecticide',
        toxicityBand: 'Blue Band (Warning)',
        dosePer15LKnapsack: '15 to 20 ml per 15L water',
        phi: '14 days',
        applicationNotes: 'Spray during the first 2-3 weeks after germination to protect soft seedling stems from maggot drilling.'
      },
      organic: 'Treat seed with wood ash or neem extract before planting. Hill up soil around bean stems to encourage adventitious root growth.'
    },
    weed: {
      targetName: 'Grass and Broadleaf Weeds in Legumes',
      thresholdText: 'Keep legumes weed-free for the first 30 days until the crop canopy closes.',
      postEmergenceChemical: {
        tradeName: 'Bentazone 480 SL (e.g. Basagran) + Fluazifop',
        activeIngredient: 'Bentazone (Broadleaf) + Fluazifop (Grasses)',
        type: 'Selective Post-Emergence Herbicide for Legumes',
        toxicityBand: 'Green Band',
        dosePer15LKnapsack: '40 to 50 ml per 15L water',
        phi: '30 days',
        applicationNotes: 'Very safe for dry beans, soybeans, and groundnuts. Spray when weeds have 2 to 4 leaves.'
      },
      organic: 'Inter-row cultivation before bean plants start flowering.'
    }
  }
};

function initPestWeedTool() {
  sprayState.currentStep = 0;
  updateStepDisplay();
}

function startPestWeedTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1Crop').classList.remove('hidden');
  sprayState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === sprayState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < sprayState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectCropType(crop) {
  sprayState.crop.type = crop;
  const names = {
    maize: 'Maize / Corn',
    tomato: 'Tomato',
    cabbage: 'Cabbage & Brassicas',
    onion: 'Onion & Garlic',
    beans: 'Beans & Legumes',
    general: 'Other Field Crop'
  };
  sprayState.crop.name = names[crop] || crop;
  
  const buttons = document.querySelectorAll('#cropSelectButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
}

function selectGrowthStage(stage) {
  sprayState.crop.stage = stage;
  const buttons = document.querySelectorAll('#stageButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === stage);
  });
}

function confirmStep1() {
  if (!sprayState.crop.type) selectCropType('maize');
  if (!sprayState.crop.stage) selectGrowthStage('vegetative');
  
  document.getElementById('step1Crop').classList.add('hidden');
  document.getElementById('step2Target').classList.remove('hidden');
  sprayState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectTargetProblem(problem) {
  sprayState.targetProblem = problem;
  const buttons = document.querySelectorAll('#targetProblemButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === problem);
  });
  
  // Show / hide problem-specific scouting inputs in Step 3
  if (problem === 'weed') {
    document.getElementById('pestScoutingGroup').classList.add('hidden');
    document.getElementById('weedScoutingGroup').classList.remove('hidden');
  } else {
    document.getElementById('pestScoutingGroup').classList.remove('hidden');
    document.getElementById('weedScoutingGroup').classList.add('hidden');
  }
}

function confirmStep2() {
  if (!sprayState.targetProblem) selectTargetProblem('pest');
  
  document.getElementById('step2Target').classList.add('hidden');
  document.getElementById('step3Scouting').classList.remove('hidden');
  sprayState.currentStep = 3;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectWeedDensity(density) {
  sprayState.scouting.weedDensity = density;
  const buttons = document.querySelectorAll('#weedDensityButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === density);
  });
}

function selectWeedStage(stage) {
  sprayState.scouting.weedStage = stage;
  const buttons = document.querySelectorAll('#weedStageButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === stage);
  });
}

function confirmStep3() {
  const totalPlants = parseInt(document.getElementById('totalScoutedInput').value) || 50;
  const infestedPlants = parseInt(document.getElementById('infestedCountInput').value) || 0;
  
  sprayState.scouting.totalPlantsScouted = totalPlants;
  sprayState.scouting.infestedPlantsCount = infestedPlants;
  sprayState.scouting.infestationPercent = Math.round((infestedPlants / Math.max(1, totalPlants)) * 100);
  
  document.getElementById('step3Scouting').classList.add('hidden');
  document.getElementById('step4Weather').classList.remove('hidden');
  sprayState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectWind(wind) {
  sprayState.weatherConditions.windSpeed = wind;
  const buttons = document.querySelectorAll('#windButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === wind);
  });
}

function selectRain(rain) {
  sprayState.weatherConditions.rainForecast = rain;
  const buttons = document.querySelectorAll('#rainButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === rain);
  });
}

function selectTimeOfDay(time) {
  sprayState.weatherConditions.timeOfDay = time;
  const buttons = document.querySelectorAll('#timeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === time);
  });
}

function confirmStep4() {
  if (!sprayState.weatherConditions.windSpeed) selectWind('calm');
  if (!sprayState.weatherConditions.rainForecast) selectRain('dry_next_6_hours');
  if (!sprayState.weatherConditions.timeOfDay) selectTimeOfDay('cool_morning_evening');
  
  document.getElementById('step4Weather').classList.add('hidden');
  document.getElementById('step5Equipment').classList.remove('hidden');
  sprayState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectSprayer(sprayer) {
  sprayState.equipment.sprayerType = sprayer;
  const buttons = document.querySelectorAll('#sprayerButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === sprayer);
  });
}

function selectPPE(ppe) {
  sprayState.equipment.hasProtectiveGear = ppe;
  const buttons = document.querySelectorAll('#ppeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === ppe);
  });
}

function confirmStep5() {
  if (!sprayState.equipment.sprayerType) selectSprayer('knapsack_15l');
  if (!sprayState.equipment.hasProtectiveGear) selectPPE('yes');
  
  calculateSprayDecision();
  
  document.getElementById('step5Equipment').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  sprayState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateSprayDecision() {
  const crop = sprayState.crop.type;
  const prob = sprayState.targetProblem;
  const dbCrop = pestWeedDatabase[crop] || pestWeedDatabase.maize;
  
  let sprayDecision = 'SPRAY TODAY';
  let decisionReason = '';
  let thresholdStatus = '';
  let chemicalInfo = null;
  let organicInfo = '';
  
  const wind = sprayState.weatherConditions.windSpeed;
  const rain = sprayState.weatherConditions.rainForecast;
  const time = sprayState.weatherConditions.timeOfDay;
  
  // Weather safety gates
  if (wind === 'strong_wind') {
    sprayDecision = 'DO NOT SPRAY TODAY (HIGH WIND)';
    decisionReason = 'Strong winds cause severe spray drift! The chemical mist will blow off your crop onto weeds, neighboring fields, or into your eyes, wasting 60% of your money. Wait for wind to drop below 10 km/h.';
  } else if (rain === 'rain_within_2_hours') {
    sprayDecision = 'DO NOT SPRAY TODAY (RAIN RISK)';
    decisionReason = 'Rain within 2 hours will wash the chemical off the foliage before it is absorbed (most chemicals need at least 3-4 rain-free hours to stick). Spraying now will waste all your chemical money.';
  } else if (time === 'hot_midday_sun') {
    sprayDecision = 'DO NOT SPRAY IN MIDDAY SUN';
    decisionReason = 'Spraying under scorching midday sun causes rapid chemical evaporation and causes "foliar scorching" (leaf chemical burns). Additionally, honeybees are actively foraging. Postpone spraying to late afternoon (3:30 PM – 6:00 PM).';
  } else {
    // Check economic injury threshold
    if (prob === 'pest') {
      const pData = dbCrop.pest;
      const infPct = sprayState.scouting.infestationPercent;
      const threshold = pData.economicThreshold;
      
      if (infPct >= threshold) {
        sprayDecision = 'SPRAY TODAY (THRESHOLD EXCEEDED)';
        thresholdStatus = `Infestation is ${infPct}% (Above the ${threshold}% economic damage threshold). Pests are causing real financial loss. Action is required now.`;
        decisionReason = `Your field scouting showed ${sprayState.scouting.infestedPlantsCount} out of ${sprayState.scouting.totalPlantsScouted} plants (${infPct}%) are infested with live pests. This has crossed the threshold where chemical treatment pays for itself.`;
        chemicalInfo = pData.chemical;
        organicInfo = pData.organic;
      } else {
        sprayDecision = 'DO NOT SPRAY YET (BELOW THRESHOLD — MONITOR)';
        thresholdStatus = `Infestation is ${infPct}% (Below the ${threshold}% economic threshold). Pests are present, but natural predators and healthy crop vigor can handle them.`;
        decisionReason = `Only ${infPct}% of plants show pests. Spraying broad-spectrum chemicals today will kill your beneficial predator bugs (ladybirds, wasps) and waste money without increasing harvest yields. Re-scout in 3-4 days.`;
        chemicalInfo = pData.chemical;
        organicInfo = pData.organic;
      }
    } else if (prob === 'weed') {
      const wData = dbCrop.weed;
      const stage = sprayState.scouting.weedStage;
      const density = sprayState.scouting.weedDensity;
      
      if (stage === 'pre_emergence') {
        sprayDecision = 'SPRAY PRE-EMERGENCE HERBICIDE TODAY';
        decisionReason = 'Apply on moist soil within 48 hours of planting to form an invisible chemical barrier that kills weed seeds as they germinate.';
        chemicalInfo = wData.preEmergenceChemical || wData.postEmergenceChemical;
      } else if (density === 'heavy_choking' || density === 'medium_active') {
        sprayDecision = 'SPRAY SELECTIVE POST-EMERGENCE HERBICIDE';
        decisionReason = 'Weeds are actively competing for soil nitrogen and moisture. Spray while weeds are young and tender (2 to 4 leaves) for 95% kill rate.';
        chemicalInfo = wData.postEmergenceChemical;
      } else {
        sprayDecision = 'LIGHT MANUAL WEEDING RECOMMENDED (NO SPRAY NEEDED)';
        decisionReason = 'Weed density is low. Hand-hoeing or shallow cultivation is cheaper and avoids putting synthetic chemicals into the soil.';
        chemicalInfo = wData.postEmergenceChemical;
      }
      organicInfo = wData.organic;
    }
  }
  
  sprayState.results = {
    sprayDecision: sprayDecision,
    decisionReason: decisionReason,
    thresholdStatus: thresholdStatus,
    recommendedChemical: chemicalInfo || {
      tradeName: 'Consult Local Agronomist',
      activeIngredient: 'Selective Active Ingredient',
      type: 'Targeted Crop Protection',
      toxicityBand: 'Green / Blue Band',
      dosePer15LKnapsack: 'Follow product label',
      phi: '7-14 days',
      applicationNotes: 'Always follow manufacturer label instructions.'
    },
    organicAlternative: organicInfo,
    scoutingSummary: {
      crop: sprayState.crop.name,
      stage: sprayState.crop.stage,
      problem: sprayState.targetProblem.toUpperCase(),
      infestation: `${sprayState.scouting.infestationPercent}% (${sprayState.scouting.infestedPlantsCount}/${sprayState.scouting.totalPlantsScouted} scouted plants)`
    },
    spraySafetyRules: [
      'Always wear rubber gloves, boots, long sleeves, and a protective face mask when measuring and mixing chemicals.',
      'Never blow clogged spray nozzles with your mouth—use a blade of grass or wash with clean water.',
      'Always triple-rinse empty chemical containers, puncture the bottom so they cannot be reused for food/water, and bury them safely.',
      'Observe the Pre-Harvest Interval (PHI) strictly before picking any crop for eating or selling.'
    ],
    termsExplained: [
      { term: 'Economic Injury Threshold', explanation: 'The pest population level where the cost of crop damage exceeds the cost of buying and spraying chemical medicine. Below this level, spraying loses you money.' },
      { term: 'Pre-Harvest Interval (PHI)', explanation: 'The mandatory number of days you must wait between spraying and harvesting food so chemical residues safely break down.' },
      { term: 'Selective vs Non-Selective Herbicide', explanation: 'A selective herbicide kills only specific weeds (like grasses) without hurting your crop (like maize). A non-selective herbicide (like Glyphosate) kills every green plant it touches.' },
      { term: 'Pre-Emergence vs Post-Emergence', explanation: 'Pre-emergence herbicides are sprayed onto moist soil before weed seeds sprout. Post-emergence herbicides are sprayed onto growing green weed leaves.' },
      { term: 'Translaminar Insecticide', explanation: 'A chemical that absorbs into the leaf and moves from the top surface to the underside to kill hidden leafminers and caterpillars.' },
      { term: 'Wetting Agent / Sticker (Adjuvant)', explanation: 'A safe liquid mixed into spray tanks to make water droplets stick and spread across waxy leaves (especially cabbage and onions) instead of bouncing off.' }
    ]
  };
  
  renderSprayResults();
}

function renderSprayResults() {
  const r = sprayState.results;
  const chem = r.recommendedChemical;
  
  // Status Banner
  const statusEl = document.getElementById('resultStatus');
  if (r.sprayDecision.includes('SPRAY TODAY') || r.sprayDecision.includes('SELECTIVE')) {
    statusEl.className = 'result-status good';
  } else if (r.sprayDecision.includes('DO NOT SPRAY') || r.sprayDecision.includes('HIGH WIND')) {
    statusEl.className = 'result-status danger';
  } else {
    statusEl.className = 'result-status warning';
  }
  statusEl.textContent = `DECISION: ${r.sprayDecision}`;
  
  // Summary Fields
  document.getElementById('summaryCrop').textContent = `${sprayState.crop.name} (${sprayState.crop.stage} stage)`;
  document.getElementById('summaryTarget').textContent = sprayState.targetProblem.toUpperCase();
  document.getElementById('summaryScoutingResult').textContent = r.scoutingSummary.infestation;
  document.getElementById('summaryDecisionVerdict').textContent = r.sprayDecision;
  
  // Decision Explanation
  document.getElementById('decisionExplanationText').innerHTML = `
    <p style="font-size: 1.05rem; line-height: 1.6; margin-bottom: 0.5rem;">${r.decisionReason}</p>
    ${r.thresholdStatus ? `<p style="font-size: 0.95rem; color: var(--field-dark); background: var(--cream); padding: 0.65rem; border-radius: 6px;"><strong>Scouting Threshold Rule:</strong> ${r.thresholdStatus}</p>` : ''}
  `;
  
  // Chemical Prescription Card
  const chemCard = document.getElementById('chemicalPrescriptionCard');
  chemCard.innerHTML = `
    <div style="font-size: 1.15rem; font-weight: 800; color: var(--field); margin-bottom: 0.35rem;">
      ${chem.tradeName}
    </div>
    <div style="font-size: 0.88rem; color: var(--muted); margin-bottom: 0.65rem;">
      <strong>Active Ingredient & Type:</strong> ${chem.activeIngredient} (${chem.type})
    </div>
    <div style="background: var(--tint); padding: 0.85rem; border-radius: 6px; margin-bottom: 0.75rem;">
      <div style="font-size: 1rem; font-weight: 700; color: var(--soil); margin-bottom: 0.25rem;">
        🥄 Knapsack Dosage: ${chem.dosePer15LKnapsack}
      </div>
      <div style="font-size: 0.9rem; margin-bottom: 0.25rem;">
        <strong>Safety Toxicity Band:</strong> ${chem.toxicityBand}
      </div>
      <div style="font-size: 0.9rem; color: var(--soil); font-weight: 700;">
        <strong>Pre-Harvest Interval (Waiting period before picking):</strong> ${chem.phi}
      </div>
    </div>
    <p style="font-size: 0.9rem; color: var(--ink);">
      <strong>Application Best Practice:</strong> ${chem.applicationNotes}
    </p>
  `;
  
  // Organic Alternative Card
  document.getElementById('organicAlternativeCard').innerHTML = `
    <div style="font-weight: 700; color: var(--field); margin-bottom: 0.35rem;">Cultural & Organic Solution (Zero Chemical Cost)</div>
    <p style="font-size: 0.9rem; line-height: 1.5; color: var(--ink);">${r.organicAlternative}</p>
  `;
  
  // Safety Rules
  const safetyUl = document.getElementById('safetyRulesList');
  safetyUl.innerHTML = '';
  r.spraySafetyRules.forEach(rule => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = rule;
    safetyUl.appendChild(li);
  });
  
  // Terms Box
  const termsBox = document.getElementById('termsContainer');
  termsBox.innerHTML = '';
  r.termsExplained.forEach(t => {
    const div = document.createElement('div');
    div.style.marginBottom = '0.75rem';
    div.innerHTML = `<strong style="color: var(--field);">${t.term}:</strong> <span style="font-size: 0.9rem; color: var(--ink);">${t.explanation}</span>`;
    termsBox.appendChild(div);
  });
}

function goBack() {
  if (sprayState.currentStep <= 1) {
    document.getElementById('step1Crop').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    sprayState.currentStep = 0;
  } else if (sprayState.currentStep === 2) {
    document.getElementById('step2Target').classList.add('hidden');
    document.getElementById('step1Crop').classList.remove('hidden');
    sprayState.currentStep = 1;
  } else if (sprayState.currentStep === 3) {
    document.getElementById('step3Scouting').classList.add('hidden');
    document.getElementById('step2Target').classList.remove('hidden');
    sprayState.currentStep = 2;
  } else if (sprayState.currentStep === 4) {
    document.getElementById('step4Weather').classList.add('hidden');
    document.getElementById('step3Scouting').classList.remove('hidden');
    sprayState.currentStep = 3;
  } else if (sprayState.currentStep === 5) {
    document.getElementById('step5Equipment').classList.add('hidden');
    document.getElementById('step4Weather').classList.remove('hidden');
    sprayState.currentStep = 4;
  } else if (sprayState.currentStep === 6) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step5Equipment').classList.remove('hidden');
    sprayState.currentStep = 5;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  sprayState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    crop: sprayState.crop.name,
    target: sprayState.targetProblem,
    decision: sprayState.results.sprayDecision,
    chemical: sprayState.results.recommendedChemical.tradeName
  };
  localStorage.setItem('agribase_last_spray_decision', JSON.stringify(resultData));
  alert('Your field scouting & spray prescription has been saved to your browser!');
}

function downloadResult() {
  const r = sprayState.results;
  const c = sprayState.crop;
  const chem = r.recommendedChemical;
  
  let reportText = `AGRIBASE FIELD SCOUTING & SPRAY DECISION RECORD\n`;
  reportText += `====================================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Crop: ${c.name} (${c.stage} stage)\n`;
  reportText += `Target Problem: ${sprayState.targetProblem.toUpperCase()}\n`;
  reportText += `Field Scouting Infestation: ${r.scoutingSummary.infestation}\n`;
  reportText += `DECISION VERDICT: ${r.sprayDecision}\n\n`;
  reportText += `WHY THIS DECISION:\n${r.decisionReason}\n\n`;
  reportText += `RECOMMENDED CHEMICAL PRESCRIPTION:\n`;
  reportText += `- Product: ${chem.tradeName} (${chem.activeIngredient})\n`;
  reportText += `- Type: ${chem.type}\n`;
  reportText += `- Dosage per 15L Knapsack: ${chem.dosePer15LKnapsack}\n`;
  reportText += `- Pre-Harvest Interval (PHI): ${chem.phi}\n`;
  reportText += `- Instructions: ${chem.applicationNotes}\n\n`;
  reportText += `ORGANIC / NON-CHEMICAL ALTERNATIVE:\n${r.organicAlternative}\n\n`;
  reportText += `SPRAY OPERATOR SAFETY RULES:\n`;
  r.spraySafetyRules.forEach(rule => { reportText += `- ${rule}\n`; });
  reportText += `\n====================================================\n`;
  reportText += `AgriBase Decision Tools — Practical Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `spray-decision-${c.type}-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initPestWeedTool();
});
