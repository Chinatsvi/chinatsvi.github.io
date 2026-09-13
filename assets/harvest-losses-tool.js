// Harvest Loss Reduction Decision Tool - JavaScript Logic
// Audits post-harvest handling practices, calculates dollar loss, and delivers actionable loss-cutting solutions
// Built for farmers with clear language, practical low-cost solutions, and difficult terms explained

const harvestLossState = {
  currentStep: 0,
  totalSteps: 6,
  
  crop: {
    type: 'grain', // grain, tomato, vegetable, potato, onion, fruit
    name: 'Maize / Cereal Grain',
    harvestVolume: 100,
    unit: 'bags_50kg', // bags_50kg, crates, tons, kg
    marketValueTotal: 2000 // $ estimated harvest value
  },
  
  harvestStage: {
    timeOfDay: 'cool_morning', // cool_morning, midday_sun, afternoon
    harvestTool: 'knives', // knives, pulling_by_hand, machine
    maturityCheck: 'visual_and_test' // moisture_meter, visual_and_test, guess
  },
  
  fieldHandling: {
    shadeProvided: 'immediate_shade', // immediate_shade, direct_sun
    dryingMethod: 'tarpaulin', // tarpaulin, bare_ground, crib
    curingDone: 'well_cured' // well_cured, no_curing, partial
  },
  
  packaging: {
    containerType: 'rigid_crates', // rigid_crates, overstuffed_sacks, loose_bulk, pics_bags
    stackingCare: 'careful' // careful, high_heavy_stack
  },
  
  transport: {
    sunCover: 'covered', // covered, open_sun
    roadDistance: 'short' // short, long_rough
  },
  
  storage: {
    storageType: 'hermetic_pics', // hermetic_pics, standard_poly_sacks, metal_silo, traditional_crib, open_floor
    moistureVerified: 'yes', // yes, no_guess
    pestProtection: 'hermetic_no_chemical', // hermetic_no_chemical, chemical_dust, none
    rodentProtection: 'good' // good, poor
  },
  
  results: {
    currentLossPercent: 0,
    dollarLossAmount: 0,
    potentialLossReductionPercent: 0,
    potentialSavingsAmount: 0,
    lossRating: 'Low Loss', // Low, Moderate, High, Severe
    
    topLeaks: [],
    actionPlan: [],
    quickWins: [],
    termsExplained: []
  }
};

const cropLossProfiles = {
  grain: {
    name: 'Maize & Cereal Grains',
    defaultUnit: 'bags_50kg',
    unitPrice: 20,
    baselineLoss: 8,
    maxPoorLoss: 35,
    keyThreats: 'Weevils, grain borers, mold (aflatoxin), and rodents in storage.'
  },
  tomato: {
    name: 'Tomatoes & Soft Fruits',
    defaultUnit: 'wooden_crates',
    unitPrice: 8,
    baselineLoss: 12,
    maxPoorLoss: 45,
    keyThreats: 'Field heat, crate squashing/bruising, overripe harvesting, sun scalding.'
  },
  vegetable: {
    name: 'Cabbage & Leafy Greens',
    defaultUnit: 'heads',
    unitPrice: 0.6,
    baselineLoss: 10,
    maxPoorLoss: 40,
    keyThreats: 'Wilting/moisture loss in sun, rough handling, tearing of outer leaves.'
  },
  potato: {
    name: 'Irish Potatoes & Tubers',
    defaultUnit: 'bags_15kg',
    unitPrice: 8,
    baselineLoss: 8,
    maxPoorLoss: 30,
    keyThreats: 'Fork/hoe cuts during digging, uncured skin peeling, sun greening (solanine).'
  },
  onion: {
    name: 'Onions & Garlic',
    defaultUnit: 'bags_10kg',
    unitPrice: 6,
    baselineLoss: 6,
    maxPoorLoss: 35,
    keyThreats: 'Neck rot, moisture trapped in bulbs before bagging, thick necks not cured.'
  }
};

function initHarvestLossTool() {
  harvestLossState.currentStep = 0;
  updateStepDisplay();
}

function startHarvestLossTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1Crop').classList.remove('hidden');
  harvestLossState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === harvestLossState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < harvestLossState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectLossCrop(crop) {
  harvestLossState.crop.type = crop;
  const p = cropLossProfiles[crop] || cropLossProfiles.grain;
  harvestLossState.crop.name = p.name;
  
  const buttons = document.querySelectorAll('#cropSelectButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
  
  // Set default estimated price
  const qty = parseFloat(document.getElementById('harvestVolumeInput').value) || 100;
  document.getElementById('cropValueInput').value = qty * p.unitPrice;
}

function confirmStep1() {
  const qty = parseFloat(document.getElementById('harvestVolumeInput').value);
  const val = parseFloat(document.getElementById('cropValueInput').value);
  
  if (isNaN(qty) || qty <= 0 || isNaN(val) || val <= 0) {
    alert('Please enter valid harvest volume and total estimated value.');
    return;
  }
  
  harvestLossState.crop.harvestVolume = qty;
  harvestLossState.crop.unit = document.getElementById('volumeUnitSelect').value;
  harvestLossState.crop.marketValueTotal = val;
  
  document.getElementById('step1Crop').classList.add('hidden');
  document.getElementById('step2Harvesting').classList.remove('hidden');
  harvestLossState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectHarvestTime(time) {
  harvestLossState.harvestStage.timeOfDay = time;
  const buttons = document.querySelectorAll('#harvestTimeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === time);
  });
}

function selectHarvestTool(tool) {
  harvestLossState.harvestStage.harvestTool = tool;
  const buttons = document.querySelectorAll('#harvestToolButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === tool);
  });
}

function confirmStep2() {
  if (!harvestLossState.harvestStage.timeOfDay) selectHarvestTime('cool_morning');
  if (!harvestLossState.harvestStage.harvestTool) selectHarvestTool('knives');
  
  document.getElementById('step2Harvesting').classList.add('hidden');
  document.getElementById('step3Handling').classList.remove('hidden');
  harvestLossState.currentStep = 3;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectShadeCare(shade) {
  harvestLossState.fieldHandling.shadeProvided = shade;
  const buttons = document.querySelectorAll('#shadeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === shade);
  });
}

function selectDryingMethod(drying) {
  harvestLossState.fieldHandling.dryingMethod = drying;
  const buttons = document.querySelectorAll('#dryingButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === drying);
  });
}

function confirmStep3() {
  if (!harvestLossState.fieldHandling.shadeProvided) selectShadeCare('immediate_shade');
  if (!harvestLossState.fieldHandling.dryingMethod) selectDryingMethod('tarpaulin');
  
  document.getElementById('step3Handling').classList.add('hidden');
  document.getElementById('step4Packaging').classList.remove('hidden');
  harvestLossState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectContainerType(container) {
  harvestLossState.packaging.containerType = container;
  const buttons = document.querySelectorAll('#containerButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === container);
  });
}

function selectSunCover(cover) {
  harvestLossState.transport.sunCover = cover;
  const buttons = document.querySelectorAll('#sunCoverButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === cover);
  });
}

function confirmStep4() {
  if (!harvestLossState.packaging.containerType) selectContainerType('rigid_crates');
  if (!harvestLossState.transport.sunCover) selectSunCover('covered');
  
  document.getElementById('step4Packaging').classList.add('hidden');
  document.getElementById('step5Storage').classList.remove('hidden');
  harvestLossState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectStorageType(type) {
  harvestLossState.storage.storageType = type;
  const buttons = document.querySelectorAll('#storageTypeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === type);
  });
}

function selectPestProtection(pest) {
  harvestLossState.storage.pestProtection = pest;
  const buttons = document.querySelectorAll('#pestProtectionButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === pest);
  });
}

function confirmStep5() {
  if (!harvestLossState.storage.storageType) selectStorageType('standard_poly_sacks');
  if (!harvestLossState.storage.pestProtection) selectPestProtection('chemical_dust');
  
  calculateHarvestLosses();
  
  document.getElementById('step5Storage').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  harvestLossState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateHarvestLosses() {
  const crop = harvestLossState.crop.type;
  const totalVal = harvestLossState.crop.marketValueTotal;
  let lossPoints = 5; // minimum unavoidable baseline loss (5%)
  
  const topLeaks = [];
  
  // 1. Time of Day
  if (harvestLossState.harvestStage.timeOfDay === 'midday_sun') {
    lossPoints += (crop === 'tomato' || crop === 'vegetable') ? 8 : 3;
    topLeaks.push({
      leak: 'Harvesting during hot midday sun',
      impact: 'Traps high "field heat" inside produce, accelerating respiration and rotting by 300%.',
      fix: 'Shift harvest hours to 6:00 AM – 9:00 AM when produce is cool and firm.'
    });
  }
  
  // 2. Shade / Direct Sun Exposure
  if (harvestLossState.fieldHandling.shadeProvided === 'direct_sun') {
    lossPoints += 6;
    topLeaks.push({
      leak: 'Leaving harvested produce in direct sun in the field',
      impact: 'Causes rapid water loss (wilting) and sun scald burns on tomatoes, leafy greens, and potatoes.',
      fix: 'Immediately carry picked crates/sacks under tree shade or a simple thatch/tarp shelter.'
    });
  }
  
  // 3. Drying on Bare Dirt
  if (harvestLossState.fieldHandling.dryingMethod === 'bare_ground') {
    lossPoints += 8;
    topLeaks.push({
      leak: 'Drying grain/beans directly on bare ground dirt',
      impact: 'Soil moisture seeps into grain, creating deadly Aspergillus mold (Aflatoxin) and mixing sand with food.',
      fix: 'Always spread a clean plastic tarpaulin, canvas sheet, or raised reed drying rack.'
    });
  }
  
  // 4. Overstuffed Sacks for Perishables
  if (harvestLossState.packaging.containerType === 'overstuffed_sacks') {
    lossPoints += (crop === 'tomato' || crop === 'vegetable') ? 14 : 4;
    topLeaks.push({
      leak: 'Using 50-100kg overstuffed sacks for soft perishable vegetables',
      impact: 'Weight crushes bottom tomatoes into juice and snaps cabbage ribs, causing massive bacterial soft rot.',
      fix: 'Switch to rigid stackable plastic crates with ventilation holes or wooden crates.'
    });
  }
  
  // 5. Open Sun Transport
  if (harvestLossState.transport.sunCover === 'open_sun') {
    lossPoints += 4;
    topLeaks.push({
      leak: 'Transporting open truckloads under scorching sun and wind',
      impact: 'Wind and sun desiccate outer produce and heat up the interior of the truckload.',
      fix: 'Tie a clean tarpaulin or light burlap sheet over the load with air gaps for ventilation.'
    });
  }
  
  // 6. Poor Storage Protection
  if (crop === 'grain' || crop === 'beans') {
    if (harvestLossState.storage.storageType === 'standard_poly_sacks' && harvestLossState.storage.pestProtection === 'none') {
      lossPoints += 15;
      topLeaks.push({
        leak: 'Storing grain in standard sacks without weevil protection',
        impact: 'Larger Grain Borer and Weevils multiply exponentially, turning grain into powder within 3 months.',
        fix: 'Use airtight PICS (Hermetic) bags or treat with approved grain dust (e.g. Actellic Gold).'
      });
    } else if (harvestLossState.storage.storageType === 'traditional_crib' && harvestLossState.storage.rodentProtection === 'poor') {
      lossPoints += 10;
      topLeaks.push({
        leak: 'Granary legs without metal rodent baffle guards',
        impact: 'Rats and mice consume 5-10% of grain and contaminate bags with urine and droppings.',
        fix: 'Nail upside-down metal tin cone cones/plates around every wooden granary support pole.'
      });
    }
  }
  
  const currentLossPct = Math.min(48, Math.max(5, lossPoints));
  const dollarLoss = (currentLossPct / 100) * totalVal;
  
  // Target achievable loss with good management: 5-8%
  const targetLossPct = 6;
  const potentialSavingsPct = Math.max(0, currentLossPct - targetLossPct);
  const dollarSavings = (potentialSavingsPct / 100) * totalVal;
  
  let lossRating = 'LOW LOSS (GOOD MANAGEMENT)';
  if (currentLossPct > 30) lossRating = 'CRITICAL / SEVERE POST-HARVEST LOSS';
  else if (currentLossPct > 18) lossRating = 'HIGH POST-HARVEST LOSS';
  else if (currentLossPct > 10) lossRating = 'MODERATE LOSS (ROOM TO SAVE MONEY)';
  
  harvestLossState.results = {
    currentLossPercent: currentLossPct,
    dollarLossAmount: dollarLoss,
    potentialLossReductionPercent: potentialSavingsPct,
    potentialSavingsAmount: dollarSavings,
    lossRating: lossRating,
    topLeaks: topLeaks.slice(0, 3), // top 3 critical leaks
    
    quickWins: [
      'Shift your picking hours to early morning (6:00 AM – 9:00 AM) to keep produce cool naturally.',
      'Never allow harvested tomatoes or vegetables to sit in the direct sun for more than 15 minutes.',
      'Sort out bruised, cut, or diseased produce immediately in the field. One rotten tomato will spoil the whole crate in 2 days.',
      'For grains, do the simple "Salt Jar Test" to guarantee grain moisture is safe (< 13%) before sealing into bags.'
    ],
    
    termsExplained: [
      { term: 'Field Heat', explanation: 'The high temperature trapped inside fruit and vegetables harvested during the hot afternoon sun. High field heat makes produce rot 3 to 5 times faster.' },
      { term: 'Hermetic Storage (PICS Bags)', explanation: 'Airtight triple-layer plastic sacks that suffocate insects and weevils without needing chemical dust.' },
      { term: 'Aflatoxin', explanation: 'A dangerous poison produced by fungi when grain or groundnuts are dried on moist dirt or stored damp. It harms human health and causes grain bans.' },
      { term: 'Curing', explanation: 'Allowing the outer skins of onions, garlic, and potatoes to dry and toughen in the shade for 1-2 weeks before packing, creating a natural shield against rot.' },
      { term: 'Mechanical Damage', explanation: 'Bruises, cuts, punctures, and crushed fruit caused by rough dropping or overstuffed sacks.' }
    ]
  };
  
  renderHarvestLossResults();
}

function renderHarvestLossResults() {
  const r = harvestLossState.results;
  const crop = harvestLossState.crop;
  
  // Status Header
  const statusEl = document.getElementById('resultStatus');
  if (r.lossRating.includes('CRITICAL') || r.lossRating.includes('HIGH')) {
    statusEl.className = 'result-status danger';
  } else if (r.lossRating.includes('MODERATE')) {
    statusEl.className = 'result-status warning';
  } else {
    statusEl.className = 'result-status good';
  }
  statusEl.textContent = `AUDIT RESULT: ${r.lossRating} (${r.currentLossPercent}% OF HARVEST)`;
  
  // Summary Fields
  document.getElementById('summaryCrop').textContent = `${crop.name} (${crop.harvestVolume} ${crop.unit.replace('_', ' ')})`;
  document.getElementById('summaryCropValue').textContent = `$${crop.marketValueTotal.toFixed(2)}`;
  document.getElementById('summaryLossPct').textContent = `${r.currentLossPercent}% of harvest`;
  document.getElementById('summaryDollarLoss').textContent = `$${r.dollarLossAmount.toFixed(2)} Lost per Season`;
  document.getElementById('summaryRecoverable').textContent = `+$${r.potentialSavingsAmount.toFixed(2)} Extra Cash in Pocket`;
  
  // Top Leaks
  const leaksContainer = document.getElementById('topLeaksContainer');
  leaksContainer.innerHTML = '';
  if (r.topLeaks.length > 0) {
    r.topLeaks.forEach((l, idx) => {
      const card = document.createElement('div');
      card.className = 'condition-card';
      card.style.background = '#fff';
      card.style.borderLeft = '5px solid var(--soil)';
      card.innerHTML = `
        <div style="font-weight: 700; color: var(--soil); font-size: 1.05rem; margin-bottom: 0.35rem;">
          #${idx + 1} LEAK: ${l.leak}
        </div>
        <p style="font-size: 0.9rem; color: var(--ink); margin-bottom: 0.4rem;"><strong>Financial Damage:</strong> ${l.impact}</p>
        <div style="font-size: 0.88rem; color: var(--field-dark); background: #f0fff0; padding: 0.5rem 0.75rem; border-radius: 4px; border: 1px solid #d0f0d0;">
          <strong>✅ Simple Low-Cost Fix:</strong> ${l.fix}
        </div>
      `;
      leaksContainer.appendChild(card);
    });
  } else {
    leaksContainer.innerHTML = '<p style="font-size: 0.95rem; color: var(--field);">Excellent handling practices! Your harvest losses are already at the lowest achievable levels.</p>';
  }
  
  // Quick Wins Checklist
  const quickWinsUl = document.getElementById('quickWinsList');
  quickWinsUl.innerHTML = '';
  r.quickWins.forEach(win => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = win;
    quickWinsUl.appendChild(li);
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
  if (harvestLossState.currentStep <= 1) {
    document.getElementById('step1Crop').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    harvestLossState.currentStep = 0;
  } else if (harvestLossState.currentStep === 2) {
    document.getElementById('step2Harvesting').classList.add('hidden');
    document.getElementById('step1Crop').classList.remove('hidden');
    harvestLossState.currentStep = 1;
  } else if (harvestLossState.currentStep === 3) {
    document.getElementById('step3Handling').classList.add('hidden');
    document.getElementById('step2Harvesting').classList.remove('hidden');
    harvestLossState.currentStep = 2;
  } else if (harvestLossState.currentStep === 4) {
    document.getElementById('step4Packaging').classList.add('hidden');
    document.getElementById('step3Handling').classList.remove('hidden');
    harvestLossState.currentStep = 3;
  } else if (harvestLossState.currentStep === 5) {
    document.getElementById('step5Storage').classList.add('hidden');
    document.getElementById('step4Packaging').classList.remove('hidden');
    harvestLossState.currentStep = 4;
  } else if (harvestLossState.currentStep === 6) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step5Storage').classList.remove('hidden');
    harvestLossState.currentStep = 5;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  harvestLossState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    crop: harvestLossState.crop.name,
    lossPercent: harvestLossState.results.currentLossPercent,
    dollarLoss: harvestLossState.results.dollarLossAmount,
    recoverableCash: harvestLossState.results.potentialSavingsAmount
  };
  localStorage.setItem('agribase_last_harvest_loss_audit', JSON.stringify(resultData));
  alert('Your post-harvest loss audit has been saved to your browser!');
}

function downloadResult() {
  const r = harvestLossState.results;
  const c = harvestLossState.crop;
  
  let reportText = `AGRIBASE POST-HARVEST LOSS REDUCTION REPORT\n`;
  reportText += `====================================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Commodity: ${c.name} (${c.harvestVolume} ${c.unit})\n`;
  reportText += `Estimated Total Crop Value: $${c.marketValueTotal.toFixed(2)}\n`;
  reportText += `Current Post-Harvest Loss: ${r.currentLossPercent}% ($${r.dollarLossAmount.toFixed(2)} Lost)\n`;
  reportText += `Recoverable Cash with Simple Fixes: +$${r.potentialSavingsAmount.toFixed(2)}\n\n`;
  reportText += `TOP 3 CRITICAL LOSS LEAKS & SOLUTIONS:\n`;
  r.topLeaks.forEach((l, idx) => {
    reportText += `${idx + 1}. Leak: ${l.leak}\n`;
    reportText += `   Damage: ${l.impact}\n`;
    reportText += `   Solution: ${l.fix}\n\n`;
  });
  reportText += `GOLDEN RULES OF POST-HARVEST HANDLING:\n`;
  r.quickWins.forEach((win, idx) => {
    reportText += `- ${win}\n`;
  });
  reportText += `\n====================================================\n`;
  reportText += `AgriBase Decision Tools — Real Practical Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `harvest-loss-audit-${c.type}-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initHarvestLossTool();
});
