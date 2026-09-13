// Farm Irrigation Water Calculator - JavaScript Logic
// Based on FAO crop water requirement methodology (FAO-56)
// This tool provides decision support, not guarantees of success
// Always use local knowledge and extension advice alongside this tool

// State Management
const waterState = {
  currentStep: 0,
  isLimitedWaterMode: false,
  
  // Farm Information
  farm: {
    country: '',
    area: 0,
    areaUnit: 'hectares'
  },
  
  // Crop Information
  crop: {
    name: '',
    growthStage: '',
    plantingDate: ''
  },
  
  // Soil Information
  soil: {
    type: '',
    moisture: ''
  },
  
  // Irrigation Method
  irrigation: {
    method: '',
    efficiencyKnowledge: '',
    systemEfficiency: 0
  },
  
  // Water Source
  waterSource: {
    type: '',
    capacity: 0,
    capacityUnit: 'l_per_hour',
    hasPump: false,
    pumpFlowRate: 0,
    pumpUnit: 'l_per_min',
    pumpHours: 0
  },
  
  // Weather
  weather: {
    conditions: '',
    recentRainfall: 0,
    expectedRain: ''
  },
  
  // Calculated Results
  results: {
    // Weather-based
    eto: 0,
    kc: 0,
    etc: 0,
    
    // Rainfall
    effectiveRainfall: 0,
    
    // Irrigation requirements
    netIrrigationRequirement: 0,
    grossIrrigationRequirement: 0,
    
    // Volumes
    volumePerDay: 0,
    volumePerDayM3: 0,
    
    // Water source
    availableWaterPerDay: 0,
    waterBalance: 0,
    waterBalancePercent: 0,
    
    // Pump runtime
    pumpRuntime: 0,
    
    // Warnings
    warnings: [],
    
    // Data sources
    dataSources: []
  }
};

// Crop Database with Growth Stages and Kc Values
// Based on FAO-56 and regional agricultural data
const cropDatabase = {
  maize: {
    name: 'Maize',
    category: 'Cereal',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.3, duration: 20 },
      development: { name: 'Vegetative', kc: 0.6, duration: 35 },
      mid: { name: 'Tasseling/Silking', kc: 1.2, duration: 40 },
      late: { name: 'Grain Filling', kc: 0.9, duration: 30 },
      harvest: { name: 'Maturity', kc: 0.6, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.8, max: 1.2 }, // metres
    waterRequirement: 'moderate',
    criticalStages: ['mid'], // Flowering/grain filling
    info: 'Maize has moderate water requirements. Critical water sensitivity during tasseling and silking. Can tolerate some drought stress during early growth.'
  },
  tomato: {
    name: 'Tomato',
    category: 'Vegetable',
    growthStages: {
      initial: { name: 'Transplant establishment', kc: 0.5, duration: 20 },
      development: { name: 'Vegetative growth', kc: 0.8, duration: 25 },
      mid: { name: 'Flowering/Fruit set', kc: 1.15, duration: 40 },
      late: { name: 'Fruit development', kc: 0.8, duration: 20 },
      harvest: { name: 'Ripening', kc: 0.6, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.6, max: 0.9 },
    waterRequirement: 'high',
    criticalStages: ['mid', 'late'], // Flowering, fruit set, fruit development
    info: 'Tomatoes have high water requirements and are sensitive to water stress during flowering and fruit development. Consistent moisture is important for fruit quality.'
  },
  cabbage: {
    name: 'Cabbage',
    category: 'Vegetable',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.5, duration: 20 },
      development: { name: 'Head formation', kc: 0.7, duration: 30 },
      mid: { name: 'Head development', kc: 1.0, duration: 40 },
      late: { name: 'Maturity', kc: 0.9, duration: 20 },
      harvest: { name: 'Harvest', kc: 0.7, duration: 10 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.6 },
    waterRequirement: 'moderate',
    criticalStages: ['mid'], // Head development
    info: 'Cabbage has moderate water requirements. Head development stage is critical. Inconsistent moisture can cause head cracking or poor head formation.'
  },
  onion: {
    name: 'Onion',
    category: 'Vegetable',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.5, duration: 25 },
      development: { name: 'Bulb initiation', kc: 0.7, duration: 35 },
      mid: { name: 'Bulb development', kc: 1.05, duration: 45 },
      late: { name: 'Bulb maturation', kc: 0.85, duration: 25 },
      harvest: { name: 'Harvest/Curing', kc: 0.7, duration: 15 }
    },
    rootDepth: { initial: 0.2, mid: 0.4, max: 0.5 },
    waterRequirement: 'moderate',
    criticalStages: ['mid'], // Bulb development
    info: 'Onions have shallow root systems and moderate water requirements. Bulb development is the most water-sensitive stage. Requires consistent moisture for good bulb size.'
  },
  potato: {
    name: 'Potato',
    category: 'Tuber',
    growthStages: {
      initial: { name: 'Plant establishment', kc: 0.4, duration: 25 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 30 },
      mid: { name: 'Tuber initiation/bulking', kc: 1.15, duration: 45 },
      late: { name: 'Tuber maturation', kc: 0.75, duration: 25 },
      harvest: { name: 'Harvest', kc: 0.4, duration: 10 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.6 },
    waterRequirement: 'moderate',
    criticalStages: ['mid'], // Tuber bulking
    info: 'Potatoes have moderate water requirements. Tuber bulking is the most water-sensitive stage. Over-irrigation can cause tuber rot, under-irrigation reduces tuber size.'
  },
  beans: {
    name: 'Beans',
    category: 'Legume',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.4, duration: 15 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 25 },
      mid: { name: 'Flowering/Pod set', kc: 1.1, duration: 30 },
      late: { name: 'Pod filling', kc: 0.9, duration: 20 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 10 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.7 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, pod set, pod filling
    info: 'Beans have moderate water requirements. Flowering and pod filling are critical stages. Can be sensitive to water stress during pod development.'
  },
  groundnuts: {
    name: 'Groundnuts',
    category: 'Legume',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.4, duration: 20 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 30 },
      mid: { name: 'Flowering/Pegging', kc: 1.0, duration: 40 },
      late: { name: 'Pod filling', kc: 0.8, duration: 30 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.6, max: 0.8 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, pegging, pod filling
    info: 'Groundnuts have moderate water requirements. Flowering and pod filling are critical. Pegging requires adequate soil moisture for proper pod development.'
  },
  soybean: {
    name: 'Soybean',
    category: 'Legume',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.4, duration: 20 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 30 },
      mid: { name: 'Flowering/Pod set', kc: 1.1, duration: 35 },
      late: { name: 'Pod filling', kc: 0.9, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.6, max: 0.9 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, pod set, pod filling
    info: 'Soybeans have moderate water requirements. Flowering and pod filling are critical stages. Can tolerate some drought stress but yield will be reduced.'
  },
  wheat: {
    name: 'Wheat',
    category: 'Cereal',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.3, duration: 20 },
      development: { name: 'Tillering', kc: 0.6, duration: 30 },
      mid: { name: 'Heading/Flowering', kc: 1.15, duration: 35 },
      late: { name: 'Grain filling', kc: 0.8, duration: 30 },
      harvest: { name: 'Maturity', kc: 0.4, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.8, max: 1.2 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Heading, flowering, grain filling
    info: 'Wheat has moderate water requirements. Heading and flowering are critical stages. Grain filling also requires adequate moisture for good yield.'
  },
  sorghum: {
    name: 'Sorghum',
    category: 'Cereal',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.3, duration: 20 },
      development: { name: 'Vegetative growth', kc: 0.5, duration: 30 },
      mid: { name: 'Heading/Flowering', kc: 1.0, duration: 35 },
      late: { name: 'Grain filling', kc: 0.7, duration: 30 },
      harvest: { name: 'Maturity', kc: 0.4, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.8, max: 1.5 },
    waterRequirement: 'low',
    criticalStages: ['mid'], // Heading, flowering
    info: 'Sorghum is relatively drought-tolerant with low to moderate water requirements. Heading and flowering are the most sensitive stages. Can withstand drought better than maize.'
  },
  millet: {
    name: 'Millet',
    category: 'Cereal',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.3, duration: 15 },
      development: { name: 'Vegetative growth', kc: 0.5, duration: 25 },
      mid: { name: 'Heading/Flowering', kc: 0.9, duration: 30 },
      late: { name: 'Grain filling', kc: 0.65, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.3, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.7, max: 1.2 },
    waterRequirement: 'low',
    criticalStages: ['mid'], // Heading, flowering
    info: 'Millet is drought-tolerant with low water requirements. Can grow in areas with limited rainfall. Heading and flowering are critical but plant is more resilient than other cereals.'
  },
  sugar_beans: {
    name: 'Sugar beans',
    category: 'Legume',
    growthStages: {
      initial: { name: 'Germination/Emergence', kc: 0.4, duration: 15 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 25 },
      mid: { name: 'Flowering/Pod set', kc: 1.1, duration: 30 },
      late: { name: 'Pod filling', kc: 0.9, duration: 20 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 10 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.7 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, pod set, pod filling
    info: 'Sugar beans have moderate water requirements similar to other beans. Flowering and pod filling are critical stages. Sensitive to water stress during pod development.'
  },
  sweet_potato: {
    name: 'Sweet potato',
    category: 'Root',
    growthStages: {
      initial: { name: 'Vine establishment', kc: 0.4, duration: 20 },
      development: { name: 'Vine growth', kc: 0.7, duration: 30 },
      mid: { name: 'Root development', kc: 0.9, duration: 40 },
      late: { name: 'Root bulking', kc: 0.7, duration: 30 },
      harvest: { name: 'Maturity', kc: 0.4, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.6 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Root development, bulking
    info: 'Sweet potatoes have moderate water requirements. Root development and bulking are critical stages. Once established, plants are relatively drought-tolerant.'
  },
  watermelon: {
    name: 'Watermelon',
    category: 'Fruit',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.4, duration: 20 },
      development: { name: 'Vine growth', kc: 0.7, duration: 30 },
      mid: { name: 'Flowering/Fruit set', kc: 1.0, duration: 35 },
      late: { name: 'Fruit development', kc: 0.8, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.6, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.8, max: 1.2 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, fruit set, fruit development
    info: 'Watermelons have moderate water requirements with deep roots. Flowering and fruit development are critical. Over-irrigation near harvest can reduce fruit quality.'
  },
  butternut: {
    name: 'Butternut',
    category: 'Fruit',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.4, duration: 20 },
      development: { name: 'Vine growth', kc: 0.7, duration: 30 },
      mid: { name: 'Flowering/Fruit set', kc: 0.95, duration: 35 },
      late: { name: 'Fruit development', kc: 0.75, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.7, max: 1.0 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, fruit set, fruit development
    info: 'Butternut has moderate water requirements. Flowering and fruit development are critical stages. Consistent moisture improves fruit size and quality.'
  },
  pumpkin: {
    name: 'Pumpkin',
    category: 'Fruit',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.4, duration: 20 },
      development: { name: 'Vine growth', kc: 0.7, duration: 30 },
      mid: { name: 'Flowering/Fruit set', kc: 0.95, duration: 35 },
      late: { name: 'Fruit development', kc: 0.75, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.5, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.8, max: 1.2 },
    waterRequirement: 'moderate',
    criticalStages: ['mid', 'late'], // Flowering, fruit set, fruit development
    info: 'Pumpkin has moderate water requirements with good root depth. Flowering and fruit development are critical. Can tolerate some drought once established.'
  },
  pepper: {
    name: 'Pepper',
    category: 'Vegetable',
    growthStages: {
      initial: { name: 'Transplant establishment', kc: 0.5, duration: 20 },
      development: { name: 'Vegetative growth', kc: 0.7, duration: 25 },
      mid: { name: 'Flowering/Fruit set', kc: 1.05, duration: 40 },
      late: { name: 'Fruit development', kc: 0.9, duration: 25 },
      harvest: { name: 'Maturity', kc: 0.7, duration: 15 }
    },
    rootDepth: { initial: 0.3, mid: 0.5, max: 0.7 },
    waterRequirement: 'high',
    criticalStages: ['mid', 'late'], // Flowering, fruit set, fruit development
    info: 'Pepper has high water requirements. Flowering and fruit development are critical stages. Inconsistent moisture can cause blossom end rot and poor fruit quality.'
  },
  spinach: {
    name: 'Spinach',
    category: 'Leafy vegetable',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.5, duration: 15 },
      development: { name: 'Leaf development', kc: 0.8, duration: 25 },
      mid: { name: 'Full canopy', kc: 1.0, duration: 20 },
      late: { name: 'Harvest stage', kc: 0.9, duration: 15 },
      harvest: { name: 'Harvest', kc: 0.7, duration: 10 }
    },
    rootDepth: { initial: 0.2, mid: 0.3, max: 0.4 },
    waterRequirement: 'high',
    criticalStages: ['mid'], // Full canopy
    info: 'Spinach has high water requirements with shallow roots. Requires consistent moisture for good leaf quality. Very sensitive to water stress.'
  },
  lettuce: {
    name: 'Lettuce',
    category: 'Leafy vegetable',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.5, duration: 15 },
      development: { name: 'Leaf development', kc: 0.8, duration: 25 },
      mid: { name: 'Head formation', kc: 1.0, duration: 20 },
      late: { name: 'Head maturation', kc: 0.9, duration: 15 },
      harvest: { name: 'Harvest', kc: 0.7, duration: 10 }
    },
    rootDepth: { initial: 0.2, mid: 0.3, max: 0.4 },
    waterRequirement: 'high',
    criticalStages: ['mid'], // Head formation
    info: 'Lettuce has high water requirements with very shallow roots. Requires consistent moisture for good head formation. Very sensitive to water stress and heat.'
  },
  carrot: {
    name: 'Carrot',
    category: 'Root',
    growthStages: {
      initial: { name: 'Seedling establishment', kc: 0.5, duration: 20 },
      development: { name: 'Root development', kc: 0.7, duration: 30 },
      mid: { name: 'Root bulking', kc: 1.0, duration: 35 },
      late: { name: 'Root maturation', kc: 0.8, duration: 20 },
      harvest: { name: 'Harvest', kc: 0.6, duration: 10 }
    },
    rootDepth: { initial: 0.2, mid: 0.4, max: 0.6 },
    waterRequirement: 'moderate',
    criticalStages: ['mid'], // Root bulking
    info: 'Carrot has moderate water requirements. Root bulking is critical. Inconsistent moisture can cause forking or poor root development. Requires good soil structure.'
  }
};

// Soil Water Holding Capacity (Reference values)
// Based on FAO soil classification
const soilDatabase = {
  sand: {
    name: 'Sand',
    fieldCapacity: 0.12, // % by volume
    wiltingPoint: 0.04,
    availableWater: 0.08,
    infiltrationRate: 'fast',
    description: 'Sandy soils drain quickly and hold less water. They typically need smaller, more frequent irrigation applications.'
  },
  sandy_loam: {
    name: 'Sandy loam',
    fieldCapacity: 0.18,
    wiltingPoint: 0.07,
    availableWater: 0.11,
    infiltrationRate: 'moderately fast',
    description: 'Sandy loam soils have moderate water storage and drainage. They offer a balance between water retention and infiltration.'
  },
  loam: {
    name: 'Loam',
    fieldCapacity: 0.25,
    wiltingPoint: 0.10,
    availableWater: 0.15,
    infiltrationRate: 'moderate',
    description: 'Loam soils have good water storage and drainage. They are often considered ideal for many crops as they balance water retention and aeration.'
  },
  clay_loam: {
    name: 'Clay loam',
    fieldCapacity: 0.32,
    wiltingPoint: 0.15,
    availableWater: 0.17,
    infiltrationRate: 'slow',
    description: 'Clay loam soils hold more water but absorb it more slowly. They can become waterlogged if over-irrigated.'
  },
  clay: {
    name: 'Clay',
    fieldCapacity: 0.40,
    wiltingPoint: 0.20,
    availableWater: 0.20,
    infiltrationRate: 'very slow',
    description: 'Clay soils hold the most water but have very slow infiltration. They are prone to waterlogging and cracking when dry.'
  }
};

// Irrigation Method Efficiency (Reference values)
// Based on FAO indicative field application efficiencies
const irrigationEfficiency = {
  drip: { efficiency: 0.90, description: 'Drip irrigation can achieve high efficiency when properly designed and maintained. Actual performance depends on system design, pressure uniformity, emitter condition, and management.' },
  sprinkler: { efficiency: 0.75, description: 'Sprinkler efficiency varies with wind, humidity, pressure uniformity, and system design. Overlap and proper pressure management are important for good performance.' },
  furrow: { efficiency: 0.60, description: 'Furrow irrigation efficiency depends on field length, slope, soil type, and inflow rate. Shorter furrows and proper management can improve efficiency.' },
  basin: { efficiency: 0.55, description: 'Basin irrigation efficiency depends on field leveling, soil infiltration rate, and application time. Level fields and proper cutoff improve efficiency.' },
  flood: { efficiency: 0.50, description: 'Flood irrigation often has lower efficiency due to runoff, deep percolation, and uneven distribution. Requires careful management to reduce losses.' },
  watering_can: { efficiency: 0.70, description: 'Watering can efficiency depends on operator skill and technique. Can be reasonably efficient when water is applied directly to the root zone.' },
  hose: { efficiency: 0.65, description: 'Hose irrigation efficiency depends on application technique and pressure. Can be moderately efficient when carefully managed.' },
  other: { efficiency: 0.65, description: 'Efficiency depends on the specific method and how it is managed. Measure actual performance where possible.' }
};

// Reference ETo values by weather condition (mm/day)
// These are indicative values for planning when specific weather data is unavailable
const referenceETo = {
  hot_dry: 6.0,
  moderate: 4.0,
  cool: 2.5,
  rainy: 3.0,
  not_sure: 4.0
};

// Effective Rainfall Estimation (FAO USDA-SCS method simplified)
function calculateEffectiveRainfall(totalRainfall, etc) {
  // Simplified FAO method for planning
  // Effective rainfall is the portion that contributes to crop water need
  if (totalRainfall <= 0) return 0;
  
  // Very simplified: assume 60-80% of rainfall is effective for most soils
  // This is a planning estimate, not precise calculation
  const effectiveness = 0.7; // 70% effective rainfall assumption
  const effective = totalRainfall * effectiveness;
  
  // Effective rainfall cannot exceed crop water demand
  return Math.min(effective, etc);
}

// Navigation Functions
function startTool() {
  showSection('farmSection');
  updateProgress(1);
  waterState.currentStep = 1;
  waterState.isLimitedWaterMode = false;
}

function startLimitedWaterMode() {
  alert('Limited water mode coming soon. For now, use the main calculator to understand your water requirements, then we can help you plan with limited water.');
  startTool();
}

function showIrrigationHelp() {
  alert('This feature is coming soon. For now, use the calculator to understand your water needs, and check the educational content below for irrigation guidance.');
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
  const stepBack = waterState.currentStep - 1;
  if (stepBack >= 0) {
    waterState.currentStep = stepBack;
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
      showSection('farmSection');
      break;
    case 2:
      showSection('cropSection');
      break;
    case 3:
      showSection('soilSection');
      break;
    case 4:
      showSection('irrigationSection');
      break;
    case 5:
      showSection('waterSourceSection');
      break;
    case 6:
      showSection('weatherSection');
      break;
    case 7:
      showSection('finalResult');
      break;
  }
}

// Toggle "Why does this matter?" explanations
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

// Farm Information Functions
function confirmFarm() {
  const country = document.getElementById('countrySelect').value;
  const area = document.getElementById('farmArea').value;
  const areaUnit = document.getElementById('areaUnit').value;

  if (!area) {
    alert('Please enter your farm area');
    return;
  }

  waterState.farm.country = country;
  waterState.farm.area = parseFloat(area);
  waterState.farm.areaUnit = areaUnit;

  waterState.currentStep = 2;
  showSection('cropSection');
  updateProgress(2);
}

// Crop Selection Functions
function showCropInfo() {
  const cropKey = document.getElementById('cropSelect').value;
  const cropInfoBox = document.getElementById('cropInfoBox');
  const cropInfoText = document.getElementById('cropInfoText');
  const growthStageSelect = document.getElementById('growthStage');

  growthStageSelect.innerHTML = '<option value="">Select growth stage</option>';

  if (cropKey && cropDatabase[cropKey]) {
    const crop = cropDatabase[cropKey];
    cropInfoText.textContent = crop.info;
    cropInfoBox.classList.remove('hidden');

    // Populate growth stages
    Object.keys(crop.growthStages).forEach(stageKey => {
      const stage = crop.growthStages[stageKey];
      const option = document.createElement('option');
      option.value = stageKey;
      option.textContent = stage.name;
      growthStageSelect.appendChild(option);
    });
  } else {
    cropInfoBox.classList.add('hidden');
  }
}

function confirmCrop() {
  const cropKey = document.getElementById('cropSelect').value;
  const growthStage = document.getElementById('growthStage').value;
  const plantingDate = document.getElementById('plantingDate').value;

  if (!cropKey) {
    alert('Please select a crop');
    return;
  }
  if (!growthStage) {
    alert('Please select the growth stage');
    return;
  }

  waterState.crop.name = cropKey;
  waterState.crop.growthStage = growthStage;
  waterState.crop.plantingDate = plantingDate;

  waterState.currentStep = 3;
  showSection('soilSection');
  updateProgress(3);
}

// Soil Functions
function selectSoil(soilType) {
  const buttons = document.querySelectorAll('[data-soil]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-soil="${soilType}"]`).classList.add('selected');
  waterState.soil.type = soilType;
}

function selectSoilMoisture(moisture) {
  const buttons = document.querySelectorAll('[data-moisture]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-moisture="${moisture}"]`).classList.add('selected');
  waterState.soil.moisture = moisture;
}

function confirmSoil() {
  const soilType = waterState.soil.type;
  const soilMoisture = waterState.soil.moisture;

  if (!soilType) {
    alert('Please select your soil type');
    return;
  }
  if (!soilMoisture) {
    alert('Please select the current soil moisture');
    return;
  }

  waterState.currentStep = 4;
  showSection('irrigationSection');
  updateProgress(4);
}

// Irrigation Method Functions
function selectIrrigationMethod(method) {
  const buttons = document.querySelectorAll('[data-method]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-method="${method}"]`).classList.add('selected');
  waterState.irrigation.method = method;
}

function selectEfficiencyKnowledge(knowledge) {
  const buttons = document.querySelectorAll('[data-efficiency]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-efficiency="${knowledge}"]`).classList.add('selected');
  waterState.irrigation.efficiencyKnowledge = knowledge;

  const efficiencyInputGroup = document.getElementById('efficiencyInputGroup');
  if (knowledge === 'yes') {
    efficiencyInputGroup.classList.remove('hidden');
  } else {
    efficiencyInputGroup.classList.add('hidden');
  }
}

function confirmIrrigation() {
  const method = waterState.irrigation.method;
  const efficiencyKnowledge = waterState.irrigation.efficiencyKnowledge;
  const systemEfficiency = document.getElementById('systemEfficiency').value;

  if (!method) {
    alert('Please select your irrigation method');
    return;
  }
  if (!efficiencyKnowledge) {
    alert('Please select whether you know your system efficiency');
    return;
  }

  waterState.irrigation.method = method;

  if (efficiencyKnowledge === 'yes' && systemEfficiency) {
    waterState.irrigation.systemEfficiency = parseFloat(systemEfficiency) / 100;
  } else if (irrigationEfficiency[method]) {
    waterState.irrigation.systemEfficiency = irrigationEfficiency[method].efficiency;
  }

  waterState.currentStep = 5;
  showSection('waterSourceSection');
  updateProgress(5);
}

// Water Source Functions
function selectWaterSource(source) {
  const buttons = document.querySelectorAll('[data-source]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-source="${source}"]`).classList.add('selected');
  waterState.waterSource.type = source;
}

function selectPump(hasPump) {
  const buttons = document.querySelectorAll('[data-pump]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-pump="${hasPump}"]`).classList.add('selected');
  waterState.waterSource.hasPump = hasPump === 'yes';

  const pumpDetailsGroup = document.getElementById('pumpDetailsGroup');
  const pumpHoursGroup = document.getElementById('pumpHoursGroup');

  if (hasPump === 'yes') {
    pumpDetailsGroup.classList.remove('hidden');
    pumpHoursGroup.classList.remove('hidden');
  } else {
    pumpDetailsGroup.classList.add('hidden');
    pumpHoursGroup.classList.add('hidden');
  }
}

function confirmWaterSource() {
  const source = waterState.waterSource.type;
  const capacity = document.getElementById('sourceCapacity').value;
  const capacityUnit = document.getElementById('capacityUnit').value;
  const hasPump = waterState.waterSource.hasPump;
  const pumpFlowRate = document.getElementById('pumpFlowRate').value;
  const pumpUnit = document.getElementById('pumpUnit').value;
  const pumpHours = document.getElementById('pumpHours').value;

  if (!source) {
    alert('Please select your water source');
    return;
  }
  if (!capacity) {
    alert('Please enter your water source capacity');
    return;
  }

  waterState.waterSource.type = source;
  waterState.waterSource.capacity = parseFloat(capacity);
  waterState.waterSource.capacityUnit = capacityUnit;

  if (hasPump) {
    if (!pumpFlowRate) {
      alert('Please enter your pump flow rate');
      return;
    }
    if (!pumpHours) {
      alert('Please enter how many hours you can operate the pump');
      return;
    }
    waterState.waterSource.pumpFlowRate = parseFloat(pumpFlowRate);
    waterState.waterSource.pumpUnit = pumpUnit;
    waterState.waterSource.pumpHours = parseFloat(pumpHours);
  }

  waterState.currentStep = 6;
  showSection('weatherSection');
  updateProgress(6);
}

// Weather Functions
function selectWeather(conditions) {
  const buttons = document.querySelectorAll('[data-weather]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-weather="${conditions}"]`).classList.add('selected');
  waterState.weather.conditions = conditions;
}

function selectExpectedRain(expected) {
  const buttons = document.querySelectorAll('[data-expected-rain]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-expected-rain="${expected}"]`).classList.add('selected');
  waterState.weather.expectedRain = expected;
}

function confirmWeather() {
  const conditions = waterState.weather.conditions;
  const recentRainfall = document.getElementById('recentRainfall').value;
  const expectedRain = waterState.weather.expectedRain;

  if (!conditions) {
    alert('Please select current weather conditions');
    return;
  }

  waterState.weather.conditions = conditions;
  waterState.weather.recentRainfall = parseFloat(recentRainfall) || 0;
  waterState.weather.expectedRain = expectedRain;

  calculateResults();
  waterState.currentStep = 7;
  showSection('finalResult');
  updateProgress(7);
}

// Main Calculation Function
function calculateResults() {
  const state = waterState;
  const results = state.results;

  // Convert area to hectares
  let areaInHectares = state.farm.area;
  if (state.farm.areaUnit === 'acres') {
    areaInHectares = state.farm.area * 0.404686; // 1 acre = 0.404686 hectares
  } else if (state.farm.areaUnit === 'sqm') {
    areaInHectares = state.farm.area / 10000; // 1 hectare = 10,000 sqm
  }

  // Get ETo based on weather conditions
  results.eto = referenceETo[state.weather.conditions] || 4.0;

  // Get Kc based on crop and growth stage
  const crop = cropDatabase[state.crop.name];
  if (crop && crop.growthStages[state.crop.growthStage]) {
    results.kc = crop.growthStages[state.crop.growthStage].kc;
  } else {
    results.kc = 1.0; // Default if unknown
  }

  // Calculate ETc (Crop evapotranspiration)
  // ETc = ETo × Kc (FAO-56 methodology)
  results.etc = results.eto * results.kc;

  // Calculate effective rainfall
  results.effectiveRainfall = calculateEffectiveRainfall(state.weather.recentRainfall, results.etc);

  // Calculate net irrigation requirement
  // Net IR = ETc - Effective Rainfall
  results.netIrrigationRequirement = Math.max(0, results.etc - results.effectiveRainfall);

  // Calculate gross irrigation requirement
  // Gross IR = Net IR ÷ Efficiency
  const efficiency = state.irrigation.systemEfficiency || 0.7;
  results.grossIrrigationRequirement = results.netIrrigationRequirement / efficiency;

  // Calculate volume per day
  // 1 mm over 1 hectare = 10,000 litres
  results.volumePerDay = results.grossIrrigationRequirement * 10000 * areaInHectares;
  results.volumePerDayM3 = results.volumePerDay / 1000; // Convert to cubic metres

  // Calculate available water per day
  results.availableWaterPerDay = convertToLitresPerDay(
    state.waterSource.capacity,
    state.waterSource.capacityUnit,
    state.waterSource.hasPump,
    state.waterSource.pumpFlowRate,
    state.waterSource.pumpUnit,
    state.waterSource.pumpHours
  );

  // Calculate water balance
  results.waterBalance = results.availableWaterPerDay - results.volumePerDay;
  if (results.volumePerDay > 0) {
    results.waterBalancePercent = (results.waterBalance / results.volumePerDay) * 100;
  } else {
    results.waterBalancePercent = 0;
  }

  // Calculate pump runtime
  if (state.waterSource.hasPump && state.waterSource.pumpFlowRate > 0) {
    const pumpFlowLPerDay = convertToLitresPerDay(
      state.waterSource.pumpFlowRate,
      state.waterSource.pumpUnit,
      false,
      0,
      '',
      state.waterSource.pumpHours
    );
    if (pumpFlowLPerDay > 0) {
      results.pumpRuntime = (results.volumePerDay / pumpFlowLPerDay) * state.waterSource.pumpHours;
    }
  }

  // Generate warnings
  generateWarnings();

  // Update UI
  updateResultsUI();
}

function convertToLitresPerDay(capacity, unit, hasPump, pumpFlowRate, pumpUnit, pumpHours) {
  let litresPerDay = 0;

  // Convert source capacity to litres per day
  switch (unit) {
    case 'l_per_hour':
      litresPerDay = capacity * 24;
      break;
    case 'l_per_min':
      litresPerDay = capacity * 60 * 24;
      break;
    case 'm3_per_hour':
      litresPerDay = capacity * 1000 * 24;
      break;
    case 'm3_per_day':
      litresPerDay = capacity * 1000;
      break;
  }

  // If pump is the limiting factor, use pump capacity
  if (hasPump && pumpFlowRate > 0 && pumpHours > 0) {
    let pumpLitresPerDay = 0;
    switch (pumpUnit) {
      case 'l_per_min':
        pumpLitresPerDay = pumpFlowRate * 60 * pumpHours;
        break;
      case 'l_per_hour':
        pumpLitresPerDay = pumpFlowRate * pumpHours;
        break;
      case 'm3_per_hour':
        pumpLitresPerDay = pumpFlowRate * 1000 * pumpHours;
        break;
    }
    // Use the smaller of source capacity or pump capacity
    litresPerDay = Math.min(litresPerDay, pumpLitresPerDay);
  }

  return litresPerDay;
}

function generateWarnings() {
  const state = waterState;
  const results = state.results;
  results.warnings = [];

  // Water shortage warning
  if (results.waterBalance < -0.1 * results.volumePerDay) {
    results.warnings.push({
      type: 'shortage',
      message: `Your water source may not provide enough water. Estimated requirement: ${results.volumePerDay.toLocaleString()} L/day. Available: ${results.availableWaterPerDay.toLocaleString()} L/day. Shortage: ${Math.abs(results.waterBalance).toLocaleString()} L/day (${Math.abs(results.waterBalancePercent).toFixed(0)}%).`
    });
  }

  // Very wet soil warning
  if (state.soil.moisture === 'very_wet') {
    results.warnings.push({
      type: 'over_irrigation',
      message: 'Your soil is very wet. Do not automatically add more water. Check drainage and soil moisture before irrigating again to avoid waterlogging and root problems.'
    });
  }

  // Very dry soil warning
  if (state.soil.moisture === 'very_dry') {
    results.warnings.push({
      type: 'under_irrigation',
      message: 'Your soil is very dry. The crop may already be under water stress. The appropriate irrigation amount depends on soil type, root zone, and crop. Consider starting with a moderate irrigation and checking soil moisture response.'
    });
  }

  // Expected heavy rain warning
  if (state.weather.expectedRain === 'heavy') {
    results.warnings.push({
      type: 'rain_expected',
      message: 'Heavy rain is expected. Check actual rainfall and soil moisture before irrigating. Recent rainfall may supply part or all of the crop water requirement, reducing or eliminating the need for irrigation.'
    });
  }

  // Low efficiency warning
  if (state.irrigation.systemEfficiency < 0.6) {
    results.warnings.push({
      type: 'low_efficiency',
      message: `Your irrigation system efficiency is estimated at ${(state.irrigation.systemEfficiency * 100).toFixed(0)}%. This means approximately ${((1 - state.irrigation.systemEfficiency) * 100).toFixed(0)}% of water is lost before reaching the crop. Consider system improvements to reduce water waste and pumping costs.`
    });
  }
}

function updateResultsUI() {
  const state = waterState;
  const results = state.results;

  // Update crop information
  const crop = cropDatabase[state.crop.name];
  document.getElementById('resultCrop').textContent = crop ? crop.name : state.crop.name;
  document.getElementById('resultGrowthStage').textContent = crop && crop.growthStages[state.crop.growthStage] ? crop.growthStages[state.crop.growthStage].name : state.crop.growthStage;
  document.getElementById('resultArea').textContent = `${state.farm.area} ${state.farm.areaUnit}`;
  document.getElementById('resultSoil').textContent = soilDatabase[state.soil.type] ? soilDatabase[state.soil.type].name : state.soil.type;
  document.getElementById('resultIrrigationMethod').textContent = state.irrigation.method;

  // Update water requirements
  document.getElementById('resultCropWaterDemand').textContent = `${results.etc.toFixed(1)} mm/day`;
  document.getElementById('resultIrrigationRequirement').textContent = `${results.netIrrigationRequirement.toFixed(1)} mm/day`;
  document.getElementById('resultGrossRequirement').textContent = `${results.grossIrrigationRequirement.toFixed(1)} mm/day`;
  document.getElementById('resultVolumePerDay').textContent = `${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day (${results.volumePerDayM3.toFixed(1)} m³/day)`;

  // Update water balance
  const waterBalance = document.getElementById('waterBalance');
  const balanceStatus = document.getElementById('balanceStatus');
  const balanceExplanation = document.getElementById('balanceExplanation');

  if (results.waterBalance >= 0.1 * results.volumePerDay) {
    waterBalance.className = 'water-balance sufficient';
    balanceStatus.textContent = 'WATER SUPPLY LOOKS SUFFICIENT';
    balanceExplanation.textContent = `Your available water (${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day) appears sufficient to meet the estimated irrigation requirement (${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day) under the current assumptions.`;
  } else if (results.waterBalance >= -0.1 * results.volumePerDay) {
    waterBalance.className = 'water-balance tight';
    balanceStatus.textContent = 'WATER SUPPLY LOOKS TIGHT';
    balanceExplanation.textContent = `Your available water (${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day) is close to the estimated requirement (${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day). Monitor water usage and soil moisture closely.`;
  } else {
    waterBalance.className = 'water-balance shortage';
    balanceStatus.textContent = 'WATER SUPPLY SHORTAGE';
    balanceExplanation.textContent = `Your available water (${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day) may not meet the estimated requirement (${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day). Shortage: ${Math.abs(results.waterBalance).toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day (${Math.abs(results.waterBalancePercent).toFixed(0)}%).`;
  }

  // Update water source capacity
  document.getElementById('resultAvailableWater').textContent = `${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day`;
  document.getElementById('resultWaterBalance').textContent = results.waterBalance >= 0 ? `+${results.waterBalance.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day` : `${results.waterBalance.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day`;

  // Update pump runtime
  const pumpRuntimeBox = document.getElementById('pumpRuntimeBox');
  if (state.waterSource.hasPump && results.pumpRuntime > 0) {
    pumpRuntimeBox.classList.remove('hidden');
    document.getElementById('resultPumpRuntime').textContent = `${results.pumpRuntime.toFixed(1)} hours/day`;
  } else {
    pumpRuntimeBox.classList.add('hidden');
  }

  // Update warnings
  const warningBox = document.getElementById('warningBox');
  const warningContent = document.getElementById('warningContent');
  if (results.warnings.length > 0) {
    warningBox.classList.remove('hidden');
    warningContent.innerHTML = results.warnings.map(warning => `<p style="margin: 0.5rem 0;">${warning.message}</p>`).join('');
  } else {
    warningBox.classList.add('hidden');
  }

  // Update main recommendation
  updateMainRecommendation();

  // Update what this means
  updateWhatThisMeans();

  // Update what to check
  updateWhatToCheck();

  // Update what you can change
  updateWhatYouCanChange();

  // Update calculation details
  updateCalculationDetails();
}

function updateMainRecommendation() {
  const state = waterState;
  const results = state.results;
  const mainRecommendation = document.getElementById('mainRecommendation');

  if (results.waterBalance < -0.2 * results.volumePerDay) {
    mainRecommendation.textContent = 'Your current water source may not provide enough water to meet the estimated irrigation requirement. Consider reducing irrigated area, improving irrigation efficiency, increasing water storage, or selecting a crop with lower water requirements.';
  } else if (results.waterBalance < 0) {
    mainRecommendation.textContent = 'Your water supply looks tight. Monitor water usage closely and check soil moisture before each irrigation. Consider improving system efficiency or having a backup water plan.';
  } else if (state.soil.moisture === 'very_wet') {
    mainRecommendation.textContent = 'Your soil is currently very wet. Check drainage and soil moisture before applying more water. Irrigation may not be needed at this time.';
  } else if (state.weather.expectedRain === 'heavy') {
    mainRecommendation.textContent = 'Heavy rain is expected. Check actual rainfall before irrigating. Recent rainfall may supply part or all of the crop water requirement.';
  } else {
    mainRecommendation.textContent = 'Your water supply appears sufficient under the current assumptions. Check soil moisture regularly and adjust irrigation based on actual conditions and weather changes.';
  }
}

function updateWhatThisMeans() {
  const state = waterState;
  const results = state.results;
  const whatThisMeans = document.getElementById('whatThisMeans');

  let explanation = `Based on your crop (${cropDatabase[state.crop.name]?.name || state.crop.name}) at the ${cropDatabase[state.crop.name]?.growthStages[state.crop.growthStage]?.name || state.crop.growthStage} stage, the estimated crop water demand is ${results.etc.toFixed(1)} mm/day. After considering recent rainfall (${state.weather.recentRainfall} mm), the estimated irrigation requirement is ${results.netIrrigationRequirement.toFixed(1)} mm/day. Due to your irrigation system efficiency (${(state.irrigation.systemEfficiency * 100).toFixed(0)}%), you need to deliver approximately ${results.grossIrrigationRequirement.toFixed(1)} mm/day, which equals ${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} litres for your ${state.farm.area} ${state.farm.areaUnit}.`;

  whatThisMeans.textContent = explanation;
}

function updateWhatToCheck() {
  const whatToCheck = document.getElementById('whatToCheck');
  const checks = [
    'Check soil moisture before the next irrigation',
    'Measure your actual pump flow rate if you haven\'t',
    'Check your irrigation system for leaks or uneven distribution',
    'Confirm the latest rainfall amount',
    'Monitor your crop for signs of water stress',
    'Check that your water source is actually delivering the expected flow'
  ];

  whatToCheck.innerHTML = checks.map(check => `<li>${check}</li>`).join('');
}

function updateWhatYouCanChange() {
  const whatYouCanChange = document.getElementById('whatYouCanChange');
  const state = waterState;
  const results = state.results;

  const changes = [];

  if (results.waterBalance < 0) {
    changes.push('Reduce irrigated area to match available water');
    changes.push('Improve irrigation system efficiency to reduce water waste');
    changes.push('Increase water storage capacity');
    changes.push('Consider crops with lower water requirements');
  }

  if (state.irrigation.systemEfficiency < 0.8) {
    changes.push('Repair leaks and maintain emitters/sprinklers');
    changes.push('Improve system design and pressure uniformity');
  }

  if (state.soil.moisture === 'very_dry') {
    changes.push('Apply a moderate irrigation and check soil moisture response');
    changes.push('Consider mulching to reduce soil evaporation');
  }

  changes.push('Recalculate when the crop enters a new growth stage');
  changes.push('Recalculate after significant rainfall or weather changes');

  whatYouCanChange.innerHTML = changes.map(change => `<li>${change}</li>`).join('');
}

function updateCalculationDetails() {
  const state = waterState;
  const results = state.results;
  const calculationExplanation = document.getElementById('calculationExplanation');

  let explanation = `
    <div class="calculation-row">
      <span class="calculation-label">Area:</span>
      <span class="calculation-value">${state.farm.area} ${state.farm.areaUnit}</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">ETo (weather demand):</span>
      <span class="calculation-value">${results.eto.toFixed(1)} mm/day</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Kc (crop coefficient):</span>
      <span class="calculation-value">${results.kc.toFixed(2)}</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">ETc (crop water use):</span>
      <span class="calculation-value">${results.etc.toFixed(1)} mm/day</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Recent rainfall:</span>
      <span class="calculation-value">${state.weather.recentRainfall} mm</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Effective rainfall:</span>
      <span class="calculation-value">${results.effectiveRainfall.toFixed(1)} mm</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Net irrigation requirement:</span>
      <span class="calculation-value">${results.netIrrigationRequirement.toFixed(1)} mm/day</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">System efficiency:</span>
      <span class="calculation-value">${(state.irrigation.systemEfficiency * 100).toFixed(0)}%</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Gross irrigation requirement:</span>
      <span class="calculation-value">${results.grossIrrigationRequirement.toFixed(1)} mm/day</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Volume per day:</span>
      <span class="calculation-value">${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L</span>
    </div>
    <div class="calculation-row">
      <span class="calculation-label">Available water:</span>
      <span class="calculation-value">${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day</span>
    </div>
  `;

  calculationExplanation.innerHTML = explanation;
}

function toggleCalculationDetails() {
  const details = document.getElementById('calculationDetails');
  details.classList.toggle('hidden');
}

// Save and Download Functions
function saveResult() {
  const state = waterState;
  const result = {
    date: new Date().toISOString(),
    farm: state.farm,
    crop: state.crop,
    soil: state.soil,
    irrigation: state.irrigation,
    waterSource: state.waterSource,
    weather: state.weather,
    results: state.results
  };

  try {
    const savedResults = JSON.parse(localStorage.getItem('waterCheckResults') || '[]');
    savedResults.push(result);
    localStorage.setItem('waterCheckResults', JSON.stringify(savedResults));
    alert('Your water plan has been saved locally on this device.');
  } catch (e) {
    alert('Could not save result. Your browser may not support local storage.');
  }
}

function downloadResult() {
  const state = waterState;
  const result = generateResultText();

  const blob = new Blob([result], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `water-plan-${state.crop.name}-${new Date().toISOString().split('T')[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function generateResultText() {
  const state = waterState;
  const results = state.results;

  let text = `FARM IRRIGATION WATER PLAN\n`;
  text += `=============================\n\n`;
  text += `Date: ${new Date().toLocaleDateString()}\n`;
  text += `Crop: ${cropDatabase[state.crop.name]?.name || state.crop.name}\n`;
  text += `Growth stage: ${cropDatabase[state.crop.name]?.growthStages[state.crop.growthStage]?.name || state.crop.growthStage}\n`;
  text += `Area: ${state.farm.area} ${state.farm.areaUnit}\n`;
  text += `Soil type: ${soilDatabase[state.soil.type]?.name || state.soil.type}\n`;
  text += `Irrigation method: ${state.irrigation.method}\n\n`;

  text += `WATER REQUIREMENTS\n`;
  text += `===================\n`;
  text += `Crop water demand: ${results.etc.toFixed(1)} mm/day\n`;
  text += `Net irrigation requirement: ${results.netIrrigationRequirement.toFixed(1)} mm/day\n`;
  text += `System efficiency: ${(state.irrigation.systemEfficiency * 100).toFixed(0)}%\n`;
  text += `Gross irrigation requirement: ${results.grossIrrigationRequirement.toFixed(1)} mm/day\n`;
  text += `Estimated volume: ${results.volumePerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day\n\n`;

  text += `WATER SOURCE\n`;
  text += `============\n`;
  text += `Source type: ${state.waterSource.type}\n`;
  text += `Available water: ${results.availableWaterPerDay.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day\n`;
  text += `Water balance: ${results.waterBalance >= 0 ? '+' : ''}${results.waterBalance.toLocaleString(undefined, { maximumFractionDigits: 0 })} L/day\n\n`;

  if (state.waterSource.hasPump && results.pumpRuntime > 0) {
    text += `PUMP RUNTIME\n`;
    text += `============\n`;
    text += `Estimated pumping time: ${results.pumpRuntime.toFixed(1)} hours/day\n\n`;
  }

  if (results.warnings.length > 0) {
    text += `WARNINGS\n`;
    text += `=========\n`;
    results.warnings.forEach((warning, index) => {
      text += `${index + 1}. ${warning.message}\n`;
    });
    text += '\n';
  }

  text += `DISCLAIMER\n`;
  text += `==========\n`;
  text += `This result is based on the information you entered and available agricultural data at the time of calculation. Water requirements change with weather, soil, crop growth and rainfall. Use this as a planning guide and check soil moisture and crop conditions regularly. Always use your own judgment and local knowledge. Consult local agricultural extension services for precise local recommendations.\n`;

  return text;
}

function restartTool() {
  // Reset state
  waterState.currentStep = 0;
  waterState.isLimitedWaterMode = false;
  waterState.farm = { country: '', area: 0, areaUnit: 'hectares' };
  waterState.crop = { name: '', growthStage: '', plantingDate: '' };
  waterState.soil = { type: '', moisture: '' };
  waterState.irrigation = { method: '', efficiencyKnowledge: '', systemEfficiency: 0 };
  waterState.waterSource = {
    type: '', capacity: 0, capacityUnit: 'l_per_hour',
    hasPump: false, pumpFlowRate: 0, pumpUnit: 'l_per_min', pumpHours: 0
  };
  waterState.weather = { conditions: '', recentRainfall: 0, expectedRain: '' };
  waterState.results = {
    eto: 0, kc: 0, etc: 0, effectiveRainfall: 0,
    netIrrigationRequirement: 0, grossIrrigationRequirement: 0,
    volumePerDay: 0, volumePerDayM3: 0,
    availableWaterPerDay: 0, waterBalance: 0, waterBalancePercent: 0,
    pumpRuntime: 0, warnings: [], dataSources: []
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