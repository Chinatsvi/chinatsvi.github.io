// Planting Decision Tool - JavaScript Logic
// This tool provides decision support for farmers, not guarantees of success
// Always use local knowledge and extension advice alongside this tool

// State Management
const plantingState = {
  currentStep: 0,
  location: {
    country: '',
    province: '',
    district: '',
    hasLocalData: false
  },
  crop: {
    type: '',
    name: '',
    info: ''
  },
  farming: {
    method: '',
    waterSource: ''
  },
  land: {
    preparation: ''
  },
  soil: {
    moisture: ''
  },
  water: {
    availability: ''
  },
  weather: {
    current: '',
    recentRain: ''
  },
  planting: {
    plannedDate: '',
    plannedOption: '',
    withinWindow: false
  },
  business: {
    costCalculated: '',
    marketPlanned: ''
  },
  risks: [],
  recommendations: []
};

// Crop Database - This can be expanded and updated
const cropDatabase = {
  maize: {
    name: 'Maize',
    description: 'Maize needs suitable temperature, adequate water, and good soil conditions. It is sensitive to water stress during flowering and grain filling. Planting when conditions are unsuitable can cause poor germination, reduced yield, and increased pest problems.',
    plantingWindows: {
      zimbabwe: {
        natural_regions: {
          'I': 'November - December',
          'IIa': 'November - mid December',
          'IIb': 'mid November - December',
          'III': 'December - early January',
          'IV': 'December - January',
          'V': 'January - February'
        },
        general: 'November - January (main season), February - March (late season)'
      },
      kenya: {
        regions: {
          'highlands': 'March - May, October - November',
          'medium_altitude': 'March - May, October - December',
          'lowlands': 'April - May, November - December'
        },
        general: 'March - May (long rains), October - December (short rains)'
      },
      south_africa: {
        provinces: {
          'mpumalanga': 'October - November',
          'free_state': 'October - November',
          'north_west': 'October - November',
          'limpopo': 'November - December',
          'kwazulu_natal': 'October - December'
        },
        general: 'October - December'
      },
      general: 'Varies by location - typically start of rainy season'
    },
    conditions: [
      {
        title: 'Suitable temperature',
        description: 'Maize grows best between 15-30°C. Frost can damage young plants.',
        importance: 'Temperature affects germination, growth rate, and flowering time.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, especially during germination and flowering.',
        importance: 'Water stress during flowering can cause poor pollination and reduced grain filling.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained soil prevents waterlogging and root diseases.',
        importance: 'Waterlogged conditions can kill young plants and reduce yield.'
      },
      {
        title: 'Seed quality',
        description: 'Use certified, disease-free seed suitable for your area.',
        importance: 'Good seed is the foundation of a healthy crop.'
      },
      {
        title: 'Fertilizer plan',
        description: 'Plan nitrogen, phosphorus, and potassium based on soil test.',
        importance: 'Maize is a heavy feeder and responds well to proper fertilization.'
      },
      {
        title: 'Weed control',
        description: 'Plan for weed control, especially in the first 6-8 weeks.',
        importance: 'Weeds compete fiercely with young maize for water and nutrients.'
      },
      {
        title: 'Expected rainfall',
        description: 'Ensure adequate rainfall during the growing season (3-4 months).',
        importance: 'Maize needs consistent water throughout the growing period.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-30°C',
    frostSensitive: true,
    droughtTolerance: 'moderate'
  },
  tomato: {
    name: 'Tomato',
    description: 'Tomato needs warm temperatures, consistent water, and good soil drainage. It is sensitive to frost, water stress, and several diseases. Planting when conditions are unsuitable can cause poor establishment, blossom drop, and increased disease pressure.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (summer crop), February - April (winter crop in irrigated areas)'
      },
      kenya: {
        general: 'Year-round in irrigated areas, rainy season planting in rain-fed areas'
      },
      south_africa: {
        general: 'September - November (summer), February - April (autumn)'
      },
      general: 'Warm seasons, avoid frost periods'
    },
    conditions: [
      {
        title: 'Suitable temperature',
        description: 'Tomatoes need 20-30°C during the day and 15-20°C at night.',
        importance: 'Temperatures below 15°C or above 35°C can cause poor fruit set and blossom drop.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, but avoid waterlogging.',
        importance: 'Uneven watering can cause blossom end rot and fruit cracking.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained soil is essential to prevent root diseases.',
        importance: 'Tomatoes are susceptible to soil-borne diseases in poorly drained soil.'
      },
      {
        title: 'Transplant condition',
        description: 'Use healthy, hardened seedlings with 4-6 true leaves.',
        importance: 'Poor seedlings never recover and remain weak throughout the season.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for common pests like aphids, whiteflies, and tomato worms.',
        importance: 'Early pest damage can stunt plants and reduce yield significantly.'
      },
      {
        title: 'Disease preparation',
        description: 'Be prepared for early blight, late blight, and bacterial diseases.',
        importance: 'Diseases can destroy entire tomato crops if not managed early.'
      },
      {
        title: 'Support system',
        description: 'Plan for staking or trellising indeterminate varieties.',
        importance: 'Proper support improves air circulation and reduces disease.'
      }
    ],
    waterNeeds: 'high',
    temperatureRange: '20-30°C',
    frostSensitive: true,
    droughtTolerance: 'low'
  },
  cabbage: {
    name: 'Cabbage',
    description: 'Cabbage needs cool to moderate temperatures, consistent moisture, and fertile soil. It can tolerate some frost but struggles in very hot conditions. Planting when conditions are unsuitable can cause poor head formation and increased pest problems.',
    plantingWindows: {
      zimbabwe: {
        general: 'March - May (winter crop), September - November (summer crop)'
      },
      kenya: {
        general: 'Year-round in highlands, avoid hottest months in lowlands'
      },
      south_africa: {
        general: 'March - May (autumn), August - October (spring)'
      },
      general: 'Cool seasons, avoid extreme heat'
    },
    conditions: [
      {
        title: 'Suitable temperature',
        description: 'Cabbage grows best at 15-20°C. Heads may not form in hot weather.',
        importance: 'High temperatures can cause bolting (premature flowering) and poor head formation.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed for proper head development.',
        importance: 'Water stress causes small heads and splitting.'
      },
      {
        title: 'Soil fertility',
        description: 'Cabbage needs fertile soil with adequate nitrogen.',
        importance: 'Poor fertility results in small heads and slow growth.'
      },
      {
        title: 'Transplant condition',
        description: 'Use healthy seedlings with 4-5 true leaves.',
        importance: 'Weak seedlings struggle to establish and produce poor heads.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for caterpillars, aphids, and diamondback moth.',
        importance: 'These pests can damage leaves and heads, making cabbage unmarketable.'
      },
      {
        title: 'Spacing',
        description: 'Proper spacing ensures good head size and air circulation.',
        importance: 'Crowding leads to small heads and increased disease pressure.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-20°C',
    frostSensitive: false,
    droughtTolerance: 'low'
  },
  onion: {
    name: 'Onion',
    description: 'Onion needs cool conditions for early growth and warm, dry conditions for bulb development. It is sensitive to water stress and weeds. Planting at the wrong time can cause poor bulb formation and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'April - June (winter planting)'
      },
      kenya: {
        general: 'March - May (short rains), October - December (short rains)'
      },
      south_africa: {
        general: 'April - June (autumn planting)'
      },
      general: 'Cool start, warm finish for bulb development'
    },
    conditions: [
      {
        title: 'Temperature pattern',
        description: 'Cool for early growth, warm and dry for bulb maturation.',
        importance: 'Wrong temperature pattern prevents proper bulb formation.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, especially during early growth.',
        importance: 'Water stress reduces bulb size and quality.'
      },
      {
        title: 'Weed control',
        description: 'Onions compete poorly with weeds - critical in early stages.',
        importance: 'Weeds can significantly reduce yield and bulb size.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained soil prevents fungal diseases.',
        importance: 'Onions are prone to rot in poorly drained conditions.'
      },
      {
        title: 'Seed/transplant quality',
        description: 'Use quality seed or healthy seedlings.',
        importance: 'Poor starting material leads to uneven growth and small bulbs.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-25°C',
    frostSensitive: false,
    droughtTolerance: 'low'
  },
  potato: {
    name: 'Potato',
    description: 'Potato needs cool conditions, well-drained soil, and consistent moisture. It is sensitive to frost and waterlogging. Planting when conditions are unsuitable can cause poor tuber development and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (early crop), February - April (late crop)'
      },
      kenya: {
        general: 'Year-round in highlands, rainy season in other areas'
      },
      south_africa: {
        general: 'September - November (spring), February - April (autumn)'
      },
      general: 'Cool seasons, avoid frost and extreme heat'
    },
    conditions: [
      {
        title: 'Soil temperature',
        description: 'Plant when soil temperature is 10-20°C.',
        importance: 'Too cold slows growth; too hot reduces tuber set.'
      },
      {
        title: 'Soil drainage',
        description: 'Excellent drainage is essential to prevent tuber rot.',
        importance: 'Waterlogged conditions cause serious tuber diseases.'
      },
      {
        title: 'Seed quality',
        description: 'Use certified disease-free seed potatoes.',
        importance: 'Diseased seed can introduce serious problems to your soil.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, but avoid waterlogging.',
        importance: 'Uneven moisture causes knobby tubers and growth cracks.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for potato tuber moth, aphids, and nematodes.',
        importance: 'These pests can damage both foliage and tubers.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-20°C',
    frostSensitive: true,
    droughtTolerance: 'moderate'
  },
  beans: {
    name: 'Beans',
    description: 'Beans need warm soil, adequate moisture, and good drainage. They are sensitive to frost and waterlogging. Different varieties have different requirements. Planting when conditions are unsuitable can cause poor germination and disease problems.',
    plantingWindows: {
      zimbabwe: {
        general: 'November - January (summer crop)'
      },
      kenya: {
        general: 'March - May (long rains), October - December (short rains)'
      },
      south_africa: {
        general: 'October - December (summer), February - March (autumn)'
      },
      general: 'Warm seasons after frost risk has passed'
    },
    conditions: [
      {
        title: 'Soil temperature',
        description: 'Plant when soil temperature is above 15°C.',
        importance: 'Cold soil causes poor germination and seed rot.'
      },
      {
        title: 'Soil moisture',
        description: 'Adequate moisture needed for germination and early growth.',
        importance: 'Beans are sensitive to water stress during flowering and pod fill.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained soil prevents root diseases.',
        importance: 'Beans are susceptible to root rots in waterlogged conditions.'
      },
      {
        title: 'Seed quality',
        description: 'Use quality seed suitable for your area.',
        importance: 'Poor seed leads to uneven germination and weak plants.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for bean fly, aphids, and pod borers.',
        importance: 'Early pest damage can significantly reduce yield.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '18-25°C',
    frostSensitive: true,
    droughtTolerance: 'low'
  },
  groundnuts: {
    name: 'Groundnuts',
    description: 'Groundnuts need warm conditions, well-drained sandy soil, and adequate moisture. They are sensitive to waterlogging and frost. Planting when conditions are unsuitable can cause poor pod development and increased aflatoxin risk.',
    plantingWindows: {
      zimbabwe: {
        general: 'November - December'
      },
      kenya: {
        general: 'October - December (short rains), March - May (long rains)'
      },
      south_africa: {
        general: 'October - December'
      },
      general: 'Warm rainy season'
    },
    conditions: [
      {
        title: 'Soil temperature',
        description: 'Plant when soil temperature is above 20°C.',
        importance: 'Cold soil causes poor germination and slow growth.'
      },
      {
        title: 'Soil type',
        description: 'Light, well-drained sandy soil is ideal.',
        importance: 'Heavy soils make harvesting difficult and can affect pod quality.'
      },
      {
        title: 'Soil moisture',
        description: 'Adequate moisture needed, but mature plants prefer drier conditions.',
        importance: 'Proper moisture timing affects pod development and harvest quality.'
      },
      {
        title: 'Calcium availability',
        description: 'Ensure adequate calcium for pod filling.',
        importance: 'Calcium deficiency causes empty pods and poor fill.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '20-30°C',
    frostSensitive: true,
    droughtTolerance: 'moderate'
  },
  soybean: {
    name: 'Soybean',
    description: 'Soybean needs warm conditions, adequate moisture, and good drainage. It is sensitive to frost and waterlogging. Planting when conditions are unsuitable can cause poor nodulation, reduced yield, and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'December - January'
      },
      kenya: {
        general: 'March - May (long rains), October - December (short rains)'
      },
      south_africa: {
        general: 'November - December'
      },
      general: 'Warm rainy season'
    },
    conditions: [
      {
        title: 'Soil temperature',
        description: 'Plant when soil temperature is above 15°C.',
        importance: 'Cold soil delays germination and reduces nodulation.'
      },
      {
        title: 'Inoculation',
        description: 'Consider inoculating seed with rhizobia bacteria.',
        importance: 'Proper nodulation is essential for nitrogen fixation and yield.'
      },
      {
        title: 'Soil moisture',
        description: 'Adequate moisture needed, especially during flowering and pod fill.',
        importance: 'Water stress during critical stages significantly reduces yield.'
      },
      {
        title: 'Day length',
        description: 'Choose varieties suited to your latitude and planting date.',
        importance: 'Wrong maturity variety can flower at the wrong time.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '20-30°C',
    frostSensitive: true,
    droughtTolerance: 'moderate'
  },
  wheat: {
    name: 'Wheat',
    description: 'Wheat needs cool conditions for early growth and warm, dry conditions for grain filling. It can tolerate some frost. Planting when conditions are unsuitable can cause poor grain development and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'May - July (winter wheat)'
      },
      kenya: {
        general: 'May - July (highlands)'
      },
      south_africa: {
        general: 'May - July (winter wheat)'
      },
      general: 'Cool season planting'
    },
    conditions: [
      {
        title: 'Temperature pattern',
        description: 'Cool start, warm finish for grain filling.',
        importance: 'Wrong temperature pattern affects grain development and quality.'
      },
      {
        title: 'Soil moisture',
        description: 'Adequate moisture needed for establishment and grain filling.',
        importance: 'Terminal drought can severely reduce grain filling and yield.'
      },
      {
        title: 'Frost tolerance',
        description: 'Most wheat varieties can tolerate some frost.',
        importance: 'Severe frost during heading can damage grain development.'
      },
      {
        title: 'Disease preparation',
        description: 'Plan for rusts, septoria, and fusarium head blight.',
        importance: 'Diseases can significantly reduce yield and grain quality.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-25°C',
    frostSensitive: false,
    droughtTolerance: 'moderate'
  },
  sweet_potato: {
    name: 'Sweet Potato',
    description: 'Sweet potato needs warm conditions, adequate moisture, and well-drained soil. It is drought-tolerant once established but sensitive to frost and waterlogging. Planting when conditions are unsuitable can cause poor vine establishment and tuber development.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (summer crop)'
      },
      kenya: {
        general: 'Year-round in warm areas, rainy season in others'
      },
      south_africa: {
        general: 'September - November (summer)'
      },
      general: 'Warm seasons, avoid frost'
    },
    conditions: [
      {
        title: 'Soil temperature',
        description: 'Plant when soil temperature is above 18°C.',
        importance: 'Cold soil slows establishment and growth.'
      },
      {
        title: 'Vine quality',
        description: 'Use healthy, disease-free vines or cuttings.',
        importance: 'Poor planting material introduces diseases and weak growth.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained soil prevents tuber rot.',
        importance: 'Waterlogged conditions cause serious tuber losses.'
      },
      {
        title: 'Weed control',
        description: 'Early weed control is critical for vine establishment.',
        importance: 'Weeds compete with young vines and reduce tuber yield.'
      }
    ],
    waterNeeds: 'low',
    temperatureRange: '20-30°C',
    frostSensitive: true,
    droughtTolerance: 'high'
  },
  butternut: {
    name: 'Butternut',
    description: 'Butternut needs warm conditions, adequate moisture, and fertile soil. It is sensitive to frost and water stress. Planting when conditions are unsuitable can cause poor fruit set and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (summer crop)'
      },
      kenya: {
        general: 'Year-round in warm areas, avoid coldest months'
      },
      south_africa: {
        general: 'September - November (summer)'
      },
      general: 'Warm seasons, avoid frost'
    },
    conditions: [
      {
        title: 'Temperature',
        description: 'Needs warm conditions (20-30°C) for good growth.',
        importance: 'Cold temperatures slow growth and can damage plants.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, especially during flowering.',
        importance: 'Water stress causes poor fruit set and small fruits.'
      },
      {
        title: 'Frost protection',
        description: 'Protect young plants from frost if risk exists.',
        importance: 'Frost can kill young plants and damage developing fruits.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for aphids, cucumber beetles, and pumpkin fly.',
        importance: 'These pests can damage leaves, flowers, and fruits.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '20-30°C',
    frostSensitive: true,
    droughtTolerance: 'moderate'
  },
  watermelon: {
    name: 'Watermelon',
    description: 'Watermelon needs warm conditions, adequate moisture, and well-drained soil. It is drought-tolerant once established but sensitive to frost. Planting when conditions is unsuitable can cause poor fruit set and reduced fruit quality.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (summer crop)'
      },
      kenya: {
        general: 'Year-round in warm areas'
      },
      south_africa: {
        general: 'September - November (summer)'
      },
      general: 'Warm seasons, avoid frost'
    },
    conditions: [
      {
        title: 'Temperature',
        description: 'Needs warm conditions (25-30°C) for best growth.',
        importance: 'Cool temperatures significantly slow growth and fruit development.'
      },
      {
        title: 'Soil moisture',
        description: 'Adequate moisture needed, especially during fruit set.',
        importance: 'Water stress during fruit set causes poor fruit development.'
      },
      {
        title: 'Soil drainage',
        description: 'Well-drained sandy soil is ideal.',
        importance: 'Poor drainage causes fruit rot and disease problems.'
      },
      {
        title: 'Pollination',
        description: 'Ensure good pollinator activity during flowering.',
        importance: 'Poor pollination results in misshapen or small fruits.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '25-30°C',
    frostSensitive: true,
    droughtTolerance: 'high'
  },
  pepper: {
    name: 'Pepper',
    description: 'Pepper needs warm conditions, consistent moisture, and fertile soil. It is sensitive to frost and water stress. Planting when conditions are unsuitable can cause poor fruit set and increased disease.',
    plantingWindows: {
      zimbabwe: {
        general: 'September - November (summer crop)'
      },
      kenya: {
        general: 'Year-round in warm areas'
      },
      south_africa: {
        general: 'September - November (summer)'
      },
      general: 'Warm seasons, avoid frost'
    },
    conditions: [
      {
        title: 'Temperature',
        description: 'Needs warm conditions (20-28°C) for good growth.',
        importance: 'Temperatures below 15°C slow growth and can damage plants.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed, but avoid waterlogging.',
        importance: 'Uneven watering causes blossom drop and fruit problems.'
      },
      {
        title: 'Transplant condition',
        description: 'Use healthy seedlings with good root systems.',
        importance: 'Poor seedlings struggle to establish and produce poorly.'
      },
      {
        title: 'Pest preparation',
        description: 'Plan for aphids, thrips, and pepper diseases.',
        importance: 'These pests and diseases can significantly reduce yield.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '20-28°C',
    frostSensitive: true,
    droughtTolerance: 'low'
  },
  spinach: {
    name: 'Spinach',
    description: 'Spinach needs cool conditions, adequate moisture, and fertile soil. It bolts (goes to seed) in hot weather. Planting when conditions are unsuitable can cause poor leaf quality and bolting.',
    plantingWindows: {
      zimbabwe: {
        general: 'March - May (winter), September - October (spring)'
      },
      kenya: {
        general: 'Year-round in highlands, cool months elsewhere'
      },
      south_africa: {
        general: 'March - May (autumn), August - October (spring)'
      },
      general: 'Cool seasons, avoid hot weather'
    },
    conditions: [
      {
        title: 'Temperature',
        description: 'Best at 15-20°C. Hot weather causes bolting.',
        importance: 'Bolting makes leaves bitter and unmarketable.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed for tender leaves.',
        importance: 'Water stress causes tough, bitter leaves and reduced yield.'
      },
      {
        title: 'Soil fertility',
        description: 'Needs fertile soil with adequate nitrogen.',
        importance: 'Poor fertility results in small, yellow leaves.'
      },
      {
        title: 'Succession planting',
        description: 'Plant in succession for continuous harvest.',
        importance: 'Spinach matures quickly and quality declines with age.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-20°C',
    frostSensitive: false,
    droughtTolerance: 'low'
  },
  carrot: {
    name: 'Carrot',
    description: 'Carrot needs cool conditions, deep loose soil, and consistent moisture. It is sensitive to soil compaction and water stress. Planting when conditions is unsuitable can cause poor root development and forked carrots.',
    plantingWindows: {
      zimbabwe: {
        general: 'March - May (winter), September - October (spring)'
      },
      kenya: {
        general: 'Year-round in highlands, cool months elsewhere'
      },
      south_africa: {
        general: 'March - May (autumn), August - October (spring)'
      },
      general: 'Cool seasons, avoid hot weather'
    },
    conditions: [
      {
        title: 'Soil preparation',
        description: 'Deep, loose, stone-free soil is essential.',
        importance: 'Compacted or stony soil causes forked and deformed roots.'
      },
      {
        title: 'Soil moisture',
        description: 'Consistent moisture needed for even root growth.',
        importance: 'Uneven moisture causes cracked and bitter carrots.'
      },
      {
        title: 'Temperature',
        description: 'Best at 15-20°C. Hot weather affects root quality.',
        importance: 'High temperatures can cause poor color and flavor.'
      },
      {
        title: 'Thinning',
        description: 'Plan for proper spacing and thinning.',
        importance: 'Crowding causes small, deformed roots.'
      }
    ],
    waterNeeds: 'moderate',
    temperatureRange: '15-20°C',
    frostSensitive: false,
    droughtTolerance: 'low'
  }
};

// Location Data - Provinces and Districts
const locationData = {
  zimbabwe: {
    provinces: ['Mashonaland East', 'Mashonaland West', 'Mashonaland Central', 'Manicaland', 'Masvingo', 'Midlands', 'Matabeleland North', 'Matabeleland South', 'Bulawayo', 'Harare', 'Chitungwiza'],
    natural_regions: {
      'Mashonaland East': 'IIa, IIb',
      'Mashonaland West': 'IIa, IIb, III',
      'Mashonaland Central': 'IIa, IIb',
      'Manicaland': 'II, III, IV',
      'Masvingo': 'III, IV, V',
      'Midlands': 'II, III, IV',
      'Matabeleland North': 'III, IV, V',
      'Matabeleland South': 'IV, V',
      'Bulawayo': 'IV, V',
      'Harare': 'II',
      'Chitungwiza': 'II'
    }
  },
  kenya: {
    provinces: ['Nairobi', 'Central', 'Coast', 'Eastern', 'North Eastern', 'Nyanza', 'Rift Valley', 'Western'],
    regions: {
      'Central': 'highlands',
      'Eastern': 'medium_altitude, lowlands',
      'Rift Valley': 'highlands, medium_altitude',
      'Western': 'highlands, medium_altitude',
      'Nyanza': 'medium_altitude, lowlands',
      'Coast': 'lowlands'
    }
  },
  south_africa: {
    provinces: ['Eastern Cape', 'Free State', 'Gauteng', 'KwaZulu-Natal', 'Limpopo', 'Mpumalanga', 'Northern Cape', 'North West', 'Western Cape'],
    maize_regions: {
      'Mpumalanga': 'major',
      'Free State': 'major',
      'North West': 'major',
      'Gauteng': 'major',
      'Limpopo': 'irrigated',
      'KwaZulu-Natal': 'mixed'
    }
  },
  zambia: {
    provinces: ['Central', 'Copperbelt', 'Eastern', 'Luapula', 'Lusaka', 'Muchinga', 'Northern', 'North-Western', 'Southern', 'Western']
  },
  ghana: {
    provinces: ['Ashanti', 'Brong-Ahafo', 'Central', 'Eastern', 'Greater Accra', 'Northern', 'Upper East', 'Upper West', 'Volta', 'Western']
  },
  nigeria: {
    provinces: ['Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara']
  },
  tanzania: {
    provinces: ['Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera', 'Katavi', 'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya', 'Morogoro', 'Mtwara', 'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma', 'Shinyanga', 'Simiyu', 'Singida', 'Tabora', 'Tanga']
  },
  ethiopia: {
    provinces: ['Addis Ababa', 'Afar', 'Amhara', 'Benishangul-Gumuz', 'Dire Dawa', 'Gambela', 'Harari', 'Oromia', 'Somali', 'Southern Nations, Nationalities, and Peoples\' Region', 'Tigray']
  },
  uganda: {
    provinces: ['Central', 'Eastern', 'Northern', 'Western']
  },
  mozambique: {
    provinces: ['Cabo Delgado', 'Gaza', 'Inhambane', 'Manica', 'Maputo City', 'Maputo Province', 'Nampula', 'Niassa', 'Sofala', 'Tete', 'Zambezia']
  },
  malawi: {
    provinces: ['Central', 'Northern', 'Southern']
  }
};

// Navigation Functions
function startTool() {
  showSection('locationSection');
  updateProgress(1);
  plantingState.currentStep = 1;
}

function showSection(sectionId) {
  // Hide all sections
  const sections = document.querySelectorAll('.tool-section');
  sections.forEach(section => section.classList.add('hidden'));

  // Show target section
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
  const stepBack = plantingState.currentStep - 1;
  if (stepBack >= 0) {
    plantingState.currentStep = stepBack;
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
      showSection('locationSection');
      break;
    case 2:
      showSection('cropSection');
      break;
    case 3:
      showSection('methodSection');
      break;
    case 4:
      showSection('landSection');
      break;
    case 5:
      showSection('moistureSection');
      break;
    case 6:
      showSection('waterSection');
      break;
    case 7:
      showSection('weatherSection');
      break;
    case 8:
      showSection('plantingWindowSection');
      break;
    case 9:
      showSection('cropConditionsSection');
      break;
    case 10:
      showSection('businessSection');
      break;
    case 11:
      showSection('finalResult');
      break;
  }
}

// Location Functions
function updateProvinces() {
  const country = document.getElementById('countrySelect').value;
  const provinceSelect = document.getElementById('provinceSelect');
  const provinceGroup = document.getElementById('provinceGroup');
  const districtGroup = document.getElementById('districtGroup');
  const locationDisclaimer = document.getElementById('locationDisclaimer');

  plantingState.location.country = country;

  provinceSelect.innerHTML = '<option value="">Select province</option>';
  districtGroup.classList.add('hidden');
  districtGroup.classList.remove('hidden');

  if (country && locationData[country]) {
    provinceGroup.classList.remove('hidden');
    locationData[country].provinces.forEach(province => {
      const option = document.createElement('option');
      option.value = province;
      option.textContent = province;
      provinceSelect.appendChild(option);
    });
    plantingState.location.hasLocalData = true;
    locationDisclaimer.style.display = 'none';
  } else if (country === 'other') {
    provinceGroup.classList.add('hidden');
    plantingState.location.hasLocalData = false;
    locationDisclaimer.style.display = 'block';
  } else {
    provinceGroup.classList.add('hidden');
  }
}

function updateDistricts() {
  const province = document.getElementById('provinceSelect').value;
  const districtSelect = document.getElementById('districtSelect');
  const districtGroup = document.getElementById('districtGroup');

  plantingState.location.province = province;

  districtSelect.innerHTML = '<option value="">Select district</option>';

  if (province) {
    districtGroup.classList.remove('hidden');
    // For simplicity, we're not adding specific districts
    // In a full implementation, this would have district data
    districtSelect.innerHTML = '<option value="">Select district (general area)</option>';
    // Add some generic options
    ['Northern District', 'Central District', 'Southern District', 'Eastern District', 'Western District'].forEach(district => {
      const option = document.createElement('option');
      option.value = district.toLowerCase().replace(' ', '_');
      option.textContent = district;
      districtSelect.appendChild(option);
    });
  } else {
    districtGroup.classList.add('hidden');
  }
}

function confirmLocation() {
  const country = document.getElementById('countrySelect').value;
  const province = document.getElementById('provinceSelect').value;
  const district = document.getElementById('districtSelect').value;

  if (!country) {
    alert('Please select your country');
    return;
  }

  plantingState.location.country = country;
  plantingState.location.province = province || '';
  plantingState.location.district = district || '';

  plantingState.currentStep = 2;
  showSection('cropSection');
  updateProgress(2);
}

// Crop Functions
function showCropInfo() {
  const cropSelect = document.getElementById('cropSelect');
  const cropInfo = document.getElementById('cropInfo');
  const cropInfoTitle = document.getElementById('cropInfoTitle');
  const cropInfoText = document.getElementById('cropInfoText');

  const selectedCrop = cropSelect.value;

  if (selectedCrop && cropDatabase[selectedCrop]) {
    const cropData = cropDatabase[selectedCrop];
    cropInfoTitle.textContent = cropData.name;
    cropInfoText.textContent = cropData.description;
    cropInfo.classList.remove('hidden');
    plantingState.crop.type = selectedCrop;
    plantingState.crop.name = cropData.name;
    plantingState.crop.info = cropData.description;
  } else {
    cropInfo.classList.add('hidden');
    plantingState.crop.type = '';
  }
}

function confirmCrop() {
  if (!plantingState.crop.type) {
    alert('Please select a crop');
    return;
  }

  plantingState.currentStep = 3;
  showSection('methodSection');
  updateProgress(3);
}

// Farming Method Functions
function selectMethod(method) {
  const buttons = document.querySelectorAll('[data-method]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-method="${method}"]`).classList.add('selected');

  plantingState.farming.method = method;

  const waterSourceGroup = document.getElementById('waterSourceGroup');
  if (method === 'irrigated' || method === 'both') {
    waterSourceGroup.classList.remove('hidden');
  } else {
    waterSourceGroup.classList.add('hidden');
  }
}

function confirmMethod() {
  if (!plantingState.farming.method) {
    alert('Please select your farming method');
    return;
  }

  if (plantingState.farming.method === 'irrigated' || plantingState.farming.method === 'both') {
    const waterSource = document.getElementById('waterSourceSelect').value;
    if (!waterSource) {
      alert('Please select your water source');
      return;
    }
    plantingState.farming.waterSource = waterSource;
  }

  plantingState.currentStep = 4;
  showSection('landSection');
  updateProgress(4);
}

// Land Preparation Functions
function selectLandPrep(prep) {
  const buttons = document.querySelectorAll('[data-prep]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-prep="${prep}"]`).classList.add('selected');

  plantingState.land.preparation = prep;
}

function confirmLandPrep() {
  if (!plantingState.land.preparation) {
    alert('Please select your land preparation status');
    return;
  }

  plantingState.currentStep = 5;
  showSection('moistureSection');
  updateProgress(5);
}

// Soil Moisture Functions
function selectMoisture(moisture) {
  const buttons = document.querySelectorAll('[data-moisture]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-moisture="${moisture}"]`).classList.add('selected');

  plantingState.soil.moisture = moisture;

  const moistureCheckInfo = document.getElementById('moistureCheckInfo');
  if (moisture === 'unknown') {
    moistureCheckInfo.classList.remove('hidden');
  } else {
    moistureCheckInfo.classList.add('hidden');
  }
}

function confirmMoisture() {
  if (!plantingState.soil.moisture) {
    alert('Please select your soil moisture condition');
    return;
  }

  plantingState.currentStep = 6;
  showSection('waterSection');
  updateProgress(6);
}

// Water Availability Functions
function selectWaterAvailability(water) {
  const buttons = document.querySelectorAll('[data-water]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-water="${water}"]`).classList.add('selected');

  plantingState.water.availability = water;
}

function confirmWater() {
  if (!plantingState.water.availability) {
    alert('Please select your water availability');
    return;
  }

  plantingState.currentStep = 7;
  showSection('weatherSection');
  updateProgress(7);
}

// Weather Functions
function selectWeather(weather) {
  const buttons = document.querySelectorAll('[data-weather]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-weather="${weather}"]`).classList.add('selected');

  plantingState.weather.current = weather;
}

function selectRecentRain(rain) {
  const buttons = document.querySelectorAll('[data-rain]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-rain="${rain}"]`).classList.add('selected');

  plantingState.weather.recentRain = rain;
}

function confirmWeather() {
  if (!plantingState.weather.current) {
    alert('Please select current weather conditions');
    return;
  }
  if (!plantingState.weather.recentRain) {
    alert('Please select recent rainfall conditions');
    return;
  }

  plantingState.currentStep = 8;
  showSection('plantingWindowSection');
  updateProgress(8);
  showPlantingWindow();
}

function showPlantingWindow() {
  const crop = cropDatabase[plantingState.crop.type];
  const country = plantingState.location.country;
  const plantingWindowInfo = document.getElementById('plantingWindowInfo');

  if (crop && crop.plantingWindows) {
    let windowText = '';

    if (crop.plantingWindows[country]) {
      const countryData = crop.plantingWindows[country];
      if (countryData.general) {
        windowText = `For ${crop.name} in ${country}, the general planting period is: ${countryData.general}.`;
      }
    } else if (crop.plantingWindows.general) {
      windowText = `For ${crop.name}, the general planting guidance is: ${crop.plantingWindows.general}.`;
    } else {
      windowText = `Specific planting window information for ${crop.name} in your area is not available in our database. Please check with local agricultural extension services for precise local recommendations.`;
    }

    plantingWindowInfo.textContent = windowText;
  }
}

// Planting Date Functions
function selectPlantingDate(dateOption) {
  const buttons = document.querySelectorAll('[data-date]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-date="${dateOption}"]`).classList.add('selected');

  plantingState.planting.plannedOption = dateOption;

  const specificDateGroup = document.getElementById('specificDateGroup');
  const plantingDateResult = document.getElementById('plantingDateResult');
  const plantingDateComparison = document.getElementById('plantingDateComparison');

  if (dateOption === 'specific') {
    specificDateGroup.classList.remove('hidden');
  } else {
    specificDateGroup.classList.add('hidden');
  }

  // Simple comparison logic (in a full implementation, this would be more sophisticated)
  let comparisonText = '';
  let withinWindow = false;

  const today = new Date();
  let plannedDate = new Date();

  switch(dateOption) {
    case 'today':
      plannedDate = today;
      break;
    case 'this_week':
      plannedDate = new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000); // 3 days from now
      break;
    case 'next_week':
      plannedDate = new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000); // 10 days from now
      break;
    case 'specific':
      // Will be set when user selects date
      break;
  }

  if (dateOption !== 'specific') {
    const month = plannedDate.getMonth() + 1;
    // Very simplified logic - in reality this would use the crop database
    if (month >= 10 && month <= 12) {
      comparisonText = 'Your planned date falls within a common planting period for many crops in your region.';
      withinWindow = true;
    } else if (month >= 3 && month <= 5) {
      comparisonText = 'Your planned date falls within a secondary planting period for some crops.';
      withinWindow = true;
    } else {
      comparisonText = 'Your planned date is outside the typical main planting periods. Some crops may still be suitable depending on your specific conditions and variety.';
      withinWindow = false;
    }

    plantingDateComparison.textContent = comparisonText;
    plantingDateResult.classList.remove('hidden');
    plantingState.planting.withinWindow = withinWindow;
  }
}

// Handle specific date input
document.addEventListener('DOMContentLoaded', function() {
  const specificDateInput = document.getElementById('specificDateInput');
  if (specificDateInput) {
    specificDateInput.addEventListener('change', function() {
      const date = this.value;
      if (date) {
        plantingState.planting.plannedDate = date;

        const plantingDateResult = document.getElementById('plantingDateResult');
        const plantingDateComparison = document.getElementById('plantingDateComparison');

        const plannedDate = new Date(date);
        const month = plannedDate.getMonth() + 1;

        let comparisonText = '';
        let withinWindow = false;

        if (month >= 10 && month <= 12) {
          comparisonText = 'Your planned date falls within a common planting period for many crops in your region.';
          withinWindow = true;
        } else if (month >= 3 && month <= 5) {
          comparisonText = 'Your planned date falls within a secondary planting period for some crops.';
          withinWindow = true;
        } else {
          comparisonText = 'Your planned date is outside the typical main planting periods. Some crops may still be suitable depending on your specific conditions and variety.';
          withinWindow = false;
        }

        plantingDateComparison.textContent = comparisonText;
        plantingDateResult.classList.remove('hidden');
        plantingState.planting.withinWindow = withinWindow;
      }
    });
  }
});

function confirmPlantingDate() {
  if (!plantingState.planting.plannedOption) {
    alert('Please select your planned planting date');
    return;
  }

  if (plantingState.planting.plannedOption === 'specific') {
    const specificDate = document.getElementById('specificDateInput').value;
    if (!specificDate) {
      alert('Please enter your planned planting date');
      return;
    }
    plantingState.planting.plannedDate = specificDate;
  } else {
    const today = new Date();
    let plannedDate = new Date();

    switch(plantingState.planting.plannedOption) {
      case 'today':
        plannedDate = today;
        break;
      case 'this_week':
        plannedDate = new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000);
        break;
      case 'next_week':
        plannedDate = new Date(today.getTime() + 10 * 24 * 60 * 60 * 1000);
        break;
    }
    plantingState.planting.plannedDate = plannedDate.toISOString().split('T')[0];
  }

  plantingState.currentStep = 9;
  showSection('cropConditionsSection');
  updateProgress(9);
  showCropConditions();
}

function showCropConditions() {
  const crop = cropDatabase[plantingState.crop.type];
  const cropConditionsContainer = document.getElementById('cropSpecificConditions');
  const selectedCropName = document.getElementById('selectedCropName');

  selectedCropName.textContent = crop.name;

  cropConditionsContainer.innerHTML = '';

  if (crop && crop.conditions) {
    crop.conditions.forEach(condition => {
      const conditionCard = document.createElement('div');
      conditionCard.className = 'condition-card';
      conditionCard.innerHTML = `
        <div class="condition-title">${condition.title}</div>
        <div class="condition-desc">${condition.description}</div>
        <div class="why-matters" style="margin-top: 0.5rem; padding: 0.5rem;">
          <div class="why-matters-title" style="font-size: 0.9rem;">Why this matters:</div>
          <p style="font-size: 0.85rem; margin: 0;">${condition.importance}</p>
        </div>
      `;
      cropConditionsContainer.appendChild(conditionCard);
    });
  }
}

function confirmCropConditions() {
  plantingState.currentStep = 10;
  showSection('businessSection');
  updateProgress(10);
}

// Business Functions
function selectCostCalc(cost) {
  const buttons = document.querySelectorAll('[data-cost]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-cost="${cost}"]`).classList.add('selected');

  plantingState.business.costCalculated = cost;

  const costCalcInfo = document.getElementById('costCalcInfo');
  if (cost === 'no' || cost === 'partly') {
    costCalcInfo.classList.remove('hidden');
  } else {
    costCalcInfo.classList.add('hidden');
  }
}

function selectMarket(market) {
  const buttons = document.querySelectorAll('[data-market]');
  buttons.forEach(button => button.classList.remove('selected'));
  document.querySelector(`[data-market="${market}"]`).classList.add('selected');

  plantingState.business.marketPlanned = market;
}

function confirmBusiness() {
  if (!plantingState.business.costCalculated) {
    alert('Please select whether you have calculated costs');
    return;
  }
  if (!plantingState.business.marketPlanned) {
    alert('Please select your market planning status');
    return;
  }

  plantingState.currentStep = 11;
  showSection('finalResult');
  updateProgress(11);
  generateFinalResult();
}

// Decision Logic and Risk Assessment
function generateFinalResult() {
  const state = plantingState;
  const crop = cropDatabase[state.crop.type];

  // Reset risks and recommendations
  state.risks = [];
  state.recommendations = [];

  // Analyze conditions and identify risks
  analyzeConditions();

  // Generate final recommendation
  const recommendation = generateRecommendation();

  // Update UI
  updateResultUI(recommendation);
}

function analyzeConditions() {
  const state = plantingState;
  const crop = cropDatabase[state.crop.type];

  // Land preparation risk
  if (state.land.preparation === 'no') {
    state.risks.push({
      level: 'high',
      title: 'Land not ready for planting',
      description: 'Your land is not prepared. Good seed planted into poorly prepared land can still give poor results.'
    });
    state.recommendations.push('Prepare your land properly before planting (tilled, weeded, drainage acceptable)');
  } else if (state.land.preparation === 'partly') {
    state.risks.push({
      level: 'moderate',
      title: 'Land partly prepared',
      description: 'Your land is only partly prepared. This may affect crop establishment.'
    });
    state.recommendations.push('Complete land preparation before planting if possible');
  }

  // Soil moisture risk
  if (state.soil.moisture === 'dry') {
    state.risks.push({
      level: 'high',
      title: 'Soil is too dry',
      description: 'Seed needs suitable moisture to germinate. Very dry soil can prevent good germination.'
    });
    state.recommendations.push('Wait for adequate soil moisture or irrigate before planting');
  } else if (state.soil.moisture === 'very_wet') {
    state.risks.push({
      level: 'moderate',
      title: 'Soil is very wet',
      description: 'Waterlogged soil can reduce oxygen around roots and damage young plants.'
    });
    state.recommendations.push('Improve drainage or wait for soil to dry to workable condition');
  } else if (state.soil.moisture === 'unknown') {
    state.risks.push({
      level: 'moderate',
      title: 'Soil moisture unknown',
      description: 'You are unsure about soil moisture conditions.'
    });
    state.recommendations.push('Check soil moisture manually before planting (squeeze test)');
  }

  // Water availability risk
  if (state.water.availability === 'no') {
    state.risks.push({
      level: 'high',
      title: 'Limited water availability',
      description: 'You have limited water for early growth. Young plants are especially sensitive to water stress.'
    });
    state.recommendations.push('Secure reliable water source before planting or consider drought-tolerant crops');
  } else if (state.water.availability === 'not_sure') {
    state.risks.push({
      level: 'moderate',
      title: 'Water availability uncertain',
      description: 'You are unsure about water availability for the growing season.'
    });
    state.recommendations.push('Confirm your water source reliability before planting');
  }

  // Weather risk
  if (state.weather.current === 'dry') {
    state.risks.push({
      level: 'high',
      title: 'Very dry conditions',
      description: 'Current weather conditions are very dry, which may affect germination and early growth.'
    });
    state.recommendations.push('Consider irrigation or wait for improved moisture conditions');
  } else if (state.weather.current === 'heavy_rain') {
    state.risks.push({
      level: 'moderate',
      title: 'Heavy rainfall risk',
      description: 'Heavy rainfall or flooding risk may damage young plants or cause soil erosion.'
    });
    state.recommendations.push('Ensure good drainage and consider waiting if heavy rain is expected');
  } else if (state.weather.current === 'extreme') {
    state.risks.push({
      level: 'high',
      title: 'Extreme weather conditions',
      description: 'Extreme weather (very hot, very cold, or storm risk) can damage young plants.'
    });
    state.recommendations.push('Wait for more suitable weather conditions');
  }

  // Recent rainfall risk
  if (state.weather.recentRain === 'low') {
    state.risks.push({
      level: 'moderate',
      title: 'Low recent rainfall',
      description: 'Recent rainfall has been low, which may affect soil moisture.'
    });
    state.recommendations.push('Check soil moisture and water availability carefully');
  } else if (state.weather.recentRain === 'excessive') {
    state.risks.push({
      level: 'moderate',
      title: 'Excessive recent rainfall',
      description: 'Excessive rainfall may have caused waterlogging or leaching of nutrients.'
    });
    state.recommendations.push('Check soil drainage and consider additional fertilizer if needed');
  }

  // Planting date risk
  if (!state.planting.withinWindow) {
    state.risks.push({
      level: 'moderate',
      title: 'Outside typical planting period',
      description: 'Your planned date is outside the typical main planting periods for your region.'
    });
    state.recommendations.push('Check if your specific variety and local conditions allow for this planting time');
  }

  // Rain-fed specific risks
  if (state.farming.method === 'rainfed') {
    if (state.weather.current === 'dry' || state.weather.recentRain === 'low') {
      state.risks.push({
        level: 'high',
        title: 'Rain-fed farming with dry conditions',
        description: 'Rain-fed farming depends on rainfall. Current dry conditions pose a significant risk.'
      });
      state.recommendations.push('Consider irrigation or wait for reliable rainfall forecast');
    }
  }

  // Business planning risk
  if (state.business.costCalculated === 'no') {
    state.risks.push({
      level: 'moderate',
      title: 'Costs not calculated',
      description: 'You have not calculated the costs for this crop.'
    });
    state.recommendations.push('Calculate your expected costs before planting to avoid financial losses');
  }

  if (state.business.marketPlanned === 'no') {
    state.risks.push({
      level: 'moderate',
      title: 'Market not planned',
      description: 'You have not planned where you will sell your harvest.'
    });
    state.recommendations.push('Identify potential buyers and market requirements before planting');
  }

  // Crop-specific risks
  if (crop && crop.frostSensitive) {
    // In a real implementation, this would check actual frost risk
    state.recommendations.push('Be aware of frost risk for this crop and have protection if needed');
  }

  if (crop && crop.droughtTolerance === 'low') {
    if (state.water.availability === 'no' || state.weather.current === 'dry') {
      state.risks.push({
        level: 'high',
        title: 'Drought-sensitive crop with water concerns',
        description: `${crop.name} has low drought tolerance and you have water concerns.`
      });
      state.recommendations.push('Ensure reliable water supply or consider more drought-tolerant crops');
    }
  }
}

function generateRecommendation() {
  const state = plantingState;
  const highRisks = state.risks.filter(r => r.level === 'high');
  const moderateRisks = state.risks.filter(r => r.level === 'moderate');

  let recommendation = {
    status: 'good',
    title: 'CONDITIONS LOOK REASONABLE',
    explanation: '',
    decision: 'YOU CAN CONSIDER PLANTING'
  };

  if (highRisks.length >= 2) {
    recommendation.status = 'danger';
    recommendation.title = 'HIGH RISK - RECONSIDER PLANTING';
    recommendation.decision = 'WAIT BEFORE PLANTING';
  } else if (highRisks.length === 1) {
    recommendation.status = 'warning';
    recommendation.title = 'CONDITIONS HAVE CONCERNS';
    recommendation.decision = 'ADDRESS CONCERNS BEFORE PLANTING';
  } else if (moderateRisks.length >= 3) {
    recommendation.status = 'warning';
    recommendation.title = 'MODERATE RISK - CHECK CONDITIONS';
    recommendation.decision = 'CHECK CONDITIONS CAREFULLY';
  }

  // Generate explanation
  let explanationParts = [];

  if (state.land.preparation === 'no') {
    explanationParts.push('Your land is not ready for planting. Preparing the field properly helps the crop establish and gives you a better chance of success.');
  }

  if (state.soil.moisture === 'dry') {
    explanationParts.push('Your soil is currently dry. Seed needs suitable moisture to germinate. If rainfall does not arrive soon enough, you may get poor germination and have to replant.');
  }

  if (state.water.availability === 'no' && state.farming.method === 'rainfed') {
    explanationParts.push('You are depending on rainfall but current conditions are dry. Rain-fed farming carries risk when rainfall is unreliable.');
  }

  if (state.weather.current === 'dry') {
    explanationParts.push('Current weather conditions are dry. This may affect germination and early growth, especially for young plants.');
  }

  if (!state.planting.withinWindow) {
    explanationParts.push('Your planned planting date is outside the typical main planting period. Some crops may still work, but conditions and variety choice become more important.');
  }

  if (explanationParts.length === 0) {
    explanationParts.push('Based on the information you provided, conditions appear reasonable for planting. However, always remember that conditions can change and local factors matter.');
  }

  recommendation.explanation = explanationParts.join(' ');

  return recommendation;
}

function updateResultUI(recommendation) {
  const state = plantingState;

  // Update status
  const resultStatus = document.getElementById('resultStatus');
  resultStatus.textContent = recommendation.title;
  resultStatus.className = 'result-status ' + recommendation.status;

  // Update summary
  document.getElementById('summaryCrop').textContent = state.crop.name;
  document.getElementById('summaryLocation').textContent = `${state.location.country}${state.location.province ? ', ' + state.location.province : ''}${state.location.district ? ', ' + state.location.district : ''}`;
  document.getElementById('summaryDate').textContent = state.planting.plannedDate;
  document.getElementById('summaryMethod').textContent = getMethodText(state.farming.method);
  document.getElementById('summaryLand').textContent = getLandPrepText(state.land.preparation);
  document.getElementById('summaryMoisture').textContent = getMoistureText(state.soil.moisture);
  document.getElementById('summaryWater').textContent = getWaterText(state.water.availability);
  document.getElementById('summaryWeather').textContent = getWeatherText(state.weather.current, state.weather.recentRain);

  // Update explanation
  document.getElementById('resultExplanation').textContent = recommendation.explanation;

  // Update risks
  const risksContainer = document.getElementById('risksContainer');
  risksContainer.innerHTML = '';

  if (state.risks.length === 0) {
    risksContainer.innerHTML = '<p>No major risks identified based on your responses. However, always monitor conditions and be prepared for changes.</p>';
  } else {
    state.risks.forEach(risk => {
      const riskElement = document.createElement('div');
      riskElement.className = `risk-item ${risk.level}`;
      riskElement.innerHTML = `
        <strong>${risk.title}</strong>
        <p style="margin: 0.25rem 0 0 0;">${risk.description}</p>
      `;
      risksContainer.appendChild(riskElement);
    });
  }

  // Update recommendations
  const recommendationsList = document.getElementById('recommendationsList');
  recommendationsList.innerHTML = '';

  state.recommendations.forEach(rec => {
    const li = document.createElement('li');
    li.textContent = rec;
    recommendationsList.appendChild(li);
  });

  // Update final decision
  document.getElementById('finalDecision').textContent = recommendation.decision;

  // Update next actions
  updateNextActions();
}

function updateNextActions() {
  const state = plantingState;
  const nextActionsContainer = document.getElementById('nextActions');
  nextActionsContainer.innerHTML = '';

  const actions = [];

  // Add actions based on conditions
  if (state.land.preparation === 'no' || state.land.preparation === 'partly') {
    actions.push({
      title: 'Prepare Your Land',
      desc: 'Learn proper land preparation techniques',
      link: '/guides/prepare-soil-for-vegetables.html'
    });
  }

  if (state.soil.moisture === 'dry' || state.soil.moisture === 'unknown') {
    actions.push({
      title: 'Check Your Soil',
      desc: 'Learn how to assess soil conditions',
      link: '/guides/understanding-your-soil.html'
    });
  }

  if (state.farming.method === 'irrigated' || state.farming.method === 'both') {
    actions.push({
      title: 'Check Irrigation',
      desc: 'Review irrigation needs and methods',
      link: '/guides/beginner-irrigation-guide.html'
    });
  }

  if (state.business.costCalculated === 'no' || state.business.costCalculated === 'partly') {
    actions.push({
      title: 'Calculate Your Costs',
      desc: 'Use the farm budget calculator',
      link: '/calculators/farm-budget.html'
    });
  }

  // Always add crop-specific learning
  actions.push({
    title: `Learn How to Plant ${state.crop.name}`,
    desc: 'Read crop-specific growing guides',
    link: '/guides/'
  });

  actions.push({
    title: 'Learn Common Pests and Diseases',
    desc: 'Understand potential crop problems',
    link: '/guides/pest-disease-management.html'
  });

  actions.push({
    title: 'View Crop Calendar',
    desc: 'Check planting and harvest timing',
    link: '/calendar/'
  });

  // Render actions
  actions.forEach(action => {
    const actionCard = document.createElement('a');
    actionCard.className = 'next-action-card';
    actionCard.href = action.link;
    actionCard.innerHTML = `
      <div class="next-action-title">${action.title}</div>
      <div class="next-action-desc">${action.desc}</div>
    `;
    nextActionsContainer.appendChild(actionCard);
  });
}

// Helper functions for text conversion
function getMethodText(method) {
  const texts = {
    'rainfed': 'Rain-fed (depends on rainfall)',
    'irrigated': 'Irrigated',
    'both': 'Both rain and irrigation'
  };
  return texts[method] || method;
}

function getLandPrepText(prep) {
  const texts = {
    'yes': 'Ready',
    'partly': 'Partly ready',
    'no': 'Not ready'
  };
  return texts[prep] || prep;
}

function getMoistureText(moisture) {
  const texts = {
    'moist': 'Moist (suitable)',
    'dry': 'Dry',
    'very_wet': 'Very wet/waterlogged',
    'unknown': 'Unknown'
  };
  return texts[moisture] || moisture;
}

function getWaterText(water) {
  const texts = {
    'yes': 'Adequate',
    'no': 'Limited',
    'not_sure': 'Not sure'
  };
  return texts[water] || water;
}

function getWeatherText(current, recentRain) {
  const currentTexts = {
    'good': 'Good',
    'dry': 'Very dry',
    'heavy_rain': 'Heavy rain risk',
    'extreme': 'Extreme',
    'unknown': 'Unknown'
  };
  const rainTexts = {
    'adequate': 'Adequate rainfall',
    'low': 'Low rainfall',
    'excessive': 'Excessive rainfall',
    'unknown': 'Unknown'
  };
  return `${currentTexts[current] || current} (recent: ${rainTexts[recentRain] || recentRain})`;
}

// Save and Download Functions
function saveResult() {
  const state = plantingState;
  const result = {
    date: new Date().toISOString(),
    crop: state.crop.name,
    location: state.location,
    plantingDate: state.planting.plannedDate,
    method: state.farming.method,
    risks: state.risks,
    recommendations: state.recommendations
  };

  // Try to save to localStorage
  try {
    const savedResults = JSON.parse(localStorage.getItem('plantingCheckResults') || '[]');
    savedResults.push(result);
    localStorage.setItem('plantingCheckResults', JSON.stringify(savedResults));
    alert('Your planting check has been saved locally on this device.');
  } catch (e) {
    alert('Could not save result. Your browser may not support local storage.');
  }
}

function downloadResult() {
  const state = plantingState;
  const result = generateResultText();

  // Create download
  const blob = new Blob([result], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `planting-check-${state.crop.name}-${new Date().toISOString().split('T')[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function generateResultText() {
  const state = plantingState;
  const crop = cropDatabase[state.crop.type];

  let text = `PLANTING CHECK RESULT\n`;
  text += `==================\n\n`;
  text += `Date: ${new Date().toLocaleDateString()}\n`;
  text += `Crop: ${state.crop.name}\n`;
  text += `Location: ${state.location.country}${state.location.province ? ', ' + state.location.province : ''}${state.location.district ? ', ' + state.location.district : ''}\n`;
  text += `Planned Planting Date: ${state.planting.plannedDate}\n`;
  text += `Farming Method: ${getMethodText(state.farming.method)}\n\n`;

  text += `CONDITIONS CHECKED:\n`;
  text += `------------------\n`;
  text += `Land Preparation: ${getLandPrepText(state.land.preparation)}\n`;
  text += `Soil Moisture: ${getMoistureText(state.soil.moisture)}\n`;
  text += `Water Availability: ${getWaterText(state.water.availability)}\n`;
  text += `Weather Conditions: ${getWeatherText(state.weather.current, state.weather.recentRain)}\n\n`;

  if (state.risks.length > 0) {
    text += `RISKS IDENTIFIED:\n`;
    text += `----------------\n`;
    state.risks.forEach((risk, index) => {
      text += `${index + 1}. ${risk.title} (${risk.level.toUpperCase()}): ${risk.description}\n`;
    });
    text += `\n`;
  }

  if (state.recommendations.length > 0) {
    text += `RECOMMENDATIONS:\n`;
    text += `----------------\n`;
    state.recommendations.forEach((rec, index) => {
      text += `${index + 1}. ${rec}\n`;
    });
    text += `\n`;
  }

  text += `DISCLAIMER:\n`;
  text += `-----------\n`;
  text += `This result is based on the information you entered and available agricultural/weather information at the time of the check. Conditions can change. This tool provides decision support, not a guarantee of success. Always use your own judgment and local knowledge. Consult local agricultural extension services for precise local recommendations.\n`;

  return text;
}

function restartTool() {
  // Reset state
  plantingState.currentStep = 0;
  plantingState.location = { country: '', province: '', district: '', hasLocalData: false };
  plantingState.crop = { type: '', name: '', info: '' };
  plantingState.farming = { method: '', waterSource: '' };
  plantingState.land = { preparation: '' };
  plantingState.soil = { moisture: '' };
  plantingState.water = { availability: '' };
  plantingState.weather = { current: '', recentRain: '' };
  plantingState.planting = { plannedDate: '', plannedOption: '', withinWindow: false };
  plantingState.business = { costCalculated: '', marketPlanned: '' };
  plantingState.risks = [];
  plantingState.recommendations = [];

  // Reset UI
  document.querySelectorAll('.option-button').forEach(btn => btn.classList.remove('selected'));
  document.querySelectorAll('select').forEach(select => select.selectedIndex = 0);
  document.querySelectorAll('.hidden').forEach(el => {
    if (el.id !== 'startScreen') {
      el.classList.add('hidden');
    }
  });

  // Show start screen
  showSection('startScreen');
  updateProgress(0);
}