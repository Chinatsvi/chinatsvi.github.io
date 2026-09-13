// Market Timing & Selling Strategy Decision Tool - JavaScript Logic
// Calculates net profit across market channels and analyzes storage economics vs immediate sale
// Designed for smallholder and commercial farmers with simple English & actionable insights

const marketState = {
  currentStep: 0,
  totalSteps: 6,
  
  crop: {
    type: 'tomato', // tomato, maize, onion, cabbage, potato, beans
    name: 'Tomatoes (Perishable)',
    category: 'perishable', // perishable, semi_perishable, grain
    quantity: 200,
    unit: 'wooden_crates', // crates, bags_50kg, tons, kg
    weightInKg: 6000
  },
  
  prices: {
    farmGatePrice: 5.0, // $ per unit
    localMarketPrice: 8.0,
    cityWholesalePrice: 12.0,
    contractPrice: 14.0,
    currency: '$'
  },
  
  logistics: {
    distanceToCityKm: 60,
    transportCostPerUnit: 2.0,
    packagingCostPerUnit: 0.5,
    marketCommissionPercent: 10, // %
    transitLossPercent: 5 // %
  },
  
  storage: {
    hasStorage: 'none', // none, basic_shed, hermetic_bags, cold_room
    plannedStorageMonths: 0,
    monthlyStorageCostPerUnit: 0.2,
    expectedFuturePrice: 10.0,
    storageLossPercent: 5
  },
  
  financialNeed: 'urgent', // urgent, can_wait, flexible
  
  results: {
    bestChannel: '',
    bestChannelNetPerUnit: 0,
    bestChannelTotalNet: 0,
    
    channelComparisons: [],
    
    storageVerdict: '',
    storageProfitOrLoss: 0,
    storageNetGainPerUnit: 0,
    breakEvenFuturePrice: 0,
    
    strategyAdvice: [],
    negotiationTips: [],
    warnings: [],
    termsExplained: []
  }
};

const cropMarketData = {
  tomato: {
    name: 'Tomatoes',
    category: 'perishable',
    defaultUnit: 'wooden_crates',
    unitWeightKg: 30,
    shelfLifeDays: 5,
    storageFeasibility: 'very_low',
    typicalFarmGatePrice: 5.0,
    typicalWholesalePrice: 10.0,
    marketNotes: 'Highly perishable. Glut periods cause price crashes within 48 hours. Best sold within 3 days of harvest.'
  },
  cabbage: {
    name: 'Cabbage',
    category: 'perishable',
    defaultUnit: 'heads',
    unitWeightKg: 3,
    shelfLifeDays: 14,
    storageFeasibility: 'low',
    typicalFarmGatePrice: 0.4,
    typicalWholesalePrice: 0.8,
    marketNotes: 'Bulk transport required. Sells well to urban markets and schools. Keep out of direct sun during transport.'
  },
  onion: {
    name: 'Onions / Garlic',
    category: 'semi_perishable',
    defaultUnit: 'bags_10kg',
    unitWeightKg: 10,
    shelfLifeDays: 120,
    storageFeasibility: 'high',
    typicalFarmGatePrice: 4.0,
    typicalWholesalePrice: 9.0,
    marketNotes: 'Excellent for storage if cured properly. Prices often double 3-4 months after peak harvest season.'
  },
  potato: {
    name: 'Irish Potato',
    category: 'semi_perishable',
    defaultUnit: 'bags_15kg',
    unitWeightKg: 15,
    shelfLifeDays: 60,
    storageFeasibility: 'medium',
    typicalFarmGatePrice: 5.0,
    typicalWholesalePrice: 10.0,
    marketNotes: 'Store in cool, dark, well-ventilated sheds to prevent greening (solanine) and sprouting.'
  },
  maize: {
    name: 'Maize / Grain',
    category: 'grain',
    defaultUnit: 'bags_50kg',
    unitWeightKg: 50,
    shelfLifeDays: 365,
    storageFeasibility: 'very_high',
    typicalFarmGatePrice: 12.0,
    typicalWholesalePrice: 20.0,
    marketNotes: 'Harvest price is usually lowest due to harvest flood. Storing in hermetic bags (PICS) captures huge off-season price peaks.'
  },
  beans: {
    name: 'Dry Beans / Soybeans',
    category: 'grain',
    defaultUnit: 'bags_50kg',
    unitWeightKg: 50,
    shelfLifeDays: 365,
    storageFeasibility: 'very_high',
    typicalFarmGatePrice: 40.0,
    typicalWholesalePrice: 65.0,
    marketNotes: 'High-value commodity with steady urban and boarding school demand throughout the year.'
  }
};

function initMarketTool() {
  marketState.currentStep = 0;
  updateStepDisplay();
}

function startMarketTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1Crop').classList.remove('hidden');
  marketState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === marketState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < marketState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectMarketCrop(crop) {
  marketState.crop.type = crop;
  const d = cropMarketData[crop] || cropMarketData.tomato;
  marketState.crop.name = d.name;
  marketState.crop.category = d.category;
  
  const buttons = document.querySelectorAll('#cropSelectButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
  
  // Set default prices in step 2 inputs
  document.getElementById('farmGatePriceInput').value = d.typicalFarmGatePrice;
  document.getElementById('cityWholesalePriceInput').value = d.typicalWholesalePrice;
}

function confirmStep1() {
  const qty = parseFloat(document.getElementById('harvestQtyInput').value);
  if (isNaN(qty) || qty <= 0) {
    alert('Please enter a valid harvest volume number.');
    return;
  }
  
  marketState.crop.quantity = qty;
  marketState.crop.unit = document.getElementById('qtyUnitSelect').value;
  
  document.getElementById('step1Crop').classList.add('hidden');
  document.getElementById('step2Prices').classList.remove('hidden');
  marketState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function confirmStep2() {
  const fg = parseFloat(document.getElementById('farmGatePriceInput').value);
  const city = parseFloat(document.getElementById('cityWholesalePriceInput').value);
  
  if (isNaN(fg) || fg < 0 || isNaN(city) || city < 0) {
    alert('Please enter valid market price numbers.');
    return;
  }
  
  marketState.prices.farmGatePrice = fg;
  marketState.prices.cityWholesalePrice = city;
  marketState.prices.localMarketPrice = parseFloat(document.getElementById('localMarketPriceInput').value) || (fg * 1.3);
  marketState.prices.contractPrice = parseFloat(document.getElementById('contractPriceInput').value) || (city * 1.15);
  
  document.getElementById('step2Prices').classList.add('hidden');
  document.getElementById('step3Logistics').classList.remove('hidden');
  marketState.currentStep = 3;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function confirmStep3() {
  const dist = parseFloat(document.getElementById('distanceKmInput').value) || 50;
  const transport = parseFloat(document.getElementById('transportCostInput').value) || 2.0;
  const packaging = parseFloat(document.getElementById('packagingCostInput').value) || 0.5;
  const transitLoss = parseFloat(document.getElementById('transitLossInput').value) || 5.0;
  
  marketState.logistics.distanceToCityKm = dist;
  marketState.logistics.transportCostPerUnit = transport;
  marketState.logistics.packagingCostPerUnit = packaging;
  marketState.logistics.transitLossPercent = transitLoss;
  
  document.getElementById('step3Logistics').classList.add('hidden');
  document.getElementById('step4Storage').classList.remove('hidden');
  marketState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectStorageType(type) {
  marketState.storage.hasStorage = type;
  const buttons = document.querySelectorAll('#storageTypeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === type);
  });
}

function confirmStep4() {
  if (!marketState.storage.hasStorage) {
    selectStorageType('none');
  }
  
  marketState.storage.plannedStorageMonths = parseInt(document.getElementById('storageMonthsInput').value) || 0;
  marketState.storage.expectedFuturePrice = parseFloat(document.getElementById('futurePriceInput').value) || (marketState.prices.farmGatePrice * 1.5);
  
  document.getElementById('step4Storage').classList.add('hidden');
  document.getElementById('step5Urgency').classList.remove('hidden');
  marketState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectFinancialNeed(need) {
  marketState.financialNeed = need;
  const buttons = document.querySelectorAll('#financialNeedButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === need);
  });
}

function confirmStep5() {
  if (!marketState.financialNeed) {
    selectFinancialNeed('can_wait');
  }
  
  calculateMarketStrategy();
  
  document.getElementById('step5Urgency').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  marketState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateMarketStrategy() {
  const qty = marketState.crop.quantity;
  const unit = marketState.crop.unit;
  const fgPrice = marketState.prices.farmGatePrice;
  const localPrice = marketState.prices.localMarketPrice;
  const cityPrice = marketState.prices.cityWholesalePrice;
  const contractPrice = marketState.prices.contractPrice;
  
  const transportUnit = marketState.logistics.transportCostPerUnit;
  const packUnit = marketState.logistics.packagingCostPerUnit;
  const transitLossPct = marketState.logistics.transitLossPercent / 100;
  
  // 1. Farm Gate Buyer / Middleman
  // No transport, no commission, minimal packaging, 0% transit loss
  const fgNetPerUnit = fgPrice - (packUnit * 0.2); // minimal packaging
  const fgTotalNet = fgNetPerUnit * qty;
  
  // 2. Local Open Market
  // Low transport ($0.5/unit), stall fee ($0.3/unit), 3% loss
  const localTrans = 0.5;
  const localStallFee = 0.3;
  const localLoss = 0.03;
  const localNetPerUnit = (localPrice * (1 - localLoss)) - (localTrans + packUnit + localStallFee);
  const localTotalNet = localNetPerUnit * qty;
  
  // 3. City Wholesale Market
  // Transport, packaging, 10% commission/handling, transit loss
  const cityComm = cityPrice * 0.10;
  const cityNetPerUnit = (cityPrice * (1 - transitLossPct)) - (transportUnit + packUnit + cityComm);
  const cityTotalNet = cityNetPerUnit * qty;
  
  // 4. Contract Buyer / Supermarket / Institution
  // Higher transport ($1.5), premium packaging ($1.0), 10% reject/sorting discount
  const contractPack = packUnit * 1.8;
  const contractNetPerUnit = (contractPrice * 0.90) - (transportUnit * 0.8 + contractPack);
  const contractTotalNet = contractNetPerUnit * qty;
  
  const channels = [
    {
      id: 'city_wholesale',
      name: 'City Wholesale Market',
      grossPrice: cityPrice,
      netPerUnit: cityNetPerUnit,
      totalNet: cityTotalNet,
      pros: 'Large bulk buying, instant cash, absorbs huge volume in one day.',
      cons: `High transport cost ($${transportUnit}/unit), trader commissions, and ${marketState.logistics.transitLossPercent}% transit bruising/spoilage.`
    },
    {
      id: 'farm_gate',
      name: 'Farm Gate Buyer / Middleman',
      grossPrice: fgPrice,
      netPerUnit: fgNetPerUnit,
      totalNet: fgTotalNet,
      pros: 'Zero transport hassle, buyer pays cash at farm, no road risk.',
      cons: 'Lower price per unit; middlemen may try to use uncalibrated scales or reject produce.'
    },
    {
      id: 'local_market',
      name: 'Local Town Open Market',
      grossPrice: localPrice,
      netPerUnit: localNetPerUnit,
      totalNet: localTotalNet,
      pros: 'Direct retail price from consumers, very low transport cost.',
      cons: 'Takes several days to sell; cannot absorb large bulk truckloads quickly.'
    },
    {
      id: 'contract_buyer',
      name: 'Supermarket / Restaurant Contract',
      grossPrice: contractPrice,
      netPerUnit: contractNetPerUnit,
      totalNet: contractTotalNet,
      pros: 'Highest guaranteed price per unit and reliable regular orders.',
      cons: 'Strict cosmetic grading (ugly produce rejected) and delayed payment (14-30 days).'
    }
  ];
  
  channels.sort((a, b) => b.totalNet - a.totalNet);
  const best = channels[0];
  
  // Storage Economics Evaluation
  const storageMonths = marketState.storage.plannedStorageMonths;
  const futurePrice = marketState.storage.expectedFuturePrice;
  let storageVerdict = '';
  let storageProfit = 0;
  let breakEvenFuturePrice = 0;
  
  if (marketState.crop.category === 'perishable') {
    storageVerdict = 'DO NOT STORE (PERISHABLE)';
    storageProfit = 0;
    breakEvenFuturePrice = fgPrice * 1.5;
  } else {
    // Semi-perishable or grain storage calculation
    const monthlyCost = 0.25; // $0.25 per unit per month (bag + storage fee + chemical dust)
    const weightShrinkagePct = 0.03; // 3% natural moisture shrinkage
    const storagePestLossPct = marketState.storage.hasStorage === 'hermetic_bags' ? 0.01 : 0.06;
    const totalLossPct = weightShrinkagePct + storagePestLossPct;
    
    const totalStorageCostPerUnit = monthlyCost * Math.max(1, storageMonths);
    breakEvenFuturePrice = (fgNetPerUnit + totalStorageCostPerUnit) / (1 - totalLossPct);
    
    const futureNetPerUnit = (futurePrice * (1 - totalLossPct)) - totalStorageCostPerUnit;
    const immediateNetPerUnit = fgNetPerUnit;
    
    storageProfit = (futureNetPerUnit - immediateNetPerUnit) * qty;
    
    if (futurePrice >= breakEvenFuturePrice && storageMonths > 0) {
      storageVerdict = 'STORE FOR OFF-SEASON PEAK (PROFITABLE)';
    } else if (storageMonths === 0) {
      storageVerdict = 'SELL NOW AT HARVEST';
    } else {
      storageVerdict = 'RISKY TO STORE — SELL NOW';
    }
  }
  
  marketState.results = {
    bestChannel: best.name,
    bestChannelNetPerUnit: best.netPerUnit,
    bestChannelTotalNet: best.totalNet,
    channelComparisons: channels,
    storageVerdict: storageVerdict,
    storageProfitOrLoss: storageProfit,
    breakEvenFuturePrice: breakEvenFuturePrice,
    
    negotiationTips: [
      'Always check the morning city wholesale price on AgriBase or phone a trusted market friend BEFORE agreeing to a middleman\'s offer.',
      'Use your own calibrated scale or standard crate volume. Never allow buyers to overstuff crates with "heaped mounds" without paying extra.',
      'Grade your produce into Grade 1 (first class) and Grade 2 before buyers arrive. Sell Grade 1 at a premium price and Grade 2 for local processing/canning.',
      'If selling at the farm gate, demand full cash on loading. Never give produce on credit to unknown mobile traders.'
    ],
    
    termsExplained: [
      { term: 'Farm-Gate Price', explanation: 'The cash price a buyer pays right at your farm fence. You have zero transport cost, but the price is usually lower.' },
      { term: 'Wholesale Price', explanation: 'The bulk price paid at major central city markets (like Mbare, Wakulima, or Joburg Market).' },
      { term: 'Net Profit per Unit', explanation: 'The real money that stays in your pocket after subtracting transport, bags, offloading fees, and trader commissions from the gross selling price.' },
      { term: 'Market Glut', explanation: 'When thousands of farmers harvest the exact same crop at the exact same week, causing supply to flood the market and prices to crash.' },
      { term: 'Hermetic Storage (PICS Bags)', explanation: 'Airtight, chemical-free triple-layer plastic sacks that suffocate grain weevils and prevent post-harvest grain losses for up to 2 years.' },
      { term: 'Post-Harvest Shrinkage', explanation: 'The natural weight loss that occurs when harvested crops lose moisture during drying and storage.' }
    ]
  };
  
  renderMarketResults();
}

function renderMarketResults() {
  const r = marketState.results;
  const qty = marketState.crop.quantity;
  const unit = marketState.crop.unit.replace('_', ' ');
  
  // Status Banner
  const statusEl = document.getElementById('resultStatus');
  statusEl.className = 'result-status good';
  statusEl.textContent = `RECOMMENDED: ${r.bestChannel.toUpperCase()} (NET PROFIT: $${r.bestChannelTotalNet.toFixed(2)})`;
  
  // Summary Fields
  document.getElementById('summaryCrop').textContent = `${marketState.crop.name} (${qty} ${unit})`;
  document.getElementById('summaryBestChannel').textContent = r.bestChannel;
  document.getElementById('summaryNetPerUnit').textContent = `$${r.bestChannelNetPerUnit.toFixed(2)} per ${unit}`;
  document.getElementById('summaryTotalNet').textContent = `$${r.bestChannelTotalNet.toFixed(2)}`;
  document.getElementById('summaryStorageVerdict').textContent = r.storageVerdict;
  
  // Channel Comparison Table
  const compContainer = document.getElementById('channelComparisonContainer');
  compContainer.innerHTML = '';
  
  r.channelComparisons.forEach((c, idx) => {
    const isBest = idx === 0;
    const card = document.createElement('div');
    card.className = 'condition-card';
    card.style.background = isBest ? '#f0fff0' : '#fff';
    card.style.borderLeft = isBest ? '5px solid var(--field)' : '1px solid var(--border)';
    
    card.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; flex-wrap: wrap;">
        <div style="font-weight: 800; font-size: 1.1rem; color: var(--field);">
          ${isBest ? '⭐ BEST OPTION: ' : ''}${c.name}
        </div>
        <div style="font-weight: 800; font-size: 1.15rem; color: ${isBest ? 'var(--field)' : 'var(--ink)'};">
          Total Net: $${c.totalNet.toFixed(2)} ($${c.netPerUnit.toFixed(2)} / unit)
        </div>
      </div>
      <div style="font-size: 0.9rem; margin-bottom: 0.35rem;">
        <strong>Gross Selling Price:</strong> $${c.grossPrice.toFixed(2)} | <strong>Net in Pocket:</strong> $${c.netPerUnit.toFixed(2)}
      </div>
      <div style="font-size: 0.85rem; color: var(--field-dark); margin-bottom: 0.25rem;">
        <strong>Advantages:</strong> ${c.pros}
      </div>
      <div style="font-size: 0.85rem; color: var(--soil);">
        <strong>Risks & Deductions:</strong> ${c.cons}
      </div>
    `;
    compContainer.appendChild(card);
  });
  
  // Storage Economics Card
  const storageCard = document.getElementById('storageEconomicsCard');
  if (marketState.crop.category === 'perishable') {
    storageCard.innerHTML = `
      <div style="font-weight: 700; color: var(--soil); margin-bottom: 0.35rem;">Sell Immediately at Harvest</div>
      <p style="font-size: 0.9rem; color: var(--ink);">
        ${marketState.crop.name} is highly perishable with a shelf life of only a few days without expensive cold chain refrigeration. Storing at ambient room temperature will lead to rotting and total financial loss. Sell within 48 hours of picking.
      </p>
    `;
  } else {
    storageCard.innerHTML = `
      <div style="font-size: 1.05rem; font-weight: 700; color: var(--field); margin-bottom: 0.5rem;">
        Storage Decision: ${r.storageVerdict}
      </div>
      <p style="font-size: 0.95rem; line-height: 1.6; margin-bottom: 0.5rem;">
        <strong>Break-Even Future Price:</strong> $${r.breakEvenFuturePrice.toFixed(2)} per ${unit}. If you expect off-season prices to rise above this amount, holding grain/onions is highly profitable.
      </p>
      <p style="font-size: 0.9rem; color: var(--ink); background: var(--tint); padding: 0.65rem; border-radius: 6px;">
        <strong>Estimated Storage Gain:</strong> $${r.storageProfitOrLoss.toFixed(2)} extra profit after subtracting storage bags, grain protectant, and natural moisture shrinkage.
      </p>
    `;
  }
  
  // Negotiation Tips
  const tipsUl = document.getElementById('negotiationTipsList');
  tipsUl.innerHTML = '';
  r.negotiationTips.forEach(tip => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = tip;
    tipsUl.appendChild(li);
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
  if (marketState.currentStep <= 1) {
    document.getElementById('step1Crop').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    marketState.currentStep = 0;
  } else if (marketState.currentStep === 2) {
    document.getElementById('step2Prices').classList.add('hidden');
    document.getElementById('step1Crop').classList.remove('hidden');
    marketState.currentStep = 1;
  } else if (marketState.currentStep === 3) {
    document.getElementById('step3Logistics').classList.add('hidden');
    document.getElementById('step2Prices').classList.remove('hidden');
    marketState.currentStep = 2;
  } else if (marketState.currentStep === 4) {
    document.getElementById('step4Storage').classList.add('hidden');
    document.getElementById('step3Logistics').classList.remove('hidden');
    marketState.currentStep = 3;
  } else if (marketState.currentStep === 5) {
    document.getElementById('step5Urgency').classList.add('hidden');
    document.getElementById('step4Storage').classList.remove('hidden');
    marketState.currentStep = 4;
  } else if (marketState.currentStep === 6) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step5Urgency').classList.remove('hidden');
    marketState.currentStep = 5;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  marketState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    crop: marketState.crop.name,
    bestChannel: marketState.results.bestChannel,
    totalNet: marketState.results.bestChannelTotalNet,
    storageVerdict: marketState.results.storageVerdict
  };
  localStorage.setItem('agribase_last_market_timing', JSON.stringify(resultData));
  alert('Your market selling strategy report has been saved to your browser!');
}

function downloadResult() {
  const r = marketState.results;
  let reportText = `AGRIBASE MARKET TIMING & SELLING STRATEGY REPORT\n`;
  reportText += `====================================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Crop: ${marketState.crop.name} (${marketState.crop.quantity} ${marketState.crop.unit})\n`;
  reportText += `Recommended Channel: ${r.bestChannel}\n`;
  reportText += `Total Net In Pocket: $${r.bestChannelTotalNet.toFixed(2)}\n`;
  reportText += `Storage Decision: ${r.storageVerdict}\n\n`;
  reportText += `CHANNEL NET PROFIT COMPARISON:\n`;
  r.channelComparisons.forEach((c, idx) => {
    reportText += `${idx + 1}. ${c.name}: Total Net $${c.totalNet.toFixed(2)} ($${c.netPerUnit.toFixed(2)}/unit)\n`;
    reportText += `   Deductions: ${c.cons}\n`;
  });
  reportText += `\nNEGOTIATION & MIDDLEMAN DEFENSE TIPS:\n`;
  r.negotiationTips.forEach((tip, idx) => {
    reportText += `${idx + 1}. ${tip}\n`;
  });
  reportText += `\n====================================================\n`;
  reportText += `AgriBase Decision Tools — Practical Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `market-timing-strategy-${marketState.crop.type}-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initMarketTool();
});
