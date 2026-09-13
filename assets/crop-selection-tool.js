// Crop & Farming Enterprise Selection Decision Tool - JavaScript Logic
// This tool helps farmers decide what to plant based on their money, land, water, market, and risk
// It does NOT simply recommend the most profitable crop - it finds the best fit for the farmer's situation

// State Management
const selectionState = {
  currentStep: 0,
  mode: 'standard', // standard, limited_money, limited_land, limited_water, quick_money, low_risk
  
  // Money
  money: {
    currency: 'USD',
    available: 0,
    isAllMoney: true,
    contingencyPercent: 10
  },
  
  // Land
  land: {
    amount: 0,
    unit: 'hectares',
    ownership: 'owned'
  },
  
  // Location
  location: {
    country: ''
  },
  
  // Water
  water: {
    type: '',
    reliability: '',
    capacity: 0,
    capacityUnit: 'l_per_day'
  },
  
  // Farming Method
  farming: {
    method: ''
  },
  
  // Soil
  soil: {
    type: '',
    tested: false
  },
  
  // Experience & Labour
  experience: {
    level: '',
    previousCrops: '',
    familyLabour: ''
  },
  
  // Market
  market: {
    type: '',
    distance: 0,
    distanceUnit: 'km',
    hasBuyer: '',
    payment: ''
  },
  
  // Calculated Results
  results: {
    recommended: [],
    comparisons: [],
    budgets: {}
  }
};

// Crop/Enterprise Database
// This is data-driven and can be updated without changing the UI
const enterpriseDatabase = {
  maize: {
    name: 'Maize',
    category: 'Cereal',
    waterRequirement: 'moderate',
    waterIntensity: 3, // 1-5 scale, 5 = highest water demand
    capitalIntensity: 2, // 1-5 scale, 5 = highest capital requirement
    labourIntensity: 3,
    managementDifficulty: 2,
    productionDuration: 120, // days
    marketRisk: 'low',
    priceVolatility: 'low',
    postHarvestLoss: 0.10, // 10% loss
    soilSuitability: ['loamy', 'sandy_loam', 'clay_loam'],
    waterSuitability: ['rainfall', 'irrigated', 'both'],
    climateSuitability: ['temperate', 'subtropical', 'tropical'],
    criticalStages: ['flowering', 'grain_filling'],
    typicalYield: { low: 2, expected: 4, high: 6 }, // tonnes per hectare
    typicalPrice: { low: 150, expected: 250, high: 350 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 15, description: 'Seed and planting material' },
      fertilizer: { percent: 25, description: 'Fertilizer and soil amendments' },
      labour: { percent: 20, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 10, description: 'Water application' },
      chemicals: { percent: 10, description: 'Pest and disease control' },
      transport: { percent: 10, description: 'Transport to market' },
      harvest: { percent: 5, description: 'Harvesting and post-harvest' },
      other: { percent: 5, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'low',
      market: 'low'
    },
    advantages: ['Relatively low input cost', 'Established market', 'Multiple uses', 'Can be stored'],
    disadvantages: ['Lower profit margin per unit', 'Seasonal price fluctuations', 'Requires timely rainfall or irrigation']
  },
  
  tomato: {
    name: 'Tomato',
    category: 'Vegetable',
    waterRequirement: 'high',
    waterIntensity: 5,
    capitalIntensity: 4,
    labourIntensity: 4,
    managementDifficulty: 4,
    productionDuration: 100,
    marketRisk: 'medium',
    priceVolatility: 'high',
    postHarvestLoss: 0.20,
    soilSuitability: ['loamy', 'sandy_loam'],
    waterSuitability: ['irrigated', 'both'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['flowering', 'fruit_set', 'fruit_development'],
    typicalYield: { low: 15, expected: 30, high: 50 }, // tonnes per hectare
    typicalPrice: { low: 300, expected: 500, high: 700 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 10, description: 'Seedlings and seeds' },
      fertilizer: { percent: 20, description: 'Fertilizer' },
      labour: { percent: 25, description: 'Pruning, staking, harvesting' },
      irrigation: { percent: 15, description: 'Frequent irrigation' },
      chemicals: { percent: 15, description: 'Pest and disease control' },
      transport: { percent: 10, description: 'Careful transport' },
      harvest: { percent: 3, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'high',
      pest: 'high',
      disease: 'high',
      price: 'high',
      market: 'medium'
    },
    advantages: ['High potential profit', 'Good market demand', 'Multiple production cycles per year'],
    disadvantages: ['High water requirement', 'High management difficulty', 'High pest/disease pressure', 'Perishable']
  },
  
  cabbage: {
    name: 'Cabbage',
    category: 'Vegetable',
    waterRequirement: 'moderate',
    waterIntensity: 4,
    capitalIntensity: 3,
    labourIntensity: 3,
    managementDifficulty: 3,
    productionDuration: 90,
    marketRisk: 'low',
    priceVolatility: 'medium',
    postHarvestLoss: 0.15,
    soilSuitability: ['loamy', 'sandy_loam', 'clay_loam'],
    waterSuitability: ['irrigated', 'both', 'rainfall'],
    climateSuitability: ['temperate', 'subtropical'],
    criticalStages: ['head_formation', 'head_development'],
    typicalYield: { low: 20, expected: 40, high: 60 }, // tonnes per hectare
    typicalPrice: { low: 200, expected: 350, high: 500 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 10, description: 'Seedlings' },
      fertilizer: { percent: 20, description: 'Fertilizer' },
      labour: { percent: 25, description: 'Weeding, harvesting' },
      irrigation: { percent: 15, description: 'Irrigation' },
      chemicals: { percent: 15, description: 'Pest control' },
      transport: { percent: 10, description: 'Transport' },
      harvest: { percent: 3, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'medium',
      market: 'low'
    },
    advantages: ['Good market demand', 'Can be stored', 'Moderate input cost'],
    disadvantages: ['Susceptible to pests', 'Requires consistent moisture', 'Market can be saturated']
  },
  
  onion: {
    name: 'Onion',
    category: 'Vegetable',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 3,
    labourIntensity: 3,
    managementDifficulty: 3,
    productionDuration: 120,
    marketRisk: 'medium',
    priceVolatility: 'high',
    postHarvestLoss: 0.10,
    soilSuitability: ['sandy', 'sandy_loam', 'loamy'],
    waterSuitability: ['irrigated', 'both'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['bulb_initiation', 'bulb_development'],
    typicalYield: { low: 15, expected: 30, high: 45 }, // tonnes per hectare
    typicalPrice: { low: 250, expected: 400, high: 600 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 12, description: 'Seed or sets' },
      fertilizer: { percent: 20, description: 'Fertilizer' },
      labour: { percent: 25, description: 'Weeding, harvesting, curing' },
      irrigation: { percent: 15, description: 'Irrigation' },
      chemicals: { percent: 12, description: 'Pest control' },
      transport: { percent: 10, description: 'Transport' },
      harvest: { percent: 4, description: 'Harvesting and curing' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'high',
      market: 'medium'
    },
    advantages: ['Good storage life', 'High market demand', 'Multiple uses'],
    disadvantages: ['Price volatility', 'Shallow root system', 'Curing required']
  },
  
  potato: {
    name: 'Potato',
    category: 'Tuber',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 4,
    labourIntensity: 4,
    managementDifficulty: 3,
    productionDuration: 100,
    marketRisk: 'low',
    priceVolatility: 'medium',
    postHarvestLoss: 0.15,
    soilSuitability: ['sandy', 'sandy_loam', 'loamy'],
    waterSuitability: ['irrigated', 'both', 'rainfall'],
    climateSuitability: ['temperate', 'subtropical'],
    criticalStages: ['tuber_initiation', 'tuber_bulking'],
    typicalYield: { low: 10, expected: 20, high: 30 }, // tonnes per hectare
    typicalPrice: { low: 200, expected: 350, high: 500 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 25, description: 'Seed potatoes' },
      fertilizer: { percent: 20, description: 'Fertilizer' },
      labour: { percent: 20, description: 'Planting, hilling, harvesting' },
      irrigation: { percent: 12, description: 'Irrigation' },
      chemicals: { percent: 10, description: 'Pest and disease control' },
      transport: { percent: 8, description: 'Transport' },
      harvest: { percent: 3, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'high',
      disease: 'high',
      price: 'medium',
      market: 'low'
    },
    advantages: ['Good market demand', 'Can be stored', 'High food security value'],
    disadvantages: ['High seed cost', 'Disease pressure', 'Requires good soil structure']
  },
  
  beans: {
    name: 'Beans',
    category: 'Legume',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 2,
    labourIntensity: 3,
    managementDifficulty: 2,
    productionDuration: 80,
    marketRisk: 'low',
    priceVolatility: 'medium',
    postHarvestLoss: 0.08,
    soilSuitability: ['loamy', 'sandy_loam', 'clay_loam'],
    waterSuitability: ['rainfall', 'both', 'irrigated'],
    climateSuitability: ['temperate', 'subtropical', 'tropical'],
    criticalStages: ['flowering', 'pod_filling'],
    typicalYield: { low: 0.8, expected: 1.5, high: 2.5 }, // tonnes per hectare
    typicalPrice: { low: 600, expected: 900, high: 1200 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 20, description: 'Seed' },
      fertilizer: { percent: 15, description: 'Fertilizer (lower for legumes)' },
      labour: { percent: 30, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 8, description: 'Irrigation if needed' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 10, description: 'Transport' },
      harvest: { percent: 5, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'medium',
      market: 'low'
    },
    advantages: ['Nitrogen fixation', 'Good protein source', 'Lower fertilizer need', 'Can be stored'],
    disadvantages: ['Lower yield per hectare', 'Labour intensive', 'Price fluctuations']
  },
  
  groundnuts: {
    name: 'Groundnuts',
    category: 'Legume',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 2,
    labourIntensity: 3,
    managementDifficulty: 2,
    productionDuration: 100,
    marketRisk: 'low',
    priceVolatility: 'medium',
    postHarvestLoss: 0.08,
    soilSuitability: ['sandy', 'sandy_loam'],
    waterSuitability: ['rainfall', 'both'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['flowering', 'pegging', 'pod_filling'],
    typicalYield: { low: 0.8, expected: 1.5, high: 2.5 }, // tonnes per hectare
    typicalPrice: { low: 700, expected: 1000, high: 1300 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 20, description: 'Seed' },
      fertilizer: { percent: 15, description: 'Fertilizer' },
      labour: { percent: 30, description: 'Planting, weeding, harvesting, lifting' },
      irrigation: { percent: 8, description: 'Irrigation if needed' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 10, description: 'Transport' },
      harvest: { percent: 5, description: 'Harvesting and drying' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'medium',
      market: 'low'
    },
    advantages: ['Nitrogen fixation', 'Oilseed crop', 'Good market', 'Can be stored'],
    disadvantages: ['Harvesting requires good soil moisture', 'Aflatoxin risk if not dried properly']
  },
  
  soybean: {
    name: 'Soybean',
    category: 'Legume',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 2,
    labourIntensity: 2,
    managementDifficulty: 2,
    productionDuration: 100,
    marketRisk: 'medium',
    priceVolatility: 'medium',
    postHarvestLoss: 0.05,
    soilSuitability: ['loamy', 'sandy_loam', 'clay_loam'],
    waterSuitability: ['rainfall', 'both', 'irrigated'],
    climateSuitability: ['temperate', 'subtropical', 'tropical'],
    criticalStages: ['flowering', 'pod_filling'],
    typicalYield: { low: 1.0, expected: 2.0, high: 3.0 }, // tonnes per hectare
    typicalPrice: { low: 400, expected: 600, high: 800 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 18, description: 'Seed' },
      fertilizer: { percent: 15, description: 'Fertilizer' },
      labour: { percent: 25, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 8, description: 'Irrigation if needed' },
      chemicals: { percent: 12, description: 'Pest control' },
      transport: { percent: 12, description: 'Transport' },
      harvest: { percent: 8, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'medium',
      market: 'medium'
    },
    advantages: ['Nitrogen fixation', 'Industrial market', 'Lower labour', 'Can be stored'],
    disadvantages: ['Market volatility', 'Requires specific buyer', 'Processing often needed']
  },
  
  sorghum: {
    name: 'Sorghum',
    category: 'Cereal',
    waterRequirement: 'low',
    waterIntensity: 2,
    capitalIntensity: 1,
    labourIntensity: 2,
    managementDifficulty: 1,
    productionDuration: 110,
    marketRisk: 'low',
    priceVolatility: 'low',
    postHarvestLoss: 0.08,
    soilSuitability: ['sandy', 'sandy_loam', 'loamy', 'clay_loam'],
    waterSuitability: ['rainfall', 'both'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['flowering', 'grain_filling'],
    typicalYield: { low: 1.5, expected: 3.0, high: 4.5 }, // tonnes per hectare
    typicalPrice: { low: 180, expected: 280, high: 380 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 15, description: 'Seed' },
      fertilizer: { percent: 20, description: 'Fertilizer' },
      labour: { percent: 25, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 5, description: 'Minimal irrigation' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 15, description: 'Transport' },
      harvest: { percent: 8, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'low',
      pest: 'low',
      disease: 'low',
      price: 'low',
      market: 'low'
    },
    advantages: ['Drought tolerant', 'Low input cost', 'Low risk', 'Can be stored'],
    disadvantages: ['Lower market price', 'Lower profit margin', 'Limited uses']
  },
  
  millet: {
    name: 'Millet',
    category: 'Cereal',
    waterRequirement: 'low',
    waterIntensity: 1,
    capitalIntensity: 1,
    labourIntensity: 2,
    managementDifficulty: 1,
    productionDuration: 90,
    marketRisk: 'low',
    priceVolatility: 'low',
    postHarvestLoss: 0.05,
    soilSuitability: ['sandy', 'sandy_loam', 'loamy'],
    waterSuitability: ['rainfall'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['flowering', 'grain_filling'],
    typicalYield: { low: 1.0, expected: 2.0, high: 3.0 }, // tonnes per hectare
    typicalPrice: { low: 250, expected: 350, high: 450 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 15, description: 'Seed' },
      fertilizer: { percent: 15, description: 'Fertilizer' },
      labour: { percent: 30, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 3, description: 'Minimal irrigation' },
      chemicals: { percent: 8, description: 'Pest control' },
      transport: { percent: 15, description: 'Transport' },
      harvest: { percent: 12, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'low',
      pest: 'low',
      disease: 'low',
      price: 'low',
      market: 'low'
    },
    advantages: ['Very drought tolerant', 'Very low input cost', 'Low risk', 'Food security crop'],
    disadvantages: ['Limited market', 'Lower profit margin', 'Labour intensive harvesting']
  },
  
  sweet_potato: {
    name: 'Sweet potato',
    category: 'Root',
    waterRequirement: 'moderate',
    waterIntensity: 3,
    capitalIntensity: 2,
    labourIntensity: 3,
    managementDifficulty: 2,
    productionDuration: 110,
    marketRisk: 'low',
    priceVolatility: 'low',
    postHarvestLoss: 0.10,
    soilSuitability: ['sandy', 'sandy_loam', 'loamy'],
    waterSuitability: ['rainfall', 'both'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['vine_establishment', 'root_development'],
    typicalYield: { low: 8, expected: 15, high: 25 }, // tonnes per hectare
    typicalPrice: { low: 150, expected: 250, high: 350 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 10, description: 'Vines/cuttings' },
      fertilizer: { percent: 15, description: 'Fertilizer' },
      labour: { percent: 30, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 8, description: 'Irrigation if needed' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 15, description: 'Transport' },
      harvest: { percent: 10, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'low',
      pest: 'medium',
      disease: 'medium',
      price: 'low',
      market: 'low'
    },
    advantages: ['Food security', 'Low input cost', 'Can be stored', 'Multiple uses'],
    disadvantages: ['Lower market price', 'Perishable if not cured', 'Labour intensive']
  },
  
  watermelon: {
    name: 'Watermelon',
    category: 'Fruit',
    waterRequirement: 'moderate',
    waterIntensity: 4,
    capitalIntensity: 2,
    labourIntensity: 3,
    managementDifficulty: 2,
    productionDuration: 90,
    marketRisk: 'medium',
    priceVolatility: 'high',
    postHarvestLoss: 0.15,
    soilSuitability: ['sandy', 'sandy_loam'],
    waterSuitability: ['irrigated', 'both', 'rainfall'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['flowering', 'fruit_set', 'fruit_development'],
    typicalYield: { low: 15, expected: 30, high: 50 }, // tonnes per hectare
    typicalPrice: { low: 100, expected: 200, high: 300 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 12, description: 'Seed' },
      fertilizer: { percent: 18, description: 'Fertilizer' },
      labour: { percent: 30, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 15, description: 'Irrigation' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 10, description: 'Transport' },
      harvest: { percent: 3, description: 'Harvesting' },
      other: { percent: 2, description: 'Other expenses' }
    },
    risks: {
      weather: 'medium',
      pest: 'medium',
      disease: 'medium',
      price: 'high',
      market: 'medium'
    },
    advantages: ['High yield potential', 'Quick cash crop', 'Good market demand'],
    disadvantages: ['Perishable', 'Price volatility', 'Requires good transport']
  },
  
  leafy_vegetables: {
    name: 'Leafy Vegetables',
    category: 'Vegetable',
    waterRequirement: 'high',
    waterIntensity: 5,
    capitalIntensity: 3,
    labourIntensity: 4,
    managementDifficulty: 3,
    productionDuration: 30,
    marketRisk: 'medium',
    priceVolatility: 'medium',
    postHarvestLoss: 0.25,
    soilSuitability: ['loamy', 'sandy_loam', 'clay_loam'],
    waterSuitability: ['irrigated'],
    climateSuitability: ['subtropical', 'tropical'],
    criticalStages: ['seedling', 'leaf_development'],
    typicalYield: { low: 5, expected: 10, high: 15 }, // tonnes per hectare
    typicalPrice: { low: 500, expected: 800, high: 1200 }, // per tonne (USD reference)
    budget: {
      seed: { percent: 10, description: 'Seed' },
      fertilizer: { percent: 15, description: 'Fertilizer' },
      labour: { percent: 35, description: 'Planting, weeding, harvesting' },
      irrigation: { percent: 20, description: 'Frequent irrigation' },
      chemicals: { percent: 10, description: 'Pest control' },
      transport: { percent: 8, description: 'Transport' },
      harvest: { percent: 2, description: 'Harvesting' },
      other: { percent: 0, description: 'Other expenses' }
    },
    risks: {
      weather: 'high',
      pest: 'high',
      disease: 'high',
      price: 'medium',
      market: 'medium'
    },
    advantages: ['Quick cash', 'High price per unit', 'Multiple cycles per year'],
    disadvantages: ['Very perishable', 'High water requirement', 'High labour', 'Very high post-harvest loss']
  }
};

// Navigation Functions
function startStandardMode() {
  selectionState.mode = 'standard';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function startLimitedMoneyMode() {
  selectionState.mode = 'limited_money';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function startLimitedLandMode() {
  selectionState.mode = 'limited_land';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function startLimitedWaterMode() {
  selectionState.mode = 'limited_water';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function startQuickMoneyMode() {
  selectionState.mode = 'quick_money';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function startLowRiskMode() {
  selectionState.mode = 'low_risk';
  showSection('moneySection');
  updateProgress(1);
  selectionState.currentStep = 1;
}

function showSection(sectionId) {
  const sections = document.querySelectorAll('.tool-section');
  sections.forEach(section => section.classList.add('hidden'));

  const targetSection = document.getElementById(sectionId);
  if (targetSection) {
    targetSection.classList.remove('hidden');
  }
}

function updateProgress(step) {
  const progressSteps = document.querySelectorAll('.progress-step');
  progressSteps.forEach((progressStep, index) => {
    progressStep.classList.remove('active', 'completed');
    if (index + 1 === step) {
      progressStep.classList.add('active');
    } else if (index + 1 < step) {
      progressStep.classList.add('completed');
    }
  });
}

function goBack() {
  const stepBack = selectionState.currentStep - 1;
  if (stepBack >= 0) {
    selectionState.currentStep = stepBack;
    navigateToStep(stepBack);
  }
}

function navigateToStep(step) {
  updateProgress(step);
  switch(step) {
    case 0:
      showSection('startScreen');
      break;
    case 1:
      showSection('moneySection');
      break;
    case 2:
      showSection('landSection');
      break;
    case 3:
      showSection('locationSection');
      break;
    case 4:
      showSection('waterSection');
      break;
    case 5:
      showSection('methodSection');
      break;
    case 6:
      showSection('soilSection');
      break;
    case 7:
      showSection('experienceSection');
      break;
    case 8:
      showSection('marketSection');
      break;
    case 9:
      showSection('finalResult');
      break;
  }
}

function toggleWhy(id) {
  const whyElement = document.getElementById(id + 'Why');
  if (whyElement) {
    whyElement.parentElement.classList.toggle('show');
    const arrow = whyElement.parentElement.querySelector('.why-matters-title span');
    if (arrow) {
      arrow.textContent = whyElement.parentElement.classList.contains('show') ? '▲' : '▼';
    }
  }
}

// Money Section
function selectMoneyType(type) {
  const buttons = document.querySelectorAll('[data-money]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-money="${type}"]`).classList.add('selected');
  selectionState.money.isAllMoney = type === 'all';
}

function confirmMoney() {
  const currency = document.getElementById('currencySelect').value;
  const availableMoney = document.getElementById('availableMoney').value;
  const contingencyPercent = document.getElementById('contingencyPercent').value;

  if (!availableMoney) {
    alert('Please enter your available money');
    return;
  }

  selectionState.money.currency = currency;
  selectionState.money.available = parseFloat(availableMoney);
  selectionState.money.contingencyPercent = parseFloat(contingencyPercent) || 10;

  selectionState.currentStep = 2;
  showSection('landSection');
  updateProgress(2);
}

// Land Section
function selectLandOwnership(ownership) {
  const buttons = document.querySelectorAll('[data-ownership]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-ownership="${ownership}"]`).classList.add('selected');
  selectionState.land.ownership = ownership;
}

function confirmLand() {
  const landAmount = document.getElementById('landAmount').value;
  const landUnit = document.getElementById('landUnit').value;

  if (!landAmount) {
    alert('Please enter your land amount');
    return;
  }

  selectionState.land.amount = parseFloat(landAmount);
  selectionState.land.unit = landUnit;

  selectionState.currentStep = 3;
  showSection('locationSection');
  updateProgress(3);
}

// Location Section
function confirmLocation() {
  const country = document.getElementById('countrySelect').value;

  if (!country) {
    alert('Please select your country');
    return;
  }

  selectionState.location.country = country;

  selectionState.currentStep = 4;
  showSection('waterSection');
  updateProgress(4);
}

// Water Section
function selectWater(type) {
  const buttons = document.querySelectorAll('[data-water]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-water="${type}"]`).classList.add('selected');
  selectionState.water.type = type;
}

function selectWaterReliability(reliability) {
  const buttons = document.querySelectorAll('[data-reliability]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-reliability="${reliability}"]`).classList.add('selected');
  selectionState.water.reliability = reliability;
}

function confirmWater() {
  const waterCapacity = document.getElementById('waterCapacity').value;
  const waterCapacityUnit = document.getElementById('waterCapacityUnit').value;

  selectionState.water.capacity = parseFloat(waterCapacity) || 0;
  selectionState.water.capacityUnit = waterCapacityUnit;

  selectionState.currentStep = 5;
  showSection('methodSection');
  updateProgress(5);
}

// Farming Method Section
function selectFarmingMethod(method) {
  const buttons = document.querySelectorAll('[data-method]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-method="${method}"]`).classList.add('selected');
  selectionState.farming.method = method;
}

function confirmMethod() {
  if (!selectionState.farming.method) {
    alert('Please select your farming method');
    return;
  }

  selectionState.currentStep = 6;
  showSection('soilSection');
  updateProgress(6);
}

// Soil Section
function selectSoil(type) {
  const buttons = document.querySelectorAll('[data-soil]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-soil="${type}"]`).classList.add('selected');
  selectionState.soil.type = type;
}

function selectSoilTest(tested) {
  const buttons = document.querySelectorAll('[data-test]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-test="${tested}"]`).classList.add('selected');
  selectionState.soil.tested = tested === 'yes';
}

function confirmSoil() {
  if (!selectionState.soil.type) {
    alert('Please select your soil type');
    return;
  }

  selectionState.currentStep = 7;
  showSection('experienceSection');
  updateProgress(7);
}

// Experience Section
function selectExperience(level) {
  const buttons = document.querySelectorAll('[data-experience]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-experience="${level}"]`).classList.add('selected');
  selectionState.experience.level = level;
}

function selectFamilyLabour(labour) {
  const buttons = document.querySelectorAll('[data-family-labour]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-family-labour="${labour}"]`).classList.add('selected');
  selectionState.experience.familyLabour = labour;
}

function confirmExperience() {
  const previousCrops = document.getElementById('previousCrops').value;

  if (!selectionState.experience.level) {
    alert('Please select your experience level');
    return;
  }

  selectionState.experience.previousCrops = previousCrops;

  selectionState.currentStep = 8;
  showSection('marketSection');
  updateProgress(8);
}

// Market Section
function selectMarket(type) {
  const buttons = document.querySelectorAll('[data-market]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-market="${type}"]`).classList.add('selected');
  selectionState.market.type = type;
}

function selectBuyer(buyer) {
  const buttons = document.querySelectorAll('[data-buyer]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-buyer="${buyer}"]`).classList.add('selected');
  selectionState.market.hasBuyer = buyer;
}

function selectPayment(payment) {
  const buttons = document.querySelectorAll('[data-payment]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-payment="${payment}"]`).classList.add('selected');
  selectionState.market.payment = payment;
}

function confirmMarket() {
  const marketDistance = document.getElementById('marketDistance').value;
  const distanceUnit = document.getElementById('distanceUnit').value;

  if (!selectionState.market.type) {
    alert('Please select your market type');
    return;
  }

  selectionState.market.distance = parseFloat(marketDistance) || 0;
  selectionState.market.distanceUnit = distanceUnit;

  calculateResults();
  selectionState.currentStep = 9;
  showSection('finalResult');
  updateProgress(9);
}

// Main Calculation Function
function calculateResults() {
  const state = selectionState;
  const results = state.results;

  // Calculate usable money after contingency
  const contingencyAmount = state.money.available * (state.money.contingencyPercent / 100);
  const usableMoney = state.money.available - contingencyAmount;

  // Convert land to hectares
  let landInHectares = state.land.amount;
  if (state.land.unit === 'acres') {
    landInHectares = state.land.amount * 0.404686;
  } else if (state.land.unit === 'sqm') {
    landInHectares = state.land.amount / 10000;
  }

  // Score each enterprise
  const scoredEnterprises = [];
  Object.keys(enterpriseDatabase).forEach(key => {
    const enterprise = enterpriseDatabase[key];
    const score = calculateSuitabilityScore(enterprise, state, usableMoney, landInHectares);
    scoredEnterprises.push({
      key: key,
      name: enterprise.name,
      score: score,
      enterprise: enterprise
    });
  });

  // Sort by score (highest first)
  scoredEnterprises.sort((a, b) => b.score.total - a.score.total);

  // Apply mode-specific filtering
  if (state.mode === 'limited_money') {
    // Prioritize enterprises that fit the budget
    scoredEnterprises.sort((a, b) => b.score.capitalFit - a.score.capitalFit);
  } else if (state.mode === 'limited_water') {
    // Prioritize water-efficient enterprises
    scoredEnterprises.sort((a, b) => a.enterprise.waterIntensity - b.enterprise.waterIntensity);
  } else if (state.mode === 'quick_money') {
    // Prioritize short-duration enterprises
    scoredEnterprises.sort((a, b) => a.enterprise.productionDuration - b.enterprise.productionDuration);
  } else if (state.mode === 'low_risk') {
    // Prioritize low-risk enterprises
    scoredEnterprises.sort((a, b) => b.score.riskScore - a.score.riskScore);
  }

  results.recommended = scoredEnterprises.slice(0, 3);
  results.budgets = calculateBudgets(results.recommended, usableMoney, landInHectares);

  // Update UI
  updateResultsUI(usableMoney, landInHectares, contingencyAmount);
}

function calculateSuitabilityScore(enterprise, state, usableMoney, landInHectares) {
  const score = {
    capitalFit: 0,
    waterFit: 0,
    soilFit: 0,
    marketFit: 0,
    experienceFit: 0,
    riskScore: 0,
    profitPotential: 0,
    total: 0
  };

  // Capital fit (0-10)
  const capitalIntensity = enterprise.capitalIntensity;
  if (usableMoney < 500) {
    score.capitalFit = capitalIntensity <= 2 ? 10 : capitalIntensity <= 3 ? 5 : 0;
  } else if (usableMoney < 2000) {
    score.capitalFit = capitalIntensity <= 3 ? 10 : capitalIntensity <= 4 ? 5 : 0;
  } else {
    score.capitalFit = 10;
  }

  // Water fit (0-10)
  const waterType = state.water.type;
  const waterReliability = state.water.reliability;
  const waterIntensity = enterprise.waterIntensity;

  if (waterType === 'none' || waterType === 'rainfall') {
    // Only rain-fed suitable
    score.waterFit = waterIntensity <= 2 ? 10 : waterIntensity <= 3 ? 5 : 0;
  } else if (waterReliability === 'very' || waterReliability === 'mostly') {
    // Good water availability
    score.waterFit = 10;
  } else if (waterReliability === 'seasonal') {
    score.waterFit = waterIntensity <= 3 ? 8 : waterIntensity <= 4 ? 5 : 2;
  } else {
    score.waterFit = waterIntensity <= 3 ? 7 : waterIntensity <= 4 ? 4 : 1;
  }

  // Soil fit (0-10)
  const soilType = state.soil.type;
  if (enterprise.soilSuitability.includes(soilType)) {
    score.soilFit = 10;
  } else if (soilType === 'not_sure') {
    score.soilFit = 5;
  } else {
    score.soilFit = 2;
  }

  // Market fit (0-10)
  const hasBuyer = state.market.hasBuyer;
  const marketType = state.market.type;
  const marketRisk = enterprise.marketRisk;

  if (hasBuyer === 'yes') {
    score.marketFit = 10;
  } else if (hasBuyer === 'looking') {
    score.marketFit = marketRisk === 'low' ? 7 : marketRisk === 'medium' ? 5 : 3;
  } else {
    score.marketFit = marketRisk === 'low' ? 5 : marketRisk === 'medium' ? 3 : 1;
  }

  // Experience fit (0-10)
  const experienceLevel = state.experience.level;
  const managementDifficulty = enterprise.managementDifficulty;

  if (experienceLevel === 'very') {
    score.experienceFit = 10;
  } else if (experienceLevel === 'experienced') {
    score.experienceFit = managementDifficulty <= 3 ? 10 : managementDifficulty <= 4 ? 7 : 4;
  } else if (experienceLevel === 'some') {
    score.experienceFit = managementDifficulty <= 2 ? 10 : managementDifficulty <= 3 ? 6 : 3;
  } else {
    score.experienceFit = managementDifficulty <= 1 ? 10 : managementDifficulty <= 2 ? 5 : 2;
  }

  // Risk score (0-10, higher is better = lower risk)
  const risks = enterprise.risks;
  let riskSum = 0;
  Object.values(risks).forEach(risk => {
    if (risk === 'low') riskSum += 2;
    else if (risk === 'medium') riskSum += 1;
    else riskSum += 0;
  });
  score.riskScore = (riskSum / 5) * 10;

  // Profit potential (0-10, simplified based on price and yield)
  const expectedYield = enterprise.typicalYield.expected;
  const expectedPrice = enterprise.typicalPrice.expected;
  const profitIndex = (expectedYield * expectedPrice) / 1000;
  score.profitPotential = Math.min(10, profitIndex);

  // Total score (weighted average)
  const weights = {
    capitalFit: 0.25,
    waterFit: 0.20,
    soilFit: 0.10,
    marketFit: 0.20,
    experienceFit: 0.10,
    riskScore: 0.10,
    profitPotential: 0.05
  };

  score.total = 
    score.capitalFit * weights.capitalFit +
    score.waterFit * weights.waterFit +
    score.soilFit * weights.soilFit +
    score.marketFit * weights.marketFit +
    score.experienceFit * weights.experienceFit +
    score.riskScore * weights.riskScore +
    score.profitPotential * weights.profitPotential;

  return score;
}

function calculateBudgets(recommended, usableMoney, landInHectares) {
  const budgets = {};

  recommended.forEach(item => {
    const enterprise = item.enterprise;
    const budget = {
      total: usableMoney,
      breakdown: {},
      costs: {}
    };

    // Calculate costs based on budget percentages
    Object.keys(enterprise.budget).forEach(category => {
      const amount = usableMoney * (enterprise.budget[category].percent / 100);
      budget.breakdown[category] = {
        amount: amount,
        percent: enterprise.budget[category].percent,
        description: enterprise.budget[category].description
      };
    });

    // Calculate estimated revenue (simplified)
    const expectedYield = enterprise.typicalYield.expected * landInHectares;
    const expectedPrice = enterprise.typicalPrice.expected;
    const grossRevenue = expectedYield * expectedPrice;
    const postHarvestLoss = grossRevenue * enterprise.postHarvestLoss;
    const netRevenue = grossRevenue - postHarvestLoss;
    const estimatedProfit = netRevenue - usableMoney;
    const profitMargin = usableMoney > 0 ? (estimatedProfit / netRevenue) * 100 : 0;
    const roi = usableMoney > 0 ? (estimatedProfit / usableMoney) * 100 : 0;

    budget.revenue = {
      gross: grossRevenue,
      postHarvestLoss: postHarvestLoss,
      net: netRevenue,
      profit: estimatedProfit,
      profitMargin: profitMargin,
      roi: roi
    };

    budgets[item.key] = budget;
  });

  return budgets;
}

function updateResultsUI(usableMoney, landInHectares, contingencyAmount) {
  const state = selectionState;
  const results = state.results;

  // Update farmer information
  document.getElementById('resultMoney').textContent = `${state.money.currency} ${state.money.available.toLocaleString()}`;
  document.getElementById('resultLand').textContent = `${state.land.amount} ${state.land.unit}`;
  document.getElementById('resultWater').textContent = `${state.water.type} (${state.water.reliability})`;
  document.getElementById('resultLocation').textContent = state.location.country;
  document.getElementById('resultMethod').textContent = state.farming.method;

  // Update recommended enterprises
  if (results.recommended.length >= 1) {
    const first = results.recommended[0];
    document.getElementById('firstChoiceName').textContent = first.name;
    document.getElementById('firstChoiceScore').textContent = `FIT: ${getFitLabel(first.score.total)}`;
    document.getElementById('firstChoiceReasons').innerHTML = generateReasons(first, state);
    document.getElementById('firstChoiceInfo').innerHTML = generateEnterpriseInfo(first, results.budgets[first.key], state);
  }

  if (results.recommended.length >= 2) {
    const second = results.recommended[1];
    document.getElementById('secondChoiceName').textContent = second.name;
    document.getElementById('secondChoicePros').innerHTML = generatePros(second, state);
    document.getElementById('secondChoiceCons').innerHTML = generateCons(second, state);
  }

  if (results.recommended.length >= 3) {
    const third = results.recommended[2];
    document.getElementById('thirdChoiceName').textContent = third.name;
    document.getElementById('thirdChoicePros').innerHTML = generatePros(third, state);
    document.getElementById('thirdChoiceCons').innerHTML = generateCons(third, state);
  }

  // Update decision matrix
  updateDecisionMatrix(results.recommended);

  // Update "Why not others"
  updateWhyNotOthers(results.recommended);

  // Update budget breakdown
  if (results.recommended.length >= 1) {
    updateBudgetBreakdown(results.budgets[results.recommended[0].key], state);
  }

  // Update profit threats
  updateProfitThreats(results.recommended[0]);

  // Update action plan
  updateActionPlan(results.recommended[0]);

  // Show no buyer warning if applicable
  if (state.market.hasBuyer !== 'yes') {
    document.getElementById('noBuyerWarning').style.display = 'block';
  }
}

function getFitLabel(score) {
  if (score >= 8) return 'HIGH';
  if (score >= 6) return 'GOOD';
  if (score >= 4) return 'MODERATE';
  return 'LOW';
}

function generateReasons(enterprise, state) {
  const reasons = [];
  const score = enterprise.score;

  if (score.capitalFit >= 8) {
    reasons.push('It fits your available capital.');
  }
  if (score.waterFit >= 8) {
    reasons.push('Your available water is suitable for this enterprise.');
  }
  if (score.marketFit >= 8) {
    reasons.push('Your market access is favorable.');
  }
  if (score.experienceFit >= 8) {
    reasons.push('Your experience level matches the management requirements.');
  }
  if (score.riskScore >= 7) {
    reasons.push('The risk level is manageable for your situation.');
  }
  if (enterprise.enterprise.productionDuration <= 90) {
    reasons.push('The production duration is relatively short, providing faster cash flow.');
  }

  return reasons.map(r => `<p>• ${r}</p>`).join('');
}

function generateEnterpriseInfo(enterprise, budget, state) {
  const info = [];
  info.push(`<p><strong>Estimated investment:</strong> ${state.money.currency} ${budget.total.toLocaleString()}</p>`);
  info.push(`<p><strong>Production duration:</strong> ${enterprise.enterprise.productionDuration} days</p>`);
  info.push(`<p><strong>Water requirement:</strong> ${enterprise.enterprise.waterRequirement}</p>`);
  info.push(`<p><strong>Estimated ROI:</strong> ${budget.revenue.roi.toFixed(1)}%</p>`);
  info.push(`<p><strong>Risk level:</strong> ${enterprise.enterprise.risks.weather}</p>`);
  return info.join('');
}

function generatePros(enterprise, state) {
  return enterprise.enterprise.advantages.map(a => `<p>• ${a}</p>`).join('');
}

function generateCons(enterprise, state) {
  return enterprise.enterprise.disadvantages.map(d => `<p>• ${d}</p>`).join('');
}

function updateDecisionMatrix(recommended) {
  const matrix = document.getElementById('decisionMatrix');
  let html = '<table class="comparison-table"><thead><tr><th>Factor</th>';
  
  recommended.forEach((item, index) => {
    html += `<th>${item.name}</th>`;
  });
  
  html += '</tr></thead><tbody>';
  
  const factors = [
    { name: 'Capital fit', key: 'capitalFit' },
    { name: 'Water fit', key: 'waterFit' },
    { name: 'Soil fit', key: 'soilFit' },
    { name: 'Market fit', key: 'marketFit' },
    { name: 'Risk', key: 'riskScore' },
    { name: 'Profit potential', key: 'profitPotential' }
  ];

  factors.forEach(factor => {
    html += `<tr><td>${factor.name}</td>`;
    recommended.forEach(item => {
      const score = item.score[factor.key];
      const fitClass = score >= 7 ? 'fit-good' : score >= 4 ? 'fit-moderate' : 'fit-poor';
      html += `<td><span class="fit-indicator ${fitClass}"></span> ${score.toFixed(1)}</td>`;
    });
    html += '</tr>';
  });

  html += '</tbody></table>';
  matrix.innerHTML = html;
}

function updateWhyNotOthers(recommended) {
  const whyNot = document.getElementById('whyNotOthers');
  if (recommended.length < 2) {
    whyNot.innerHTML = '<p>Need more enterprises to compare.</p>';
    return;
  }

  const first = recommended[0];
  const second = recommended[1];
  
  let explanation = `<p><strong>Why not ${second.name}?</strong></p>`;
  
  if (first.score.capitalFit > second.score.capitalFit + 2) {
    explanation += `<p>${second.name} requires more capital relative to your available money.</p>`;
  }
  if (first.score.waterFit > second.score.waterFit + 2) {
    explanation += `<p>${second.name} has higher water requirements that may not match your available water.</p>`;
  }
  if (first.score.marketFit > second.score.marketFit + 2) {
    explanation += `<p>${second.name} has higher market risk or requires better market access.</p>`;
  }
  if (first.score.riskScore > second.score.riskScore + 2) {
    explanation += `<p>${second.name} carries higher production or price risk.</p>`;
  }
  if (first.score.experienceFit > second.score.experienceFit + 2) {
    explanation += `<p>${second.name} requires more technical management experience.</p>`;
  }

  whyNot.innerHTML = explanation;
}

function updateBudgetBreakdown(budget, state) {
  const breakdown = document.getElementById('budgetBreakdown');
  let html = '';

  Object.keys(budget.breakdown).forEach(category => {
    const item = budget.breakdown[category];
    html += `
      <div class="budget-item">
        <div class="budget-item-label">${item.description}</div>
        <div class="budget-item-value">${state.money.currency} ${item.amount.toLocaleString(undefined, { maximumFractionDigits: 0 })}</div>
        <div class="budget-item-percent">${item.percent}%</div>
        <div class="percentage-bar">
          <div class="percentage-fill" style="width: ${item.percent}%"></div>
        </div>
      </div>
    `;
  });

  breakdown.innerHTML = html;
}

function updateProfitThreats(enterprise) {
  const threats = document.getElementById('profitThreats');
  const ent = enterprise.enterprise;
  
  let html = '<ol>';
  html += `<li><strong>Selling price:</strong> If price falls significantly, your profit may fall sharply. Market volatility: ${ent.priceVolatility}.</li>`;
  html += `<li><strong>Yield:</strong> Poor crop establishment or pest/disease problems can reduce saleable production. Post-harvest loss: ${(ent.postHarvestLoss * 100).toFixed(0)}%.</li>`;
  html += `<li><strong>Water:</strong> Insufficient or expensive water can reduce production or increase costs. Water requirement: ${ent.waterRequirement}.</li>`;
  html += `<li><strong>Market access:</strong> Transport and weak prices can reduce the amount you actually receive. Market risk: ${ent.marketRisk}.</li>`;
  html += `<li><strong>Management:</strong> This enterprise requires ${ent.managementDifficulty <= 2 ? 'low' : ent.managementDifficulty <= 3 ? 'moderate' : 'high'} management skill. Poor management can significantly reduce results.</li>`;
  html += '</ol>';

  threats.innerHTML = html;
}

function updateActionPlan(enterprise) {
  const actionPlan = document.getElementById('actionPlan');
  const actions = [
    'Check your soil pH and fertility where possible.',
    'Confirm your water availability and reliability.',
    'Check current local prices for inputs and produce.',
    'Speak to at least 2-3 potential buyers and confirm expected price, quantity, quality, and payment terms.',
    'Confirm seed/input prices before purchasing.',
    'Calculate transport costs to your market.',
    'Check the production calendar and planting window.',
    'Keep an emergency reserve for unexpected problems.',
    'Start with an area you can properly manage.',
    'Recalculate the budget using actual local prices before committing your money.'
  ];

  actionPlan.innerHTML = actions.map(action => `<li>${action}</li>`).join('');
}

// Save and Download Functions
function saveResult() {
  const state = selectionState;
  const result = {
    date: new Date().toISOString(),
    mode: state.mode,
    money: state.money,
    land: state.land,
    location: state.location,
    water: state.water,
    farming: state.farming,
    soil: state.soil,
    experience: state.experience,
    market: state.market,
    results: state.results
  };

  try {
    const savedResults = JSON.parse(localStorage.getItem('cropSelectionResults') || '[]');
    savedResults.push(result);
    localStorage.setItem('cropSelectionResults', JSON.stringify(savedResults));
    alert('Your decision has been saved locally on this device.');
  } catch (e) {
    alert('Could not save result. Your browser may not support local storage.');
  }
}

function downloadResult() {
  const state = selectionState;
  const result = generateResultText();

  const blob = new Blob([result], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `crop-selection-${new Date().toISOString().split('T')[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function generateResultText() {
  const state = selectionState;
  const results = state.results;

  let text = `CROP & FARMING ENTERPRISE SELECTION DECISION\n`;
  text += `=============================================\n\n`;
  text += `Date: ${new Date().toLocaleDateString()}\n`;
  text += `Mode: ${state.mode}\n\n`;

  text += `YOUR INFORMATION\n`;
  text += `================\n`;
  text += `Available money: ${state.money.currency} ${state.money.available}\n`;
  text += `Land: ${state.land.amount} ${state.land.unit}\n`;
  text += `Location: ${state.location.country}\n`;
  text += `Water: ${state.water.type} (${state.water.reliability})\n`;
  text += `Farming method: ${state.farming.method}\n`;
  text += `Soil: ${state.soil.type}\n`;
  text += `Experience: ${state.experience.level}\n`;
  text += `Market: ${state.market.type}\n`;
  text += `Has buyer: ${state.market.hasBuyer}\n\n`;

  text += `RECOMMENDED ENTERPRISES\n`;
  text += `========================\n`;
  results.recommended.forEach((item, index) => {
    text += `\n${index + 1}. ${item.name}\n`;
    text += `   Overall fit score: ${item.score.total.toFixed(1)}/10\n`;
    text += `   Capital fit: ${item.score.capitalFit.toFixed(1)}/10\n`;
    text += `   Water fit: ${item.score.waterFit.toFixed(1)}/10\n`;
    text += `   Soil fit: ${item.score.soilFit.toFixed(1)}/10\n`;
    text += `   Market fit: ${item.score.marketFit.toFixed(1)}/10\n`;
    text += `   Experience fit: ${item.score.experienceFit.toFixed(1)}/10\n`;
    text += `   Risk score: ${item.score.riskScore.toFixed(1)}/10\n`;
    text += `   Profit potential: ${item.score.profitPotential.toFixed(1)}/10\n`;
  });

  text += `\n\nDISCLAIMER\n`;
  text += `==========\n`;
  text += `This calculator is a decision-support tool, not a guarantee of profit. Farming results depend on actual weather, production management, input prices, yields, market prices, losses and other local conditions. Use current local prices and confirm your market before committing your money. The recommendations are based on the information you provided and available agricultural data. Always use your own judgment and local knowledge. Consult local agricultural extension services for precise local recommendations.\n`;

  return text;
}

function restartTool() {
  // Reset state
  selectionState.currentStep = 0;
  selectionState.mode = 'standard';
  selectionState.money = { currency: 'USD', available: 0, isAllMoney: true, contingencyPercent: 10 };
  selectionState.land = { amount: 0, unit: 'hectares', ownership: 'owned' };
  selectionState.location = { country: '' };
  selectionState.water = { type: '', reliability: '', capacity: 0, capacityUnit: 'l_per_day' };
  selectionState.farming = { method: '' };
  selectionState.soil = { type: '', tested: false };
  selectionState.experience = { level: '', previousCrops: '', familyLabour: '' };
  selectionState.market = { type: '', distance: 0, distanceUnit: 'km', hasBuyer: '', payment: '' };
  selectionState.results = { recommended: [], comparisons: [], budgets: {} };

  // Reset UI
  document.querySelectorAll('.option-button').forEach(btn => btn.classList.remove('selected'));
  document.querySelectorAll('.form-input').forEach(input => input.value = '');
  document.querySelectorAll('.form-select').forEach(select => select.selectedIndex = 0);
  document.querySelectorAll('.hidden').forEach(el => {
    if (el.id !== 'startScreen') {
      el.classList.add('hidden');
    }
  });

  // Show start screen
  showSection('startScreen');
  updateProgress(0);
}