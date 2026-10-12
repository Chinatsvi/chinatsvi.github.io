// Soil Needs & Fertilizer Decision Tool - JavaScript Logic
// Calculates soil health, pH adjustments (liming), and exact N-P-K fertilizer schedules
// Supports both formal laboratory test inputs and field observation mode

const soilState = {
  currentStep: 0,
  totalSteps: 6,
  
  farm: {
    area: 1,
    unit: 'hectares', // hectares, acres, sqm
    areaInHa: 1
  },
  
  crop: {
    type: 'maize',
    name: 'Maize / Corn',
    targetYield: 'medium' // low, medium, high
  },
  
  hasLabTest: false,
  
  // Lab test inputs
  labTest: {
    ph: 5.8,
    nitrogen: 'medium', // low, medium, high
    phosphorus: 'medium',
    potassium: 'medium',
    organicMatter: 2.0 // %
  },
  
  // Field observation inputs (no lab test)
  fieldObs: {
    texture: 'sandy_loam', // sand, sandy_loam, loam, clay
    color: 'red_brown', // dark_black, red_brown, pale_sand
    drainage: 'normal', // fast, normal, waterlogged
    previousCrop: 'maize', // legume, cereal, vegetable, fallow
    manureHistory: 'none', // recent, old, none
    observedIssues: [] // crusting, yellowing, acid_weeds, stunted
  },
  
  budgetApproach: 'standard', // standard, organic_only, low_cost_split
  
  results: {
    phStatus: '',
    phDescription: '',
    limeRequiredKgHa: 0,
    limeTotalBags50kg: 0,
    limeType: 'Agricultural Lime (Calcitic or Dolomitic)',
    
    basalFertilizerName: '',
    basalKgHa: 0,
    basalTotalBags50kg: 0,
    basalTiming: '',
    
    topDressFertilizerName: '',
    topDressKgHa: 0,
    topDressTotalBags50kg: 0,
    topDressTiming: '',
    topDressSplits: [],
    
    organicOption: {
      type: '',
      rateTonsHa: 0,
      totalLoads: 0,
      instructions: ''
    },
    
    soilHealthScore: 70, // 0 - 100
    keyWarnings: [],
    actionPlan: [],
    termsExplained: []
  }
};

// Crop Nutrient Requirement Database (kg of N, P2O5, K2O per hectare for standard target yields)
const cropNutrientDatabase = {
  maize: {
    name: 'Maize / Corn',
    idealPhMin: 5.8,
    idealPhMax: 6.8,
    nutrientNeeds: { N: 120, P: 50, K: 40 }, // kg/ha
    recommendedBasal: 'Compound D (NPK 7-14-7) or NPK 10-20-10',
    recommendedTopDress: 'Ammonium Nitrate (34.5% N) or Urea (46% N)',
    basalRateKgHa: 300,
    topDressRateKgHa: 200,
    topDressSchedule: [
      'Split 1 (50%): When maize is knee-high (4-5 weeks after emergence).',
      'Split 2 (50%): Just before tasseling / flowering (7-8 weeks after emergence).'
    ],
    info: 'Maize is a heavy nitrogen feeder. Acidic soil (pH < 5.5) severely restricts root phosphorus uptake.'
  },
  tomato: {
    name: 'Tomato',
    idealPhMin: 6.0,
    idealPhMax: 6.8,
    nutrientNeeds: { N: 140, P: 80, K: 160 },
    recommendedBasal: 'Compound S / NPK 7-21-7 + 0.04% B or NPK 6-18-15',
    recommendedTopDress: 'Calcium Nitrate (early) + Potassium Nitrate / AN (fruiting)',
    basalRateKgHa: 400,
    topDressRateKgHa: 250,
    topDressSchedule: [
      'Split 1 (30%): 2 weeks after transplanting (Calcium Nitrate for strong roots).',
      'Split 2 (35%): At first flowering / fruit set.',
      'Split 3 (35%): During peak fruit swelling (high Potassium for fruit firmness and weight).'
    ],
    info: 'Tomatoes need high potassium and calcium. Uneven watering and low calcium trigger Blossom End Rot.'
  },
  cabbage: {
    name: 'Cabbage / Brassicas',
    idealPhMin: 6.2,
    idealPhMax: 7.2,
    nutrientNeeds: { N: 150, P: 60, K: 100 },
    recommendedBasal: 'Compound C (NPK 5-15-12) or NPK 7-14-7',
    recommendedTopDress: 'Ammonium Nitrate (AN) or Calcium Ammonium Nitrate (CAN)',
    basalRateKgHa: 350,
    topDressRateKgHa: 250,
    topDressSchedule: [
      'Split 1 (50%): 3 weeks after transplanting.',
      'Split 2 (50%): When cabbage heads begin cupping and folding in (6-7 weeks).'
    ],
    info: 'Cabbage prefers slightly sweeter soil (pH > 6.2). Acid soils trigger Clubroot disease.'
  },
  potato: {
    name: 'Irish Potato',
    idealPhMin: 5.2,
    idealPhMax: 6.2,
    nutrientNeeds: { N: 120, P: 100, K: 180 },
    recommendedBasal: 'Compound C (NPK 5-15-12) or NPK 10-20-20',
    recommendedTopDress: 'Ammonium Nitrate + Potassium Sulfate (SOP)',
    basalRateKgHa: 600,
    topDressRateKgHa: 200,
    topDressSchedule: [
      'Apply 70% of total fertilizer at planting in deep furrows below seed pieces.',
      'Top-dress remaining nitrogen at first ridging (hilling up) when plants are 15-20cm tall.'
    ],
    info: 'Potatoes tolerate slightly acidic soil (pH 5.2-5.8), which also suppresses potato scab disease.'
  },
  onion: {
    name: 'Onion / Garlic',
    idealPhMin: 6.0,
    idealPhMax: 7.0,
    nutrientNeeds: { N: 100, P: 60, K: 120 },
    recommendedBasal: 'Compound C (NPK 5-15-12) or NPK 7-14-7',
    recommendedTopDress: 'Ammonium Nitrate or CAN',
    basalRateKgHa: 350,
    topDressRateKgHa: 150,
    topDressSchedule: [
      'Split 1 (50%): 3 weeks after transplanting.',
      'Split 2 (50%): 6 weeks after transplanting. STOP all nitrogen 4 weeks before harvest so bulbs cure properly.'
    ],
    info: 'Onions have shallow root systems and need well-rotted organic matter and phosphorus near the top 10cm.'
  },
  beans: {
    name: 'Beans / Soybeans / Legumes',
    idealPhMin: 5.8,
    idealPhMax: 6.8,
    nutrientNeeds: { N: 20, P: 60, K: 40 },
    recommendedBasal: 'Single Superphosphate (SSP) or Compound D (low N, high P)',
    recommendedTopDress: 'Usually none required (or light booster if nodules fail)',
    basalRateKgHa: 200,
    topDressRateKgHa: 0,
    topDressSchedule: [
      'Apply high phosphorus basal at planting. Legumes make their own nitrogen from the air using root nodules.'
    ],
    info: 'Legumes fix nitrogen naturally. Applying heavy nitrogen fertilizers will make leaves grow but reduce pod yield.'
  },
  wheat: {
    name: 'Wheat / Barley',
    idealPhMin: 6.0,
    idealPhMax: 7.0,
    nutrientNeeds: { N: 110, P: 50, K: 40 },
    recommendedBasal: 'Compound D (NPK 7-14-7) or NPK 10-20-10',
    recommendedTopDress: 'Ammonium Nitrate (34.5% N) or Urea',
    basalRateKgHa: 300,
    topDressRateKgHa: 200,
    topDressSchedule: [
      'Split 1 (50%): At tillering (3-4 weeks after germination).',
      'Split 2 (50%): At stem elongation / piping stage before heading.'
    ],
    info: 'Wheat requires good soil structure and balanced phosphorus for strong tillering.'
  }
};

function initSoilTool() {
  soilState.currentStep = 0;
  updateStepDisplay();
}

function startSoilTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1AreaCrop').classList.remove('hidden');
  soilState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === soilState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < soilState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectCrop(crop) {
  soilState.crop.type = crop;
  const db = cropNutrientDatabase[crop] || cropNutrientDatabase.maize;
  soilState.crop.name = db.name;
  
  const buttons = document.querySelectorAll('#cropSelectButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
}

function confirmStep1() {
  const areaInput = parseFloat(document.getElementById('farmAreaInput').value);
  const unitSelect = document.getElementById('areaUnitSelect').value;
  
  if (isNaN(areaInput) || areaInput <= 0) {
    alert('Please enter a valid farm area number (e.g. 1, 0.5, or 2).');
    return;
  }
  
  soilState.farm.area = areaInput;
  soilState.farm.unit = unitSelect;
  
  // Normalize area to hectares
  if (unitSelect === 'hectares') {
    soilState.farm.areaInHa = areaInput;
  } else if (unitSelect === 'acres') {
    soilState.farm.areaInHa = areaInput * 0.4047;
  } else if (unitSelect === 'sqm') {
    soilState.farm.areaInHa = areaInput / 10000;
  }
  
  if (!soilState.crop.type) {
    selectCrop('maize');
  }
  
  document.getElementById('step1AreaCrop').classList.add('hidden');
  document.getElementById('step2TestChoice').classList.remove('hidden');
  soilState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectTestMode(mode) {
  soilState.hasLabTest = (mode === 'lab');
  
  const buttons = document.querySelectorAll('#testModeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === mode);
  });
  
  if (soilState.hasLabTest) {
    document.getElementById('step2TestChoice').classList.add('hidden');
    document.getElementById('step3LabInputs').classList.remove('hidden');
    soilState.currentStep = 3;
  } else {
    document.getElementById('step2TestChoice').classList.add('hidden');
    document.getElementById('step3FieldObs').classList.remove('hidden');
    soilState.currentStep = 3;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Step 3 Lab Test Confirm
function confirmStep3Lab() {
  const phVal = parseFloat(document.getElementById('labPhInput').value);
  if (isNaN(phVal) || phVal < 3.5 || phVal > 9.5) {
    alert('Please enter a realistic soil pH number between 4.0 and 8.5 (e.g. 5.5).');
    return;
  }
  
  soilState.labTest.ph = phVal;
  soilState.labTest.nitrogen = document.getElementById('labNSelect').value;
  soilState.labTest.phosphorus = document.getElementById('labPSelect').value;
  soilState.labTest.potassium = document.getElementById('labKSelect').value;
  soilState.labTest.organicMatter = parseFloat(document.getElementById('labOMInput').value) || 2.0;
  
  goToStep4History();
}

// Step 3 Field Observation Choice
function selectSoilTexture(texture) {
  soilState.fieldObs.texture = texture;
  const buttons = document.querySelectorAll('#textureButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === texture);
  });
}

function selectSoilColor(color) {
  soilState.fieldObs.color = color;
  const buttons = document.querySelectorAll('#colorButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === color);
  });
}

function confirmStep3Field() {
  if (!soilState.fieldObs.texture) {
    alert('Please select your soil texture (how it feels in your hands).');
    return;
  }
  if (!soilState.fieldObs.color) {
    alert('Please select your soil color.');
    return;
  }
  
  goToStep4History();
}

function goToStep4History() {
  document.getElementById('step3LabInputs').classList.add('hidden');
  document.getElementById('step3FieldObs').classList.add('hidden');
  document.getElementById('step4History').classList.remove('hidden');
  soilState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectPreviousCrop(crop) {
  soilState.fieldObs.previousCrop = crop;
  const buttons = document.querySelectorAll('#prevCropButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
}

function selectManureHistory(manure) {
  soilState.fieldObs.manureHistory = manure;
  const buttons = document.querySelectorAll('#manureHistoryButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === manure);
  });
}

function confirmStep4() {
  if (!soilState.fieldObs.previousCrop) {
    alert('Please select what was planted in this field last season.');
    return;
  }
  if (!soilState.fieldObs.manureHistory) {
    alert('Please tell us if you added animal manure or compost recently.');
    return;
  }
  
  document.getElementById('step4History').classList.add('hidden');
  document.getElementById('step5Approach').classList.remove('hidden');
  soilState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectApproach(approach) {
  soilState.budgetApproach = approach;
  const buttons = document.querySelectorAll('#approachButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === approach);
  });
}

function confirmStep5() {
  calculateSoilNeeds();
  
  document.getElementById('step5Approach').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  soilState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateSoilNeeds() {
  const cropData = cropNutrientDatabase[soilState.crop.type] || cropNutrientDatabase.maize;
  const ha = soilState.farm.areaInHa;
  let estimatedPh = 5.8;
  let soilTexture = 'sandy_loam';
  
  if (soilState.hasLabTest) {
    estimatedPh = soilState.labTest.ph;
  } else {
    // Estimate pH based on texture, color, and field cues
    soilTexture = soilState.fieldObs.texture;
    if (soilTexture === 'sand' && soilState.fieldObs.color === 'pale_sand') {
      estimatedPh = 5.0; // Very prone to high acidity and nutrient leaching
    } else if (soilTexture === 'clay') {
      estimatedPh = 6.2;
    } else {
      estimatedPh = 5.6;
    }
  }
  
  // Liming Calculations
  let limeKgHa = 0;
  let phStatus = 'IDEAL';
  let phDescription = '';
  
  if (estimatedPh < 5.0) {
    phStatus = 'SEVERELY ACIDIC (SOUR SOIL)';
    phDescription = `Your soil pH of ${estimatedPh.toFixed(1)} is critically acidic. In sour soil, phosphorus and nitrogen get locked up and roots cannot absorb them. Crop yields will drop by 40-70% even if you apply expensive chemical fertilizer.`;
    limeKgHa = soilTexture === 'sand' ? 1200 : (soilTexture === 'clay' ? 2500 : 1800);
  } else if (estimatedPh < 5.8) {
    phStatus = 'MODERATELY ACIDIC';
    phDescription = `Your soil pH of ${estimatedPh.toFixed(1)} is below the ideal range (${cropData.idealPhMin} - ${cropData.idealPhMax}) for ${cropData.name}. Applying agricultural lime will release trapped plant nutrients.`;
    limeKgHa = soilTexture === 'sand' ? 600 : (soilTexture === 'clay' ? 1400 : 1000);
  } else if (estimatedPh <= 7.0) {
    phStatus = 'EXCELLENT (SWEET / BALANCED SOIL)';
    phDescription = `Your soil pH of ${estimatedPh.toFixed(1)} is in the prime sweet spot for ${cropData.name}. Plant roots can easily absorb all fertilizers and natural soil minerals. No lime is needed this season!`;
    limeKgHa = 0;
  } else {
    phStatus = 'ALKALINE (SWEET / CALCAREOUS)';
    phDescription = `Your soil pH of ${estimatedPh.toFixed(1)} is high/alkaline. Do not apply lime. Use ammonium-based fertilizers and organic compost to gently buffer soil.`;
    limeKgHa = 0;
  }
  
  const totalLimeKg = limeKgHa * ha;
  const limeBags = Math.ceil(totalLimeKg / 50);
  
  // Fertilizer Calculations
  let basalKgHa = cropData.basalRateKgHa;
  let topDressKgHa = cropData.topDressRateKgHa;
  
  // Adjust based on previous legume or manure history
  if (soilState.fieldObs.previousCrop === 'legume') {
    topDressKgHa = Math.max(0, topDressKgHa - 40); // 40kg nitrogen credit from legumes
  }
  if (soilState.fieldObs.manureHistory === 'recent') {
    basalKgHa = Math.max(100, basalKgHa - 100);
    topDressKgHa = Math.max(50, topDressKgHa - 50);
  }
  
  if (soilState.budgetApproach === 'organic_only') {
    basalKgHa = 0;
    topDressKgHa = 0;
  }
  
  const totalBasalKg = basalKgHa * ha;
  const basalBags = Math.ceil(totalBasalKg / 50);
  
  const totalTopDressKg = topDressKgHa * ha;
  const topDressBags = Math.ceil(totalTopDressKg / 50);
  
  // Organic Manure Recommendation
  const manureTonsHa = 10;
  const totalManureTons = (manureTonsHa * ha).toFixed(1);
  const wheelbarrows = Math.round(totalManureTons * 20); // ~50kg per full wheelbarrow
  
  soilState.results = {
    phStatus: phStatus,
    phDescription: phDescription,
    limeRequiredKgHa: limeKgHa,
    limeTotalBags50kg: limeBags,
    limeType: 'Agricultural Lime (Dolomitic if magnesium is low, Calcitic otherwise)',
    
    basalFertilizerName: cropData.recommendedBasal,
    basalKgHa: basalKgHa,
    basalTotalBags50kg: basalBags,
    basalTiming: 'Apply at planting time, placed 5cm below and 5cm to the side of seeds/seedlings.',
    
    topDressFertilizerName: cropData.recommendedTopDress,
    topDressKgHa: topDressKgHa,
    topDressTotalBags50kg: topDressBags,
    topDressTiming: 'Apply when soil is moist in split applications.',
    topDressSplits: cropData.topDressSchedule,
    
    organicOption: {
      type: 'Well-cured cattle/poultry manure or mature compost',
      rateTonsHa: manureTonsHa,
      totalTons: totalManureTons,
      wheelbarrows: wheelbarrows,
      instructions: 'Broadcast evenly and incorporate into the top 15cm of soil 2-4 weeks before planting.'
    },
    
    termsExplained: [
      { term: 'Soil pH', explanation: 'A measure of whether your soil is sour (acidic), sweet (alkaline), or balanced (neutral). 6.0 - 6.8 is the sweet spot where crops grow best.' },
      { term: 'Agricultural Lime', explanation: 'Crushed natural limestone rock that neutralizes sour soil acids and adds essential Calcium and Magnesium.' },
      { term: 'Basal Fertilizer', explanation: 'Fertilizer applied at or before planting to feed early root and shoot growth (high in Phosphorus).' },
      { term: 'Top-Dressing', explanation: 'Nitrogen-rich fertilizer spread around growing crops after emergence to fuel leafy green growth.' },
      { term: 'Nutrient Lockup', explanation: 'When plant food is trapped in the soil because the wrong pH prevents roots from drinking it in.' },
      { term: 'Leaching', explanation: 'When heavy rain washes plant nutrients down deep into sandy soil where plant roots cannot reach them.' }
    ]
  };
  
  renderSoilResults();
}

function renderSoilResults() {
  const r = soilState.results;
  const ha = soilState.farm.areaInHa;
  const areaText = `${soilState.farm.area} ${soilState.farm.unit} (${ha.toFixed(2)} Ha)`;
  
  // Status Header
  const statusEl = document.getElementById('resultStatus');
  if (r.phStatus.includes('SEVERELY')) {
    statusEl.className = 'result-status danger';
  } else if (r.phStatus.includes('MODERATELY')) {
    statusEl.className = 'result-status warning';
  } else {
    statusEl.className = 'result-status good';
  }
  statusEl.textContent = `SOIL HEALTH: ${r.phStatus}`;
  
  // Summary
  document.getElementById('summaryCrop').textContent = soilState.crop.name;
  document.getElementById('summaryArea').textContent = areaText;
  document.getElementById('summaryPhStatus').textContent = r.phStatus;
  document.getElementById('summaryLimeNeeds').textContent = r.limeTotalBags50kg > 0 ? `${r.limeTotalBags50kg} Bags (50kg)` : 'Zero (Not needed)';
  document.getElementById('summaryBasalNeeds').textContent = r.basalTotalBags50kg > 0 ? `${r.basalTotalBags50kg} Bags (${r.basalFertilizerName})` : 'Zero (Organic approach)';
  document.getElementById('summaryTopDressNeeds').textContent = r.topDressTotalBags50kg > 0 ? `${r.topDressTotalBags50kg} Bags (${r.topDressFertilizerName})` : 'Zero (Organic approach)';
  
  // Soil pH Description
  document.getElementById('phExplanationText').textContent = r.phDescription;
  
  // Liming Card
  const limeCard = document.getElementById('limeRecommendationCard');
  if (r.limeTotalBags50kg > 0) {
    limeCard.innerHTML = `
      <div style="font-size: 1.15rem; font-weight: 700; color: var(--soil); margin-bottom: 0.5rem;">
        Apply ${r.limeTotalBags50kg} bags (50kg each) of Agricultural Lime
      </div>
      <p style="font-size: 0.95rem; line-height: 1.6; margin-bottom: 0.5rem;">
        <strong>Application Rate:</strong> ${(r.limeRequiredKgHa / 1000).toFixed(1)} tons/ha (${r.limeRequiredKgHa} kg/ha).
      </p>
      <p style="font-size: 0.9rem; color: var(--ink); background: var(--cream); padding: 0.75rem; border-radius: 6px;">
        <strong>How to apply lime:</strong> Broadcast lime evenly across the dry field 4 to 6 weeks before planting. Plow or disc it 15-20cm deep so it mixes thoroughly with the root zone. Lime needs moisture and time to react with soil acids.
      </p>
    `;
  } else {
    limeCard.innerHTML = `
      <div style="font-size: 1.05rem; font-weight: 700; color: var(--field);">No Lime Required This Season!</div>
      <p style="font-size: 0.9rem; color: var(--muted); margin-top: 0.25rem;">Your soil pH is already favorable. Adding lime when not needed can push pH too high and lock up iron and zinc.</p>
    `;
  }
  
  // Fertilizer Prescription Cards
  const basalCard = document.getElementById('basalRecommendationCard');
  if (r.basalTotalBags50kg > 0) {
    basalCard.innerHTML = `
      <div style="font-size: 1.15rem; font-weight: 700; color: var(--field); margin-bottom: 0.5rem;">
        Basal Fertilizer: ${r.basalTotalBags50kg} Bags (50kg) of ${r.basalFertilizerName}
      </div>
      <p style="font-size: 0.95rem; line-height: 1.5; margin-bottom: 0.4rem;">
        <strong>Rate per Hectare:</strong> ${r.basalKgHa} kg/ha (approx. ${(r.basalKgHa / 20).toFixed(1)} bags per hectare).
      </p>
      <div style="font-size: 0.88rem; color: var(--ink); background: var(--tint); padding: 0.65rem; border-radius: 6px;">
        <strong>How & When:</strong> ${r.basalTiming} Never let raw fertilizer touch bare seeds directly.
      </div>
    `;
  } else {
    basalCard.innerHTML = '<p style="font-size: 0.95rem; color: var(--muted);">Organic / low-cost pathway selected. See organic manure prescription below.</p>';
  }
  
  const topDressCard = document.getElementById('topDressRecommendationCard');
  if (r.topDressTotalBags50kg > 0) {
    let splitsHtml = '<ul style="margin: 0.5rem 0 0 1.25rem; font-size: 0.9rem; line-height: 1.6;">';
    r.topDressSplits.forEach(s => {
      splitsHtml += `<li>${s}</li>`;
    });
    splitsHtml += '</ul>';
    
    topDressCard.innerHTML = `
      <div style="font-size: 1.15rem; font-weight: 700; color: var(--field); margin-bottom: 0.5rem;">
        Top-Dressing: ${r.topDressTotalBags50kg} Bags (50kg) of ${r.topDressFertilizerName}
      </div>
      <p style="font-size: 0.95rem; line-height: 1.5; margin-bottom: 0.4rem;">
        <strong>Rate per Hectare:</strong> ${r.topDressKgHa} kg/ha.
      </p>
      <div style="font-size: 0.88rem; color: var(--ink); background: var(--tint); padding: 0.65rem; border-radius: 6px;">
        <strong>Split Application Schedule:</strong>
        ${splitsHtml}
      </div>
    `;
  } else {
    topDressCard.innerHTML = '<p style="font-size: 0.95rem; color: var(--muted);">Zero synthetic top-dressing required under your current organic/legume plan.</p>';
  }
  
  // Organic Manure Prescription
  document.getElementById('organicRecommendationCard').innerHTML = `
    <div style="font-size: 1.05rem; font-weight: 700; color: var(--field); margin-bottom: 0.35rem;">
      Apply ~${r.organicOption.totalTons} Tons of ${r.organicOption.type} (${r.organicOption.wheelbarrows} full wheelbarrows)
    </div>
    <p style="font-size: 0.9rem; line-height: 1.5; color: var(--ink);">
      ${r.organicOption.instructions} Animal manure improves soil water retention, adds millions of beneficial microbes, and buffers soil against drought.
    </p>
  `;
  
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
  if (soilState.currentStep <= 1) {
    document.getElementById('step1AreaCrop').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    soilState.currentStep = 0;
  } else if (soilState.currentStep === 2) {
    document.getElementById('step2TestChoice').classList.add('hidden');
    document.getElementById('step1AreaCrop').classList.remove('hidden');
    soilState.currentStep = 1;
  } else if (soilState.currentStep === 3) {
    document.getElementById('step3LabInputs').classList.add('hidden');
    document.getElementById('step3FieldObs').classList.add('hidden');
    document.getElementById('step2TestChoice').classList.remove('hidden');
    soilState.currentStep = 2;
  } else if (soilState.currentStep === 4) {
    document.getElementById('step4History').classList.add('hidden');
    if (soilState.hasLabTest) {
      document.getElementById('step3LabInputs').classList.remove('hidden');
    } else {
      document.getElementById('step3FieldObs').classList.remove('hidden');
    }
    soilState.currentStep = 3;
  } else if (soilState.currentStep === 5) {
    document.getElementById('step5Approach').classList.add('hidden');
    document.getElementById('step4History').classList.remove('hidden');
    soilState.currentStep = 4;
  } else if (soilState.currentStep === 6) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step5Approach').classList.remove('hidden');
    soilState.currentStep = 5;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  soilState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    crop: soilState.crop.name,
    area: `${soilState.farm.area} ${soilState.farm.unit}`,
    phStatus: soilState.results.phStatus,
    limeBags: soilState.results.limeTotalBags50kg,
    basalBags: soilState.results.basalTotalBags50kg,
    topDressBags: soilState.results.topDressTotalBags50kg
  };
  localStorage.setItem('agribase_last_soil_prescription', JSON.stringify(resultData));
  alert('Your soil and fertilizer prescription has been saved to your browser!');
}

function downloadResult() {
  const r = soilState.results;
  let reportText = `AGRIBASE SOIL & FERTILIZER PRESCRIPTION REPORT\n`;
  reportText += `=================================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Target Crop: ${soilState.crop.name}\n`;
  reportText += `Field Area: ${soilState.farm.area} ${soilState.farm.unit} (${soilState.farm.areaInHa.toFixed(2)} Hectares)\n`;
  reportText += `Soil Health Status: ${r.phStatus}\n\n`;
  reportText += `SOIL pH & ACIDITY EVALUATION:\n${r.phDescription}\n\n`;
  reportText += `1. AGRICULTURAL LIME PRESCRIPTION:\n`;
  reportText += `- Total Bags Needed: ${r.limeTotalBags50kg} Bags (50kg each)\n`;
  reportText += `- Application Rate: ${(r.limeRequiredKgHa / 1000).toFixed(1)} tons/ha\n\n`;
  reportText += `2. BASAL FERTILIZER (AT PLANTING):\n`;
  reportText += `- Type: ${r.basalFertilizerName}\n`;
  reportText += `- Total Bags Needed: ${r.basalTotalBags50kg} Bags (50kg each)\n`;
  reportText += `- Application Rate: ${r.basalKgHa} kg/ha\n`;
  reportText += `- Method: ${r.basalTiming}\n\n`;
  reportText += `3. TOP-DRESSING FERTILIZER:\n`;
  reportText += `- Type: ${r.topDressFertilizerName}\n`;
  reportText += `- Total Bags Needed: ${r.topDressTotalBags50kg} Bags (50kg each)\n`;
  reportText += `- Application Rate: ${r.topDressKgHa} kg/ha\n`;
  reportText += `Split Application Timings:\n`;
  r.topDressSplits.forEach((s, idx) => { reportText += `  ${idx + 1}. ${s}\n`; });
  reportText += `\n4. ORGANIC MANURE AMENDMENT:\n`;
  reportText += `- Quantity: ~${r.organicOption.totalTons} Tons (${r.organicOption.wheelbarrows} wheelbarrows)\n`;
  reportText += `- Instructions: ${r.organicOption.instructions}\n`;
  reportText += `\n=================================================\n`;
  reportText += `AgriBase Decision Tools — Real Practical Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `soil-fertilizer-prescription-${soilState.crop.type}-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initSoilTool();
});
