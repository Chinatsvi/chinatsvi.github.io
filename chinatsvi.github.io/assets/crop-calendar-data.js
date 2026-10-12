/**
 * AgriBase Crop Calendar Data Module
 * Ported from AgriBase Flutter App (Regional Agro-Zones & Horticultural Crop Datasets)
 */

const RegionalAgroZonesData = {
  presetLocations: [
    // 🇿🇼 ZIMBABWE
    {
      country: 'Zimbabwe',
      countryCode: 'ZW',
      region: 'Masvingo',
      district: 'Masvingo',
      climateZone: 'Middleveld / Lowveld Transition',
      latitude: -20.0744,
      longitude: 30.8328,
      elevationMeters: 1080,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [9, 10, 11, 12, 1],
      seasonalNotes: 'Warm to hot climate with moderate summer rainfall. Lowveld areas (e.g. Chiredzi, Triangle) are virtually frost-free, allowing winter irrigated tomato and vegetable production.'
    },
    {
      country: 'Zimbabwe',
      countryCode: 'ZW',
      region: 'Harare',
      district: 'Harare',
      climateZone: 'Highveld (Natural Region IIa)',
      latitude: -17.8292,
      longitude: 31.0522,
      elevationMeters: 1490,
      isSouthernHemisphere: true,
      frostRiskMonths: [5, 6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [9, 10, 11],
      seasonalNotes: 'High altitude plateau. Mild summers with reliable rain; cool dry winters with notable frost risk between late May and late July in low-lying vleis.'
    },
    {
      country: 'Zimbabwe',
      countryCode: 'ZW',
      region: 'Bulawayo & Matabeleland',
      district: 'Bulawayo',
      climateZone: 'Semi-Arid Middleveld (Region IV)',
      latitude: -20.1569,
      longitude: 28.5833,
      elevationMeters: 1350,
      isSouthernHemisphere: true,
      frostRiskMonths: [5, 6, 7],
      wetSeasonMonths: [11, 12, 1, 2],
      hotSeasonMonths: [9, 10, 11, 12],
      seasonalNotes: 'Semi-arid with lower erratic rainfall. Irrigation is strongly recommended for commercial horticulture. Winter frost is common in June.'
    },
    {
      country: 'Zimbabwe',
      countryCode: 'ZW',
      region: 'Manicaland',
      district: 'Mutare & Eastern Highlands',
      climateZone: 'Highland & Subtropical Valleys (Region I & II)',
      latitude: -18.9728,
      longitude: 32.6694,
      elevationMeters: 1120,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [10, 11, 12, 1, 2, 3, 4],
      hotSeasonMonths: [9, 10, 11],
      seasonalNotes: 'Microclimates range from mist-belt mountains (Nyanga, Vumba) to warm irrigated valleys (Honde, Save). Excellent year-round horticultural potential.'
    },
    {
      country: 'Zimbabwe',
      countryCode: 'ZW',
      region: 'Midlands',
      district: 'Gweru & Kwekwe',
      climateZone: 'Highveld / Middleveld (Region III)',
      latitude: -19.4500,
      longitude: 29.8167,
      elevationMeters: 1420,
      isSouthernHemisphere: true,
      frostRiskMonths: [5, 6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [9, 10, 11],
      seasonalNotes: 'Highveld zone with sharp winter frosts in open fields. Irrigation essential for dry season horticulture.'
    },

    // 🇿🇦 SOUTH AFRICA
    {
      country: 'South Africa',
      countryCode: 'ZA',
      region: 'Limpopo',
      district: 'Polokwane & Tzaneen',
      climateZone: 'Bushveld & Subtropical Lowveld',
      latitude: -23.9045,
      longitude: 29.4688,
      elevationMeters: 1310,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [10, 11, 12, 1, 2],
      seasonalNotes: 'Polokwane has winter frost, whereas Tzaneen and the Lowveld are frost-free subtropics famous for winter tomato, cabbage, and avocado production.'
    },
    {
      country: 'South Africa',
      countryCode: 'ZA',
      region: 'Gauteng',
      district: 'Johannesburg & Pretoria',
      climateZone: 'Highveld Plateau',
      latitude: -26.2041,
      longitude: 28.0473,
      elevationMeters: 1750,
      isSouthernHemisphere: true,
      frostRiskMonths: [5, 6, 7, 8],
      wetSeasonMonths: [10, 11, 12, 1, 2, 3],
      hotSeasonMonths: [10, 11, 12, 1],
      seasonalNotes: 'Severe winter frost between May and August makes open-field tomato/pepper impossible without tunnels or frost protection.'
    },
    {
      country: 'South Africa',
      countryCode: 'ZA',
      region: 'Western Cape',
      district: 'Cape Town & Boland',
      climateZone: 'Mediterranean (Winter Rainfall)',
      latitude: -33.9249,
      longitude: 18.4241,
      elevationMeters: 25,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [5, 6, 7, 8],
      hotSeasonMonths: [12, 1, 2, 3],
      seasonalNotes: 'Mediterranean climate: wet, cool winters and dry, warm/windy summers. Summer crops depend 100% on irrigation.'
    },
    {
      country: 'South Africa',
      countryCode: 'ZA',
      region: 'KwaZulu-Natal',
      district: 'Durban & Coastal Belt',
      climateZone: 'Humid Subtropical',
      latitude: -29.8587,
      longitude: 31.0218,
      elevationMeters: 20,
      isSouthernHemisphere: true,
      frostRiskMonths: [],
      wetSeasonMonths: [10, 11, 12, 1, 2, 3],
      hotSeasonMonths: [11, 12, 1, 2, 3],
      seasonalNotes: 'Frost-free coastal zone with high humidity. High fungal disease pressure in summer; excellent winter vegetable production.'
    },

    // 🇿🇲 ZAMBIA
    {
      country: 'Zambia',
      countryCode: 'ZM',
      region: 'Lusaka',
      district: 'Lusaka',
      climateZone: 'Central Plateau (Region IIa)',
      latitude: -15.3875,
      longitude: 28.3228,
      elevationMeters: 1280,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [9, 10, 11],
      seasonalNotes: 'Three distinct seasons: warm wet (Nov–Apr), cool dry (May–Aug), and hot dry (Sep–Nov). Heavy irrigation needed in hot dry season.'
    },

    // 🇲🇼 MALAWI
    {
      country: 'Malawi',
      countryCode: 'MW',
      region: 'Central Region',
      district: 'Lilongwe',
      climateZone: 'Central Plateau',
      latitude: -13.9626,
      longitude: 33.7741,
      elevationMeters: 1050,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [9, 10, 11],
      seasonalNotes: 'Subtropical climate with unimodal summer rainy season. Winter dambo and irrigated vegetable gardens are highly productive.'
    },

    // 🇰🇪 KENYA
    {
      country: 'Kenya',
      countryCode: 'KE',
      region: 'Rift Valley / Central',
      district: 'Nakuru & Naivasha',
      climateZone: 'Equatorial Highland (Bimodal)',
      latitude: -0.3031,
      longitude: 36.0800,
      elevationMeters: 1850,
      isSouthernHemisphere: false,
      frostRiskMonths: [],
      wetSeasonMonths: [3, 4, 5, 10, 11, 12],
      hotSeasonMonths: [1, 2, 3],
      seasonalNotes: 'Equatorial bimodal rainfall pattern: Long rains (March–May) and Short rains (October–December). Moderate year-round temperatures ideal for horticultural exports.'
    },

    // 🇳🇬 NIGERIA
    {
      country: 'Nigeria',
      countryCode: 'NG',
      region: 'Northern Nigeria',
      district: 'Kano & Kaduna',
      climateZone: 'Sudan / Northern Guinea Savanna',
      latitude: 12.0022,
      longitude: 8.5920,
      elevationMeters: 480,
      isSouthernHemisphere: false,
      frostRiskMonths: [],
      wetSeasonMonths: [6, 7, 8, 9],
      hotSeasonMonths: [3, 4, 5],
      seasonalNotes: 'Single short rainy season (June–September) followed by dry Harmattan period (November–February). Dry season Fadama irrigation is central to tomato/onion output.'
    },
    {
      country: 'Nigeria',
      countryCode: 'NG',
      region: 'South West',
      district: 'Ibadan & Oyo',
      climateZone: 'Derived Savanna / Forest (Bimodal)',
      latitude: 7.3775,
      longitude: 3.9470,
      elevationMeters: 230,
      isSouthernHemisphere: false,
      frostRiskMonths: [],
      wetSeasonMonths: [4, 5, 6, 7, 9, 10],
      hotSeasonMonths: [1, 2, 3],
      seasonalNotes: 'Bimodal rainfall with early rains (April–July) and late rains (September–November) interrupted by the August dry spell.'
    },

    // 🇬🇭 GHANA
    {
      country: 'Ghana',
      countryCode: 'GH',
      region: 'Ashanti / Central',
      district: 'Kumasi',
      climateZone: 'Deciduous Forest Zone (Bimodal)',
      latitude: 6.6885,
      longitude: -1.6244,
      elevationMeters: 250,
      isSouthernHemisphere: false,
      frostRiskMonths: [],
      wetSeasonMonths: [4, 5, 6, 7, 9, 10],
      hotSeasonMonths: [1, 2, 3],
      seasonalNotes: 'Major season (April–July) and minor season (September–November). High relative humidity.'
    }
  ],

  getDefaultSouthernProfile: function() {
    return {
      country: 'Southern Africa (General)',
      countryCode: 'GEN_SH',
      region: 'General Region',
      district: 'Local District',
      climateZone: 'Southern Hemisphere Subtropical',
      latitude: -20.0,
      longitude: 30.0,
      elevationMeters: 1000,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [10, 11, 12, 1],
      seasonalNotes: 'Standard Southern Hemisphere seasonal cycle: Summer wet season (Nov–Mar) and Winter dry/cool season (May–Aug).'
    };
  },

  getDefaultNorthernProfile: function() {
    return {
      country: 'Northern Hemisphere (General)',
      countryCode: 'GEN_NH',
      region: 'General Region',
      district: 'Local District',
      climateZone: 'Northern Hemisphere Temperate/Subtropical',
      latitude: 20.0,
      longitude: 10.0,
      elevationMeters: 300,
      isSouthernHemisphere: false,
      frostRiskMonths: [12, 1, 2],
      wetSeasonMonths: [5, 6, 7, 8, 9],
      hotSeasonMonths: [6, 7, 8],
      seasonalNotes: 'Standard Northern Hemisphere seasonal cycle: Spring/Summer planting (Mar–Jul) and Winter dormancy/frost (Dec–Feb).'
    };
  }
};

const HorticulturalCropsData = {
  allCrops: [
    // 🍅 TOMATO
    {
      id: 'tomato',
      name: 'Tomato',
      scientificName: 'Solanum lycopersicum',
      category: 'vegetable',
      iconEmoji: '🍅',
      generalDescription: 'Warm-season solanaceous crop requiring frost-free conditions, consistent moisture, and fertile, well-drained soils.',
      standardMaturityDaysMin: 70,
      standardMaturityDaysMax: 100,
      optimalTempMin: 18.0,
      optimalTempMax: 28.0,
      frostToleranceScore: 0.0,
      waterRequirement: 'High (400–600 mm/season)',
      soilPhRange: '6.0 – 6.8',
      defaultDataSource: 'Agricultural Research Council (ARC) / AREX Zimbabwe Horticultural Handbook',
      varieties: [
        {
          id: 'tom_early',
          name: 'Early Maturity (Determinate Bush)',
          maturityType: 'early',
          maturityDaysMin: 65,
          maturityDaysMax: 75,
          description: 'Bush type, concentrated fruit set, good for shorter growing windows or avoiding mid-season frost/rain.'
        },
        {
          id: 'tom_med',
          name: 'Medium Maturity (Indeterminate / Semi)',
          maturityType: 'medium',
          maturityDaysMin: 75,
          maturityDaysMax: 90,
          description: 'Extended harvest period, requires trellising/staking, high yield potential under continuous irrigation.'
        },
        {
          id: 'tom_late',
          name: 'Late Maturity (Indeterminate Beefsteak)',
          maturityType: 'late',
          maturityDaysMin: 90,
          maturityDaysMax: 110,
          description: 'Large fruit, long production cycle, needs protected or frost-free climate.'
        },
        {
          id: 'tom_star9009',
          name: 'Star 9009 / Rodade / Tengeru',
          maturityType: 'medium',
          maturityDaysMin: 75,
          maturityDaysMax: 85,
          description: 'Widely grown open-pollinated & hybrid varieties in Southern & East Africa with bacterial wilt tolerance.'
        }
      ],
      standardStages: [
        {
          id: 'tom_stage_1',
          name: 'Planting / Transplanting',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 7,
          title: 'Transplanting & Root Settling',
          description: 'Transplant hardy 4–6 week old seedlings in moist soil during early morning or cool late afternoon.',
          whyItMatters: 'Minimizes transplant shock and promotes immediate root-soil contact.',
          whatToMonitor: [
            { title: 'Transplant Shock / Wilting', detail: 'Ensure light, frequent irrigation to keep root zone damp during initial 3–5 days.' },
            { title: 'Cutworm Activity', detail: 'Check seedling bases at soil level for severed stems early in the morning.', isWarning: true }
          ],
          nutrientGuidance: 'Apply basal compound fertilizer (e.g. Compound S/C or NPK 7:14:7) banded 5cm below root zone.',
          weedingGuidance: 'Ensure field is weed-free at transplanting. Avoid soil compaction near delicate seedling stems.',
          warnings: 'Do not bury stem too deeply if soil is waterlogged to prevent stem rot.'
        },
        {
          id: 'tom_stage_2',
          name: 'Early Establishment',
          type: 'establishment',
          startDayOffset: 7,
          endDayOffset: 21,
          title: 'Vegetative Growth & Root Expansion',
          description: 'Rapid root branching and vegetative shoot extension. Staking or trellising is prepared.',
          whyItMatters: 'Strong vegetative canopy provides photosynthetic foundation for heavy fruit load.',
          whatToMonitor: [
            { title: 'Damping Off & Fungal Lesions', detail: 'Inspect lower foliage and collar region for brown lesions.' },
            { title: 'Red Spider Mite & Aphids', detail: 'Check undersides of leaves for webbing, stippling, or curling.', isWarning: true }
          ],
          nutrientGuidance: 'Side-dress with first split of nitrogen/potassium (e.g. CAN or Ammonium Nitrate) 2–3 weeks post-transplant.',
          weedingGuidance: 'Conduct shallow manual weeding while weeds are small (2–4 leaf stage).',
          warnings: 'Avoid over-watering which induces shallow root systems.'
        },
        {
          id: 'tom_stage_3',
          name: 'Flowering & Early Fruit Set',
          type: 'flowering',
          startDayOffset: 30,
          endDayOffset: 50,
          title: 'First Flower Truss to Fruit Set',
          description: 'First blossom trusses appear and undergo pollination. Temperature control and uniform moisture are critical.',
          whyItMatters: 'Flower drop directly reduces total market yield.',
          whatToMonitor: [
            { title: 'Blossom Drop from Heat/Cold', detail: 'Temperatures >32°C or <13°C inhibit pollen viability.', isWarning: true },
            { title: 'Tuta Absoluta / Leafminer', detail: 'Inspect leaves for translucent blotch mines and check pheromone traps.', isWarning: true }
          ],
          nutrientGuidance: 'Introduce potassium-rich top-dressing and ensure Calcium availability to prevent Blossom End Rot.',
          weedingGuidance: 'Maintain clean intra-row beds. Mulching with clean grass helps suppress weeds.',
          warnings: 'Do not allow moisture swings during fruit set, which induces Blossom End Rot and fruit cracking.'
        },
        {
          id: 'tom_stage_4',
          name: 'Fruit Bulking & Ripening',
          type: 'fruitDevelopment',
          startDayOffset: 50,
          endDayOffset: 75,
          title: 'Fruit Expansion to Color Break',
          description: 'Green fruits enlarge and progress towards breaker and mature red stages.',
          whyItMatters: 'Determines fruit size, firmness, brix level, and market grade.',
          whatToMonitor: [
            { title: 'Helicoverpa / Fruit Borer', detail: 'Check near calyx of green tomatoes for small entry holes.', isWarning: true },
            { title: 'Fruit Cracking / Sunscald', detail: 'Ensure adequate leaf canopy coverage or shade netting.' }
          ],
          nutrientGuidance: 'Maintain steady potassium levels for fruit color and firm cell walls.',
          weedingGuidance: 'Spot weed rogue weeds that interfere with air movement.',
          warnings: 'Irregular watering right before harvest causes skin split and soft fruit.'
        },
        {
          id: 'tom_stage_5',
          name: 'Harvesting',
          type: 'harvesting',
          startDayOffset: 70,
          endDayOffset: 110,
          title: 'Harvest Window (Breaker to Full Ripe)',
          description: 'Harvest at pink/breaker stage for distant transport or full red for immediate local sales.',
          whyItMatters: 'Careful harvesting reduces post-harvest bruising and extends shelf life.',
          whatToMonitor: [
            { title: 'Fruit Grading & Sorting', detail: 'Cull damaged or diseased fruit immediately to prevent container rot.' },
            { title: 'Post-Harvest Cooling', detail: 'Keep picked crates in shaded, well-ventilated areas.' }
          ],
          nutrientGuidance: 'For indeterminate crops, continue light split potassium feeding between pickings.',
          weedingGuidance: 'Keep paths clear for harvest transport.',
          warnings: 'Never harvest when wet with morning dew to minimize post-harvest bacterial decay.'
        }
      ]
    },

    // 🥬 CABBAGE
    {
      id: 'cabbage',
      name: 'Cabbage',
      scientificName: 'Brassica oleracea var. capitata',
      category: 'vegetable',
      iconEmoji: '🥬',
      generalDescription: 'Cool to moderate season brassica with high nitrogen demand, requiring uniform irrigation and good pest scouting.',
      standardMaturityDaysMin: 70,
      standardMaturityDaysMax: 110,
      optimalTempMin: 15.0,
      optimalTempMax: 22.0,
      frostToleranceScore: 0.7,
      waterRequirement: 'High (380–500 mm)',
      soilPhRange: '6.2 – 7.2',
      defaultDataSource: 'Horticultural Research Centre / FAO Crop Profiles',
      varieties: [
        { id: 'cab_early', name: 'Early Maturity (e.g. Star 3301, Gloria)', maturityType: 'early', maturityDaysMin: 65, maturityDaysMax: 80, description: 'Fast compact heads, good for rapid market turnaround.' },
        { id: 'cab_med', name: 'Medium Maturity (e.g. Marcanta, Conquistador)', maturityType: 'medium', maturityDaysMin: 80, maturityDaysMax: 95, description: 'Dense large heads with good holding ability in field.' },
        { id: 'cab_late', name: 'Late Maturity (e.g. Drummond, Grandslam)', maturityType: 'late', maturityDaysMin: 95, maturityDaysMax: 120, description: 'Heavy yielding, ideal for cool winter season production.' }
      ],
      standardStages: [
        {
          id: 'cab_stage_1',
          name: 'Transplanting & Rooting',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 10,
          title: 'Establishment Phase',
          description: 'Transplant healthy 4–5 week seedlings into moist, limed soil.',
          whyItMatters: 'Quick establishment prevents premature head buttoning.',
          whatToMonitor: [
            { title: 'Cutworm & Aphid Colonization', detail: 'Scout seedlings daily for severed stems and green peach aphids.', isWarning: true }
          ],
          nutrientGuidance: 'Apply basal NPK (Compound C / 5:15:12) according to soil test.',
          weedingGuidance: 'Ensure weed-free beds at planting.'
        },
        {
          id: 'cab_stage_2',
          name: 'Foliage Development',
          type: 'vegetative',
          startDayOffset: 10,
          endDayOffset: 35,
          title: 'Frame & Outer Leaf Expansion',
          description: 'Formation of 18–25 large outer frame leaves before cupping.',
          whyItMatters: 'Frame size determines eventual head diameter and weight.',
          whatToMonitor: [
            { title: 'Diamondback Moth (DBM) & Bagrada Bug', detail: 'Check leaf undersides for green DBM caterpillars.', isWarning: true }
          ],
          nutrientGuidance: 'Top-dress with CAN or Ammonium Nitrate at 3 and 5 weeks after transplanting.',
          weedingGuidance: 'Weed early before canopy closes; avoid damaging shallow brassica roots.'
        },
        {
          id: 'cab_stage_3',
          name: 'Head Formation & Compacting',
          type: 'fruitDevelopment',
          startDayOffset: 35,
          endDayOffset: 70,
          title: 'Head Cupping & Compacting',
          description: 'Inner leaves curl inward, overlap, and compact into a dense head.',
          whyItMatters: 'Steady moisture is essential to prevent head burst.',
          whatToMonitor: [
            { title: 'Black Rot (Xanthomonas)', detail: 'Look for yellow V-shaped lesions along leaf margins.', isWarning: true },
            { title: 'Head Splitting', detail: 'Avoid sudden heavy irrigation following dry spells.' }
          ],
          nutrientGuidance: 'Avoid late excessive nitrogen which causes soft puffy heads with poor storage.',
          weedingGuidance: 'Canopy should now suppress most weeds.'
        },
        {
          id: 'cab_stage_4',
          name: 'Harvesting',
          type: 'harvesting',
          startDayOffset: 70,
          endDayOffset: 110,
          title: 'Maturity & Head Cutting',
          description: 'Harvest when heads feel solid and firm to thumb pressure.',
          whyItMatters: 'Overdue heads split and lose commercial value.',
          whatToMonitor: [
            { title: 'Head Firmness & Wrapper Leaves', detail: 'Leave 2–3 wrapper leaves attached to protect head in transport.' }
          ]
        }
      ]
    },

    // 🧅 ONION
    {
      id: 'onion',
      name: 'Onion',
      scientificName: 'Allium cepa',
      category: 'vegetable',
      iconEmoji: '🧅',
      generalDescription: 'Daylength and temperature sensitive bulb crop. Requires friable soil, meticulous weed management, and dry curing conditions at harvest.',
      standardMaturityDaysMin: 120,
      standardMaturityDaysMax: 180,
      optimalTempMin: 13.0,
      optimalTempMax: 24.0,
      frostToleranceScore: 0.8,
      waterRequirement: 'Moderate (350–500 mm)',
      soilPhRange: '6.0 – 6.8',
      defaultDataSource: 'National Horticultural Guidelines / ARC South Africa',
      varieties: [
        { id: 'on_short_day', name: 'Short-Day Varieties (e.g. Texas Grano, Red Creole)', maturityType: 'medium', maturityDaysMin: 120, maturityDaysMax: 150, description: 'Suited to African latitudes; initiates bulbing with 11–12 hours daylight.' },
        { id: 'on_inter', name: 'Intermediate-Day Varieties', maturityType: 'late', maturityDaysMin: 150, maturityDaysMax: 180, description: 'High pungency, excellent storage quality.' }
      ],
      standardStages: [
        {
          id: 'on_stage_1',
          name: 'Sowing / Transplanting',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 20,
          title: 'Nursery or Seedling Establishment',
          description: 'Transplant pencil-thick seedlings at 8–10 cm intra-row spacing.',
          whyItMatters: 'Correct planting depth prevents double bulbs or shallow roots.',
          whatToMonitor: [{ title: 'Thrips & Damping Off', detail: 'Inspect leaf crevices for tiny thrips.', isWarning: true }],
          nutrientGuidance: 'Incorporate phosphorus and potassium basal fertilizer prior to planting.',
          weedingGuidance: 'Onions have poor foliage cover and cannot compete with weeds. Keep bed spotless.'
        },
        {
          id: 'on_stage_2',
          name: 'Vegetative Leaf Production',
          type: 'vegetative',
          startDayOffset: 20,
          endDayOffset: 70,
          title: 'Foliage Growth & Root System',
          description: 'Producing 10–13 healthy upright leaves before bulbing trigger.',
          whyItMatters: 'Each leaf corresponds to a bulb ring; more leaves = bigger bulb.',
          whatToMonitor: [{ title: 'Purple Blotch & Downy Mildew', detail: 'Watch for water-soaked spots turning purple-brown.' }],
          nutrientGuidance: 'Apply split nitrogen top-dressings. Stop nitrogen 4 weeks before bulbing.',
          weedingGuidance: 'Regular shallow hoeing or hand pulling.'
        },
        {
          id: 'on_stage_3',
          name: 'Bulbing & Swelling',
          type: 'fruitDevelopment',
          startDayOffset: 70,
          endDayOffset: 130,
          title: 'Bulb Expansion',
          description: 'Base of plant swells into bulb. Daylight hours and warmth trigger.',
          whyItMatters: 'Consistent soil moisture prevents split/doubled bulbs.',
          whatToMonitor: [{ title: 'Neck Softening & Leaf Lodging', detail: 'Monitor natural collapse of tops.' }],
          nutrientGuidance: 'Ensure adequate potassium and sulfur for bulb firmness.',
          warnings: 'Stop irrigation when 50–70% of tops have fallen over.'
        },
        {
          id: 'on_stage_4',
          name: 'Maturity & Curing',
          type: 'harvesting',
          startDayOffset: 120,
          endDayOffset: 170,
          title: 'Harvest & Field Curing',
          description: 'Lift bulbs and cure in field or ventilated shed for 10–14 days.',
          whyItMatters: 'Dry cured necks prevent bacterial rot in storage.',
          whatToMonitor: [{ title: 'Neck Dryness', detail: 'Neck should be completely papery and dry before trimming.' }]
        }
      ]
    },

    // 🥕 CARROT
    {
      id: 'carrot',
      name: 'Carrot',
      scientificName: 'Daucus carota',
      category: 'vegetable',
      iconEmoji: '🥕',
      generalDescription: 'Direct-seeded root crop requiring deep, loose, stone-free sandy-loam soils and steady moisture during germination.',
      standardMaturityDaysMin: 75,
      standardMaturityDaysMax: 110,
      optimalTempMin: 16.0,
      optimalTempMax: 22.0,
      frostToleranceScore: 0.6,
      waterRequirement: 'Moderate (300–450 mm)',
      soilPhRange: '5.8 – 6.8',
      defaultDataSource: 'ARC Horticulture Guide / Ministry of Agriculture',
      varieties: [
        { id: 'car_nantes', name: 'Nantes / Cape Market', maturityType: 'early', maturityDaysMin: 70, maturityDaysMax: 85, description: 'Cylindrical sweet roots with blunt ends, popular for fresh market.' },
        { id: 'car_kuroda', name: 'Kuroda / Chantenay', maturityType: 'medium', maturityDaysMin: 85, maturityDaysMax: 105, description: 'Conical roots, performs well in heavier soils and warmer seasons.' }
      ],
      standardStages: [
        {
          id: 'car_stage_1',
          name: 'Direct Sowing & Emergence',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 14,
          title: 'Germination Window',
          description: 'Sow fine seed 1cm deep in finely prepared beds. Keep surface continuously damp.',
          whyItMatters: 'Crusted dry soil prevents fragile carrot seedlings from emerging.',
          whatToMonitor: [{ title: 'Soil Crusting & Moisture', detail: 'Irrigate lightly 1–2 times daily until green rows are visible.' }],
          nutrientGuidance: 'Avoid fresh animal manure which causes root forking.'
        },
        {
          id: 'car_stage_2',
          name: 'Thinning & Root Extension',
          type: 'vegetative',
          startDayOffset: 14,
          endDayOffset: 40,
          title: 'Thinning to 3–5 cm',
          description: 'Thin seedlings to single plants to allow uniform root expansion.',
          whyItMatters: 'Unthinned carrots remain thin and twisted.',
          whatToMonitor: [{ title: 'Alternaria Leaf Blight', detail: 'Inspect for yellow-brown spotting on foliage.' }]
        },
        {
          id: 'car_stage_3',
          name: 'Root Bulking & Harvest',
          type: 'harvesting',
          startDayOffset: 70,
          endDayOffset: 110,
          title: 'Root Sizing & Harvest',
          description: 'Crown diameter reaches 2.5–3.5 cm with intense orange color.',
          whyItMatters: 'Lift when soil is moist to prevent root snapping.',
          whatToMonitor: [{ title: 'Green Shoulders', detail: 'Keep root crowns covered with soil to avoid bitterness.' }]
        }
      ]
    },

    // 🥔 POTATO
    {
      id: 'potato',
      name: 'Potato (Irish Potato)',
      scientificName: 'Solanum tuberosum',
      category: 'rootAndTuber',
      iconEmoji: '🥔',
      generalDescription: 'Major commercial tuber crop requiring cool nights, certified seed tubers, ridging/earthing up, and intensive blight management.',
      standardMaturityDaysMin: 85,
      standardMaturityDaysMax: 120,
      optimalTempMin: 15.0,
      optimalTempMax: 22.0,
      frostToleranceScore: 0.1,
      waterRequirement: 'High (450–600 mm)',
      soilPhRange: '5.2 – 6.2',
      defaultDataSource: 'Potato Seed Association / ARC South Africa / AREX',
      varieties: [
        { id: 'pot_bp1', name: 'BP1 / Mondial / Sifra', maturityType: 'medium', maturityDaysMin: 90, maturityDaysMax: 110, description: 'Standard Southern & East African commercial table varieties.' },
        { id: 'pot_early', name: 'Early Maturity (e.g. Valor)', maturityType: 'early', maturityDaysMin: 75, maturityDaysMax: 90, description: 'Fast bulking for early market entry.' }
      ],
      standardStages: [
        {
          id: 'pot_stage_1',
          name: 'Tuber Planting & Sprouting',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 25,
          title: 'Certified Seed Planting',
          description: 'Plant well-sprouted seed tubers 10–15cm deep in furrows or ridges.',
          whyItMatters: 'Certified clean seed prevents devastating bacterial wilt and viruses.',
          whatToMonitor: [{ title: 'Blackleg & Rhizoctonia', detail: 'Inspect emerging sprouts for blackened stem bases.', isWarning: true }]
        },
        {
          id: 'pot_stage_2',
          name: 'Vegetative & Earthing Up',
          type: 'vegetative',
          startDayOffset: 25,
          endDayOffset: 50,
          title: 'Earthing Up / Ridging',
          description: 'Mound soil around stem bases when plants reach 15–20cm height.',
          whyItMatters: 'Prevents tubers from greening and potato tuber moth damage.',
          whatToMonitor: [{ title: 'Late Blight (Phytophthora)', detail: 'Inspect leaves for dark water-soaked spots.', isWarning: true }]
        },
        {
          id: 'pot_stage_3',
          name: 'Tuber Bulking & Harvest',
          type: 'harvesting',
          startDayOffset: 50,
          endDayOffset: 115,
          title: 'Bulking & Haulm Maturity',
          description: 'Tubers swell rapidly. Allow haulms to die back 10–14 days before lifting.',
          whyItMatters: 'Skin setting prevents scuffing and rots during transport.',
          whatToMonitor: [{ title: 'Skin Slip Test', detail: 'Rub thumb firmly against skin; it should not peel.' }]
        }
      ]
    },

    // 🍠 SWEET POTATO
    {
      id: 'sweet_potato',
      name: 'Sweet Potato',
      scientificName: 'Ipomoea batatas',
      category: 'rootAndTuber',
      iconEmoji: '🍠',
      generalDescription: 'Resilient warm-season tuberous crop propagated by vine cuttings. High drought resilience and food security value.',
      standardMaturityDaysMin: 90,
      standardMaturityDaysMax: 140,
      optimalTempMin: 22.0,
      optimalTempMax: 30.0,
      frostToleranceScore: 0.0,
      waterRequirement: 'Moderate',
      soilPhRange: '5.5 – 6.5',
      defaultDataSource: 'International Potato Center (CIP) / Regional Extension',
      varieties: [
        { id: 'sp_ofsp', name: 'Orange-Fleshed (OFSP - e.g. Bophelo, Alisha)', maturityType: 'medium', maturityDaysMin: 90, maturityDaysMax: 120, description: 'High provitamin A beta-carotene content, high consumer demand.' },
        { id: 'sp_white', name: 'White/Cream Fleshed Traditional', maturityType: 'late', maturityDaysMin: 120, maturityDaysMax: 150, description: 'High dry matter content, excellent storage in soil.' }
      ],
      standardStages: [
        {
          id: 'sp_stage_1',
          name: 'Vine Cutting Planting (Ridges)',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 25,
          title: 'Vine Planting on Mounds/Ridges',
          description: 'Plant 25–30cm healthy apical vine cuttings with at least 3 nodes buried.',
          whyItMatters: 'Mounds provide loose soil for tuber expansion and easy harvest.',
          whatToMonitor: [{ title: 'Sweet Potato Weevil (Cylas spp.)', detail: 'Use clean pest-free planting vine material.', isWarning: true }]
        },
        {
          id: 'sp_stage_2',
          name: 'Tuber Harvest',
          type: 'harvesting',
          startDayOffset: 90,
          endDayOffset: 150,
          title: 'Harvest Window',
          description: 'Harvest piecemeal or clear-cut when leaves begin yellowing.',
          whyItMatters: 'Timely harvest avoids sweet potato weevil damage in dry soil.',
          whatToMonitor: [{ title: 'Tuber Cracking', detail: 'Avoid harvesting in cold wet soils.' }]
        }
      ]
    },

    // 🫑 PEPPER
    {
      id: 'pepper',
      name: 'Sweet Pepper & Chilli',
      scientificName: 'Capsicum annuum',
      category: 'vegetable',
      iconEmoji: '🫑',
      generalDescription: 'Warm-season solanaceous crop requiring long warm frost-free season, consistent moisture, and protection from sunscald.',
      standardMaturityDaysMin: 75,
      standardMaturityDaysMax: 120,
      optimalTempMin: 20.0,
      optimalTempMax: 29.0,
      frostToleranceScore: 0.0,
      waterRequirement: 'High (450–600 mm)',
      soilPhRange: '6.0 – 6.8',
      defaultDataSource: 'National Horticultural Guidelines',
      varieties: [
        { id: 'pep_sweet', name: 'Sweet Bell Pepper (California Wonder / Hercules)', maturityType: 'medium', maturityDaysMin: 75, maturityDaysMax: 100, description: 'Large blocky fruits.' },
        { id: 'pep_hot', name: 'Hot Chilli (Bird Eye / Habanero / Serrano)', maturityType: 'late', maturityDaysMin: 90, maturityDaysMax: 120, description: 'Pungent fruits, high heat tolerance.' }
      ],
      standardStages: [
        {
          id: 'pep_stage_1',
          name: 'Transplanting & Canopy Build',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 25,
          title: 'Establishment & Branching',
          description: 'Transplant 6-week seedlings. Crown flower removal encourages vegetative branching.',
          whyItMatters: 'Strong bush prevents fruit sunburn.',
          whatToMonitor: [{ title: 'Thrips & Broad Mites', detail: 'Check for distorted upward/downward leaf curling.', isWarning: true }]
        },
        {
          id: 'pep_stage_2',
          name: 'Harvesting',
          type: 'harvesting',
          startDayOffset: 75,
          endDayOffset: 140,
          title: 'Harvest Window',
          description: 'Cut with sharp secateurs leaving pedicel attached.',
          whyItMatters: 'Pulling fruits by hand tears branches.',
          whatToMonitor: [{ title: 'Bacterial Spot & Anthracnose', detail: 'Inspect fruit walls for sunken lesions.' }]
        }
      ]
    },

    // 🌽 SWEET CORN
    {
      id: 'sweet_corn',
      name: 'Sweet Corn',
      scientificName: 'Zea mays var. saccharata',
      category: 'vegetable',
      iconEmoji: '🌽',
      generalDescription: 'High-sugar maize variety harvested at milk stage for fresh vegetable consumption. Requires block planting for wind pollination.',
      standardMaturityDaysMin: 70,
      standardMaturityDaysMax: 90,
      optimalTempMin: 18.0,
      optimalTempMax: 30.0,
      frostToleranceScore: 0.0,
      waterRequirement: 'High (450–550 mm)',
      soilPhRange: '5.8 – 6.8',
      defaultDataSource: 'National Agronomic Guidelines',
      varieties: [
        { id: 'sc_sh2', name: 'Super Sweet (sh2 / su)', maturityType: 'medium', maturityDaysMin: 72, maturityDaysMax: 85, description: 'Extra sweet, holds sugar level longer post-harvest.' }
      ],
      standardStages: [
        {
          id: 'sc_stage_1',
          name: 'Direct Planting (In Blocks)',
          type: 'planting',
          startDayOffset: 0,
          endDayOffset: 15,
          title: 'Block Sowing',
          description: 'Plant in square blocks rather than long single rows for uniform wind pollination.',
          whyItMatters: 'Poor pollination results in missing kernels on cobs.',
          whatToMonitor: [{ title: 'Fall Armyworm (FAW)', detail: 'Inspect leaf whorls for frass and larval feeding damage.', isWarning: true }]
        },
        {
          id: 'sc_stage_2',
          name: 'Milk Stage Harvest',
          type: 'harvesting',
          startDayOffset: 70,
          endDayOffset: 90,
          title: 'Harvest Window',
          description: 'Harvest when silks turn brown and piercing a kernel releases milky sap.',
          whyItMatters: 'Watery sap = premature; doughy sap = overmature.',
          whatToMonitor: [{ title: 'Kernel Sap Clarity', detail: 'Must be milky white.' }]
        }
      ]
    }
  ]
};

if (typeof window !== 'undefined') {
  window.RegionalAgroZonesData = RegionalAgroZonesData;
  window.HorticulturalCropsData = HorticulturalCropsData;
}
