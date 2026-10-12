// Farm Risk Check Decision Tool - JavaScript Logic
// 360-Degree Farm Resilience & Risk Assessment across 5 Core Pillars
// Built for farmers with clear language, practical low-cost resilience roadmaps, and simple terms

const riskState = {
  currentStep: 0,
  totalSteps: 6,
  
  farm: {
    name: 'My Farm',
    size: 'smallholder', // smallholder (< 5ha), medium (5-20ha), commercial (> 20ha)
    mainEnterprises: [] // maize, horticulture, livestock, poultry, grains
  },
  
  pillar1Weather: {
    waterSource: 'rainfed_only', // rainfed_only, partial_irrigation, reliable_borehole_solar
    weatherHistory: 'frequent_droughts', // frequent_droughts, seasonal_frost_floods, rare_extremes
    soilConservation: 'none' // none, basic_contours, high_mulch_agroforestry
  },
  
  pillar2Market: {
    buyerDiversity: 'single_middleman', // single_middleman, 2_3_buyers, contracts_and_direct
    storageBuffer: 'no_storage', // no_storage, basic_storage, hermetic_or_cold
    priceKnowledge: 'reactive' // reactive, checks_prices_regularly
  },
  
  pillar3Financial: {
    cashReserveMonths: 'zero', // zero, 1_to_3_months, more_than_6_months
    debtLevel: 'high_debt', // high_debt, moderate_manageable, zero_debt
    incomeSources: 'single_crop' // single_crop, 2_crops, diversified_crops_livestock_off_farm
  },
  
  pillar4Operational: {
    singlePointFailure: 'high', // high (if 1 pump breaks farm stops), low_backup_available
    seedSource: 'certified', // certified, farm_saved_untested
    labourReliability: 'scarce_unreliable', // scarce_unreliable, reliable
    mechanizationBackup: 'manual_hired' // manual_hired, own_equipment
  },
  
  pillar5BiosecurityLegal: {
    landTenure: 'informal_communal', // informal_communal, long_lease_registered, title_deed
    rotationPractice: 'continuous_same_crop', // continuous_same_crop, 2_year_rotation, 3_year_diverse_rotation
    fencingSecurity: 'unfenced', // unfenced, live_fence_hedges, secure_perimeter_wire
    livestockVaccines: 'irregular' // irregular, strict_vaccine_schedule, not_applicable
  },
  
  results: {
    overallRiskScore: 65, // 0 - 100 (Higher = Higher Risk)
    riskRating: 'High Risk',
    pillarScores: {
      weather: 70,
      market: 65,
      financial: 80,
      operational: 50,
      biosecurityLegal: 55
    },
    criticalThreats: [],
    resilienceRoadmap: [],
    termsExplained: []
  }
};

function initRiskTool() {
  riskState.currentStep = 0;
  updateStepDisplay();
}

function startRiskTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1Profile').classList.remove('hidden');
  riskState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === riskState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < riskState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectFarmSize(size) {
  riskState.farm.size = size;
  const buttons = document.querySelectorAll('#farmSizeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === size);
  });
}

function toggleEnterprise(ent) {
  if (riskState.farm.mainEnterprises.includes(ent)) {
    riskState.farm.mainEnterprises = riskState.farm.mainEnterprises.filter(e => e !== ent);
  } else {
    riskState.farm.mainEnterprises.push(ent);
  }
}

function confirmStep1() {
  if (!riskState.farm.size) selectFarmSize('smallholder');
  
  document.getElementById('step1Profile').classList.add('hidden');
  document.getElementById('step2Weather').classList.remove('hidden');
  riskState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Pillar 1 Selectors
function selectWaterSource(water) {
  riskState.pillar1Weather.waterSource = water;
  const buttons = document.querySelectorAll('#waterSourceButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === water);
  });
}

function selectWeatherHistory(hist) {
  riskState.pillar1Weather.weatherHistory = hist;
  const buttons = document.querySelectorAll('#weatherHistButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === hist);
  });
}

function confirmStep2() {
  if (!riskState.pillar1Weather.waterSource) selectWaterSource('rainfed_only');
  if (!riskState.pillar1Weather.weatherHistory) selectWeatherHistory('frequent_droughts');
  
  document.getElementById('step2Weather').classList.add('hidden');
  document.getElementById('step3Market').classList.remove('hidden');
  riskState.currentStep = 3;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Pillar 2 Selectors
function selectBuyerDiversity(buyer) {
  riskState.pillar2Market.buyerDiversity = buyer;
  const buttons = document.querySelectorAll('#buyerDiversityButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === buyer);
  });
}

function selectStorageBuffer(store) {
  riskState.pillar2Market.storageBuffer = store;
  const buttons = document.querySelectorAll('#storageBufferButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === store);
  });
}

function confirmStep3() {
  if (!riskState.pillar2Market.buyerDiversity) selectBuyerDiversity('single_middleman');
  if (!riskState.pillar2Market.storageBuffer) selectStorageBuffer('no_storage');
  
  document.getElementById('step3Market').classList.add('hidden');
  document.getElementById('step4Financial').classList.remove('hidden');
  riskState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Pillar 3 Selectors
function selectCashReserve(cash) {
  riskState.pillar3Financial.cashReserveMonths = cash;
  const buttons = document.querySelectorAll('#cashReserveButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === cash);
  });
}

function selectDebtLevel(debt) {
  riskState.pillar3Financial.debtLevel = debt;
  const buttons = document.querySelectorAll('#debtLevelButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === debt);
  });
}

function selectIncomeSources(sources) {
  riskState.pillar3Financial.incomeSources = sources;
  const buttons = document.querySelectorAll('#incomeSourcesButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === sources);
  });
}

function confirmStep4() {
  if (!riskState.pillar3Financial.cashReserveMonths) selectCashReserve('zero');
  if (!riskState.pillar3Financial.debtLevel) selectDebtLevel('moderate_manageable');
  if (!riskState.pillar3Financial.incomeSources) selectIncomeSources('single_crop');
  
  document.getElementById('step4Financial').classList.add('hidden');
  document.getElementById('step5Operations').classList.remove('hidden');
  riskState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Pillar 4 & 5 Selectors
function selectSinglePoint(sp) {
  riskState.pillar4Operational.singlePointFailure = sp;
  const buttons = document.querySelectorAll('#singlePointButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === sp);
  });
}

function selectLandTenure(tenure) {
  riskState.pillar5BiosecurityLegal.landTenure = tenure;
  const buttons = document.querySelectorAll('#landTenureButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === tenure);
  });
}

function selectRotationPractice(rot) {
  riskState.pillar5BiosecurityLegal.rotationPractice = rot;
  const buttons = document.querySelectorAll('#rotationButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === rot);
  });
}

function confirmStep5() {
  if (!riskState.pillar4Operational.singlePointFailure) selectSinglePoint('high');
  if (!riskState.pillar5BiosecurityLegal.landTenure) selectLandTenure('informal_communal');
  if (!riskState.pillar5BiosecurityLegal.rotationPractice) selectRotationPractice('2_year_rotation');
  
  calculateFarmRisk();
  
  document.getElementById('step5Operations').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  riskState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateFarmRisk() {
  const criticalThreats = [];
  const roadmap = [];
  
  // 1. Weather Score (0-100)
  let weatherScore = 20;
  if (riskState.pillar1Weather.waterSource === 'rainfed_only') {
    weatherScore += 45;
    criticalThreats.push({
      pillar: 'Weather & Climate',
      threat: '100% Dependent on Unpredictable Rain',
      impact: 'A 3-week mid-season dry spell will wipe out crop investment and input costs.',
      action: 'Install a low-cost rainwater harvesting pond or 5000L tank with gravity drip lines.'
    });
  } else if (riskState.pillar1Weather.waterSource === 'partial_irrigation') {
    weatherScore += 20;
  }
  if (riskState.pillar1Weather.weatherHistory === 'frequent_droughts') weatherScore += 25;
  
  // 2. Market Score
  let marketScore = 20;
  if (riskState.pillar2Market.buyerDiversity === 'single_middleman') {
    marketScore += 40;
    criticalThreats.push({
      pillar: 'Market & Sales',
      threat: 'Single Middleman / Buyer Dependency',
      impact: 'If that one buyer fails to arrive, your entire harvest will rot or you must sell at 70% discount.',
      action: 'Identify at least 2 alternative local wholesale buyers or sign contracts with local schools/hotels.'
    });
  } else if (riskState.pillar2Market.buyerDiversity === '2_3_buyers') {
    marketScore += 15;
  }
  if (riskState.pillar2Market.storageBuffer === 'no_storage') {
    marketScore += 30;
    roadmap.push('Build or acquire hermetic PICS bags so you are never forced into emergency distress sales during peak harvest gluts.');
  }
  
  // 3. Financial Score
  let finScore = 15;
  if (riskState.pillar3Financial.cashReserveMonths === 'zero') {
    finScore += 45;
    criticalThreats.push({
      pillar: 'Financial & Cash Flow',
      threat: 'Zero Emergency Cash Reserves',
      impact: 'Any single crop failure, pump breakdown, or family illness will force emergency asset sales or high-interest debt.',
      action: 'Build a dedicated farm emergency buffer account equal to 3 months of basic operating expenses.'
    });
  } else if (riskState.pillar3Financial.cashReserveMonths === '1_to_3_months') {
    finScore += 20;
  }
  if (riskState.pillar3Financial.debtLevel === 'high_debt') finScore += 35;
  if (riskState.pillar3Financial.incomeSources === 'single_crop') {
    finScore += 25;
    roadmap.push('Diversify into at least 2 enterprise streams (e.g. combine a grain crop with indigenous poultry or dairy goats).');
  }
  
  // 4. Operational Score
  let opScore = 20;
  if (riskState.pillar4Operational.singlePointFailure === 'high') {
    opScore += 40;
    roadmap.push('Keep critical spare parts on the farm (spare pump seals, generator belts, backup pipes) to prevent downtime.');
  }
  
  // 5. Biosecurity & Legal Score
  let bioLegalScore = 15;
  if (riskState.pillar5BiosecurityLegal.landTenure === 'informal_communal') {
    bioLegalScore += 30;
    roadmap.push('Formalize land boundaries with local leaders or obtain written long-term lease agreements before investing in permanent infrastructure.');
  }
  if (riskState.pillar5BiosecurityLegal.rotationPractice === 'continuous_same_crop') {
    bioLegalScore += 40;
    criticalThreats.push({
      pillar: 'Biosecurity & Agronomy',
      threat: 'Continuous Monoculture (Same Crop Every Season)',
      impact: 'Builds up massive soil-borne nematodes, bacterial wilt, and pest resistance, causing permanent yield decline.',
      action: 'Implement a strict 3-year crop rotation: Nightshades (Tomatoes) → Legumes (Beans) → Cereals (Maize/Wheat) → Brassicas (Cabbage).'
    });
  }
  
  // Overall Weighted Score (0-100)
  const overallScore = Math.round((weatherScore * 0.25) + (marketScore * 0.20) + (finScore * 0.25) + (opScore * 0.15) + (bioLegalScore * 0.15));
  
  let riskRating = 'LOW RISK — HIGH RESILIENCE';
  if (overallScore > 70) riskRating = 'CRITICAL VULNERABILITY (HIGH RISK OF FAILURE)';
  else if (overallScore > 50) riskRating = 'HIGH RISK (SIGNIFICANT PROFIT THREATS)';
  else if (overallScore > 30) riskRating = 'MODERATE RISK (OPPORTUNITIES TO FORTIFY)';
  
  riskState.results = {
    overallRiskScore: overallScore,
    riskRating: riskRating,
    pillarScores: {
      weather: Math.min(100, weatherScore),
      market: Math.min(100, marketScore),
      financial: Math.min(100, finScore),
      operational: Math.min(100, opScore),
      biosecurityLegal: Math.min(100, bioLegalScore)
    },
    criticalThreats: criticalThreats.slice(0, 3),
    resilienceRoadmap: roadmap.slice(0, 4),
    
    termsExplained: [
      { term: 'Monoculture vs Diversification', explanation: 'Monoculture means growing only one crop everywhere. If pests or prices hit that crop, you lose 100%. Diversification means growing 2-3 different crops plus livestock so you always have income.' },
      { term: 'Cash Flow Bottleneck', explanation: 'When a farmer has valuable crops growing in the field, but runs completely out of cash in the pocket to pay workers, diesel, or household food before harvest.' },
      { term: 'Single Point of Failure', explanation: 'A critical piece of equipment (like your only water pump) that, if broken, immediately halts the entire farm operations.' },
      { term: 'Biosecurity', explanation: 'Practical hygiene rules (like footbaths, quarantine pens for new animals, and cleaning boots) to keep deadly diseases out of your farm.' },
      { term: 'Working Capital Reserve', explanation: 'A cash emergency buffer saved in the bank or mobile money to cover 2-3 months of farm expenses without needing emergency loans.' }
    ]
  };
  
  renderRiskResults();
}

function renderRiskResults() {
  const r = riskState.results;
  
  // Status Header
  const statusEl = document.getElementById('resultStatus');
  if (r.overallRiskScore > 50) {
    statusEl.className = 'result-status danger';
  } else if (r.overallRiskScore > 30) {
    statusEl.className = 'result-status warning';
  } else {
    statusEl.className = 'result-status good';
  }
  statusEl.textContent = `FARM RISK: ${r.riskRating} (VULNERABILITY SCORE: ${r.overallRiskScore}/100)`;
  
  // Summary
  document.getElementById('summaryRating').textContent = r.riskRating;
  document.getElementById('summaryScore').textContent = `${r.overallRiskScore} / 100`;
  document.getElementById('summaryWeatherScore').textContent = `${r.pillarScores.weather}% Risk`;
  document.getElementById('summaryMarketScore').textContent = `${r.pillarScores.market}% Risk`;
  document.getElementById('summaryFinancialScore').textContent = `${r.pillarScores.financial}% Risk`;
  document.getElementById('summaryOperationalScore').textContent = `${r.pillarScores.operational}% Risk`;
  document.getElementById('summaryBioLegalScore').textContent = `${r.pillarScores.biosecurityLegal}% Risk`;
  
  // Critical Threats Cards
  const threatsContainer = document.getElementById('criticalThreatsContainer');
  threatsContainer.innerHTML = '';
  if (r.criticalThreats.length > 0) {
    r.criticalThreats.forEach((t, idx) => {
      const card = document.createElement('div');
      card.className = 'condition-card';
      card.style.background = '#fff';
      card.style.borderLeft = '5px solid var(--soil)';
      card.innerHTML = `
        <div style="font-weight: 700; color: var(--soil); font-size: 1.05rem; margin-bottom: 0.35rem;">
          #${idx + 1} FATAL THREAT: ${t.threat} (${t.pillar})
        </div>
        <p style="font-size: 0.9rem; color: var(--ink); margin-bottom: 0.4rem;"><strong>The Danger:</strong> ${t.impact}</p>
        <div style="font-size: 0.88rem; color: var(--field-dark); background: #f0fff0; padding: 0.5rem 0.75rem; border-radius: 4px; border: 1px solid #d0f0d0;">
          <strong>🛡️ Practical Protection Action:</strong> ${t.action}
        </div>
      `;
      threatsContainer.appendChild(card);
    });
  } else {
    threatsContainer.innerHTML = '<p style="font-size: 0.95rem; color: var(--field);">Outstanding risk management! Your farm displays strong resilience across all 5 risk pillars.</p>';
  }
  
  // Resilience Roadmap
  const roadmapUl = document.getElementById('resilienceRoadmapList');
  roadmapUl.innerHTML = '';
  r.resilienceRoadmap.forEach(item => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = item;
    roadmapUl.appendChild(li);
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
  if (riskState.currentStep <= 1) {
    document.getElementById('step1Profile').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    riskState.currentStep = 0;
  } else if (riskState.currentStep === 2) {
    document.getElementById('step2Weather').classList.add('hidden');
    document.getElementById('step1Profile').classList.remove('hidden');
    riskState.currentStep = 1;
  } else if (riskState.currentStep === 3) {
    document.getElementById('step3Market').classList.add('hidden');
    document.getElementById('step2Weather').classList.remove('hidden');
    riskState.currentStep = 2;
  } else if (riskState.currentStep === 4) {
    document.getElementById('step4Financial').classList.add('hidden');
    document.getElementById('step3Market').classList.remove('hidden');
    riskState.currentStep = 3;
  } else if (riskState.currentStep === 5) {
    document.getElementById('step5Operations').classList.add('hidden');
    document.getElementById('step4Financial').classList.remove('hidden');
    riskState.currentStep = 4;
  } else if (riskState.currentStep === 6) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step5Operations').classList.remove('hidden');
    riskState.currentStep = 5;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  riskState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    rating: riskState.results.riskRating,
    score: riskState.results.overallRiskScore
  };
  localStorage.setItem('agribase_last_farm_risk_audit', JSON.stringify(resultData));
  alert('Your farm risk & resilience audit has been saved to your browser!');
}

function downloadResult() {
  const r = riskState.results;
  let reportText = `AGRIBASE 360-DEGREE FARM RISK & RESILIENCE REPORT\n`;
  reportText += `====================================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Overall Risk Rating: ${r.riskRating}\n`;
  reportText += `Vulnerability Score: ${r.overallRiskScore} / 100 (Lower is safer)\n\n`;
  reportText += `5 PILLAR RISK PROFILE:\n`;
  reportText += `- Weather & Climate Risk: ${r.pillarScores.weather}%\n`;
  reportText += `- Market & Sales Risk: ${r.pillarScores.market}%\n`;
  reportText += `- Financial & Cash Flow Risk: ${r.pillarScores.financial}%\n`;
  reportText += `- Operational & Equipment Risk: ${r.pillarScores.operational}%\n`;
  reportText += `- Biosecurity & Land Tenure Risk: ${r.pillarScores.biosecurityLegal}%\n\n`;
  reportText += `TOP CRITICAL FATAL THREATS & PROTECTIONS:\n`;
  r.criticalThreats.forEach((t, idx) => {
    reportText += `${idx + 1}. [${t.pillar}] ${t.threat}\n`;
    reportText += `   Danger: ${t.impact}\n`;
    reportText += `   Action: ${t.action}\n\n`;
  });
  reportText += `RESILIENCE ROADMAP ACTION ITEMS:\n`;
  r.resilienceRoadmap.forEach((item, idx) => {
    reportText += `${idx + 1}. ${item}\n`;
  });
  reportText += `\n====================================================\n`;
  reportText += `AgriBase Decision Tools — Real Practical Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `farm-risk-audit-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initRiskTool();
});
