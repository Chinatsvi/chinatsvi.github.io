import '../../models/crop_calendar/crop_calendar_models.dart';

class HorticulturalCropsData {
  static List<HorticulturalCrop> getAllCrops() {
    return [
      // ==========================================
      // 🍅 TOMATO
      // ==========================================
      const HorticulturalCrop(
        id: 'tomato',
        name: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        category: CropCategory.vegetable,
        iconEmoji: '🍅',
        generalDescription:
            'Warm-season solanaceous crop requiring frost-free conditions, consistent moisture, and fertile, well-drained soils.',
        standardMaturityDaysMin: 70,
        standardMaturityDaysMax: 100,
        optimalTempMin: 18.0,
        optimalTempMax: 28.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'High (400–600 mm/season)',
        soilPhRange: '6.0 – 6.8',
        defaultDataSource:
            'Agricultural Research Council (ARC) / AREX Zimbabwe Horticultural Handbook',
        varieties: [
          CropVariety(
            id: 'tom_early',
            name: 'Early Maturity (Determinate)',
            maturityType: MaturityType.early,
            maturityDaysMin: 65,
            maturityDaysMax: 75,
            description:
                'Bush type, concentrated fruit set, good for shorter growing windows or avoiding mid-season frost/rain.',
          ),
          CropVariety(
            id: 'tom_med',
            name: 'Medium Maturity (Indeterminate / Semi)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 75,
            maturityDaysMax: 90,
            description:
                'Extended harvest period, requires trellising/staking, high yield potential under continuous irrigation.',
          ),
          CropVariety(
            id: 'tom_late',
            name: 'Late Maturity (Indeterminate Beefsteak)',
            maturityType: MaturityType.late,
            maturityDaysMin: 90,
            maturityDaysMax: 110,
            description:
                'Large fruit, long production cycle, needs protected or frost-free climate.',
          ),
          CropVariety(
            id: 'tom_star9009',
            name: 'Star 9009 / Rodade / Tengeru',
            maturityType: MaturityType.medium,
            maturityDaysMin: 75,
            maturityDaysMax: 85,
            description:
                'Widely grown open pollinated & hybrid varieties in Southern & East Africa with bacterial wilt and nematode tolerances.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'tom_stage_1',
            name: 'Planting / Transplanting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 7,
            title: 'Transplanting & Root Settling',
            description:
                'Transplant hardy 4–6 week old seedlings in moist soil during early morning or cool late afternoon.',
            whyItMatters:
                'Minimizes transplant shock and promotes immediate root-soil contact.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Transplant Shock / Wilting',
                detail:
                    'Ensure light, frequent irrigation to keep root zone damp during initial 3–5 days.',
              ),
              StageMonitoringItem(
                title: 'Cutworm Activity',
                detail:
                    'Check seedling bases at soil level for severed stems early in the morning.',
                isWarning: true,
              ),
            ],
            nutrientGuidance:
                'Apply basal compound fertilizer (e.g. Compound S/C or NPK 7:14:7) banded 5cm below and beside seedling root zone as per soil test recommendations.',
            weedingGuidance:
                'Ensure field is weed-free at transplanting. Avoid soil compaction near delicate seedling stems.',
            warnings:
                'Do not bury the stem too deeply if soil is waterlogged to prevent stem rot.',
          ),
          GrowthStage(
            id: 'tom_stage_2',
            name: 'Early Establishment',
            type: StageType.establishment,
            startDayOffset: 7,
            endDayOffset: 21,
            title: 'Vegetative Growth & Root Expansion',
            description:
                'Rapid root branching and vegetative shoot extension. Staking or trellising is prepared.',
            whyItMatters:
                'Strong vegetative canopy provides photosynthetic foundation for heavy fruit load.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Damping Off & Fungal Lesions',
                detail:
                    'Inspect lower foliage and collar region for brown lesions or water-soaking.',
              ),
              StageMonitoringItem(
                title: 'Red Spider Mite & Aphids',
                detail:
                    'Check undersides of leaves for webbing, fine stippling, or curling.',
                isWarning: true,
              ),
            ],
            nutrientGuidance:
                'Side-dress with first split of nitrogen/potassium (e.g. Ammonium Nitrate / CAN) approximately 2–3 weeks after transplanting according to soil test rates.',
            weedingGuidance:
                'Conduct shallow manual or mechanical weeding while weeds are small (2–4 leaf stage). Avoid root disturbance.',
            warnings:
                'Avoid over-watering which induces shallow root systems and increases fungal root rot risk.',
          ),
          GrowthStage(
            id: 'tom_stage_3',
            name: 'Flowering & Early Fruit Set',
            type: StageType.flowering,
            startDayOffset: 30,
            endDayOffset: 50,
            title: 'First Flower Truss to Fruit Set',
            description:
                'First blossom trusses appear and undergo pollination. Temperature control and uniform moisture are critical.',
            whyItMatters:
                'Flower drop directly reduces total market yield.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Blossom Drop from Heat/Cold',
                detail:
                    'Temperatures >32°C or <13°C inhibit pollen viability. Note extreme temperature days.',
                isWarning: true,
              ),
              StageMonitoringItem(
                title: 'Tuta Absoluta / Tomato Leafminer',
                detail:
                    'Inspect leaves for translucent blotch mines and check pheromone traps.',
                isWarning: true,
              ),
              StageMonitoringItem(
                title: 'Early Blight (Alternaria)',
                detail:
                    'Look for concentric target-like brown spots on older lower leaves.',
              ),
            ],
            nutrientGuidance:
                'Introduce potassium-rich top-dressing (e.g. Potassium Nitrate or Potassium Sulphate) and ensure Calcium availability to prevent Blossom End Rot.',
            weedingGuidance:
                'Maintain clean intra-row beds. Mulching with clean grass helps suppress weeds and conserve root moisture.',
            warnings:
                'Do not allow moisture swings during fruit set, which induces Blossom End Rot and fruit cracking.',
          ),
          GrowthStage(
            id: 'tom_stage_4',
            name: 'Fruit Bulking & Ripening',
            type: StageType.fruitDevelopment,
            startDayOffset: 50,
            endDayOffset: 75,
            title: 'Fruit Expansion to Color Break',
            description:
                'Green fruits enlarge and progress towards breaker and mature red stages.',
            whyItMatters:
                'Determines fruit size, firmness, brix level, and market grade.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Helicoverpa / Fruit Borer',
                detail:
                    'Check near the calyx of green tomatoes for small entry holes and larval frass.',
                isWarning: true,
              ),
              StageMonitoringItem(
                title: 'Fruit Cracking / Sunscald',
                detail:
                    'Ensure adequate leaf canopy coverage or shade netting to shield ripening fruit from intense sun.',
              ),
            ],
            nutrientGuidance:
                'Maintain steady potassium levels for fruit color and firm cell walls. Avoid excess nitrogen which delays ripening.',
            weedingGuidance:
                'Spot weed rogue weeds that interfere with air movement or harbor pest vectors.',
            warnings:
                'Irregular watering right before harvest causes skin split and soft fruit.',
          ),
          GrowthStage(
            id: 'tom_stage_5',
            name: 'Harvesting',
            type: StageType.harvesting,
            startDayOffset: 70,
            endDayOffset: 110,
            title: 'Harvest Window (Breaker to Full Ripe)',
            description:
                'Harvest at pink/breaker stage for distant transport or full red for immediate local sales.',
            whyItMatters:
                'Careful harvesting reduces post-harvest bruising and extends shelf life.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Fruit Grading & Sorting',
                detail:
                    'Cull damaged or diseased fruit immediately to prevent container rot.',
              ),
              StageMonitoringItem(
                title: 'Post-Harvest Cooling',
                detail:
                    'Keep picked crates in shaded, well-ventilated areas away from direct sunlight.',
              ),
            ],
            nutrientGuidance:
                'For indeterminate crops, continue light split potassium feeding between pickings.',
            weedingGuidance: 'Keep paths clear for harvest transport.',
            warnings:
                'Never harvest when wet with morning dew to minimize post-harvest bacterial decay.',
          ),
        ],
      ),

      // ==========================================
      // 🥬 CABBAGE
      // ==========================================
      const HorticulturalCrop(
        id: 'cabbage',
        name: 'Cabbage',
        scientificName: 'Brassica oleracea var. capitata',
        category: CropCategory.vegetable,
        iconEmoji: '🥬',
        generalDescription:
            'Cool to moderate season brassica with high nitrogen demand, requiring uniform irrigation and good pest scouting.',
        standardMaturityDaysMin: 70,
        standardMaturityDaysMax: 110,
        optimalTempMin: 15.0,
        optimalTempMax: 22.0,
        frostToleranceScore: 0.7,
        waterRequirement: 'High (380–500 mm)',
        soilPhRange: '6.2 – 7.2',
        defaultDataSource: 'Horticultural Research Centre / FAO Crop Profiles',
        varieties: [
          CropVariety(
            id: 'cab_early',
            name: 'Early Maturity (e.g. Star 3301, Gloria)',
            maturityType: MaturityType.early,
            maturityDaysMin: 65,
            maturityDaysMax: 80,
            description: 'Fast compact heads, good for rapid market turnaround.',
          ),
          CropVariety(
            id: 'cab_med',
            name: 'Medium Maturity (e.g. Marcanta, Conquistador)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 80,
            maturityDaysMax: 95,
            description: 'Dense large heads with good holding ability in field.',
          ),
          CropVariety(
            id: 'cab_late',
            name: 'Late Maturity (e.g. Drummond, Grandslam)',
            maturityType: MaturityType.late,
            maturityDaysMin: 95,
            maturityDaysMax: 120,
            description: 'Heavy yielding, ideal for cool winter season production.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'cab_stage_1',
            name: 'Transplanting & Rooting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 10,
            title: 'Establishment Phase',
            description: 'Transplant healthy 4–5 week seedlings into moist, limed soil.',
            whyItMatters: 'Quick establishment prevents premature head buttoning.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cutworm & Aphid Colonization',
                detail: 'Scout seedlings daily for severed stems and green peach aphids.',
                isWarning: true,
              ),
            ],
            nutrientGuidance:
                'Apply basal NPK (Compound C / 5:15:12) according to soil test.',
            weedingGuidance: 'Ensure weed-free beds at planting.',
          ),
          GrowthStage(
            id: 'cab_stage_2',
            name: 'Foliage Development',
            type: StageType.vegetative,
            startDayOffset: 10,
            endDayOffset: 35,
            title: 'Frame & Outer Leaf Expansion',
            description: 'Formation of 18–25 large outer frame leaves before cupping.',
            whyItMatters: 'Frame size determines the eventual head diameter and weight.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Diamondback Moth (DBM) & Bagrada Bug',
                detail:
                    'Check leaf undersides for green DBM caterpillars and windowing damage.',
                isWarning: true,
              ),
            ],
            nutrientGuidance:
                'Top-dress with CAN or Ammonium Nitrate at 3 and 5 weeks after transplanting.',
            weedingGuidance:
                'Weed early before canopy closes; avoid damaging shallow brassica feeder roots.',
          ),
          GrowthStage(
            id: 'cab_stage_3',
            name: 'Head Formation (Cupping & Folding)',
            type: StageType.fruitDevelopment,
            startDayOffset: 35,
            endDayOffset: 70,
            title: 'Head Cupping & Compacting',
            description: 'Inner leaves curl inward, overlap, and compact into a dense head.',
            whyItMatters: 'Steady moisture is essential to prevent head burst.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Black Rot (Xanthomonas)',
                detail: 'Look for yellow V-shaped lesions along leaf margins.',
                isWarning: true,
              ),
              StageMonitoringItem(
                title: 'Head Splitting',
                detail: 'Avoid sudden heavy irrigation following dry spells.',
              ),
            ],
            nutrientGuidance:
                'Avoid late excessive nitrogen which causes soft puffy heads with poor storage.',
            weedingGuidance: 'Canopy should now suppress most weeds.',
          ),
          GrowthStage(
            id: 'cab_stage_4',
            name: 'Harvesting',
            type: StageType.harvesting,
            startDayOffset: 70,
            endDayOffset: 110,
            title: 'Maturity & Head Cutting',
            description: 'Harvest when heads feel solid and firm to thumb pressure.',
            whyItMatters: 'Overdue heads split and lose commercial value.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Head Firmness & Clean Outer Leaves',
                detail: 'Leave 2–3 wrapper leaves attached to protect head in transport.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🧅 ONION
      // ==========================================
      const HorticulturalCrop(
        id: 'onion',
        name: 'Onion',
        scientificName: 'Allium cepa',
        category: CropCategory.vegetable,
        iconEmoji: '🧅',
        generalDescription:
            'Daylength and temperature sensitive bulb crop. Requires friable soil, meticulous weed management, and dry curing conditions at harvest.',
        standardMaturityDaysMin: 120,
        standardMaturityDaysMax: 180,
        optimalTempMin: 13.0,
        optimalTempMax: 24.0,
        frostToleranceScore: 0.8,
        waterRequirement: 'Moderate (350–500 mm)',
        soilPhRange: '6.0 – 6.8',
        defaultDataSource: 'National Horticultural Guidelines / ARC South Africa',
        varieties: [
          CropVariety(
            id: 'on_short_day',
            name: 'Short-Day Varieties (e.g. Texas Grano, Red Creole)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 120,
            maturityDaysMax: 150,
            description:
                'Suited to African latitudes; initiates bulbing with 11–12 hours daylight.',
          ),
          CropVariety(
            id: 'on_inter',
            name: 'Intermediate-Day Varieties',
            maturityType: MaturityType.late,
            maturityDaysMin: 150,
            maturityDaysMax: 180,
            description: 'High pungency, excellent storage quality.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'on_stage_1',
            name: 'Sowing / Transplanting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Nursery or Seedling Establishment',
            description: 'Transplant pencil-thick seedlings at 8–10 cm intra-row spacing.',
            whyItMatters: 'Correct planting depth prevents double bulbs or shallow roots.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Thrips & Damping Off',
                detail: 'Inspect leaf crevices for tiny yellow/black thrips.',
                isWarning: true,
              ),
            ],
            nutrientGuidance:
                'Incorporate phosphorus and potassium basal fertilizer prior to planting.',
            weedingGuidance:
                'Onions have poor foliage cover and cannot compete with weeds. Keep bed spotless.',
          ),
          GrowthStage(
            id: 'on_stage_2',
            name: 'Vegetative Leaf Production',
            type: StageType.vegetative,
            startDayOffset: 20,
            endDayOffset: 70,
            title: 'Foliage Growth & Root System',
            description: 'Producing 10–13 healthy upright leaves before bulbing trigger.',
            whyItMatters: 'Each leaf corresponds to a bulb ring; more leaves = bigger bulb.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Purple Blotch & Downy Mildew',
                detail: 'Watch for water-soaked spots turning purple-brown with yellow halos.',
              ),
            ],
            nutrientGuidance:
                'Apply split nitrogen top-dressings. Stop nitrogen 4 weeks before bulbing.',
            weedingGuidance: 'Regular shallow hoeing or hand pulling.',
          ),
          GrowthStage(
            id: 'on_stage_3',
            name: 'Bulbing & Swelling',
            type: StageType.fruitDevelopment,
            startDayOffset: 70,
            endDayOffset: 130,
            title: 'Bulb Expansion',
            description: 'Base of plant swells into bulb. Daylight hours and warmth trigger.',
            whyItMatters: 'Consistent soil moisture prevents split/doubled bulbs.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Neck Softening & Leaf Lodging',
                detail: 'Monitor natural collapse of tops (tops fall over when mature).',
              ),
            ],
            nutrientGuidance:
                'Ensure adequate potassium and sulfur for bulb firmness and pungency.',
            weedingGuidance: 'Avoid soil throwing onto bulbs during weeding.',
            warnings: 'Stop irrigation when 50–70% of tops have fallen over.',
          ),
          GrowthStage(
            id: 'on_stage_4',
            name: 'Maturity & Curing',
            type: StageType.harvesting,
            startDayOffset: 120,
            endDayOffset: 170,
            title: 'Harvest & Field Curing',
            description: 'Lift bulbs and cure in field or ventilated shed for 10–14 days.',
            whyItMatters: 'Dry cured necks prevent bacterial rot in storage.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Neck Dryness & Outer Skin Sheen',
                detail: 'Neck should be completely papery and dry before trimming.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🥕 CARROT
      // ==========================================
      const HorticulturalCrop(
        id: 'carrot',
        name: 'Carrot',
        scientificName: 'Daucus carota subsp. sativus',
        category: CropCategory.vegetable,
        iconEmoji: '🥕',
        generalDescription:
            'Direct-seeded root crop requiring deep, loose, stone-free sandy-loam soils and steady moisture during germination.',
        standardMaturityDaysMin: 75,
        standardMaturityDaysMax: 110,
        optimalTempMin: 16.0,
        optimalTempMax: 22.0,
        frostToleranceScore: 0.6,
        waterRequirement: 'Moderate (300–450 mm)',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'ARC Horticulture Guide / Ministry of Agriculture',
        varieties: [
          CropVariety(
            id: 'car_nantes',
            name: 'Nantes / Cape Market (Early-Med)',
            maturityType: MaturityType.early,
            maturityDaysMin: 70,
            maturityDaysMax: 85,
            description: 'Cylindrical sweet roots with blunt ends, popular for fresh market.',
          ),
          CropVariety(
            id: 'car_kuroda',
            name: 'Kuroda / Chantenay (Heat Tolerant)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 85,
            maturityDaysMax: 105,
            description: 'Conical roots, performs well in heavier soils and warmer seasons.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'car_stage_1',
            name: 'Direct Sowing & Emergence',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 14,
            title: 'Germination Window',
            description: 'Sow fine seed 1cm deep in finely prepared beds. Keep surface continuously damp.',
            whyItMatters: 'Crusted dry soil prevents fragile carrot seedlings from emerging.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Soil Crusting & Moisture',
                detail: 'Irrigate lightly 1–2 times daily until green rows are visible.',
              ),
            ],
            nutrientGuidance: 'Avoid fresh animal manure which causes root forking.',
            weedingGuidance: 'Pre-emergence weed control or immediate delicate hand-weeding.',
          ),
          GrowthStage(
            id: 'car_stage_2',
            name: 'Thinning & Root Extension',
            type: StageType.vegetative,
            startDayOffset: 14,
            endDayOffset: 40,
            title: 'Thinning to 3–5 cm',
            description: 'Thin seedlings to single plants to allow uniform root expansion.',
            whyItMatters: 'Unthinned carrots remain thin and twisted.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Alternaria Leaf Blight & Root Knot Nematodes',
                detail: 'Inspect for yellow-brown spotting on feathery foliage.',
              ),
            ],
            nutrientGuidance: 'Side-dress lightly with potassium and nitrogen.',
            weedingGuidance: 'Keep rows clear of weed competition.',
          ),
          GrowthStage(
            id: 'car_stage_3',
            name: 'Root Bulking & Harvest',
            type: StageType.harvesting,
            startDayOffset: 70,
            endDayOffset: 110,
            title: 'Root Sizing & Harvest',
            description: 'Crown diameter reaches 2.5–3.5 cm with intense orange color.',
            whyItMatters: 'Lift when soil is moist to prevent root snapping.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Green Shoulders',
                detail: 'Keep root crowns covered with soil to avoid bitterness.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 SPINACH & SWISS CHARD
      // ==========================================
      const HorticulturalCrop(
        id: 'spinach',
        name: 'Spinach & Swiss Chard',
        scientificName: 'Beta vulgaris subsp. vulgaris / Spinacia oleracea',
        category: CropCategory.vegetable,
        iconEmoji: '🥬',
        generalDescription:
            'Nutritious fast-growing leafy green responsive to high organic matter and continuous nitrogen. Multi-cut harvesting.',
        standardMaturityDaysMin: 45,
        standardMaturityDaysMax: 70,
        optimalTempMin: 14.0,
        optimalTempMax: 24.0,
        frostToleranceScore: 0.7,
        waterRequirement: 'High (350–450 mm)',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'SADC Horticultural Extension Service',
        varieties: [
          CropVariety(
            id: 'spin_fordhook',
            name: 'Fordhook Giant (Swiss Chard)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 50,
            maturityDaysMax: 65,
            description: 'Broad dark green crinkled leaves with thick white ribs. Highly productive in Africa.',
          ),
          CropVariety(
            id: 'spin_true',
            name: 'English / Baby Leaf Spinach',
            maturityType: MaturityType.early,
            maturityDaysMin: 35,
            maturityDaysMax: 50,
            description: 'Cool season crop; bolts quickly in hot weather.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'spin_stage_1',
            name: 'Planting / Direct Seed',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 14,
            title: 'Sowing / Transplanting',
            description: 'Sow or transplant at 20x30cm spacing.',
            whyItMatters: 'Quick seedling establishment allows continuous harvesting later.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Snails / Cutworms',
                detail: 'Inspect for severed seedlings.',
              ),
            ],
            nutrientGuidance: 'High basal compost or organic manure + Compound D/S.',
          ),
          GrowthStage(
            id: 'spin_stage_2',
            name: 'Vegetative Canopy & First Cut',
            type: StageType.harvesting,
            startDayOffset: 40,
            endDayOffset: 120,
            title: 'Continuous Harvest & Regrowth',
            description: 'Harvest outer 3–5 leaves per plant every 7–10 days leaving the central growing heart.',
            whyItMatters: 'Regular picking stimulates new tender leaf production.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cercospora Leaf Spot',
                detail: 'Check for small circular spots with gray centres on older leaves.',
              ),
            ],
            nutrientGuidance:
                'Apply split nitrogen top dressing (CAN / Liquid manure) every 2 weeks after harvests.',
            weedingGuidance: 'Keep bed weed-free to prevent leaf contamination.',
          ),
        ],
      ),

      // ==========================================
      // 🥬 RAPE (AFRICAN KALE / BRASSICA)
      // ==========================================
      const HorticulturalCrop(
        id: 'rape',
        name: 'Rape / Covo / African Kale',
        scientificName: 'Brassica napus / Brassica oleracea var. acephala',
        category: CropCategory.vegetable,
        iconEmoji: '🌱',
        generalDescription:
            'Staple African traditional leafy brassica. High yielding, cut-and-come-again crop with great regional food security importance.',
        standardMaturityDaysMin: 40,
        standardMaturityDaysMax: 65,
        optimalTempMin: 15.0,
        optimalTempMax: 26.0,
        frostToleranceScore: 0.5,
        waterRequirement: 'Moderate to High',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'AREX Zimbabwe / Zambian Ministry of Agriculture',
        varieties: [
          CropVariety(
            id: 'rape_english',
            name: 'English Giant / Hobson',
            maturityType: MaturityType.early,
            maturityDaysMin: 40,
            maturityDaysMax: 55,
            description: 'Fast growing, wide succulent green leaves.',
          ),
          CropVariety(
            id: 'covo_perennial',
            name: 'Covo / Chomolia (Stem cuttings/seed)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 50,
            maturityDaysMax: 70,
            description: 'Extended multi-month harvesting, rugged African brassica.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'rape_stage_1',
            name: 'Transplanting & Rooting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 12,
            title: 'Seedling Establishment',
            description: 'Transplant 3–4 week seedlings at 30cm spacing.',
            whyItMatters: 'Strong root anchor supports multiple leaf harvests.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Bagrada Bug & Flea Beetle',
                detail: 'Inspect for tiny shot-holes on newly emerged leaves.',
                isWarning: true,
              ),
            ],
            nutrientGuidance: 'Basal Compound D/NPK followed by nitrogen top dressing.',
          ),
          GrowthStage(
            id: 'rape_stage_2',
            name: 'Vegetative Picking Window',
            type: StageType.harvesting,
            startDayOffset: 35,
            endDayOffset: 150,
            title: 'Harvest Cycle',
            description: 'Snap lower mature leaves by hand. Harvest weekly.',
            whyItMatters: 'Regular picking prevents early flowering (bolting).',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Aphid Clusters (Mealycabbage Aphid)',
                detail: 'Check inner leaves and leaf petioles for gray-waxy colonies.',
              ),
            ],
            nutrientGuidance: 'Apply CAN/Urea or well-fermented poultry manure tea after every 2 harvests.',
          ),
        ],
      ),

      // ==========================================
      // 🥗 LETTUCE
      // ==========================================
      const HorticulturalCrop(
        id: 'lettuce',
        name: 'Lettuce',
        scientificName: 'Lactuca sativa',
        category: CropCategory.vegetable,
        iconEmoji: '🥗',
        generalDescription:
            'Shallow-rooted cool-season salad crop. Sensitive to high heat (>28°C) which causes premature seed stalk elongation (bolting) and leaf bitterness.',
        standardMaturityDaysMin: 50,
        standardMaturityDaysMax: 75,
        optimalTempMin: 15.0,
        optimalTempMax: 22.0,
        frostToleranceScore: 0.4,
        waterRequirement: 'High, frequent light applications',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'FAO Horticultural Guidance',
        varieties: [
          CropVariety(
            id: 'let_crisp',
            name: 'Crisphead / Iceberg',
            maturityType: MaturityType.medium,
            maturityDaysMin: 65,
            maturityDaysMax: 80,
            description: 'Dense crunchy head, requires cooler temperatures.',
          ),
          CropVariety(
            id: 'let_loose',
            name: 'Looseleaf / Butterhead / Romaine',
            maturityType: MaturityType.early,
            maturityDaysMin: 45,
            maturityDaysMax: 60,
            description: 'Quick maturing, more heat tolerant, harvest individual leaves or whole head.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'let_stage_1',
            name: 'Transplanting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 10,
            title: 'Establishment',
            description: 'Transplant 3–4 week seedlings without burying the crown.',
            whyItMatters: 'Burying the crown causes bottom rot.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Slugs & Cutworms',
                detail: 'Inspect base of plants.',
              ),
            ],
            nutrientGuidance: 'Light balanced basal fertilizer with high organic matter.',
          ),
          GrowthStage(
            id: 'let_stage_2',
            name: 'Head/Leaf Development & Harvest',
            type: StageType.harvesting,
            startDayOffset: 45,
            endDayOffset: 75,
            title: 'Harvest Window',
            description: 'Cut heads early morning when leaves are crisp and cool.',
            whyItMatters: 'Warm afternoon harvest causes rapid leaf wilting.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Tipburn & Bolting',
                detail: 'Inspect inner leaf margins for brown necrosis caused by calcium/heat stress.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🥒 CUCUMBER
      // ==========================================
      const HorticulturalCrop(
        id: 'cucumber',
        name: 'Cucumber',
        scientificName: 'Cucumis sativus',
        category: CropCategory.vegetable,
        iconEmoji: '🥒',
        generalDescription:
            'Fast-growing warm season vine. High water content requiring trellising or mulch beds, frequent picking, and powdery mildew monitoring.',
        standardMaturityDaysMin: 50,
        standardMaturityDaysMax: 70,
        optimalTempMin: 20.0,
        optimalTempMax: 30.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'High (400–500 mm)',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'ARC Roodeplaat Horticultural Institute',
        varieties: [
          CropVariety(
            id: 'cuc_slicer',
            name: 'Slicing Cucumber (e.g. Ashley, Marketer)',
            maturityType: MaturityType.early,
            maturityDaysMin: 55,
            maturityDaysMax: 65,
            description: 'Long dark green fruits for fresh consumption.',
          ),
          CropVariety(
            id: 'cuc_gh',
            name: 'Greenhouse Parthenocarpic (Seedless)',
            maturityType: MaturityType.early,
            maturityDaysMin: 45,
            maturityDaysMax: 60,
            description: 'Does not require bee pollination, high yield in protected tunnels.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'cuc_stage_1',
            name: 'Sowing & Early Vine Growth',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Vine Establishment & Trellising',
            description: 'Direct seed or transplant into warm soil. Train vines onto wire or nets.',
            whyItMatters: 'Trellising keeps fruit off soil, preventing rot and crooked fruit.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cucumber Beetles & Aphids',
                detail: 'Vector for Mosaic viruses.',
                isWarning: true,
              ),
            ],
            nutrientGuidance: 'Basal Compound + balanced fertigation/side-dressing.',
          ),
          GrowthStage(
            id: 'cuc_stage_2',
            name: 'Flowering & Continuous Harvest',
            type: StageType.harvesting,
            startDayOffset: 45,
            endDayOffset: 85,
            title: 'Harvest Window (Pick every 2 days)',
            description: 'Harvest fruits when firm and uniformly green before yellowing.',
            whyItMatters: 'Leaving oversized fruit halts new flower development.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Powdery & Downy Mildew',
                detail: 'White powdery patches on upper leaf surfaces.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🎃 PUMPKIN & BUTTERNUT
      // ==========================================
      const HorticulturalCrop(
        id: 'butternut',
        name: 'Butternut Squash',
        scientificName: 'Cucurbita moschata',
        category: CropCategory.vegetable,
        iconEmoji: '🥜',
        generalDescription:
            'Warm-season cucurbit vine with good drought tolerance, high market demand, and excellent post-harvest storage qualities.',
        standardMaturityDaysMin: 85,
        standardMaturityDaysMax: 115,
        optimalTempMin: 20.0,
        optimalTempMax: 30.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Moderate (350–450 mm)',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'Agricultural Research Council (ARC)',
        varieties: [
          CropVariety(
            id: 'but_waltham',
            name: 'Waltham / Atlas F1',
            maturityType: MaturityType.medium,
            maturityDaysMin: 85,
            maturityDaysMax: 105,
            description: 'Standard bell-shaped fruit with orange flesh and small seed cavity.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'but_stage_1',
            name: 'Planting & Vine Run',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 30,
            title: 'Planting & Early Vine Spread',
            description: 'Direct seed at 1.5m x 0.5m spacing in well-drained fertile stations.',
            whyItMatters: 'Rapid early ground cover suppresses weeds.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cutworms & Pumpkin Fly (Dacus spp.)',
                detail: 'Check young stems and early fruit buds for sting marks.',
                isWarning: true,
              ),
            ],
            nutrientGuidance: 'Compound S/C basal application with organic manure.',
          ),
          GrowthStage(
            id: 'but_stage_2',
            name: 'Fruit Bulking & Curing',
            type: StageType.harvesting,
            startDayOffset: 80,
            endDayOffset: 120,
            title: 'Maturity & Harvest',
            description: 'Harvest when skin turns tan-buff and resists fingernail puncture.',
            whyItMatters: 'Cut with 2–5cm stem attached for long shelf storage.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Skin Hardness & Stem Corking',
                detail: 'Stem should show dry longitudinal corky streaks.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🫑 PEPPER (SWEET & HOT)
      // ==========================================
      const HorticulturalCrop(
        id: 'pepper',
        name: 'Sweet Pepper & Chilli',
        scientificName: 'Capsicum annuum / Capsicum chinense',
        category: CropCategory.vegetable,
        iconEmoji: '🫑',
        generalDescription:
            'Warm-season solanaceous crop requiring long warm frost-free season, consistent moisture, and protection from sunscald.',
        standardMaturityDaysMin: 75,
        standardMaturityDaysMax: 120,
        optimalTempMin: 20.0,
        optimalTempMax: 29.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'High (450–600 mm)',
        soilPhRange: '6.0 – 6.8',
        defaultDataSource: 'National Horticultural Guidelines',
        varieties: [
          CropVariety(
            id: 'pep_sweet_green',
            name: 'Sweet Bell Pepper (Green to Red/Yellow)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 75,
            maturityDaysMax: 100,
            description: 'California Wonder, Commander F1, Hercules.',
          ),
          CropVariety(
            id: 'pep_hot_chilli',
            name: 'Hot Chilli (Bird Eye / Habanero / Serrano)',
            maturityType: MaturityType.late,
            maturityDaysMin: 90,
            maturityDaysMax: 120,
            description: 'Pungent fruits, high heat tolerance, long harvest season.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'pep_stage_1',
            name: 'Transplanting & Canopy Build',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 25,
            title: 'Establishment & Branching',
            description: 'Transplant 6-week seedlings. Crown flower removal encourages vegetative branching.',
            whyItMatters: 'Strong bush prevents fruit sunburn.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Thrips & Broad Mites',
                detail: 'Check for distorted upward/downward leaf curling.',
                isWarning: true,
              ),
            ],
            nutrientGuidance: 'Basal NPK compound followed by potassium nitrate splits.',
          ),
          GrowthStage(
            id: 'pep_stage_2',
            name: 'Harvesting (Green or Colored)',
            type: StageType.harvesting,
            startDayOffset: 75,
            endDayOffset: 140,
            title: 'Harvest Window',
            description: 'Cut with sharp secateurs leaving pedicel attached.',
            whyItMatters: 'Pulling fruits by hand tears branches.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Bacterial Spot & Anthracnose',
                detail: 'Inspect fruit walls for water-soaked sunken lesions.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🍆 EGGPLANT
      // ==========================================
      const HorticulturalCrop(
        id: 'eggplant',
        name: 'Eggplant (Brinjal)',
        scientificName: 'Solanum melongena',
        category: CropCategory.vegetable,
        iconEmoji: '🍆',
        generalDescription:
            'Warm to hot season solanaceous vegetable with high heat tolerance and sturdy bush architecture.',
        standardMaturityDaysMin: 70,
        standardMaturityDaysMax: 95,
        optimalTempMin: 22.0,
        optimalTempMax: 32.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Moderate to High',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'FAO Crop Guide / Subtropical Research Centre',
        varieties: [
          CropVariety(
            id: 'egg_black_beauty',
            name: 'Black Beauty / Florida Market',
            maturityType: MaturityType.medium,
            maturityDaysMin: 75,
            maturityDaysMax: 90,
            description: 'Classic glossy deep purple-black oval fruit.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'egg_stage_1',
            name: 'Transplanting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 15,
            title: 'Establishment',
            description: 'Transplant at 50x75cm spacing in fertile beds.',
            whyItMatters: 'Deep root establishment for heat tolerance.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Flea Beetles & Spider Mites',
                detail: 'Look for pinprick leaf damage.',
              ),
            ],
          ),
          GrowthStage(
            id: 'egg_stage_2',
            name: 'Fruit Harvest',
            type: StageType.harvesting,
            startDayOffset: 70,
            endDayOffset: 120,
            title: 'Harvest Window',
            description: 'Pick while skin remains high-gloss before seed browning occurs.',
            whyItMatters: 'Dull fruit indicates overmaturity and spongy bitter flesh.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Skin Glossiness',
                detail: 'Thumb impression should rebound quickly.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 OKRA
      // ==========================================
      const HorticulturalCrop(
        id: 'okra',
        name: 'Okra (Lady Finger)',
        scientificName: 'Abelmoschus esculentus',
        category: CropCategory.vegetable,
        iconEmoji: '🌱',
        generalDescription:
            'Highly drought- and heat-tolerant African native malvaceous vegetable. Direct-seeded with high culinary and economic value.',
        standardMaturityDaysMin: 50,
        standardMaturityDaysMax: 70,
        optimalTempMin: 24.0,
        optimalTempMax: 35.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Low to Moderate',
        soilPhRange: '6.0 – 7.2',
        defaultDataSource: 'West & East African Regional Vegetable Guides',
        varieties: [
          CropVariety(
            id: 'ok_clemson',
            name: 'Clemson Spineless / Pusa Sawani',
            maturityType: MaturityType.early,
            maturityDaysMin: 50,
            maturityDaysMax: 65,
            description: 'Grooved spineless tender green pods.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'ok_stage_1',
            name: 'Direct Sowing',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 10,
            title: 'Germination & Sowing',
            description: 'Soak hard seed in warm water overnight; sow 2cm deep in warm soil.',
            whyItMatters: 'Overcoming seed hardness ensures uniform emergence.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Soil Temperature (>20°C)',
                detail: 'Cold soils cause seed rot.',
              ),
            ],
          ),
          GrowthStage(
            id: 'ok_stage_2',
            name: 'Continuous Pod Harvest',
            type: StageType.harvesting,
            startDayOffset: 50,
            endDayOffset: 100,
            title: 'Frequent Pod Harvest (Every 2–3 Days)',
            description: 'Snap or cut tender 7–10cm pods.',
            whyItMatters: 'Pods become fibrous and inedible if left on the stalk.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Pod Tenderness',
                detail: 'Pod tips should snap crisply when bent.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🥦 BROCCOLI & CAULIFLOWER
      // ==========================================
      const HorticulturalCrop(
        id: 'broccoli',
        name: 'Broccoli & Cauliflower',
        scientificName: 'Brassica oleracea var. italica / botrytis',
        category: CropCategory.vegetable,
        iconEmoji: '🥦',
        generalDescription:
            'High-value cool-season brassicas requiring precise temperature ranges and fertile, boron-adequate soils.',
        standardMaturityDaysMin: 65,
        standardMaturityDaysMax: 90,
        optimalTempMin: 14.0,
        optimalTempMax: 20.0,
        frostToleranceScore: 0.6,
        waterRequirement: 'High',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'ARC Horticulture Guide',
        varieties: [
          CropVariety(
            id: 'broc_standard',
            name: 'Standard Head (e.g. Marathon, Green Sprouting)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 65,
            maturityDaysMax: 85,
            description: 'Tight blue-green bead head with secondary side-shoot production.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'broc_stage_1',
            name: 'Transplanting & Vegetative',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 30,
            title: 'Establishment Phase',
            description: 'Transplant in cool conditions.',
            whyItMatters: 'Stress during early stages causes premature buttoning.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'DBM & Boron Deficiency (Hollow stem)',
                detail: 'Ensure micronutrient balance in soil.',
              ),
            ],
          ),
          GrowthStage(
            id: 'broc_stage_2',
            name: 'Head Harvest',
            type: StageType.harvesting,
            startDayOffset: 65,
            endDayOffset: 95,
            title: 'Head Cutting',
            description: 'Cut compact heads before florets separate or turn yellow.',
            whyItMatters: 'Flowering heads lose commercial value immediately.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Bead Tightness',
                detail: 'Must be dense and firm.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🫘 GREEN BEANS & PEAS
      // ==========================================
      const HorticulturalCrop(
        id: 'green_beans',
        name: 'Green Beans (Snap / Bush)',
        scientificName: 'Phaseolus vulgaris',
        category: CropCategory.vegetable,
        iconEmoji: '🫘',
        generalDescription:
            'Quick-turnaround nitrogen-fixing legume. Sensitive to frost and extreme heat during flowering.',
        standardMaturityDaysMin: 50,
        standardMaturityDaysMax: 70,
        optimalTempMin: 18.0,
        optimalTempMax: 26.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Moderate (300–400 mm)',
        soilPhRange: '6.0 – 6.8',
        defaultDataSource: 'FAO Crop Manual',
        varieties: [
          CropVariety(
            id: 'bean_bush',
            name: 'Bush Type (e.g. Contender, Star 2000)',
            maturityType: MaturityType.early,
            maturityDaysMin: 50,
            maturityDaysMax: 65,
            description: 'Self-supporting, concentrated pod flush.',
          ),
          CropVariety(
            id: 'bean_pole',
            name: 'Runner / Pole Beans',
            maturityType: MaturityType.medium,
            maturityDaysMin: 65,
            maturityDaysMax: 85,
            description: 'Climbing vines requiring trellising, long harvest window.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'bean_stage_1',
            name: 'Direct Sowing & Nodulation',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Direct Sowing',
            description: 'Sow 3–4cm deep into warm, moist seedbed.',
            whyItMatters: 'Beans do not transplant well due to sensitive taproots.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Bean Stem Maggot (Ophiomyia)',
                detail: 'Check seedling collar for swelling and wilting.',
                isWarning: true,
              ),
            ],
          ),
          GrowthStage(
            id: 'bean_stage_2',
            name: 'Pod Picking',
            type: StageType.harvesting,
            startDayOffset: 50,
            endDayOffset: 75,
            title: 'Harvest Window',
            description: 'Pick tender straight pods before seeds bulge visibly.',
            whyItMatters: 'Frequent picking encourages continued flowering.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Rust & Anthracnose',
                detail: 'Inspect pods for blemishes.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🟣 BEETROOT & RADISH
      // ==========================================
      const HorticulturalCrop(
        id: 'beetroot',
        name: 'Beetroot',
        scientificName: 'Beta vulgaris subsp. vulgaris',
        category: CropCategory.vegetable,
        iconEmoji: '🟣',
        generalDescription:
            'Hardy root crop rich in nutrients. Tolerates cool weather and moderate frost, requires loose soil for round bulb development.',
        standardMaturityDaysMin: 60,
        standardMaturityDaysMax: 85,
        optimalTempMin: 15.0,
        optimalTempMax: 22.0,
        frostToleranceScore: 0.7,
        waterRequirement: 'Moderate',
        soilPhRange: '6.2 – 7.2',
        defaultDataSource: 'ARC Horticulture Guide',
        varieties: [
          CropVariety(
            id: 'beet_detroit',
            name: 'Detroit Dark Red / Early Wonder',
            maturityType: MaturityType.early,
            maturityDaysMin: 55,
            maturityDaysMax: 70,
            description: 'Globular smooth blood-red roots, excellent uniform size.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'beet_stage_1',
            name: 'Sowing & Thinning',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Sowing & Cluster Thinning',
            description: 'Thin multi-germ seed clusters to single plants at 8cm spacing.',
            whyItMatters: 'Beet seeds are clusters; failure to thin causes crowded deformed roots.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Seedling Crowding',
                detail: 'Thin when plants are 5cm tall.',
              ),
            ],
          ),
          GrowthStage(
            id: 'beet_stage_2',
            name: 'Root Lifting',
            type: StageType.harvesting,
            startDayOffset: 60,
            endDayOffset: 85,
            title: 'Harvesting',
            description: 'Pull when roots reach 5–8cm diameter.',
            whyItMatters: 'Overgrown beets become woody and develop white concentric rings.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Root Size & Tenderness',
                detail: 'Harvest promptly once target diameter is reached.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌽 SWEET CORN
      // ==========================================
      const HorticulturalCrop(
        id: 'sweet_corn',
        name: 'Sweet Corn',
        scientificName: 'Zea mays var. saccharata',
        category: CropCategory.vegetable,
        iconEmoji: '🌽',
        generalDescription:
            'High-sugar maize variety harvested at milk stage for fresh vegetable consumption. Requires block planting for wind pollination.',
        standardMaturityDaysMin: 70,
        standardMaturityDaysMax: 90,
        optimalTempMin: 18.0,
        optimalTempMax: 30.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'High (450–550 mm)',
        soilPhRange: '5.8 – 6.8',
        defaultDataSource: 'National Agronomic Guidelines',
        varieties: [
          CropVariety(
            id: 'sc_sh2',
            name: 'Super Sweet (sh2 / su)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 72,
            maturityDaysMax: 85,
            description: 'Extra sweet, holds sugar level longer post-harvest.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'sc_stage_1',
            name: 'Direct Planting (In Blocks)',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 15,
            title: 'Block Sowing',
            description: 'Plant in square blocks rather than long single rows for uniform wind pollination.',
            whyItMatters: 'Poor pollination results in missing kernels on cobs.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Fall Armyworm (FAW)',
                detail: 'Inspect leaf whorls for frass and larval feeding damage.',
                isWarning: true,
              ),
            ],
          ),
          GrowthStage(
            id: 'sc_stage_2',
            name: 'Tasseling & Silking',
            type: StageType.flowering,
            startDayOffset: 45,
            endDayOffset: 65,
            title: 'Silking & Moisture Critical Window',
            description: 'Pollen sheds from tassels onto silks. Water stress must be strictly avoided.',
            whyItMatters: 'Water deficit at silking causes severe kernel abortion.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Earworm & Silk Drying',
                detail: 'Inspect silks.',
              ),
            ],
          ),
          GrowthStage(
            id: 'sc_stage_3',
            name: 'Milk Stage Harvest',
            type: StageType.harvesting,
            startDayOffset: 70,
            endDayOffset: 90,
            title: 'Harvest Window',
            description: 'Harvest when silks turn brown and piercing a kernel releases milky sap.',
            whyItMatters: 'Watery sap = premature; doughy sap = overmature.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Kernel Sap Clarity',
                detail: 'Must be milky white.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🥔 POTATO (ROOT & TUBER)
      // ==========================================
      const HorticulturalCrop(
        id: 'potato',
        name: 'Potato (Irish Potato)',
        scientificName: 'Solanum tuberosum',
        category: CropCategory.rootAndTuber,
        iconEmoji: '🥔',
        generalDescription:
            'Major commercial tuber crop requiring cool nights, certified seed tubers, ridging/earthing up, and intensive blight management.',
        standardMaturityDaysMin: 85,
        standardMaturityDaysMax: 120,
        optimalTempMin: 15.0,
        optimalTempMax: 22.0,
        frostToleranceScore: 0.1,
        waterRequirement: 'High (450–600 mm)',
        soilPhRange: '5.2 – 6.2',
        defaultDataSource: 'Potato Seed Association / ARC South Africa / AREX',
        varieties: [
          CropVariety(
            id: 'pot_bp1',
            name: 'BP1 / Mondial / Sifra',
            maturityType: MaturityType.medium,
            maturityDaysMin: 90,
            maturityDaysMax: 110,
            description: 'Standard Southern & East African commercial table varieties with high yields.',
          ),
          CropVariety(
            id: 'pot_early',
            name: 'Early Maturity (e.g. Valor, Buffelspoort)',
            maturityType: MaturityType.early,
            maturityDaysMin: 75,
            maturityDaysMax: 90,
            description: 'Fast bulking for early market entry.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'pot_stage_1',
            name: 'Tuber Planting & Sprouting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 25,
            title: 'Certified Seed Planting',
            description: 'Plant well-sprouted seed tubers 10–15cm deep in furrows or ridges.',
            whyItMatters: 'Certified clean seed prevents devastating bacterial wilt and viruses.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Blackleg & Rhizoctonia',
                detail: 'Inspect emerging sprouts for blackened stem bases.',
                isWarning: true,
              ),
            ],
            nutrientGuidance: 'High potassium and phosphorus basal (e.g. Compound S or 7:14:7).',
          ),
          GrowthStage(
            id: 'pot_stage_2',
            name: 'Vegetative & Earthing Up',
            type: StageType.vegetative,
            startDayOffset: 25,
            endDayOffset: 50,
            title: 'Earthing Up / Ridging',
            description: 'Mound soil around stem bases when plants reach 15–20cm height.',
            whyItMatters: 'Prevents tubers from greening (solanine toxicity) and potato tuber moth damage.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Late Blight (Phytophthora infestans)',
                detail: 'Inspect leaves for dark water-soaked spots with white fungal margin during humid weather.',
                isWarning: true,
              ),
            ],
            weedingGuidance: 'Earthing up smothers intra-row weeds.',
          ),
          GrowthStage(
            id: 'pot_stage_3',
            name: 'Tuber Bulking',
            type: StageType.fruitDevelopment,
            startDayOffset: 50,
            endDayOffset: 85,
            title: 'Tuber Initiation & Enlargement',
            description: 'Stolons swell into tubers. High steady moisture requirement.',
            whyItMatters: 'Moisture fluctuations cause knobby/cracked tubers and hollow heart.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Potato Tuber Moth',
                detail: 'Ensure ridges have no cracks where moths can lay eggs on tubers.',
              ),
            ],
          ),
          GrowthStage(
            id: 'pot_stage_4',
            name: 'Haulm Destruction & Skin Setting',
            type: StageType.harvesting,
            startDayOffset: 85,
            endDayOffset: 120,
            title: 'Maturity & Harvest',
            description: 'Allow haulms to senesce (or cut tops) 10–14 days before lifting to harden skin.',
            whyItMatters: 'Skin setting prevents scuffing and rots during transport.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Skin Slip Test',
                detail: 'Rub thumb firmly against skin; it should not peel.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🍠 SWEET POTATO (ROOT & TUBER)
      // ==========================================
      const HorticulturalCrop(
        id: 'sweet_potato',
        name: 'Sweet Potato',
        scientificName: 'Ipomoea batatas',
        category: CropCategory.rootAndTuber,
        iconEmoji: '🍠',
        generalDescription:
            'Resilient warm-season tuberous crop propagated by vine cuttings. High drought resilience and food security value.',
        standardMaturityDaysMin: 90,
        standardMaturityDaysMax: 140,
        optimalTempMin: 22.0,
        optimalTempMax: 30.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Moderate',
        soilPhRange: '5.5 – 6.5',
        defaultDataSource: 'International Potato Center (CIP) / Regional Extension',
        varieties: [
          CropVariety(
            id: 'sp_ofsp',
            name: 'Orange-Fleshed (OFSP - e.g. Bophelo, Alisha)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 90,
            maturityDaysMax: 120,
            description: 'High provitamin A beta-carotene content, high consumer demand.',
          ),
          CropVariety(
            id: 'sp_white',
            name: 'White/Cream Fleshed Traditional',
            maturityType: MaturityType.late,
            maturityDaysMin: 120,
            maturityDaysMax: 150,
            description: 'High dry matter content, excellent storage in soil.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'sp_stage_1',
            name: 'Vine Cutting Planting (Ridges)',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 25,
            title: 'Vine Planting on Mounds/Ridges',
            description: 'Plant 25–30cm healthy apical vine cuttings with at least 3 nodes buried.',
            whyItMatters: 'Mounds provide loose soil for tuber expansion and easy harvest.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Sweet Potato Weevil (Cylas spp.)',
                detail: 'Use clean pest-free planting vine material.',
                isWarning: true,
              ),
            ],
          ),
          GrowthStage(
            id: 'sp_stage_2',
            name: 'Tuber Harvest',
            type: StageType.harvesting,
            startDayOffset: 90,
            endDayOffset: 150,
            title: 'Harvest Window',
            description: 'Harvest piecemeal or clear-cut when leaves begin yellowing.',
            whyItMatters: 'Avoid lifting with sharp hoes to prevent gouging tubers.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Weevil Infestation in Soil Cracks',
                detail: 'Re-ridge to close soil fissures.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 CASSAVA (ROOT & TUBER)
      // ==========================================
      const HorticulturalCrop(
        id: 'cassava',
        name: 'Cassava',
        scientificName: 'Manihot esculenta',
        category: CropCategory.rootAndTuber,
        iconEmoji: '🪵',
        generalDescription:
            'Extremely hardy, drought-tolerant tropical root crop capable of producing in marginal soils. Essential food security buffer.',
        standardMaturityDaysMin: 240,
        standardMaturityDaysMax: 365,
        optimalTempMin: 24.0,
        optimalTempMax: 32.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Low to Moderate',
        soilPhRange: '5.0 – 6.5',
        defaultDataSource: 'IITA / National Agricultural Research Systems',
        varieties: [
          CropVariety(
            id: 'cas_improved',
            name: 'Improved Disease Resistant (CMD/CBSD Resistant)',
            maturityType: MaturityType.medium,
            maturityDaysMin: 240,
            maturityDaysMax: 300,
            description: 'Resistant to Cassava Mosaic Disease and Brown Streak Disease.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'cas_stage_1',
            name: 'Stem Cutting Planting',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 30,
            title: 'Stem Stake Planting',
            description: 'Plant 20–25cm mature stem cuttings slanted or horizontal 5–10cm deep.',
            whyItMatters: 'Viable disease-free stakes ensure rapid sprouting.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cassava Mosaic Symptoms',
                detail: 'Inspect first emerging leaves for yellow/green mosaic distortion.',
                isWarning: true,
              ),
            ],
          ),
          GrowthStage(
            id: 'cas_stage_2',
            name: 'Root Harvest Window',
            type: StageType.harvesting,
            startDayOffset: 240,
            endDayOffset: 400,
            title: 'Flexible Harvest Window',
            description: 'Roots can remain stored underground until needed for market or consumption.',
            whyItMatters: 'Process or market within 48 hours of digging to prevent post-harvest physiological deterioration.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Root Bulking & Starch Quality',
                detail: 'Sample test root size before bulk lifting.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 CORIANDER / CILANTRO (HERB)
      // ==========================================
      const HorticulturalCrop(
        id: 'coriander',
        name: 'Coriander (Dhania)',
        scientificName: 'Coriandrum sativum',
        category: CropCategory.herb,
        iconEmoji: '🌿',
        generalDescription:
            'Quick-growing annual herb with high fresh market demand. Prone to premature flowering in hot dry weather.',
        standardMaturityDaysMin: 35,
        standardMaturityDaysMax: 50,
        optimalTempMin: 15.0,
        optimalTempMax: 24.0,
        frostToleranceScore: 0.5,
        waterRequirement: 'Moderate, regular',
        soilPhRange: '6.2 – 7.0',
        defaultDataSource: 'Horticultural Extension Service',
        varieties: [
          CropVariety(
            id: 'cor_slow_bolt',
            name: 'Slow Bolt / Calypso',
            maturityType: MaturityType.early,
            maturityDaysMin: 35,
            maturityDaysMax: 45,
            description: 'Resists premature seed stalk formation during warm spells.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'cor_stage_1',
            name: 'Direct Sowing',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 12,
            title: 'Direct Sowing & Emergence',
            description: 'Crush dual seeds gently; sow directly in shallow drills 1cm deep.',
            whyItMatters: 'Taproot is sensitive to transplanting.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Soil Moisture',
                detail: 'Keep topsoil moist until emergence.',
              ),
            ],
          ),
          GrowthStage(
            id: 'cor_stage_2',
            name: 'Fresh Leaf Harvest',
            type: StageType.harvesting,
            startDayOffset: 35,
            endDayOffset: 55,
            title: 'Harvest Window',
            description: 'Harvest whole plant by pulling or cut outer leaves when 15cm tall.',
            whyItMatters: 'Cut before flower stems emerge.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Bolting Trigger',
                detail: 'Harvest immediately if central stem begins elongating.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 PARSLEY (HERB)
      // ==========================================
      const HorticulturalCrop(
        id: 'parsley',
        name: 'Parsley',
        scientificName: 'Petroselinum crispum',
        category: CropCategory.herb,
        iconEmoji: '🌿',
        generalDescription:
            'Biennial culinary herb grown as annual. Slow initial germination followed by vigorous, multi-cut production over several months.',
        standardMaturityDaysMin: 65,
        standardMaturityDaysMax: 85,
        optimalTempMin: 15.0,
        optimalTempMax: 24.0,
        frostToleranceScore: 0.7,
        waterRequirement: 'Moderate',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'National Horticultural Guidelines',
        varieties: [
          CropVariety(
            id: 'par_curly',
            name: 'Curly Leaf / Italian Flat Leaf',
            maturityType: MaturityType.medium,
            maturityDaysMin: 65,
            maturityDaysMax: 80,
            description: 'Flat leaf offers stronger aromatic flavor; curly leaf preferred for garnishing.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'par_stage_1',
            name: 'Sowing / Seedling',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 25,
            title: 'Slow Emergence & Establishment',
            description: 'Seed takes 14–21 days to germinate. Soak seed in warm water before sowing.',
            whyItMatters: 'Patience required; prevent bed from drying out.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Weed Competition',
                detail: 'Hand-weed gently around slow-emerging seedlings.',
              ),
            ],
          ),
          GrowthStage(
            id: 'par_stage_2',
            name: 'Multi-Cut Harvesting',
            type: StageType.harvesting,
            startDayOffset: 65,
            endDayOffset: 180,
            title: 'Continuous Harvest Window',
            description: 'Cut outer stalks near soil line; leave central heart intact.',
            whyItMatters: 'Provides regular weekly cuts for months.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Septoria Leaf Spot',
                detail: 'Inspect for tiny brown spots with yellow halos.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 BASIL (HERB)
      // ==========================================
      const HorticulturalCrop(
        id: 'basil',
        name: 'Sweet Basil',
        scientificName: 'Ocimum basilicum',
        category: CropCategory.herb,
        iconEmoji: '🌿',
        generalDescription:
            'Warm-loving aromatic herb highly sensitive to cold and frost. Fast vegetative growth with frequent pinching of flower buds.',
        standardMaturityDaysMin: 40,
        standardMaturityDaysMax: 60,
        optimalTempMin: 20.0,
        optimalTempMax: 30.0,
        frostToleranceScore: 0.0,
        waterRequirement: 'Moderate (well-drained)',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'FAO Horticultural Crop Guide',
        varieties: [
          CropVariety(
            id: 'bas_genovese',
            name: 'Genovese / Sweet Basil',
            maturityType: MaturityType.early,
            maturityDaysMin: 40,
            maturityDaysMax: 55,
            description: 'Large tender aromatic green leaves.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'bas_stage_1',
            name: 'Planting & Pinching',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Establishment & Tip Pinching',
            description: 'Pinch top shoots when plants reach 15cm to stimulate bushy branching.',
            whyItMatters: 'Prevents single-stem leggy plants and multiplies harvestable tips.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Cold Shock & Fusarium Wilt',
                detail: 'Ensure temperature stays above 15°C.',
              ),
            ],
          ),
          GrowthStage(
            id: 'bas_stage_2',
            name: 'Harvesting & Flower Removal',
            type: StageType.harvesting,
            startDayOffset: 40,
            endDayOffset: 90,
            title: 'Harvest Window',
            description: 'Cut upper leaf clusters regularly; pinch off any flower spikes immediately.',
            whyItMatters: 'Flowering makes leaves tough and bitter.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Flower Spike Emergence',
                detail: 'Remove flower buds as soon as they form.',
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // 🌿 MINT (HERB)
      // ==========================================
      const HorticulturalCrop(
        id: 'mint',
        name: 'Mint (Spearmint / Peppermint)',
        scientificName: 'Mentha spicata / Mentha piperita',
        category: CropCategory.herb,
        iconEmoji: '🌿',
        generalDescription:
            'Vigorous perennial herb spreading rapidly via underground rhizomes. Prefers moist, rich soil and semi-shade in hot regions.',
        standardMaturityDaysMin: 45,
        standardMaturityDaysMax: 65,
        optimalTempMin: 16.0,
        optimalTempMax: 26.0,
        frostToleranceScore: 0.8,
        waterRequirement: 'High',
        soilPhRange: '6.0 – 7.0',
        defaultDataSource: 'Horticultural Extension Service',
        varieties: [
          CropVariety(
            id: 'mint_spear',
            name: 'Spearmint / Peppermint (Stolon cuttings)',
            maturityType: MaturityType.early,
            maturityDaysMin: 45,
            maturityDaysMax: 60,
            description: 'Hardy runner herb; best propagated from root runners or stem cuttings.',
          ),
        ],
        standardStages: [
          GrowthStage(
            id: 'mint_stage_1',
            name: 'Planting Runners/Cuttings',
            type: StageType.planting,
            startDayOffset: 0,
            endDayOffset: 20,
            title: 'Runner Establishment',
            description: 'Plant runners 5cm deep in contained or bordered beds.',
            whyItMatters: 'Mint can be invasive if not given boundaries.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Soil Moisture',
                detail: 'Keep moist; mint has high transpiration rate.',
              ),
            ],
          ),
          GrowthStage(
            id: 'mint_stage_2',
            name: 'Continuous Shoot Cutting',
            type: StageType.harvesting,
            startDayOffset: 45,
            endDayOffset: 200,
            title: 'Harvest Window',
            description: 'Cut top 10–15cm of stems for bunching.',
            whyItMatters: 'Stimulates lush new basal shoot emergence.',
            whatToMonitor: [
              StageMonitoringItem(
                title: 'Mint Rust (Puccinia menthae)',
                detail: 'Look for orange pustules on lower leaves.',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static HorticulturalCrop? getCropById(String id) {
    try {
      return getAllCrops().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
