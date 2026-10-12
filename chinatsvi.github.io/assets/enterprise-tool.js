// Farm Enterprise Profitability Calculator - JavaScript Logic
// This tool provides decision support, not guarantees of success
// Always use local knowledge and extension advice alongside this tool

// State Management
const enterpriseState = {
  currentStep: 0,
  isComparison: false,
  comparisonEnterprises: [],
  
  // Farm Information
  farm: {
    country: '',
    goal: ''
  },
  
  // Enterprise Selection
  enterprise: {
    type: '',
    name: '',
    scale: 0,
    scaleUnit: 'hectares'
  },
  
  // Capital
  capital: {
    currency: 'USD',
    available: 0,
    type: '',
    contingencyPercent: 10
  },
  
  // Resources
  resources: {
    land: {
      amount: 0,
      unit: 'hectares',
      type: ''
    },
    water: '',
    waterAvailability: '',
    labour: '',
    workers: 0,
    dailyWage: 0
  },
  
  // Production Costs
  costs: {},
  
  // Production and Market
  production: {
    expected: 0,
    unit: 'kg',
    sellingPrice: 0,
    priceLevel: '',
    lossPercent: 10,
    marketDistance: 0,
    distanceUnit: 'km',
    transportCost: 0,
    tripsCount: 0
  },
  
  // Market Analysis
  market: {
    where: '',
    confirmedBuyer: '',
    buyerCount: '',
    perishability: '',
    storage: ''
  },
  
  // Experience and Risk
  experience: {
    level: '',
    concern: ''
  },
  
  // Calculated Results
  results: {
    totalCost: 0,
    contingencyAmount: 0,
    totalFunding: 0,
    marketableProduction: 0,
    grossRevenue: 0,
    variableCosts: 0,
    fixedCosts: 0,
    grossMargin: 0,
    netProfit: 0,
    profitMargin: 0,
    roi: 0,
    breakEvenPrice: 0,
    breakEvenProduction: 0,
    capitalUtilization: 0,
    maxCashRequirement: 0,
    risks: [],
    threats: [],
    sensitivity: {}
  }
};

// Enterprise Database - This can be expanded and updated
const enterpriseDatabase = {
  crops: {
    maize: {
      name: 'Maize',
      category: 'Crops',
      productionPeriod: '4-6 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 2000, medium: 4000, high: 6000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 15, variable: true },
        fertilizer: { typicalPercent: 25, variable: true },
        labour: { typicalPercent: 20, variable: true },
        landPrep: { typicalPercent: 10, variable: true },
        planting: { typicalPercent: 5, variable: true },
        weeding: { typicalPercent: 8, variable: true },
        harvesting: { typicalPercent: 7, variable: true },
        transport: { typicalPercent: 5, variable: true },
        other: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Maize is a staple crop with generally stable demand, but prices can vary seasonally. Requires storage capacity or timely selling.',
      riskFactors: ['weather', 'pests', 'price', 'yield'],
      beginnerFriendly: true
    },
    tomato: {
      name: 'Tomato',
      category: 'Horticulture',
      productionPeriod: '3-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 15000, medium: 25000, high: 40000 },
      waterRequirement: 'high',
      labourRequirement: 'high',
      skillRequirement: 'high',
      perishability: 'high',
      marketRisk: 'high',
      priceVolatility: 'high',
      costCategories: {
        seedlings: { typicalPercent: 12, variable: true },
        fertilizer: { typicalPercent: 18, variable: true },
        labour: { typicalPercent: 30, variable: true },
        irrigation: { typicalPercent: 10, variable: true },
        pestControl: { typicalPercent: 12, variable: true },
        staking: { typicalPercent: 5, variable: true },
        harvesting: { typicalPercent: 8, variable: true },
        packaging: { typicalPercent: 3, variable: true },
        transport: { typicalPercent: 2, variable: true }
      },
      marketConsiderations: 'Tomatoes are highly perishable and require consistent market access. Prices can be volatile but high quality tomatoes can command premium prices.',
      riskFactors: ['weather', 'pests', 'disease', 'price', 'market', 'water'],
      beginnerFriendly: false
    },
    cabbage: {
      name: 'Cabbage',
      category: 'Horticulture',
      productionPeriod: '3-4 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 20000, medium: 35000, high: 50000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'moderate',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seedlings: { typicalPercent: 10, variable: true },
        fertilizer: { typicalPercent: 20, variable: true },
        labour: { typicalPercent: 25, variable: true },
        irrigation: { typicalPercent: 8, variable: true },
        pestControl: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 12, variable: true },
        packaging: { typicalPercent: 5, variable: true },
        transport: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Cabbage has moderate perishability and good market demand. Quality and consistency are important for getting good prices.',
      riskFactors: ['weather', 'pests', 'price', 'market'],
      beginnerFriendly: true
    },
    onion: {
      name: 'Onion',
      category: 'Horticulture',
      productionPeriod: '4-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 15000, medium: 25000, high: 40000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'high',
      costCategories: {
        seed: { typicalPercent: 8, variable: true },
        fertilizer: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 25, variable: true },
        irrigation: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 15, variable: true },
        curing: { typicalPercent: 8, variable: true },
        transport: { typicalPercent: 4, variable: true }
      },
      marketConsiderations: 'Onions store well and can be sold over time. Prices can be volatile but storage provides some market flexibility.',
      riskFactors: ['weather', 'price', 'storage'],
      beginnerFriendly: true
    },
    potato: {
      name: 'Potato',
      category: 'Crops',
      productionPeriod: '3-4 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 15000, medium: 25000, high: 40000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'moderate',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 25, variable: true },
        fertilizer: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 20, variable: true },
        landPrep: { typicalPercent: 15, variable: true },
        planting: { typicalPercent: 8, variable: true },
        weeding: { typicalPercent: 7, variable: true },
        harvesting: { typicalPercent: 8, variable: true },
        transport: { typicalPercent: 2, variable: true }
      },
      marketConsiderations: 'Potatoes have good market demand but require quality seed and proper storage. Disease management is important.',
      riskFactors: ['weather', 'disease', 'seed_quality', 'storage'],
      beginnerFriendly: true
    },
    beans: {
      name: 'Beans',
      category: 'Crops',
      productionPeriod: '3-4 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 800, medium: 1200, high: 1800 },
      waterRequirement: 'moderate',
      labourRequirement: 'low',
      skillRequirement: 'low',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 20, variable: true },
        fertilizer: { typicalPercent: 10, variable: true },
        labour: { typicalPercent: 25, variable: true },
        landPrep: { typicalPercent: 20, variable: true },
        planting: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 10, variable: true },
        harvesting: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Beans are a protein source with consistent demand. Lower input requirements but also lower yields compared to some crops.',
      riskFactors: ['weather', 'pests', 'price'],
      beginnerFriendly: true
    },
    groundnuts: {
      name: 'Groundnuts',
      category: 'Crops',
      productionPeriod: '4-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 800, medium: 1200, high: 1800 },
      waterRequirement: 'moderate',
      labourRequirement: 'high',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 30, variable: true },
        landPrep: { typicalPercent: 20, variable: true },
        planting: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 8, variable: true },
        drying: { typicalPercent: 2, variable: true }
      },
      marketConsiderations: 'Groundnuts require good soil conditions and careful harvesting. Market demand is generally stable but aflatoxin control is important for food safety.',
      riskFactors: ['weather', 'aflatoxin', 'labour', 'soil'],
      beginnerFriendly: false
    },
    soybean: {
      name: 'Soybean',
      category: 'Crops',
      productionPeriod: '4-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 1000, medium: 1800, high: 2500 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 18, variable: true },
        fertilizer: { typicalPercent: 12, variable: true },
        labour: { typicalPercent: 25, variable: true },
        landPrep: { typicalPercent: 20, variable: true },
        planting: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 10, variable: true },
        harvesting: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Soybeans are often grown for oil and animal feed markets. Price depends on global markets and local processing capacity.',
      riskFactors: ['weather', 'price', 'market_access'],
      beginnerFriendly: false
    },
    wheat: {
      name: 'Wheat',
      category: 'Crops',
      productionPeriod: '4-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 2000, medium: 3500, high: 5000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'low',
      priceVolatility: 'low',
      costCategories: {
        seed: { typicalPercent: 15, variable: true },
        fertilizer: { typicalPercent: 20, variable: true },
        labour: { typicalPercent: 20, variable: true },
        landPrep: { typicalPercent: 15, variable: true },
        planting: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 8, variable: true },
        harvesting: { typicalPercent: 10, variable: true },
        transport: { typicalPercent: 2, variable: true }
      },
      marketConsiderations: 'Wheat has stable demand as a food staple. Requires quality seed and disease management. Less perishable than many vegetables.',
      riskFactors: ['weather', 'disease', 'quality'],
      beginnerFriendly: true
    },
    sweet_potato: {
      name: 'Sweet Potato',
      category: 'Crops',
      productionPeriod: '4-6 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 10000, medium: 20000, high: 30000 },
      waterRequirement: 'low',
      labourRequirement: 'moderate',
      skillRequirement: 'low',
      perishability: 'moderate',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        vines: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 30, variable: true },
        landPrep: { typicalPercent: 20, variable: true },
        planting: { typicalPercent: 10, variable: true },
        weeding: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 10, variable: true }
      },
      marketConsiderations: 'Sweet potatoes are drought-tolerant once established and have good market demand. Vine quality affects establishment success.',
      riskFactors: ['weather', 'vine_quality', 'market'],
      beginnerFriendly: true
    },
    watermelon: {
      name: 'Watermelon',
      category: 'Horticulture',
      productionPeriod: '3-4 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 15000, medium: 25000, high: 40000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'moderate',
      marketRisk: 'high',
      priceVolatility: 'high',
      costCategories: {
        seed: { typicalPercent: 10, variable: true },
        fertilizer: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 30, variable: true },
        irrigation: { typicalPercent: 10, variable: true },
        pestControl: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 15, variable: true },
        transport: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Watermelons can be profitable but are highly perishable and require good market access. Pollination affects fruit set.',
      riskFactors: ['weather', 'pollination', 'market', 'perishability'],
      beginnerFriendly: false
    },
    butternut: {
      name: 'Butternut',
      category: 'Horticulture',
      productionPeriod: '4-5 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 8000, medium: 15000, high: 25000 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        seed: { typicalPercent: 10, variable: true },
        fertilizer: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 30, variable: true },
        irrigation: { typicalPercent: 10, variable: true },
        pestControl: { typicalPercent: 15, variable: true },
        harvesting: { typicalPercent: 15, variable: true },
        transport: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Butternut stores well and has good market demand. Requires pollination and pest management.',
      riskFactors: ['weather', 'pests', 'pollination'],
      beginnerFriendly: true
    },
    leafy_vegetables: {
      name: 'Leafy Vegetables (Spinach, etc.)',
      category: 'Horticulture',
      productionPeriod: '1-2 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 5000, medium: 10000, high: 15000 },
      waterRequirement: 'high',
      labourRequirement: 'high',
      skillRequirement: 'moderate',
      perishability: 'high',
      marketRisk: 'high',
      priceVolatility: 'high',
      costCategories: {
        seed: { typicalPercent: 12, variable: true },
        fertilizer: { typicalPercent: 15, variable: true },
        labour: { typicalPercent: 35, variable: true },
        irrigation: { typicalPercent: 15, variable: true },
        pestControl: { typicalPercent: 10, variable: true },
        harvesting: { typicalPercent: 10, variable: true },
        packaging: { typicalPercent: 3, variable: true }
      },
      marketConsiderations: 'Leafy vegetables are highly perishable and require frequent harvesting. Quick turnover but continuous market access needed.',
      riskFactors: ['weather', 'perishability', 'market', 'water'],
      beginnerFriendly: false
    }
  },
  livestock: {
    broilers: {
      name: 'Broiler Chickens',
      category: 'Poultry',
      productionPeriod: '6-8 weeks',
      productionUnit: 'birds',
      typicalYieldPerUnit: { low: 1.8, medium: 2.2, high: 2.5 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'high',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        chicks: { typicalPercent: 25, variable: true },
        feed: { typicalPercent: 45, variable: true },
        vaccines: { typicalPercent: 5, variable: true },
        medication: { typicalPercent: 5, variable: true },
        housing: { typicalPercent: 8, variable: false },
        electricity: { typicalPercent: 5, variable: true },
        labour: { typicalPercent: 7, variable: true },
        transport: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Broilers have a short production cycle but require consistent feed and market access. Feed price is a major cost factor.',
      riskFactors: ['feed_price', 'disease', 'market', 'mortality'],
      beginnerFriendly: false
    },
    layers: {
      name: 'Layer Chickens',
      category: 'Poultry',
      productionPeriod: '18-24 months',
      productionUnit: 'birds',
      typicalYieldPerUnit: { low: 250, medium: 280, high: 300 },
      waterRequirement: 'moderate',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'moderate',
      marketRisk: 'low',
      priceVolatility: 'low',
      costCategories: {
        chicks: { typicalPercent: 15, variable: true },
        feed: { typicalPercent: 55, variable: true },
        vaccines: { typicalPercent: 5, variable: true },
        medication: { typicalPercent: 5, variable: true },
        housing: { typicalPercent: 12, variable: false },
        electricity: { typicalPercent: 5, variable: true },
        labour: { typicalPercent: 8, variable: true }
      },
      marketConsiderations: 'Layers provide regular income but require long-term commitment and consistent egg market access. Feed costs are the major expense.',
      riskFactors: ['feed_price', 'disease', 'market', 'long_term'],
      beginnerFriendly: false
    },
    goats: {
      name: 'Goats',
      category: 'Livestock',
      productionPeriod: 'Variable',
      productionUnit: 'animals',
      typicalYieldPerUnit: { low: 1, medium: 2, high: 3 },
      waterRequirement: 'low',
      labourRequirement: 'moderate',
      skillRequirement: 'moderate',
      perishability: 'low',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        animals: { typicalPercent: 30, variable: true },
        housing: { typicalPercent: 15, variable: false },
        feed: { typicalPercent: 25, variable: true },
        vaccines: { typicalPercent: 5, variable: true },
        medication: { typicalPercent: 5, variable: true },
        labour: { typicalPercent: 15, variable: true },
        transport: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Goats are adaptable and can browse on various vegetation. Market demand varies by region and purpose (meat, milk, breeding).',
      riskFactors: ['disease', 'predation', 'market', 'feed'],
      beginnerFriendly: true
    },
    pigs: {
      name: 'Pigs',
      category: 'Livestock',
      productionPeriod: '5-6 months',
      productionUnit: 'animals',
      typicalYieldPerUnit: { low: 70, medium: 90, high: 110 },
      waterRequirement: 'high',
      labourRequirement: 'high',
      skillRequirement: 'high',
      perishability: 'moderate',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        piglets: { typicalPercent: 25, variable: true },
        feed: { typicalPercent: 40, variable: true },
        housing: { typicalPercent: 15, variable: false },
        vaccines: { typicalPercent: 5, variable: true },
        medication: { typicalPercent: 5, variable: true },
        labour: { typicalPercent: 10, variable: true }
      },
      marketConsiderations: 'Pigs require significant feed investment and good biosecurity. Market demand is generally consistent but price fluctuations occur.',
      riskFactors: ['feed_price', 'disease', 'biosecurity', 'market'],
      beginnerFriendly: false
    }
  },
  fish: {
    tilapia: {
      name: 'Tilapia',
      category: 'Fish',
      productionPeriod: '6-8 months',
      productionUnit: 'kg',
      typicalYieldPerHectare: { low: 5000, medium: 10000, high: 15000 },
      waterRequirement: 'high',
      labourRequirement: 'moderate',
      skillRequirement: 'high',
      perishability: 'high',
      marketRisk: 'moderate',
      priceVolatility: 'moderate',
      costCategories: {
        fingerlings: { typicalPercent: 15, variable: true },
        feed: { typicalPercent: 40, variable: true },
        pond: { typicalPercent: 20, variable: false },
        aeration: { typicalPercent: 10, variable: true },
        labour: { typicalPercent: 10, variable: true },
        medication: { typicalPercent: 5, variable: true }
      },
      marketConsiderations: 'Tilapia farming requires good water quality and consistent feeding. Market demand is growing but requires proper handling and transport.',
      riskFactors: ['water_quality', 'feed_price', 'disease', 'market_access'],
      beginnerFriendly: false
    }
  }
};

// Navigation Functions
function startTool() {
  showSection('farmInfoSection');
  updateProgress(1);
  enterpriseState.currentStep = 1;
  enterpriseState.isComparison = false;
}

function startComparison() {
  alert('Enterprise comparison feature coming soon. For now, use the single enterprise analysis to understand the decision-making process.');
  startTool();
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
  const stepBack = enterpriseState.currentStep - 1;
  if (stepBack >= 0) {
    enterpriseState.currentStep = stepBack;
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
      showSection('farmInfoSection');
      break;
    case 2:
      showSection('enterpriseSection');
      break;
    case 3:
      showSection('capitalSection');
      break;
    case 4:
      showSection('resourcesSection');
      break;
    case 5:
      showSection('costsSection');
      break;
    case 6:
      showSection('productionSection');
      break;
    case 7:
      showSection('marketSection');
      break;
    case 8:
      showSection('experienceSection');
      break;
    case 9:
      showSection('finalResult');
      break;
  }
}

// Toggle "Why are we asking this?" explanations
function toggleWhy(id) {
  const whyElement = document.getElementById(id + 'Why');
  if (whyElement) {
    whyElement.parentElement.classList.toggle('show');
    const arrow = whyElement.parentElement.querySelector('.why-asking-title span');
    if (arrow) {
      arrow.textContent = whyElement.parentElement.classList.contains('show') ? '▲' : '▼';
    }
  }
}

// Farm Information Functions
function selectGoal(goal) {
  const buttons = document.querySelectorAll('[data-goal]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-goal="${goal}"]`).classList.add('selected');
  enterpriseState.farm.goal = goal;
}

function confirmFarmInfo() {
  const country = document.getElementById('countrySelect').value;
  const goal = enterpriseState.farm.goal;

  if (!country) {
    alert('Please select your country');
    return;
  }
  if (!goal) {
    alert('Please select your farming goal');
    return;
  }

  enterpriseState.farm.country = country;
  enterpriseState.currentStep = 2;
  showSection('enterpriseSection');
  updateProgress(2);
}

// Enterprise Selection Functions
function showEnterprises() {
  const type = document.getElementById('enterpriseType').value;
  const enterpriseSelect = document.getElementById('enterpriseSelect');
  const enterpriseSelectGroup = document.getElementById('enterpriseSelectGroup');
  const enterpriseInfo = document.getElementById('enterpriseInfo');

  enterpriseSelect.innerHTML = '<option value="">Select enterprise</option>';
  enterpriseInfo.classList.add('hidden');

  if (type && enterpriseDatabase[type]) {
    enterpriseSelectGroup.classList.remove('hidden');
    
    const enterprises = enterpriseDatabase[type];
    Object.keys(enterprises).forEach(key => {
      const option = document.createElement('option');
      option.value = key;
      option.textContent = enterprises[key].name;
      enterpriseSelect.appendChild(option);
    });
  } else {
    enterpriseSelectGroup.classList.add('hidden');
  }
}

function showEnterpriseInfo() {
  const type = document.getElementById('enterpriseType').value;
  const key = document.getElementById('enterpriseSelect').value;
  const enterpriseInfo = document.getElementById('enterpriseInfo');
  const enterpriseInfoText = document.getElementById('enterpriseInfoText');

  if (type && key && enterpriseDatabase[type] && enterpriseDatabase[type][key]) {
    const enterprise = enterpriseDatabase[type][key];
    enterpriseInfoText.textContent = `${enterprise.name} - ${enterprise.marketConsiderations}`;
    enterpriseInfo.classList.remove('hidden');
    enterpriseState.enterprise.type = type;
    enterpriseState.enterprise.name = enterprise.name;
  } else {
    enterpriseInfo.classList.add('hidden');
  }
}

function confirmEnterprise() {
  const type = enterpriseState.enterprise.type;
  const name = enterpriseState.enterprise.name;
  const scale = document.getElementById('enterpriseScale').value;
  const scaleUnit = document.getElementById('scaleUnit').value;

  if (!type || !name) {
    alert('Please select an enterprise');
    return;
  }
  if (!scale) {
    alert('Please enter your planned scale');
    return;
  }

  enterpriseState.enterprise.scale = parseFloat(scale);
  enterpriseState.enterprise.scaleUnit = scaleUnit;

  enterpriseState.currentStep = 3;
  showSection('capitalSection');
  updateProgress(3);
  generateCostInputs();
}

// Generate cost inputs based on enterprise type
function generateCostInputs() {
  const type = enterpriseState.enterprise.type;
  const key = Object.keys(enterpriseDatabase[type]).find(k => 
    enterpriseDatabase[type][k].name === enterpriseState.enterprise.name
  );

  const costInputsContainer = document.getElementById('costInputs');
  costInputsContainer.innerHTML = '';

  if (type && key && enterpriseDatabase[type][key]) {
    const enterprise = enterpriseDatabase[type][key];
    const costCategories = enterprise.costCategories;

    Object.keys(costCategories).forEach(category => {
      const div = document.createElement('div');
      div.className = 'question-group';
      div.innerHTML = `
        <label class="question-label">${category.charAt(0).toUpperCase() + category.slice(1)}</label>
        <div class="currency-group">
          <input type="number" class="form-input number-input" id="cost_${category}" placeholder="Cost amount">
        </div>
      `;
      costInputsContainer.appendChild(div);
    });
  }
}

// Capital Functions
function selectCapitalType(type) {
  const buttons = document.querySelectorAll('[data-capital]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-capital="${type}"]`).classList.add('selected');
  enterpriseState.capital.type = type;
}

function confirmCapital() {
  const currency = document.getElementById('currencySelect').value;
  const available = document.getElementById('availableCapital').value;
  const type = enterpriseState.capital.type;
  const contingency = document.getElementById('contingencyPercent').value;

  if (!available) {
    alert('Please enter your available capital');
    return;
  }
  if (!type) {
    alert('Please select your capital type');
    return;
  }

  enterpriseState.capital.currency = currency;
  enterpriseState.capital.available = parseFloat(available);
  enterpriseState.capital.contingencyPercent = parseFloat(contingency) || 10;

  enterpriseState.currentStep = 4;
  showSection('resourcesSection');
  updateProgress(4);
}

// Resources Functions
function selectLandType(type) {
  const buttons = document.querySelectorAll('[data-land]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-land="${type}"]`).classList.add('selected');
  enterpriseState.resources.land.type = type;
}

function selectWater(water) {
  const buttons = document.querySelectorAll('[data-water]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-water="${water}"]`).classList.add('selected');
  enterpriseState.resources.water = water;
}

function selectWaterAvailability(availability) {
  const buttons = document.querySelectorAll('[data-water-avail]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-water-avail="${availability}"]`).classList.add('selected');
  enterpriseState.resources.waterAvailability = availability;
}

function selectLabour(labour) {
  const buttons = document.querySelectorAll('[data-labour]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-labour="${labour}"]`).classList.add('selected');
  enterpriseState.resources.labour = labour;
}

function confirmResources() {
  const landAmount = document.getElementById('landAmount').value;
  const landUnit = document.getElementById('landUnit').value;
  const landType = enterpriseState.resources.land.type;
  const water = enterpriseState.resources.water;
  const waterAvailability = enterpriseState.resources.waterAvailability;
  const labour = enterpriseState.resources.labour;
  const workers = document.getElementById('workerCount').value;
  const dailyWage = document.getElementById('dailyWage').value;

  if (!landAmount) {
    alert('Please enter your land amount');
    return;
  }
  if (!landType) {
    alert('Please select your land type');
    return;
  }
  if (!water) {
    alert('Please select your water source');
    return;
  }
  if (!labour) {
    alert('Please select your labour type');
    return;
  }

  enterpriseState.resources.land.amount = parseFloat(landAmount);
  enterpriseState.resources.land.unit = landUnit;
  enterpriseState.resources.workers = parseFloat(workers) || 0;
  enterpriseState.resources.dailyWage = parseFloat(dailyWage) || 0;

  enterpriseState.currentStep = 5;
  showSection('costsSection');
  updateProgress(5);
}

// Costs Functions
function confirmCosts() {
  const type = enterpriseState.enterprise.type;
  const key = Object.keys(enterpriseDatabase[type]).find(k => 
    enterpriseDatabase[type][k].name === enterpriseState.enterprise.name
  );

  if (type && key && enterpriseDatabase[type][key]) {
    const enterprise = enterpriseDatabase[type][key];
    const costCategories = enterprise.costCategories;

    let totalCost = 0;
    enterpriseState.costs = {};

    Object.keys(costCategories).forEach(category => {
      const input = document.getElementById(`cost_${category}`);
      if (input && input.value) {
        const cost = parseFloat(input.value);
        enterpriseState.costs[category] = cost;
        totalCost += cost;
      }
    });

    // Calculate labour cost if not entered
    if (!enterpriseState.costs.labour && enterpriseState.resources.workers > 0 && enterpriseState.resources.dailyWage > 0) {
      // Estimate 90 working days for typical crop cycle
      const estimatedLabourDays = 90;
      const labourCost = enterpriseState.resources.workers * enterpriseState.resources.dailyWage * estimatedLabourDays;
      enterpriseState.costs.labour = labourCost;
      totalCost += labourCost;
    }

    enterpriseState.results.totalCost = totalCost;
  }

  enterpriseState.currentStep = 6;
  showSection('productionSection');
  updateProgress(6);
}

// Production and Market Functions
function selectPriceLevel(level) {
  const buttons = document.querySelectorAll('[data-price]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-price="${level}"]`).classList.add('selected');
  enterpriseState.production.priceLevel = level;
}

function confirmProduction() {
  const expected = document.getElementById('expectedProduction').value;
  const unit = document.getElementById('productionUnit').value;
  const sellingPrice = document.getElementById('sellingPrice').value;
  const priceLevel = enterpriseState.production.priceLevel;
  const lossPercent = document.getElementById('lossPercent').value;
  const marketDistance = document.getElementById('marketDistance').value;
  const distanceUnit = document.getElementById('distanceUnit').value;
  const transportCost = document.getElementById('transportCost').value;
  const tripsCount = document.getElementById('tripsCount').value;

  if (!expected) {
    alert('Please enter expected production');
    return;
  }
  if (!sellingPrice) {
    alert('Please enter expected selling price');
    return;
  }
  if (!priceLevel) {
    alert('Please select price level');
    return;
  }

  enterpriseState.production.expected = parseFloat(expected);
  enterpriseState.production.unit = unit;
  enterpriseState.production.sellingPrice = parseFloat(sellingPrice);
  enterpriseState.production.lossPercent = parseFloat(lossPercent) || 10;
  enterpriseState.production.marketDistance = parseFloat(marketDistance) || 0;
  enterpriseState.production.distanceUnit = distanceUnit;
  enterpriseState.production.transportCost = parseFloat(transportCost) || 0;
  enterpriseState.production.tripsCount = parseFloat(tripsCount) || 0;

  enterpriseState.currentStep = 7;
  showSection('marketSection');
  updateProgress(7);
}

// Market Analysis Functions
function selectMarket(where) {
  const buttons = document.querySelectorAll('[data-market]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-market="${where}"]`).classList.add('selected');
  enterpriseState.market.where = where;
}

function selectBuyer(buyer) {
  const buttons = document.querySelectorAll('[data-buyer]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-buyer="${buyer}"]`).classList.add('selected');
  enterpriseState.market.confirmedBuyer = buyer;
}

function selectBuyerCount(count) {
  const buttons = document.querySelectorAll('[data-buyer-count]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-buyer-count="${count}"]`).classList.add('selected');
  enterpriseState.market.buyerCount = count;
}

function selectPerishability(perish) {
  const buttons = document.querySelectorAll('[data-perish]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-perish="${perish}"]`).classList.add('selected');
  enterpriseState.market.perishability = perish;
}

function selectStorage(storage) {
  const buttons = document.querySelectorAll('[data-storage]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-storage="${storage}"]`).classList.add('selected');
  enterpriseState.market.storage = storage;
}

function confirmMarket() {
  const where = enterpriseState.market.where;
  const confirmedBuyer = enterpriseState.market.confirmedBuyer;
  const buyerCount = enterpriseState.market.buyerCount;
  const perishability = enterpriseState.market.perishability;
  const storage = enterpriseState.market.storage;

  if (!where) {
    alert('Please select where you will sell');
    return;
  }
  if (!confirmedBuyer) {
    alert('Please select whether you have a confirmed buyer');
    return;
  }
  if (!perishability) {
    alert('Please select perishability level');
    return;
  }
  if (!storage) {
    alert('Please select storage availability');
    return;
  }

  enterpriseState.currentStep = 8;
  showSection('experienceSection');
  updateProgress(8);
}

// Experience and Risk Functions
function selectExperience(level) {
  const buttons = document.querySelectorAll('[data-experience]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-experience="${level}"]`).classList.add('selected');
  enterpriseState.experience.level = level;
}

function selectConcern(concern) {
  const buttons = document.querySelectorAll('[data-concern]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-concern="${concern}"]`).classList.add('selected');
  enterpriseState.experience.concern = concern;
}

function confirmExperience() {
  const level = enterpriseState.experience.level;
  const concern = enterpriseState.experience.concern;

  if (!level) {
    alert('Please select your experience level');
    return;
  }
  if (!concern) {
    alert('Please select your main concern');
    return;
  }

  calculateResults();
  enterpriseState.currentStep = 9;
  showSection('finalResult');
  updateProgress(9);
}

// Main Calculation Function
function calculateResults() {
  const state = enterpriseState;
  const type = state.enterprise.type;
  const key = Object.keys(enterpriseDatabase[type]).find(k => 
    enterpriseDatabase[type][k].name === state.enterprise.name
  );

  if (!type || !key || !enterpriseDatabase[type][key]) {
    return;
  }

  const enterprise = enterpriseDatabase[type][key];

  // Calculate contingency amount
  state.results.contingencyAmount = state.results.totalCost * (state.capital.contingencyPercent / 100);
  state.results.totalFunding = state.results.totalCost + state.results.contingencyAmount;

  // Calculate marketable production after losses
  state.results.marketableProduction = state.production.expected * (1 - state.production.lossPercent / 100);

  // Calculate gross revenue
  state.results.grossRevenue = state.results.marketableProduction * state.production.sellingPrice;

  // Add transport costs
  const totalTransportCost = state.production.transportCost * state.production.tripsCount;
  state.results.totalCost += totalTransportCost;

  // Calculate variable vs fixed costs
  state.results.variableCosts = 0;
  state.results.fixedCosts = 0;

  if (enterprise.costCategories) {
    Object.keys(enterprise.costCategories).forEach(category => {
      const costInfo = enterprise.costCategories[category];
      const cost = state.costs[category] || 0;
      if (costInfo.variable) {
        state.results.variableCosts += cost;
      } else {
        state.results.fixedCosts += cost;
      }
    });
  }

  // Calculate gross margin
  state.results.grossMargin = state.results.grossRevenue - state.results.variableCosts;

  // Calculate net profit
  state.results.netProfit = state.results.grossRevenue - state.results.totalCost;

  // Calculate profit margin
  if (state.results.grossRevenue > 0) {
    state.results.profitMargin = (state.results.netProfit / state.results.grossRevenue) * 100;
  } else {
    state.results.profitMargin = 0;
  }

  // Calculate ROI
  if (state.capital.available > 0) {
    state.results.roi = (state.results.netProfit / state.capital.available) * 100;
  } else {
    state.results.roi = 0;
  }

  // Calculate break-even price
  if (state.results.marketableProduction > 0) {
    state.results.breakEvenPrice = state.results.totalCost / state.results.marketableProduction;
  } else {
    state.results.breakEvenPrice = 0;
  }

  // Calculate break-even production
  if (state.production.sellingPrice > 0) {
    state.results.breakEvenProduction = state.results.totalCost / state.production.sellingPrice;
  } else {
    state.results.breakEvenProduction = 0;
  }

  // Calculate capital utilization
  if (state.capital.available > 0) {
    state.results.capitalUtilization = (state.results.totalFunding / state.capital.available) * 100;
  } else {
    state.results.capitalUtilization = 0;
  }

  // Calculate sensitivity analysis
  calculateSensitivityAnalysis();

  // Perform risk analysis
  performRiskAnalysis();

  // Update UI
  updateResultsUI();
}

function calculateSensitivityAnalysis() {
  const state = enterpriseState;
  const results = state.results;

  // Price sensitivity
  results.sensitivity.price = {};
  const priceChanges = [-30, -20, -10, 0, 10, 20, 30];
  priceChanges.forEach(change => {
    const adjustedPrice = state.production.sellingPrice * (1 + change / 100);
    const adjustedRevenue = state.results.marketableProduction * adjustedPrice;
    const adjustedProfit = adjustedRevenue - state.results.totalCost;
    results.sensitivity.price[change] = {
      price: adjustedPrice,
      revenue: adjustedRevenue,
      profit: adjustedProfit
    };
  });

  // Yield sensitivity
  results.sensitivity.yield = {};
  const yieldChanges = [-30, -20, -10, 0, 10, 20, 30];
  yieldChanges.forEach(change => {
    const adjustedProduction = state.results.marketableProduction * (1 + change / 100);
    const adjustedRevenue = adjustedProduction * state.production.sellingPrice;
    const adjustedProfit = adjustedRevenue - state.results.totalCost;
    results.sensitivity.yield[change] = {
      production: adjustedProduction,
      revenue: adjustedRevenue,
      profit: adjustedProfit
    };
  });

  // Cost sensitivity
  results.sensitivity.cost = {};
  const costChanges = [5, 10, 20, 30];
  costChanges.forEach(change => {
    const adjustedCost = state.results.totalCost * (1 + change / 100);
    const adjustedProfit = state.results.grossRevenue - adjustedCost;
    results.sensitivity.cost[change] = {
      cost: adjustedCost,
      profit: adjustedProfit
    };
  });
}

function performRiskAnalysis() {
  const state = enterpriseState;
  const results = state.results;
  const type = state.enterprise.type;
  const key = Object.keys(enterpriseDatabase[type]).find(k => 
    enterpriseDatabase[type][k].name === state.enterprise.name
  );

  if (!type || !key || !enterpriseDatabase[type][key]) {
    return;
  }

  const enterprise = enterpriseDatabase[type][key];
  results.risks = [];
  results.threats = [];

  // Capital risk
  if (results.capitalUtilization > 90) {
    results.risks.push({
      category: 'Capital',
      level: 'high',
      title: 'High capital utilization',
      description: `You plan to use ${results.capitalUtilization.toFixed(0)}% of your available capital. This leaves little buffer for unexpected costs or household needs.`
    });
  } else if (results.capitalUtilization > 70) {
    results.risks.push({
      category: 'Capital',
      level: 'moderate',
      title: 'Moderate capital utilization',
      description: `You plan to use ${results.capitalUtilization.toFixed(0)}% of your available capital. Consider keeping some reserve for emergencies.`
    });
  }

  // Market risk
  if (state.market.confirmedBuyer === 'no') {
    results.risks.push({
      category: 'Market',
      level: 'high',
      title: 'No confirmed buyer',
      description: 'You do not have a confirmed buyer. Market access and price uncertainty are significant risks.'
    });
  } else if (state.market.confirmedBuyer === 'not_sure') {
    results.risks.push({
      category: 'Market',
      level: 'moderate',
      title: 'Uncertain buyer status',
      description: 'You are unsure about buyer status. Market access risk is moderate.'
    });
  }

  // Market concentration risk
  if (state.market.buyerCount === '1') {
    results.risks.push({
      category: 'Market',
      level: 'high',
      title: 'Single buyer concentration',
      description: 'Depending on only one buyer increases your bargaining risk. If that buyer reduces the price or stops buying, you may have few alternatives.'
    });
  } else if (state.market.buyerCount === '2-3') {
    results.risks.push({
      category: 'Market',
      level: 'moderate',
      title: 'Limited buyer diversity',
      description: 'Having only 2-3 buyers provides some but not complete protection against buyer risk.'
    });
  }

  // Perishability risk
  if (state.market.perishability === 'high') {
    results.risks.push({
      category: 'Market',
      level: 'high',
      title: 'High perishability',
      description: 'Your product is highly perishable. This requires timely selling or good storage, and increases the risk of post-harvest losses.'
    });
  }

  // Storage risk
  if (state.market.storage === 'no') {
    results.risks.push({
      category: 'Market',
      level: 'moderate',
      title: 'No storage available',
      description: 'Without storage, you must sell quickly. This reduces your ability to wait for better prices or manage market timing.'
    });
  }

  // Water risk
  if (state.resources.waterAvailability === 'no' || state.resources.waterAvailability === 'not_sure') {
    results.risks.push({
      category: 'Water',
      level: 'high',
      title: 'Uncertain water availability',
      description: 'Water availability during the production period is uncertain. This is a significant risk for crop success.'
    });
  }

  // Experience risk
  if (state.experience.level === 'beginner') {
    results.risks.push({
      category: 'Skill',
      level: 'moderate',
      title: 'Beginner experience level',
      description: 'As a beginner with this enterprise, consider starting smaller to learn while limiting your exposure to loss.'
    });
  }

  // Profit sensitivity risk
  const priceRisk = results.sensitivity.price[-20]?.profit || 0;
  if (priceRisk < 0) {
    results.threats.push({
      title: 'Selling price drop of 20%',
      impact: `Profit would change to ${formatCurrency(priceRisk)}`,
      severity: 'high'
    });
  }

  const yieldRisk = results.sensitivity.yield[-20]?.profit || 0;
  if (yieldRisk < 0) {
    results.threats.push({
      title: 'Production drop of 20%',
      impact: `Profit would change to ${formatCurrency(yieldRisk)}`,
      severity: 'high'
    });
  }

  const costRisk = results.sensitivity.cost[20]?.profit || 0;
  if (costRisk < 0) {
    results.threats.push({
      title: 'Cost increase of 20%',
      impact: `Profit would change to ${formatCurrency(costRisk)}`,
      severity: 'moderate'
    });
  }

  // Transport cost risk
  const transportShare = (state.production.transportCost * state.production.tripsCount) / results.totalCost * 100;
  if (transportShare > 15) {
    results.threats.push({
      title: 'High transport costs',
      impact: `Transport represents ${transportShare.toFixed(0)}% of your planned costs. This could significantly affect profitability.`,
      severity: 'moderate'
    });
  }
}

function updateResultsUI() {
  const state = enterpriseState;
  const results = state.results;

  // Update summary
  document.getElementById('summaryEnterprise').textContent = state.enterprise.name;
  document.getElementById('summaryLocation').textContent = state.farm.country;
  document.getElementById('summaryScale').textContent = `${state.enterprise.scale} ${state.enterprise.scaleUnit}`;
  document.getElementById('summaryCapitalRequired').textContent = `${formatCurrency(results.totalFunding)} (${state.capital.currency})`;
  document.getElementById('summaryCapitalUsed').textContent = `${results.capitalUtilization.toFixed(0)}% of available capital`;
  document.getElementById('summaryTotalCost').textContent = formatCurrency(results.totalCost);
  document.getElementById('summaryRevenue').textContent = formatCurrency(results.grossRevenue);
  document.getElementById('summaryProfit').textContent = formatCurrency(results.netProfit);
  document.getElementById('summaryMargin').textContent = `${results.profitMargin.toFixed(1)}%`;
  document.getElementById('summaryROI').textContent = `${results.roi.toFixed(1)}%`;
  document.getElementById('summaryBreakEvenPrice').textContent = `${formatCurrency(results.breakEvenPrice)} per ${state.production.unit}`;
  document.getElementById('summaryBreakEvenProduction').textContent = `${results.breakEvenProduction.toFixed(0)} ${state.production.unit}`;

  // Update cost breakdown
  updateCostBreakdown();

  // Update threats
  updateThreats();

  // Update sensitivity analysis
  updateSensitivityAnalysis();

  // Update risk analysis
  updateRiskAnalysis();

  // Update result status and explanation
  updateFinalResult();

  // Update verification checklist
  updateVerificationChecklist();

  // Update next actions
  updateNextActions();
}

function updateCostBreakdown() {
  const state = enterpriseState;
  const container = document.getElementById('costBreakdownChart');
  container.innerHTML = '';

  const costs = Object.entries(state.costs).map(([category, amount]) => ({ category, amount }));
  costs.sort((a, b) => b.amount - a.amount);

  const total = state.results.totalCost;

  costs.forEach((cost, index) => {
    const percent = (cost.amount / total * 100).toFixed(1);
    const isLargest = index === 0;

    const div = document.createElement('div');
    div.className = `cost-item ${isLargest ? 'largest' : ''}`;
    div.innerHTML = `
      <div class="cost-item-label">${cost.category.charAt(0).toUpperCase() + cost.category.slice(1)}</div>
      <div class="cost-item-value">${formatCurrency(cost.amount)}</div>
      <div class="cost-item-percent">${percent}%</div>
      <div class="percentage-bar">
        <div class="percentage-fill" style="width: ${percent}%"></div>
      </div>
    `;
    container.appendChild(div);
  });

  // Add transport cost if significant
  const transportCost = state.production.transportCost * state.production.tripsCount;
  if (transportCost > 0) {
    const transportPercent = (transportCost / total * 100).toFixed(1);
    const div = document.createElement('div');
    div.className = 'cost-item';
    div.innerHTML = `
      <div class="cost-item-label">Transport</div>
      <div class="cost-item-value">${formatCurrency(transportCost)}</div>
      <div class="cost-item-percent">${transportPercent}%</div>
      <div class="percentage-bar">
        <div class="percentage-fill" style="width: ${transportPercent}%"></div>
      </div>
    `;
    container.appendChild(div);
  }
}

function updateThreats() {
  const container = document.getElementById('threatsContainer');
  container.innerHTML = '';

  if (enterpriseState.results.threats.length === 0) {
    container.innerHTML = '<p>Based on your information, no major specific threats were identified. However, always monitor conditions and be prepared for changes.</p>';
    return;
  }

  enterpriseState.results.threats.forEach((threat, index) => {
    const div = document.createElement('div');
    div.style.marginBottom = '0.75rem';
    div.innerHTML = `
      <strong>${index + 1}. ${threat.title}:</strong>
      <p style="margin: 0.25rem 0 0 0;">${threat.impact}</p>
    `;
    container.appendChild(div);
  });
}

function updateSensitivityAnalysis() {
  const state = enterpriseState;
  const results = state.results;

  // Price sensitivity
  const priceContainer = document.getElementById('priceSensitivity');
  priceContainer.innerHTML = '';

  const priceChanges = [-30, -20, -10, 0, 10, 20, 30];
  priceChanges.forEach(change => {
    const data = results.sensitivity.price[change];
    const cell = document.createElement('div');
    cell.className = `sensitivity-cell ${data.profit < 0 ? 'negative' : data.profit > 0 ? 'positive' : 'neutral'}`;
    cell.innerHTML = `
      <div>${change > 0 ? '+' : ''}${change}%</div>
      <div style="font-size: 0.75rem;">${formatCurrency(data.profit)}</div>
    `;
    priceContainer.appendChild(cell);
  });

  // Yield sensitivity
  const yieldContainer = document.getElementById('yieldSensitivity');
  yieldContainer.innerHTML = '';

  yieldChanges.forEach(change => {
    const data = results.sensitivity.yield[change];
    const cell = document.createElement('div');
    cell.className = `sensitivity-cell ${data.profit < 0 ? 'negative' : data.profit > 0 ? 'positive' : 'neutral'}`;
    cell.innerHTML = `
      <div>${change > 0 ? '+' : ''}${change}%</div>
      <div style="font-size: 0.75rem;">${formatCurrency(data.profit)}</div>
    `;
    yieldContainer.appendChild(cell);
  });

  // Cost sensitivity
  const costContainer = document.getElementById('costSensitivity');
  costContainer.innerHTML = '';

  const costChanges = [5, 10, 20, 30];
  costChanges.forEach(change => {
    const data = results.sensitivity.cost[change];
    const cell = document.createElement('div');
    cell.className = `sensitivity-cell ${data.profit < 0 ? 'negative' : data.profit > 0 ? 'positive' : 'neutral'}`;
    cell.innerHTML = `
      <div>+${change}%</div>
      <div style="font-size: 0.75rem;">${formatCurrency(data.profit)}</div>
    `;
    costContainer.appendChild(cell);
  });
}

function updateRiskAnalysis() {
  const container = document.getElementById('riskAnalysis');
  container.innerHTML = '';

  if (enterpriseState.results.risks.length === 0) {
    container.innerHTML = '<p>Based on your information, no major specific risks were identified. However, farming always carries uncertainty, and conditions can change.</p>';
    return;
  }

  enterpriseState.results.risks.forEach(risk => {
    const div = document.createElement('div');
    div.className = `risk-category ${risk.level}`;
    div.innerHTML = `
      <div class="risk-title">${risk.category} RISK (${risk.level.toUpperCase()})</div>
      <p style="margin: 0.5rem 0 0 0;">${risk.description}</p>
    `;
    container.appendChild(div);
  });
}

function updateFinalResult() {
  const state = enterpriseState;
  const results = state.results;

  let status = 'possible-fit';
  let statusText = 'POSSIBLE FIT — CHECK KEY RISKS';
  let explanation = '';

  // Analyze overall fit
  const highRisks = results.risks.filter(r => r.level === 'high').length;
  const moderateRisks = results.risks.filter(r => r.level === 'moderate').length;

  if (results.netProfit < 0) {
    status = 'poor-fit';
    statusText = 'POOR FIT WITH CURRENT ASSUMPTIONS';
    explanation = 'Based on your cost and revenue assumptions, this enterprise shows a negative expected profit. Review your cost estimates, expected yield, and selling price assumptions.';
  } else if (highRisks >= 3) {
    status = 'high-risk';
    statusText = 'HIGHER RISK — CONSIDER STARTING SMALL';
    explanation = `Your estimated profit is positive, but you face ${highRisks} high-risk factors. Consider starting with a smaller scale to learn the enterprise while limiting your exposure to loss.`;
  } else if (highRisks >= 1) {
    status = 'possible-fit';
    statusText = 'POSSIBLE FIT — ADDRESS KEY RISKS';
    explanation = 'Your estimated profit is positive and capital requirements fit within your budget, but you have some high-risk factors that need attention before investing.';
  } else if (moderateRisks >= 4) {
    status = 'possible-fit';
    statusText = 'POSSIBLE FIT — SEVERAL MODERATE RISKS';
    explanation = 'Your estimated profit is positive, but you have several moderate risks. Consider whether these risks are acceptable for your situation.';
  } else {
    status = 'strong-fit';
    statusText = 'STRONGER FIT — GOOD RESOURCE ALIGNMENT';
    explanation = 'Based on your information, this enterprise shows positive expected profit with relatively low risk factors. Your resources appear well-aligned with the enterprise requirements.';
  }

  const resultStatus = document.getElementById('resultStatus');
  resultStatus.textContent = statusText;
  resultStatus.className = `result-status ${status}`;

  document.getElementById('resultExplanation').textContent = explanation;
}

function updateVerificationChecklist() {
  const container = document.getElementById('verificationChecklist');
  container.innerHTML = '';

  const checklistItems = [
    'I checked current local selling prices',
    'I know who may buy my product',
    'I estimated transport costs',
    'I calculated production costs',
    'I included labour costs',
    'I included water/irrigation costs',
    'I included post-harvest costs',
    'I considered possible losses',
    'I checked my available capital',
    'I have enough working capital',
    'I considered a contingency reserve',
    'I checked production risks',
    'I understand the enterprise requirements',
    'I have considered a lower-price scenario',
    'I have considered a lower-yield scenario',
    'I know what I will do if the market changes'
  ];

  checklistItems.forEach(item => {
    const div = document.createElement('div');
    div.className = 'checklist-item';
    div.innerHTML = `
      <div class="checklist-checkbox" onclick="toggleChecklist(this)"></div>
      <div class="checklist-text">${item}</div>
    `;
    container.appendChild(div);
  });
}

function toggleChecklist(checkbox) {
  checkbox.classList.toggle('checked');
}

function updateNextActions() {
  const state = enterpriseState;
  const container = document.getElementById('nextActions');
  container.innerHTML = '';

  const actions = [];

  // Based on experience level
  if (state.experience.level === 'beginner') {
    actions.push('Start with a smaller scale to learn the enterprise');
    actions.push('Seek extension advice before investing large amounts');
  }

  // Based on market
  if (state.market.confirmedBuyer === 'no') {
    actions.push('Speak to potential buyers before planting/investing');
    actions.push('Confirm market demand and pricing');
  }

  // Based on water
  if (state.resources.waterAvailability === 'no' || state.resources.waterAvailability === 'not_sure') {
    actions.push('Secure reliable water source before investing');
  }

  // Based on capital
  if (state.results.capitalUtilization > 80) {
    actions.push('Consider using less capital to maintain emergency reserve');
  }

  // Based on risks
  if (state.results.threats.length > 0) {
    actions.push('Address the main threats identified in the analysis');
  }

  // Always add general advice
  actions.push('Recalculate using a 20% lower selling price scenario');
  actions.push('Recalculate using a 20% lower yield scenario');

  actions.forEach(action => {
    const li = document.createElement('li');
    li.textContent = action;
    container.appendChild(li);
  });
}

// Helper function to format currency
function formatCurrency(amount) {
  const state = enterpriseState;
  const currency = state.capital.currency;
  return `${currency} ${amount.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

// Save and Download Functions
function saveResult() {
  const state = enterpriseState;
  const result = {
    date: new Date().toISOString(),
    enterprise: state.enterprise,
    location: state.farm,
    capital: state.capital,
    resources: state.resources,
    costs: state.costs,
    production: state.production,
    market: state.market,
    experience: state.experience,
    results: state.results
  };

  try {
    const savedResults = JSON.parse(localStorage.getItem('enterpriseCheckResults') || '[]');
    savedResults.push(result);
    localStorage.setItem('enterpriseCheckResults', JSON.stringify(savedResults));
    alert('Your enterprise decision has been saved locally on this device.');
  } catch (e) {
    alert('Could not save result. Your browser may not support local storage.');
  }
}

function downloadResult() {
  const state = enterpriseState;
  const result = generateResultText();

  const blob = new Blob([result], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `enterprise-check-${state.enterprise.name}-${new Date().toISOString().split('T')[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function generateResultText() {
  const state = enterpriseState;
  const results = state.results;

  let text = `FARMING ENTERPRISE DECISION REPORT\n`;
  text += `================================\n\n`;
  text += `Date: ${new Date().toLocaleDateString()}\n`;
  text += `Enterprise: ${state.enterprise.name}\n`;
  text += `Location: ${state.farm.country}\n`;
  text += `Planned Scale: ${state.enterprise.scale} ${state.enterprise.scaleUnit}\n\n`;

  text += `CAPITAL ANALYSIS\n`;
  text += `================\n`;
  text += `Available Capital: ${formatCurrency(state.capital.available)}\n`;
  text += `Capital Type: ${state.capital.type}\n`;
  text += `Total Production Cost: ${formatCurrency(results.totalCost)}\n`;
  text += `Contingency (${state.capital.contingencyPercent}%): ${formatCurrency(results.contingencyAmount)}\n`;
  text += `Total Funding Required: ${formatCurrency(results.totalFunding)}\n`;
  text += `Capital Utilization: ${results.capitalUtilization.toFixed(1)}%\n\n`;

  text += `PRODUCTION ASSUMPTIONS\n`;
  text += `======================\n`;
  text += `Expected Production: ${state.production.expected} ${state.production.unit}\n`;
  text += `Post-Harvest Losses (${state.production.lossPercent}%): ${state.production.expected * state.production.lossPercent / 100} ${state.production.unit}\n`;
  text += `Marketable Production: ${results.marketableProduction.toFixed(0)} ${state.production.unit}\n`;
  text += `Selling Price: ${formatCurrency(state.production.sellingPrice)} per ${state.production.unit}\n`;
  text += `Price Level: ${state.production.priceLevel}\n\n`;

  text += `FINANCIAL RESULTS\n`;
  text += `==================\n`;
  text += `Gross Revenue: ${formatCurrency(results.grossRevenue)}\n`;
  text += `Total Costs: ${formatCurrency(results.totalCost)}\n`;
  text += `Net Profit: ${formatCurrency(results.netProfit)}\n`;
  text += `Profit Margin: ${results.profitMargin.toFixed(1)}%\n`;
  text += `ROI: ${results.roi.toFixed(1)}%\n`;
  text += `Break-Even Price: ${formatCurrency(results.breakEvenPrice)} per ${state.production.unit}\n`;
  text += `Break-Even Production: ${results.breakEvenProduction.toFixed(0)} ${state.production.unit}\n\n`;

  text += `RISK ANALYSIS\n`;
  text += `==============\n`;
  if (results.risks.length > 0) {
    results.risks.forEach((risk, index) => {
      text += `${index + 1}. ${risk.category} Risk (${risk.level.toUpperCase()}): ${risk.description}\n`;
    });
  } else {
    text += 'No major risks identified based on your responses.\n';
  }
  text += '\n';

  text += `THREATS TO PROFIT\n`;
  text += `==================\n`;
  if (results.threats.length > 0) {
    results.threats.forEach((threat, index) => {
      text += `${index + 1}. ${threat.title}: ${threat.impact}\n`;
    });
  } else {
    text += 'No specific threats identified based on your sensitivity analysis.\n';
  }
  text += '\n';

  text += `DISCLAIMER\n`;
  text += `=========\n`;
  text += `This result is based on the information you entered and available agricultural data at the time of analysis. Actual results can change because of weather, yields, input prices, selling prices, pests, diseases, labour costs, transport and market conditions. This tool provides decision support, not a guarantee of success. Always use your own judgment and local knowledge. Consult local agricultural extension services for precise local recommendations.\n`;

  return text;
}

function restartTool() {
  // Reset state
  enterpriseState.currentStep = 0;
  enterpriseState.isComparison = false;
  enterpriseState.comparisonEnterprises = [];
  enterpriseState.farm = { country: '', goal: '' };
  enterpriseState.enterprise = { type: '', name: '', scale: 0, scaleUnit: 'hectares' };
  enterpriseState.capital = { currency: 'USD', available: 0, type: '', contingencyPercent: 10 };
  enterpriseState.resources = {
    land: { amount: 0, unit: 'hectares', type: '' },
    water: '', waterAvailability: '', labour: '', workers: 0, dailyWage: 0
  };
  enterpriseState.costs = {};
  enterpriseState.production = {
    expected: 0, unit: 'kg', sellingPrice: 0, priceLevel: '',
    lossPercent: 10, marketDistance: 0, distanceUnit: 'km',
    transportCost: 0, tripsCount: 0
  };
  enterpriseState.market = {
    where: '', confirmedBuyer: '', buyerCount: '',
    perishability: '', storage: ''
  };
  enterpriseState.experience = { level: '', concern: '' };
  enterpriseState.results = {
    totalCost: 0, contingencyAmount: 0, totalFunding: 0,
    marketableProduction: 0, grossRevenue: 0, variableCosts: 0,
    fixedCosts: 0, grossMargin: 0, netProfit: 0, profitMargin: 0,
    roi: 0, breakEvenPrice: 0, breakEvenProduction: 0,
    capitalUtilization: 0, maxCashRequirement: 0,
    risks: [], threats: [], sensitivity: {}
  };

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