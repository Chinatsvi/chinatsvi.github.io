// Crop Diagnosis Decision Tool - JavaScript Logic
// Diagnoses crop pests, diseases, nutrient deficiencies, and environmental issues
// Built for farmers with clear language, term explanations, and actionable treatment plans

const diagnosisState = {
  currentStep: 0,
  totalSteps: 7,
  
  crop: {
    type: '',
    name: '',
    stage: '',
    scale: 'commercial'
  },
  
  affectedPart: '',
  
  symptoms: [],
  
  distribution: '',
  
  onsetSpeed: '',
  
  fieldConditions: {
    recentWeather: '',
    wateringHistory: '',
    recentSprayOrFertilizer: '',
    drainageStatus: ''
  },
  
  observations: {
    insectsVisible: '',
    insectType: '',
    smellOrOoze: '',
    underleafCheck: '',
    rootCondition: ''
  },
  
  results: {
    primaryDiagnosis: null,
    secondaryPossibilities: [],
    urgency: 'medium',
    confidence: 'medium',
    immediateAction: '',
    treatmentPlan: [],
    culturalControl: [],
    chemicalOptions: [],
    prevention: [],
    termsExplained: []
  }
};

// Comprehensive Crop Health Problem Database
const cropProblemsDatabase = [
  // MAIZE PROBLEMS
  {
    id: 'maize_fall_armyworm',
    crop: 'maize',
    name: 'Fall Armyworm (Invasive Caterpillar Pest)',
    category: 'pest',
    affectedParts: ['leaves', 'stem', 'entire_plant'],
    symptomMatches: ['chewed_holes', 'ragged_leaves', 'sawdust_droppings', 'caterpillar_in_funnel', 'window_pane_feeding'],
    distribution: ['scattered', 'widespread'],
    onsetSpeed: 'rapid',
    description: 'Fall Armyworm is a destructive caterpillar that feeds inside the maize funnel (whorl) and leaves ragged holes with wet, sawdust-like droppings (frass).',
    urgency: 'high',
    immediateAction: 'Inspect crop early morning or late afternoon. Check deep inside the maize funnel (whorl). If caterpillars are young (small), spray immediately into the funnel before they bore deep inside.',
    treatmentPlan: [
      'Target spraying directly into the plant funnel/whorl where the caterpillar hides.',
      'Rotate chemical active ingredients to avoid the caterpillars developing resistance (becoming immune to sprays).'
    ],
    culturalControl: [
      'Handpick and crush caterpillars and egg masses (fuzzy grey patches on leaves) in small plots.',
      'Place a pinch of dry fine sand or clean wood ash directly into the plant funnel—this irritates and kills young caterpillars.',
      'Intercrop maize with companion plants like desmodium or beans (Push-Pull technique) to repel moths.'
    ],
    chemicalOptions: [
      {
        name: 'Emamectin Benzoate 5% WDG',
        type: 'Insecticide (caterpillar specialist)',
        rate: '4g per 15L backpack sprayer',
        phi: '7 days',
        safetyTip: 'Spray late in the afternoon when caterpillars come up to feed. Always wear gloves and mask.'
      },
      {
        name: 'Chlorantraniliprole 20% SC',
        type: 'Systemic Insecticide',
        rate: '3-4ml per 15L water',
        phi: '14 days',
        safetyTip: 'Very effective and long-lasting; safe for beneficial insects when used correctly.'
      }
    ],
    prevention: [
      'Plant early at the very start of the rains to escape peak moth populations.',
      'Destroy crop residues after harvest to kill pupae hiding in the soil.'
    ],
    terms: [
      { term: 'Whorl / Funnel', explanation: 'The circle of young leaves growing in the centre top of the maize stalk.' },
      { term: 'Frass', explanation: 'The waste droppings left behind by insects, which looks like wet sawdust in maize.' },
      { term: 'Pre-Harvest Interval (PHI)', explanation: 'The exact number of days you MUST wait between spraying a chemical and safely harvesting or eating the crop.' }
    ]
  },
  {
    id: 'maize_maize_streak_virus',
    crop: 'maize',
    name: 'Maize Streak Virus (MSV)',
    category: 'disease',
    affectedParts: ['leaves', 'entire_plant'],
    symptomMatches: ['yellow_streaks_parallel', 'stunted_growth', 'small_deformed_cobs', 'pale_stripes'],
    distribution: ['scattered', 'along_edges'],
    onsetSpeed: 'gradual',
    description: 'Maize Streak Virus is spread by tiny jumping insects called leafhoppers. It creates narrow, pale yellow streaks along the leaf veins and severely stunts young maize plants.',
    urgency: 'medium',
    immediateAction: 'Uproot and burn heavily stunted, infected seedlings to prevent leafhoppers from carrying the virus to healthy plants. MSV cannot be cured once inside the plant.',
    treatmentPlan: [
      'Control leafhopper vectors (the jumping insects carrying the disease) in surrounding grasses and fields.',
      'Ensure proper top-dressing fertilizer to support uninfected plants in growing vigorously.'
    ],
    culturalControl: [
      'Always plant certified MSV-resistant or tolerant hybrid seed (e.g. SC513, PAN53, or similar certified local hybrids).',
      'Clear grassy weeds and volunteer maize around field borders where leafhoppers survive.'
    ],
    chemicalOptions: [
      {
        name: 'Seed dressing (Imidacloprid / Thiamethoxam)',
        type: 'Preventative Seed Treatment',
        rate: 'Applied to seed before planting',
        phi: 'N/A (early seedling stage only)',
        safetyTip: 'Treated seed protects young maize shoots from leafhopper bites during the first 3-4 critical weeks.'
      }
    ],
    prevention: [
      'Avoid planting new maize directly downwind of old, dried-up maize fields where leafhoppers are leaving.',
      'Use certified disease-resistant seed varieties every season.'
    ],
    terms: [
      { term: 'Vector', explanation: 'An insect or pest that carries a disease organism from a sick plant to a healthy plant.' },
      { term: 'Resistant Variety', explanation: 'A crop type bred specifically to fight off and survive a particular disease without losing yield.' }
    ]
  },
  {
    id: 'maize_nitrogen_deficiency',
    crop: 'maize',
    name: 'Nitrogen Deficiency (Lack of Plant Food / Nitrogen)',
    category: 'nutrient',
    affectedParts: ['leaves', 'entire_plant'],
    symptomMatches: ['yellowing_v_shape_tip', 'lower_leaves_yellow_first', 'stunted_thin_stalks', 'pale_green_yellow'],
    distribution: ['widespread', 'low_spots', 'sandy_patches'],
    onsetSpeed: 'gradual',
    description: 'Nitrogen is the fuel for leafy green growth. When lacking, maize plants turn pale green and develop an inverted V-shaped yellowing starting from the tip of older bottom leaves moving down the midrib.',
    urgency: 'medium',
    immediateAction: 'Apply nitrogen top-dressing fertilizer (such as Ammonium Nitrate or Urea) around the base of the plants if maize is still between knee-high and early tasseling stage.',
    treatmentPlan: [
      'Apply 100-150 kg/ha of Ammonium Nitrate (AN 34.5% N) or Urea (46% N) as a split top-dressing.',
      'Apply when the soil is moist (after rain or irrigation) and cover slightly with soil to stop nitrogen gas escaping into the air.'
    ],
    culturalControl: [
      'Incorporate well-rotted cattle or poultry manure before planting to build long-term soil nitrogen.',
      'Practice crop rotation with legumes (beans, groundnuts, cowpeas, soybeans) which add natural nitrogen to the soil.'
    ],
    chemicalOptions: [
      {
        name: 'Ammonium Nitrate (AN) or Urea Top-Dressing',
        type: 'Mineral Fertilizer',
        rate: '1 beer bottle cap (approx. 5-8 grams) per maize station placed 5cm away from stalk',
        phi: 'Safe at any time before harvest',
        safetyTip: 'Do not place dry fertilizer touching the plant stem—it will scorch (burn) the plant.'
      }
    ],
    prevention: [
      'Do soil testing before planting to calculate exact fertilizer rates.',
      'Split top-dressing into two applications (at knee-high and at early tasseling) rather than applying all at once on sandy soil.'
    ],
    terms: [
      { term: 'Top-dressing', explanation: 'Fertilizer applied onto or near the soil around growing plants after they have emerged.' },
      { term: 'Leaching', explanation: 'When heavy rain or over-watering washes water-soluble nutrients down deep beyond the reach of plant roots.' }
    ]
  },
  {
    id: 'maize_stalk_borer',
    crop: 'maize',
    name: 'African Maize Stalk Borer',
    category: 'pest',
    affectedParts: ['leaves', 'stem'],
    symptomMatches: ['pin_holes_in_straight_line', 'broken_top_dead_heart', 'holes_in_stalk_with_frass'],
    distribution: ['scattered'],
    onsetSpeed: 'moderate',
    description: 'Stalk borer larvae hatch on leaves and bore directly into the maize stalk, eating the plant from the inside out, causing "dead heart" and snapped stalks.',
    urgency: 'medium',
    immediateAction: 'Scout plants showing rows of pinholes across leaves. Treat funnels before caterpillars drill inside stems.',
    treatmentPlan: [
      'Apply registered stalk borer granules or targeted spray directly into the whorl.',
      'Remove and destroy plants showing complete dead heart to kill larvae inside.'
    ],
    culturalControl: [
      'Burn or feed maize crop stover (dry stalks) to livestock after harvest to kill overwintering caterpillars.',
      'Rotate maize with sunflower, cotton, or legumes.'
    ],
    chemicalOptions: [
      {
        name: 'Carbaryl 5% Granules or Cypermethrin',
        type: 'Granular / Liquid Insecticide',
        rate: 'Pinch of granules per whorl or 20ml liquid per 15L water',
        phi: '14 days',
        safetyTip: 'Wear protective gloves when handling granular pesticides.'
      }
    ],
    prevention: [
      'Clear volunteer maize and wild sorghum grass around fields before planting.'
    ],
    terms: [
      { term: 'Dead Heart', explanation: 'When the central growing point of the maize stalk dies and dries up because an insect ate through the inside.' }
    ]
  },

  // TOMATO PROBLEMS
  {
    id: 'tomato_early_late_blight',
    crop: 'tomato',
    name: 'Tomato Blight (Late Blight / Early Blight)',
    category: 'disease',
    affectedParts: ['leaves', 'stem', 'fruit'],
    symptomMatches: ['dark_brown_black_patches', 'greasy_water_soaked_spots', 'white_fuzzy_mold_underleaf', 'brown_fruit_rot', 'target_concentric_rings'],
    distribution: ['widespread', 'patches_spreading_fast'],
    onsetSpeed: 'rapid',
    description: 'Blight is an aggressive fungal disease favoured by cool, wet, cloudy, and humid weather. Late blight causes dark water-soaked rot that destroys an entire tomato field in days.',
    urgency: 'high',
    immediateAction: 'Immediately prune and safely destroy severely infected bottom leaves. Spray a curative systemic fungicide immediately, covering both top and bottom of all leaves.',
    treatmentPlan: [
      'During wet cloudy periods, spray a preventative contact fungicide (like Copper Oxychloride or Mancozeb) every 5-7 days.',
      'If active spots appear, switch to a systemic curative fungicide (e.g. Metalaxyl + Mancozeb).'
    ],
    culturalControl: [
      'Water at the base of plants using drip or furrow—NEVER use overhead sprinklers which splash water and fungal spores onto leaves.',
      'Stake and prune tomato plants to allow maximum air circulation and fast drying of leaves.',
      'Prune off all leaves touching the ground (the bottom 20cm of the stem).'
    ],
    chemicalOptions: [
      {
        name: 'Metalaxyl 8% + Mancozeb 64% WP (e.g. Ridomil Gold / Mastercop)',
        type: 'Systemic + Contact Fungicide',
        rate: '40-50g per 15L sprayer',
        phi: '7 days',
        safetyTip: 'Spray thoroughly in early morning before high sun heat. Observe the 7-day waiting period before picking fruit.'
      },
      {
        name: 'Copper Oxychloride 85% WP',
        type: 'Contact Protective Fungicide',
        rate: '40g per 15L water',
        phi: '3 days',
        safetyTip: 'Acts as a protective barrier on clean leaves before rain falls.'
      }
    ],
    prevention: [
      'Practice 3-year crop rotation (do NOT plant tomatoes after potatoes, peppers, or eggplants).',
      'Mulch the soil surface with clean dry grass to prevent rain splashes from bouncing soil fungi onto leaves.'
    ],
    terms: [
      { term: 'Contact Fungicide', explanation: 'A medicine that stays on the outside of the leaf to kill spores landing on it, like a protective shield.' },
      { term: 'Systemic Fungicide', explanation: 'A medicine that is absorbed into the sap of the plant and travels inside to stop disease that already entered.' },
      { term: 'Concentric Rings', explanation: 'Target-like circles inside leaf spots, typical of Early Blight (Alternaria).' }
    ]
  },
  {
    id: 'tomato_tuta_absoluta',
    crop: 'tomato',
    name: 'Tomato Leafminer (Tuta Absoluta)',
    category: 'pest',
    affectedParts: ['leaves', 'stem', 'fruit'],
    symptomMatches: ['transparent_leaf_mines', 'blotchy_white_leaf_patches', 'pinholes_near_calyx_fruit', 'black_frass_in_mines'],
    distribution: ['widespread', 'random'],
    onsetSpeed: 'rapid',
    description: 'Tuta Absoluta is a devastating tiny moth whose caterpillars burrow between the upper and lower leaf layers, creating clear white paper-like "mines" and boring pinholes into green and ripe tomatoes.',
    urgency: 'high',
    immediateAction: 'Install yellow sticky traps and pheromone delta traps to catch male moths. Spray a translaminar/systemic insecticide targeting larvae inside leaves.',
    treatmentPlan: [
      'Spray at dusk or very early morning when moths are active.',
      'Rotate chemical groups every 2 weeks (e.g. diamides to avermectins to spinosyns) to prevent rapid insecticide resistance.'
    ],
    culturalControl: [
      'Crush infested leaves by hand when infestation first starts.',
      'Collect and seal all dropped and damaged tomatoes in airtight black plastic bags in the sun to boil and kill larvae.',
      'Maintain weed-free borders around the greenhouse or field (remove wild solanum weeds).'
    ],
    chemicalOptions: [
      {
        name: 'Emamectin Benzoate 5% + Lufenuron',
        type: 'Translaminar Larvicide',
        rate: '10ml per 15L water',
        phi: '3 days',
        safetyTip: 'Penetrates through the leaf surface to kill caterpillars feeding inside the leaf tissue.'
      },
      {
        name: 'Spinetoram or Flubendiamide',
        type: 'Selective Leafminer Insecticide',
        rate: '5ml per 15L water',
        phi: '3 days',
        safetyTip: 'Fast knockdown of resistant leafminer populations.'
      }
    ],
    prevention: [
      'Install insect-proof netting on seedling nurseries.',
      'Use pheromone traps for early monitoring of moth arrivals.'
    ],
    terms: [
      { term: 'Translaminar', explanation: 'A chemical that penetrates through one side of the leaf to the other side to kill hidden bugs inside.' },
      { term: 'Pheromone Trap', explanation: 'A sticky trap using natural scent lures to attract and catch male moths to count their numbers.' }
    ]
  },
  {
    id: 'tomato_blossom_end_rot',
    crop: 'tomato',
    name: 'Blossom End Rot (Calcium Deficiency / Irregular Watering)',
    category: 'nutrient',
    affectedParts: ['fruit'],
    symptomMatches: ['sunken_black_leathery_bottom', 'fruit_flat_dry_bottom', 'dry_dark_rot_at_flower_end'],
    distribution: ['widespread', 'heavy_fruiting_plants'],
    onsetSpeed: 'moderate',
    description: 'Blossom End Rot is NOT a disease caused by germs—it is a physiological disorder caused by a lack of calcium in the growing fruit tip, almost always triggered by uneven watering (dry periods followed by heavy watering).',
    urgency: 'medium',
    immediateAction: 'Immediately stabilize your watering schedule to keep soil evenly moist (never let soil dry out bone-dry and then drown it). Apply a foliar Calcium spray to flowers and young fruit.',
    treatmentPlan: [
      'Pick off and discard damaged fruit so the plant directs calcium and energy into new, healthy fruit.',
      'Apply foliar Calcium Nitrate or Chelated Calcium spray directly onto young fruit and foliage weekly.'
    ],
    culturalControl: [
      'Apply heavy organic mulch (dry grass/straw) around plants to keep soil moisture uniform and reduce evaporation.',
      'Water with drip irrigation on regular daily schedules rather than large floods every 4-5 days.',
      'Avoid heavy root pruning during weeding.'
    ],
    chemicalOptions: [
      {
        name: 'Calcium Nitrate Foliar Spray (e.g. Calmax / Fertileader)',
        type: 'Foliar Nutrient Supplement',
        rate: '30-40g per 15L water',
        phi: '0 days (safe nutrient)',
        safetyTip: 'Spray during cool morning or evening hours on developing fruit bunches.'
      }
    ],
    prevention: [
      'Apply agricultural lime or gypsum during land preparation to provide base calcium.',
      'Avoid excess Ammonium nitrogen fertilizer, which blocks calcium uptake by roots.'
    ],
    terms: [
      { term: 'Physiological Disorder', explanation: 'A plant health problem caused by weather, water, or nutrient imbalance rather than an insect or fungus.' },
      { term: 'Foliar Spray', explanation: 'Liquid fertilizer sprayed directly onto the leaves where the plant absorbs it quickly through leaf pores.' }
    ]
  },
  {
    id: 'tomato_bacterial_wilt',
    crop: 'tomato',
    name: 'Bacterial Wilt (Ralstonia solanacearum)',
    category: 'disease',
    affectedParts: ['entire_plant', 'stem', 'roots'],
    symptomMatches: ['wilting_while_green', 'wilting_in_hot_sun_recover_night', 'brown_ring_inside_stem', 'milky_white_ooze_in_water_test'],
    distribution: ['patches', 'along_water_flow'],
    onsetSpeed: 'rapid',
    description: 'Bacterial Wilt is a soil-borne disease where bacteria clog the plant water-carrying tubes (xylem). The plant suddenly wilts rapidly while the leaves are still completely green.',
    urgency: 'high',
    immediateAction: 'Conduct the simple "Glass of Water Ooze Test" (cut stem, place in clear water). If white milky threads stream down within 3 minutes, it is Bacterial Wilt. Uproot infected plants with surrounding soil and burn them.',
    treatmentPlan: [
      'There is NO chemical cure once a plant is infected with Bacterial Wilt. Protect the rest of the field.',
      'Isolate the infected area and stop irrigation water from running from infected beds to clean beds.'
    ],
    culturalControl: [
      'Do not plant solanaceous crops (tomatoes, potatoes, peppers) in that bed for at least 3-4 years.',
      'Rotate with grasses, maize, sorghum, or brassicas.',
      'Improve field drainage and plant on raised beds.'
    ],
    chemicalOptions: [
      {
        name: 'Copper-based Soil Drench around neighbouring plants',
        type: 'Preventative Barrier',
        rate: '50g Copper Oxychloride per 15L water drenched at base of nearby healthy plants',
        phi: 'N/A',
        safetyTip: 'Suppresses surface bacteria but cannot heal already infected vascular systems.'
      }
    ],
    prevention: [
      'Use certified disease-free seedlings from clean nurseries.',
      'Graft commercial tomato scions onto resistant wild eggplant rootstocks in bacterial wilt-prone soils.'
    ],
    terms: [
      { term: 'Vascular System', explanation: 'The internal pipeline of veins inside a plant stem that carries water from roots up to leaves.' },
      { term: 'Soil Drench', explanation: 'Pouring liquid treatment directly onto the soil at the base of the plant stem.' }
    ]
  },

  // CABBAGE / BRASSICA PROBLEMS
  {
    id: 'cabbage_diamondback_moth',
    crop: 'cabbage',
    name: 'Diamondback Moth (DBM Caterpillars)',
    category: 'pest',
    affectedParts: ['leaves'],
    symptomMatches: ['window_pane_feeding', 'holes_under_leaves', 'tiny_green_wriggling_caterpillar_hangs_on_thread'],
    distribution: ['widespread'],
    onsetSpeed: 'rapid',
    description: 'DBM is the number one cabbage pest. Small light green caterpillars feed on the underside of leaves leaving a thin transparent layer ("window-paning") before eating through into severe holes and ruining head formation.',
    urgency: 'high',
    immediateAction: 'Check underside of leaves. If touched, DBM caterpillars wriggle violently and drop down on a silk thread. Spray with a bio-insecticide or targeted caterpillar spray.',
    treatmentPlan: [
      'DBM quickly becomes immune to regular cheap sprays (like simple pyrethroids). Use modern selective products.',
      'Always add a sticker/wetting agent to spray tanks because cabbage leaves have a slippery waxy surface that repels water drops.'
    ],
    culturalControl: [
      'Intercrop cabbage with pungent crops like coriander, garlic, or onions to confuse the flying moths.',
      'Use overhead sprinkler irrigation early in the evening to knock egg-laying moths out of the air.'
    ],
    chemicalOptions: [
      {
        name: 'Bacillus thuringiensis (Bt) or Spinosad',
        type: 'Biological Insecticide',
        rate: '15-20g/ml per 15L water + 5ml Agricultural Wetting Agent',
        phi: '1-3 days',
        safetyTip: 'Extremely safe for humans; kills only caterpillars when they eat the sprayed leaf.'
      },
      {
        name: 'Emamectin Benzoate 5% WDG',
        type: 'Targeted Caterpillar Control',
        rate: '4g per 15L water',
        phi: '7 days',
        safetyTip: 'Ensure under-leaf coverage when spraying.'
      }
    ],
    prevention: [
      'Scout seedlings in the nursery before transplanting to ensure no DBM eggs are brought to the main field.',
      'Plow under old cabbage crop stumps immediately after harvest.'
    ],
    terms: [
      { term: 'Sticker / Wetting Agent', explanation: 'A safe liquid mixed into spray water to help the chemical spread and stick onto slippery, waxy cabbage leaves.' },
      { term: 'Insecticide Resistance', explanation: 'When pests survive a chemical because the same spray was used repeatedly over many seasons.' }
    ]
  },
  {
    id: 'cabbage_black_rot',
    crop: 'cabbage',
    name: 'Black Rot (Xanthomonas campestris)',
    category: 'disease',
    affectedParts: ['leaves', 'stem'],
    symptomMatches: ['yellow_v_shaped_lesions_leaf_edge', 'blackened_leaf_veins', 'foul_rotting_smell_head'],
    distribution: ['patches', 'spreading_with_rain'],
    onsetSpeed: 'moderate',
    description: 'Black Rot is a damaging bacterial disease that enters leaves through water pores at the leaf edges. It causes characteristic yellow V-shaped yellow wedges with blackened veins.',
    urgency: 'high',
    immediateAction: 'Do not work in or weed the cabbage field when the leaves are wet from morning dew or rain, as your clothes, boots, and tools will spread the bacteria across the entire field.',
    treatmentPlan: [
      'Spray copper hydroxide / copper oxychloride to protect unaffected plants.',
      'Remove severely infected rotting plants and dispose of them outside the farm.'
    ],
    culturalControl: [
      'Use hot-water treated certified seeds (50°C for 25 minutes).',
      'Never plant cabbage, broccoli, kale, or rape in the same field consecutively—maintain a 3-year brassica break.'
    ],
    chemicalOptions: [
      {
        name: 'Copper Hydroxide 77% WP (e.g. Kocide / Champion)',
        type: 'Bactericide & Protective Barrier',
        rate: '35g per 15L water',
        phi: '3 days',
        safetyTip: 'Apply on a dry sunny afternoon. Acts on leaf surfaces to reduce bacterial spread.'
      }
    ],
    prevention: [
      'Plant on raised ridges to prevent standing puddles.',
      'Buy certified black-rot tolerant cabbage varieties (e.g. Gloria, Marcanta, Terminator hybrids).'
    ],
    terms: [
      { term: 'V-shaped Lesion', explanation: 'A yellow dead triangle on the edge of the leaf pointing inward toward the leaf stem.' },
      { term: 'Bactericide', explanation: 'A chemical or substance used specifically to control or kill harmful bacteria on crops.' }
    ]
  },

  // ONION / ALLIUM PROBLEMS
  {
    id: 'onion_thrips',
    crop: 'onion',
    name: 'Onion Thrips (Thrips tabaci)',
    category: 'pest',
    affectedParts: ['leaves'],
    symptomMatches: ['silvery_white_patches_leaf', 'distorted_crinkled_tips', 'tiny_yellow_black_specks_in_leaf_sheaths'],
    distribution: ['widespread', 'hot_dry_weather'],
    onsetSpeed: 'rapid',
    description: 'Thrips are tiny, slender insects that hide deep inside the tight neck/crevices of onion leaves. They scrape leaf surfaces and suck sap, turning leaves silvery-white and reducing bulb size.',
    urgency: 'high',
    immediateAction: 'Pull apart the inner leaf sheath near the bulb base to inspect for crawling yellow/brown specks. Spray with high pressure targeting down into the leaf sheath/neck with a surfactant/sticker.',
    treatmentPlan: [
      'Apply registered thripicides at early morning before thrips retreat deep into leaf bases.',
      'Include a quality wetting agent/sticker so spray penetrates the waxy tubular leaves.'
    ],
    culturalControl: [
      'Use overhead sprinkler irrigation in dry weather—water droplets disturb and drown thrips in leaf crotches.',
      'Maintain adequate soil moisture; drought-stressed onions suffer 3x more thrips damage.'
    ],
    chemicalOptions: [
      {
        name: 'Acetamiprid 20% SP or Spinetoram',
        type: 'Systemic / Translaminar Insecticide',
        rate: '5g/ml per 15L water + Sticker',
        phi: '7 days',
        safetyTip: 'Do not spray when honeybees are foraging.'
      },
      {
        name: 'Lambda-Cyhalothrin + Thiamethoxam',
        type: 'Knockdown + Systemic Blend',
        rate: '10ml per 15L water',
        phi: '14 days',
        safetyTip: 'Provides rapid knockdown of adult thrips.'
      }
    ],
    prevention: [
      'Avoid planting onions next to mature wheat, garlic, or alfalfa fields that are drying down.',
      'Destroy all cull/reject onion piles from previous harvests.'
    ],
    terms: [
      { term: 'Leaf Sheath / Neck', explanation: 'The tight area where onion leaves join together at the top of the bulb.' },
      { term: 'Silvering', explanation: 'The shiny, bleached appearance of leaves caused when thrips suck out chlorophyll from plant cells.' }
    ]
  },
  {
    id: 'onion_purple_blotch',
    crop: 'onion',
    name: 'Purple Blotch & Stemphylium Blight',
    category: 'disease',
    affectedParts: ['leaves'],
    symptomMatches: ['purple_brown_sunken_spots', 'yellow_halo_around_purple_lesion', 'leaves_collapsing_at_center'],
    distribution: ['widespread', 'warm_humid_weather'],
    onsetSpeed: 'moderate',
    description: 'Purple Blotch is a fungal disease that enters through thrips feeding wounds or leaf tips. It forms oval water-soaked spots that turn brown-purple with yellow halos, causing leaves to snap and fall.',
    urgency: 'medium',
    immediateAction: 'Control thrips immediately (as thrips wounds let the fungus enter). Spray a combination curative and protective fungicide.',
    treatmentPlan: [
      'Apply systemic fungicide (e.g., Difenoconazole or Azoxystrobin) mixed with sticker.',
      'Ensure leaves dry quickly by avoiding late evening irrigation.'
    ],
    culturalControl: [
      'Maintain wide row spacing to allow sunlight and wind between onion foliage.',
      'Avoid excess nitrogen fertilizer late in bulb growth which makes soft, vulnerable leaf tissue.'
    ],
    chemicalOptions: [
      {
        name: 'Difenoconazole 250 EC + Azoxystrobin',
        type: 'Broad-Spectrum Systemic Fungicide',
        rate: '10ml per 15L water + Sticker',
        phi: '14 days',
        safetyTip: 'Spray at first sign of purple pinpoint spots on leaves.'
      },
      {
        name: 'Mancozeb 80% WP',
        type: 'Contact Protective Fungicide',
        rate: '40g per 15L water',
        phi: '7 days',
        safetyTip: 'Use as a weekly preventative coat during warm humid periods.'
      }
    ],
    prevention: [
      'Practice 3-year rotation away from all allium crops (onions, garlic, leeks, shallots).',
      'Cure harvested bulbs in a dry, ventilated shed before storage.'
    ],
    terms: [
      { term: 'Halo', explanation: 'A yellow ring of stressed plant tissue surrounding a diseased spot.' },
      { term: 'Alliums', explanation: 'The plant family that includes onions, garlic, shallots, and leeks.' }
    ]
  },

  // POTATO PROBLEMS
  {
    id: 'potato_late_blight',
    crop: 'potato',
    name: 'Potato Late Blight (Phytophthora infestans)',
    category: 'disease',
    affectedParts: ['leaves', 'stem', 'tuber_roots'],
    symptomMatches: ['dark_water_soaked_leaf_margins', 'white_fungal_growth_underleaf', 'stem_blackening_snapping', 'rotting_smelly_tubers'],
    distribution: ['widespread', 'exploding_after_rain'],
    onsetSpeed: 'rapid',
    description: 'Late blight is the most notorious killer of potato crops. In wet, cold, or misty weather, it can completely brown and destroy a healthy potato canopy in 48-72 hours and rot tubers underground.',
    urgency: 'high',
    immediateAction: 'Spray an emergency curative systemic fungicide immediately. If tubers are close to maturity and foliage is heavily blighted, cut off and destroy all haulms (above-ground vines) to stop blight spores washing down into tubers.',
    treatmentPlan: [
      'Spray Metalaxyl + Mancozeb or Cymoxanil at first sign of disease.',
      'Follow up 5 days later with a protective copper or mancozeb spray.',
      'Hill up (ridge) soil high over tubers so rain cannot wash spores from leaves into underground potatoes.'
    ],
    culturalControl: [
      'Plant certified disease-free seed tubers (never use supermarket table potatoes as seed).',
      'De-haulm (cut and remove stems) 2 weeks before harvesting tubers.'
    ],
    chemicalOptions: [
      {
        name: 'Cymoxanil + Mancozeb (e.g. Curzate M) or Ridomil Gold',
        type: 'Systemic Translaminar Fungicide',
        rate: '45g per 15L water',
        phi: '7-14 days',
        safetyTip: 'Spray both upper and lower leaf surfaces thoroughly.'
      }
    ],
    prevention: [
      'Plant resistant/tolerant potato varieties (e.g. Shangi, BP1, Unica, Jelly depending on local area).',
      'Destroy volunteer potato plants and cull piles near fields.'
    ],
    terms: [
      { term: 'Haulm / De-haulming', explanation: 'The green above-ground foliage and stems of the potato plant. De-haulming means cutting them off before harvest.' },
      { term: 'Tuber', explanation: 'The swollen underground stem that forms the edible potato.' }
    ]
  },

  // BEAN / LEGUME PROBLEMS
  {
    id: 'bean_anthracnose',
    crop: 'beans',
    name: 'Bean Anthracnose (Colletotrichum lindemuthianum)',
    category: 'disease',
    affectedParts: ['leaves', 'stem', 'fruit'],
    symptomMatches: ['brick_red_purple_vein_lesions', 'sunken_circular_pod_cankers_with_dark_rims', 'oozing_salmon_pink_spores'],
    distribution: ['widespread', 'wet_cool_conditions'],
    onsetSpeed: 'moderate',
    description: 'Anthracnose is a seed-borne fungus causing dark brick-red or purple veins on the underside of bean leaves and sunken, circular black-rimmed craters on bean pods that ruin grain quality.',
    urgency: 'high',
    immediateAction: 'Avoid entering wet bean fields to prevent spreading spores on clothing. Spray systemic fungicide.',
    treatmentPlan: [
      'Apply systemic carbendazim, azoxystrobin, or copper hydroxide spray.',
      'Harvest mature dry pods quickly during sunny breaks to prevent seed staining.'
    ],
    culturalControl: [
      'Always plant certified, clean, disease-free seed—never plant farm-saved seed from an infected crop.',
      'Burn or deeply bury crop residues after harvest.'
    ],
    chemicalOptions: [
      {
        name: 'Azoxystrobin 250 SC or Copper Hydroxide',
        type: 'Fungicide',
        rate: '15ml or 35g per 15L water',
        phi: '7 days',
        safetyTip: 'Ensure pods are well covered when spraying.'
      }
    ],
    prevention: [
      'Rotate with non-legumes (cereals, brassicas, roots) for at least 2 years.'
    ],
    terms: [
      { term: 'Seed-borne Disease', explanation: 'A disease whose spores or bacteria hide inside or on the seed coat and infect the new plant right from germination.' },
      { term: 'Canker', explanation: 'A sunken, dead, open wound or crater on a plant stem, branch, or pod.' }
    ]
  },

  // GENERAL NUTRIENT DEFICIENCIES
  {
    id: 'general_phosphorus_deficiency',
    crop: 'general',
    name: 'Phosphorus (P) Deficiency',
    category: 'nutrient',
    affectedParts: ['leaves', 'roots', 'entire_plant'],
    symptomMatches: ['purple_reddish_underside_leaves', 'dark_dull_green_stunted', 'poor_root_development', 'delayed_flowering'],
    distribution: ['widespread', 'cold_wet_acidic_soil'],
    onsetSpeed: 'slow',
    description: 'Phosphorus is essential for root growth and energy transfer. When lacking (often in cold, acidic soils), leaves turn dark dull green with intense purple or reddish-bronze tinting on the underside.',
    urgency: 'medium',
    immediateAction: 'Apply high-phosphorus foliar feed (such as Mono-Potassium Phosphate or high-P starter fertilizer) for rapid leaf uptake while correcting soil root conditions.',
    treatmentPlan: [
      'In acidic soils (pH below 5.5), phosphorus gets "locked up" and roots cannot absorb it. Apply agricultural lime to release locked phosphorus.',
      'Apply basal compound fertilizers (like Compound D / NPK 7-14-7 or Single Superphosphate) placed directly near root zones at planting.'
    ],
    culturalControl: [
      'Incorporate organic compost and animal manure, which produce natural humic acids that unlock trapped soil phosphorus.',
      'Maintain good soil moisture so roots can reach nutrient bands.'
    ],
    chemicalOptions: [
      {
        name: 'High-P Foliar Fertilizer (e.g. 10-52-10 or MKP)',
        type: 'Quick-Absorb Foliar Plant Food',
        rate: '30-40g per 15L water',
        phi: '0 days (safe nutrient)',
        safetyTip: 'Spray early in the morning when leaf stomata (pores) are open.'
      }
    ],
    prevention: [
      'Always test soil pH and apply lime if soil is acidic.',
      'Apply basal fertilizer banded 5cm below and 5cm beside seed at planting time.'
    ],
    terms: [
      { term: 'Nutrient Lockup', explanation: 'When minerals are present in the soil, but wrong soil pH prevents plant roots from absorbing them.' },
      { term: 'Basal Fertilizer', explanation: 'Fertilizer applied at or before planting to support early root growth and seedling establishment.' }
    ]
  },
  {
    id: 'general_potassium_deficiency',
    crop: 'general',
    name: 'Potassium (K) Deficiency',
    category: 'nutrient',
    affectedParts: ['leaves', 'fruit'],
    symptomMatches: ['leaf_edge_browning_scorching', 'yellowing_margins_older_leaves', 'weak_lodging_stalks', 'poor_fruit_filling'],
    distribution: ['widespread', 'sandy_soils'],
    onsetSpeed: 'gradual',
    description: 'Potassium regulates plant water balance, stem strength, and fruit size. Deficiency shows as "marginal chlorosis and necrosis"—yellowing and brown scorched edges on older bottom leaves as if burned with a flame.',
    urgency: 'medium',
    immediateAction: 'Apply Potassium Chloride (MOP) or Potassium Sulfate (SOP) or a high-K foliar feed if plants are flowering/fruiting.',
    treatmentPlan: [
      'Apply Potassium top-dressing or side-dressing at 50-100 kg/ha on sandy soils prone to leaching.',
      'Apply wood ash (from clean, untreated firewood) around plants as a free, rich organic source of potassium and calcium.'
    ],
    culturalControl: [
      'Mulch with dry plant material which returns potassium to soil as it breaks down.',
      'Avoid excessive over-irrigation on sandy soils that washes potassium down into deep ground.'
    ],
    chemicalOptions: [
      {
        name: 'Potassium Nitrate (KNO3) or SOP Foliar Spray',
        type: 'Foliar Nutrient',
        rate: '30g per 15L water',
        phi: '0 days',
        safetyTip: 'Greatly enhances fruit sweetness, firm skin, and disease resistance.'
      }
    ],
    prevention: [
      'Apply balanced compound fertilizers based on soil tests.',
      'Incorporate well-cured manure annually.'
    ],
    terms: [
      { term: 'Marginal Scorch', explanation: 'Browning and dying of the outer edges and rims of leaves.' },
      { term: 'Lodging', explanation: 'When crop stalks bend or fall flat on the ground due to weak stems or storm winds.' }
    ]
  },

  // ENVIRONMENTAL / MANAGEMENT STRESS
  {
    id: 'general_waterlogging_root_rot',
    crop: 'general',
    name: 'Waterlogging & Damping-Off / Root Rot',
    category: 'environmental',
    affectedParts: ['roots', 'entire_plant', 'leaves'],
    symptomMatches: ['yellow_drooping_leaves_wet_soil', 'black_rotted_mushy_roots', 'plants_falling_over_at_soil_line', 'sour_swampy_soil_smell'],
    distribution: ['low_spots', 'heavy_clay_areas'],
    onsetSpeed: 'moderate',
    description: 'When soil stays flooded or overwatered, roots suffocate from lack of oxygen and are attacked by water-mold pathogens (Pythium/Phytophthora), turning roots black, mushy, and foul-smelling.',
    urgency: 'high',
    immediateAction: 'Immediately stop all irrigation. Dig drainage trenches to evacuate standing water away from crop beds. Loosen compacted soil gently without ripping roots.',
    treatmentPlan: [
      'Allow soil surface to dry out before giving any more water.',
      'If damping off is spreading in seedlings, drench soil with Propamocarb or Copper fungicide.'
    ],
    culturalControl: [
      'Always plant crops on raised beds (15-20cm high) in heavy clay or flood-prone ground.',
      'Add coarse compost or sand to improve heavy clay drainage.'
    ],
    chemicalOptions: [
      {
        name: 'Propamocarb Hydrochloride (e.g. Previcur N)',
        type: 'Anti-Oomycete Root Drench',
        rate: '25ml per 15L water drenched at base of plants',
        phi: '7 days',
        safetyTip: 'Halts damping-off and root rot fungi in wet seedbeds.'
      }
    ],
    prevention: [
      'Design farm slopes with contours and grassed waterways.',
      'Check soil moisture 10cm deep before deciding to turn on irrigation pumps.'
    ],
    terms: [
      { term: 'Damping Off', explanation: 'A fungal condition where young tender seedlings rot at the soil line, collapse, and die.' },
      { term: 'Anaerobic Soil', explanation: 'Waterlogged soil with zero air/oxygen, causing roots to drown and rot.' }
    ]
  },
  {
    id: 'general_chemical_herbicide_damage',
    crop: 'general',
    name: 'Herbicide Drift / Chemical Burn',
    category: 'environmental',
    affectedParts: ['leaves', 'stem', 'entire_plant'],
    symptomMatches: ['distorted_cupped_twisted_leaves', 'bleached_white_yellow_spots_after_spray', 'strap_like_skinny_leaves', 'sudden_wilt_after_spraying'],
    distribution: ['border_next_to_sprayed_field', 'patches_near_spray_path'],
    onsetSpeed: 'rapid',
    description: 'Accidental spray drift from nearby fields (e.g. 2,4-D or Glyphosate) or chemical residues left in unwashed knapsack sprayers causes leaf curling, shoe-stringing, bleaching, and distorted growth.',
    urgency: 'high',
    immediateAction: 'If spray drift happened in the last 2 hours, immediately wash the crop foliage with heavy clean water spray to rinse off surface chemicals. Apply a biostimulant / amino acid anti-stress spray to help plants recover.',
    treatmentPlan: [
      'Keep soil moist and apply seaweed extract or bio-stimulant foliar feed.',
      'Never use the same knapsack sprayer for weedkillers (herbicides) and insecticides/fungicides unless thoroughly neutralized.'
    ],
    culturalControl: [
      'Dedicate one clearly labelled sprayer ONLY for weedkillers and another sprayer ONLY for insecticides and fertilizers.',
      'Never spray weedkillers on windy days.'
    ],
    chemicalOptions: [
      {
        name: 'Seaweed Extract / Amino Acid Biostimulant (e.g. Kelpak / Megafol)',
        type: 'Plant Stress Recovery Tonic',
        rate: '30-50ml per 15L water',
        phi: '0 days',
        safetyTip: 'Provides raw amino acids to help stressed plant cells rebuild after chemical shock.'
      }
    ],
    prevention: [
      'Install live windbreak hedges along boundary fences to catch drift.',
      'Use drift-reducing fan nozzles on sprayers.'
    ],
    terms: [
      { term: 'Spray Drift', explanation: 'Fine mist droplets of chemical blown by wind away from the target weed patch into neighboring sensitive crops.' },
      { term: 'Biostimulant', explanation: 'A natural plant tonic made from seaweed or amino acids that boosts plant immune defense and recovery from stress.' }
    ]
  }
];

// Navigation and Tool Interaction Logic
function initCropDiagnosisTool() {
  diagnosisState.currentStep = 0;
  updateStepDisplay();
}

function startDiagnosisTool() {
  document.getElementById('startScreen').classList.add('hidden');
  document.getElementById('step1Crop').classList.remove('hidden');
  diagnosisState.currentStep = 1;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function updateStepDisplay() {
  const steps = document.querySelectorAll('.progress-step');
  steps.forEach((step, index) => {
    const stepNum = index + 1;
    step.classList.remove('active', 'completed');
    if (stepNum === diagnosisState.currentStep) {
      step.classList.add('active');
    } else if (stepNum < diagnosisState.currentStep) {
      step.classList.add('completed');
    }
  });
}

function selectCropType(crop) {
  diagnosisState.crop.type = crop;
  const cropNames = {
    maize: 'Maize / Corn',
    tomato: 'Tomato',
    cabbage: 'Cabbage / Brassicas (Kale, Rape, Broccoli)',
    onion: 'Onion / Garlic',
    potato: 'Irish Potato',
    beans: 'Beans / Legumes (Cowpeas, Groundnuts, Soybeans)',
    pepper: 'Peppers / Chilies',
    wheat: 'Wheat / Barley',
    general: 'Other Crop'
  };
  diagnosisState.crop.name = cropNames[crop] || crop;
  
  // Highlight button
  const buttons = document.querySelectorAll('#cropTypeButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === crop);
  });
}

function selectGrowthStage(stage) {
  diagnosisState.crop.stage = stage;
  const buttons = document.querySelectorAll('#growthStageButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === stage);
  });
}

function confirmStep1() {
  if (!diagnosisState.crop.type) {
    alert('Please select your crop type to continue.');
    return;
  }
  if (!diagnosisState.crop.stage) {
    alert('Please select the growth stage of your crop.');
    return;
  }
  
  document.getElementById('step1Crop').classList.add('hidden');
  document.getElementById('step2Part').classList.remove('hidden');
  diagnosisState.currentStep = 2;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectAffectedPart(part) {
  diagnosisState.affectedPart = part;
  const buttons = document.querySelectorAll('#affectedPartButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === part);
  });
}

function confirmStep2() {
  if (!diagnosisState.affectedPart) {
    alert('Please choose which part of the plant is showing symptoms.');
    return;
  }
  
  renderSymptomChecklist();
  document.getElementById('step2Part').classList.add('hidden');
  document.getElementById('step3Symptoms').classList.remove('hidden');
  diagnosisState.currentStep = 3;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function renderSymptomChecklist() {
  const container = document.getElementById('symptomsContainer');
  container.innerHTML = '';
  
  const symptomList = [
    { id: 'chewed_holes', label: 'Chewed holes in leaves or ragged edges (caterpillars / beetles)' },
    { id: 'sawdust_droppings', label: 'Wet sawdust-like waste (frass) inside the leaf funnel or stem' },
    { id: 'caterpillar_in_funnel', label: 'Caterpillars or worms visible inside the leaf whorl or stem' },
    { id: 'window_pane_feeding', label: 'Transparent "window pane" patches on leaves (skinny leaf layer left)' },
    { id: 'transparent_leaf_mines', label: 'White serpentine trails / blotches inside the leaf tissue (leafminers)' },
    { id: 'yellowing_v_shape_tip', label: 'Yellowing in an inverted V-shape starting from the leaf tip down the center vein (Nitrogen lack)' },
    { id: 'lower_leaves_yellow_first', label: 'Old bottom leaves turn completely yellow while top leaves stay green' },
    { id: 'purple_reddish_underside_leaves', label: 'Purple or reddish tinting on the underside of leaves or stems (Phosphorus lack)' },
    { id: 'leaf_edge_browning_scorching', label: 'Outer leaf edges turn yellow and brown/scorched like burnt with fire (Potassium lack)' },
    { id: 'dark_brown_black_patches', label: 'Large dark brown or greasy black rot patches on leaves and stems (Blight)' },
    { id: 'white_fuzzy_mold_underleaf', label: 'White or grey powdery/fuzzy mold on the underside of leaves' },
    { id: 'target_concentric_rings', label: 'Dark circular spots with target-like rings inside them' },
    { id: 'sunken_black_leathery_bottom', label: 'Black sunken leathery flat spot at the blossom bottom of fruit (Blossom End Rot)' },
    { id: 'wilting_while_green', label: 'Plant collapses and wilts suddenly while leaves are still green (Bacterial Wilt)' },
    { id: 'wilting_in_hot_sun_recover_night', label: 'Wilts in midday heat, slightly recovers at night' },
    { id: 'silvery_white_patches_leaf', label: 'Silvery white bleached speckling on leaves with tiny black dots (Thrips / Mites)' },
    { id: 'yellow_v_shaped_lesions_leaf_edge', label: 'Yellow V-shaped wedge starting from leaf edges with black veins (Black Rot)' },
    { id: 'distorted_cupped_twisted_leaves', label: 'Leaves are curled, cupped, twisted, or strap-like (Herbicide drift or Virus)' },
    { id: 'yellow_drooping_leaves_wet_soil', label: 'Leaves turn pale yellow and droop while soil is completely wet/waterlogged' },
    { id: 'black_rotted_mushy_roots', label: 'Roots are dark brown/black, soft, peeling, or foul smelling' },
    { id: 'pin_holes_in_straight_line', label: 'Straight rows of pinholes across the leaf as it unfolds (Stalk borer)' }
  ];
  
  symptomList.forEach(item => {
    const div = document.createElement('div');
    div.className = 'symptom-check-card';
    div.innerHTML = `
      <label style="display: flex; align-items: flex-start; gap: 0.75rem; cursor: pointer; width: 100%;">
        <input type="checkbox" value="${item.id}" onchange="toggleSymptom('${item.id}', this.checked)" style="width: 20px; height: 20px; margin-top: 3px; accent-color: var(--field);" ${diagnosisState.symptoms.includes(item.id) ? 'checked' : ''}>
        <span style="font-size: 0.95rem; line-height: 1.4; color: var(--ink);">${item.label}</span>
      </label>
    `;
    container.appendChild(div);
  });
}

function toggleSymptom(id, checked) {
  if (checked) {
    if (!diagnosisState.symptoms.includes(id)) diagnosisState.symptoms.push(id);
  } else {
    diagnosisState.symptoms = diagnosisState.symptoms.filter(s => s !== id);
  }
}

function confirmStep3() {
  if (diagnosisState.symptoms.length === 0) {
    alert('Please select at least one symptom from the list.');
    return;
  }
  
  document.getElementById('step3Symptoms').classList.add('hidden');
  document.getElementById('step4Pattern').classList.remove('hidden');
  diagnosisState.currentStep = 4;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectDistribution(dist) {
  diagnosisState.distribution = dist;
  const buttons = document.querySelectorAll('#distributionButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === dist);
  });
}

function selectOnsetSpeed(speed) {
  diagnosisState.onsetSpeed = speed;
  const buttons = document.querySelectorAll('#speedButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === speed);
  });
}

function confirmStep4() {
  if (!diagnosisState.distribution) {
    alert('Please select how the problem is distributed across your field.');
    return;
  }
  if (!diagnosisState.onsetSpeed) {
    alert('Please choose how fast the problem appeared.');
    return;
  }
  
  document.getElementById('step4Pattern').classList.add('hidden');
  document.getElementById('step5History').classList.remove('hidden');
  diagnosisState.currentStep = 5;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectWeatherHistory(weather) {
  diagnosisState.fieldConditions.recentWeather = weather;
  const buttons = document.querySelectorAll('#weatherHistoryButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === weather);
  });
}

function selectSprayHistory(spray) {
  diagnosisState.fieldConditions.recentSprayOrFertilizer = spray;
  const buttons = document.querySelectorAll('#sprayHistoryButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === spray);
  });
}

function confirmStep5() {
  if (!diagnosisState.fieldConditions.recentWeather) {
    alert('Please select recent weather conditions.');
    return;
  }
  if (!diagnosisState.fieldConditions.recentSprayOrFertilizer) {
    alert('Please select recent chemical/fertilizer spray history.');
    return;
  }
  
  document.getElementById('step5History').classList.add('hidden');
  document.getElementById('step6Inspection').classList.remove('hidden');
  diagnosisState.currentStep = 6;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function selectInsectPresence(insects) {
  diagnosisState.observations.insectsVisible = insects;
  const buttons = document.querySelectorAll('#insectPresenceButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === insects);
  });
}

function selectRootCondition(root) {
  diagnosisState.observations.rootCondition = root;
  const buttons = document.querySelectorAll('#rootConditionButtons .option-button');
  buttons.forEach(btn => {
    btn.classList.toggle('selected', btn.dataset.value === root);
  });
}

function confirmStep6() {
  if (!diagnosisState.observations.insectsVisible) {
    alert('Please tell us if you see any insects or pests on the plants.');
    return;
  }
  if (!diagnosisState.observations.rootCondition) {
    alert('Please select the root and soil condition.');
    return;
  }
  
  calculateDiagnosis();
  
  document.getElementById('step6Inspection').classList.add('hidden');
  document.getElementById('finalResult').classList.remove('hidden');
  diagnosisState.currentStep = 7;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function calculateDiagnosis() {
  const userCrop = diagnosisState.crop.type;
  const userSymptoms = diagnosisState.symptoms;
  const userPart = diagnosisState.affectedPart;
  const userDist = diagnosisState.distribution;
  const userSpeed = diagnosisState.onsetSpeed;
  const userWeather = diagnosisState.fieldConditions.recentWeather;
  const userSpray = diagnosisState.fieldConditions.recentSprayOrFertilizer;
  const userInsects = diagnosisState.observations.insectsVisible;
  const userRoots = diagnosisState.observations.rootCondition;
  
  const scoredProblems = cropProblemsDatabase.map(problem => {
    let score = 0;
    
    if (problem.crop === userCrop) {
      score += 35;
    } else if (problem.crop === 'general') {
      score += 15;
    } else {
      score -= 30;
    }
    
    if (problem.affectedParts.includes(userPart) || problem.affectedParts.includes('entire_plant')) {
      score += 20;
    }
    
    let matchingSymptomsCount = 0;
    problem.symptomMatches.forEach(sym => {
      if (userSymptoms.includes(sym)) {
        score += 25;
        matchingSymptomsCount++;
      }
    });
    
    if (problem.distribution.includes(userDist)) score += 10;
    if (problem.onsetSpeed === userSpeed) score += 10;
    
    if (userWeather === 'wet_cloudy' && (problem.id.includes('blight') || problem.id.includes('rot'))) score += 15;
    if (userWeather === 'hot_dry' && (problem.id.includes('thrips') || problem.id.includes('tuta'))) score += 15;
    if (userSpray === 'recent_herbicide' && problem.id.includes('herbicide')) score += 40;
    if (userInsects === 'caterpillars' && (problem.id.includes('armyworm') || problem.id.includes('borer') || problem.id.includes('moth') || problem.id.includes('tuta'))) score += 25;
    if (userInsects === 'tiny_specks' && (problem.id.includes('thrips') || problem.id.includes('mite'))) score += 25;
    if (userRoots === 'black_mushy' && (problem.id.includes('waterlog') || problem.id.includes('wilt'))) score += 30;
    
    return {
      problem: problem,
      score: score,
      matchingSymptomsCount: matchingSymptomsCount
    };
  });
  
  scoredProblems.sort((a, b) => b.score - a.score);
  
  const bestMatch = scoredProblems[0].problem;
  const secondary = scoredProblems.slice(1, 4).filter(p => p.score > 30).map(p => p.problem);
  
  diagnosisState.results.primaryDiagnosis = bestMatch;
  diagnosisState.results.secondaryPossibilities = secondary;
  diagnosisState.results.urgency = bestMatch.urgency || 'medium';
  diagnosisState.results.confidence = scoredProblems[0].score >= 70 ? 'High' : (scoredProblems[0].score >= 45 ? 'Moderate' : 'General Match');
  
  renderDiagnosisResults(bestMatch, secondary);
}

function renderDiagnosisResults(primary, secondaries) {
  const statusEl = document.getElementById('resultStatus');
  statusEl.className = 'result-status ' + (primary.urgency === 'high' ? 'danger' : (primary.urgency === 'medium' ? 'warning' : 'good'));
  statusEl.innerHTML = `DIAGNOSIS: ${primary.name.toUpperCase()} (${diagnosisState.results.confidence.toUpperCase()} CONFIDENCE)`;
  
  document.getElementById('summaryCrop').textContent = diagnosisState.crop.name + ' (' + diagnosisState.crop.stage + ' stage)';
  document.getElementById('summaryPart').textContent = diagnosisState.affectedPart.replace('_', ' ').toUpperCase();
  document.getElementById('summaryCategory').textContent = primary.category.toUpperCase() + ' PROBLEM';
  document.getElementById('summaryUrgency').textContent = primary.urgency.toUpperCase() + ' — TAKE ACTION PROMPTLY';
  
  document.getElementById('problemDescription').innerHTML = `
    <p style="font-size: 1.05rem; line-height: 1.6; margin-bottom: 0.75rem;"><strong>What this is:</strong> ${primary.description}</p>
    <p style="font-size: 0.95rem; color: var(--field-dark);"><strong>Why it happened:</strong> Favourable conditions such as weather, pest life cycles, or soil nutrient balances allowed this issue to establish.</p>
  `;
  
  document.getElementById('immediateActionText').textContent = primary.immediateAction;
  
  const treatmentUl = document.getElementById('treatmentList');
  treatmentUl.innerHTML = '';
  primary.treatmentPlan.forEach(step => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = step;
    treatmentUl.appendChild(li);
  });
  
  const culturalUl = document.getElementById('culturalList');
  culturalUl.innerHTML = '';
  primary.culturalControl.forEach(step => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = step;
    culturalUl.appendChild(li);
  });
  
  const chemContainer = document.getElementById('chemicalOptionsContainer');
  chemContainer.innerHTML = '';
  if (primary.chemicalOptions && primary.chemicalOptions.length > 0) {
    primary.chemicalOptions.forEach(chem => {
      const card = document.createElement('div');
      card.className = 'condition-card';
      card.style.background = '#fff';
      card.style.borderLeft = '4px solid var(--soil)';
      card.innerHTML = `
        <div style="font-weight: 700; color: var(--field); font-size: 1.05rem;">${chem.name}</div>
        <div style="font-size: 0.85rem; color: var(--muted); margin-bottom: 0.5rem;"><strong>Type:</strong> ${chem.type}</div>
        <div style="font-size: 0.9rem; margin-bottom: 0.25rem;"><strong>Application Rate:</strong> ${chem.rate}</div>
        <div style="font-size: 0.9rem; margin-bottom: 0.25rem; color: var(--soil); font-weight: 700;"><strong>Pre-Harvest Interval (Waiting period before picking):</strong> ${chem.phi}</div>
        <div style="font-size: 0.85rem; color: var(--ink); margin-top: 0.4rem; background: var(--cream); padding: 0.5rem; border-radius: 4px;"><strong>Safety & Best Practice:</strong> ${chem.safetyTip}</div>
      `;
      chemContainer.appendChild(card);
    });
  } else {
    chemContainer.innerHTML = '<p style="font-size: 0.9rem; color: var(--muted);">No synthetic chemical required for this issue. Cultural and organic adjustments are the most effective solution.</p>';
  }
  
  const prevUl = document.getElementById('preventionList');
  prevUl.innerHTML = '';
  primary.prevention.forEach(step => {
    const li = document.createElement('li');
    li.style.marginBottom = '0.5rem';
    li.innerHTML = step;
    prevUl.appendChild(li);
  });
  
  const termsContainer = document.getElementById('termsContainer');
  termsContainer.innerHTML = '';
  if (primary.terms && primary.terms.length > 0) {
    primary.terms.forEach(t => {
      const termDiv = document.createElement('div');
      termDiv.style.marginBottom = '0.75rem';
      termDiv.innerHTML = `<strong style="color: var(--field);">${t.term}:</strong> <span style="font-size: 0.9rem; color: var(--ink);">${t.explanation}</span>`;
      termsContainer.appendChild(termDiv);
    });
  }
  
  const secContainer = document.getElementById('secondaryPossibilities');
  secContainer.innerHTML = '';
  if (secondaries.length > 0) {
    secondaries.forEach(sec => {
      const secDiv = document.createElement('div');
      secDiv.className = 'condition-card';
      secDiv.innerHTML = `
        <div style="font-weight: 700; color: var(--field);">${sec.name}</div>
        <p style="font-size: 0.85rem; color: var(--muted); margin: 0.25rem 0 0.5rem 0;">${sec.description}</p>
        <div style="font-size: 0.85rem;"><strong>Quick check:</strong> ${sec.immediateAction}</div>
      `;
      secContainer.appendChild(secDiv);
    });
  } else {
    secContainer.innerHTML = '<p style="font-size: 0.9rem; color: var(--muted);">No other conflicting diagnoses found. Primary diagnosis is highly probable.</p>';
  }
}

function goBack() {
  if (diagnosisState.currentStep <= 1) {
    document.getElementById('step1Crop').classList.add('hidden');
    document.getElementById('startScreen').classList.remove('hidden');
    diagnosisState.currentStep = 0;
  } else if (diagnosisState.currentStep === 2) {
    document.getElementById('step2Part').classList.add('hidden');
    document.getElementById('step1Crop').classList.remove('hidden');
    diagnosisState.currentStep = 1;
  } else if (diagnosisState.currentStep === 3) {
    document.getElementById('step3Symptoms').classList.add('hidden');
    document.getElementById('step2Part').classList.remove('hidden');
    diagnosisState.currentStep = 2;
  } else if (diagnosisState.currentStep === 4) {
    document.getElementById('step4Pattern').classList.add('hidden');
    document.getElementById('step3Symptoms').classList.remove('hidden');
    diagnosisState.currentStep = 3;
  } else if (diagnosisState.currentStep === 5) {
    document.getElementById('step5History').classList.add('hidden');
    document.getElementById('step4Pattern').classList.remove('hidden');
    diagnosisState.currentStep = 4;
  } else if (diagnosisState.currentStep === 6) {
    document.getElementById('step6Inspection').classList.add('hidden');
    document.getElementById('step5History').classList.remove('hidden');
    diagnosisState.currentStep = 5;
  } else if (diagnosisState.currentStep === 7) {
    document.getElementById('finalResult').classList.add('hidden');
    document.getElementById('step6Inspection').classList.remove('hidden');
    diagnosisState.currentStep = 6;
  }
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function restartTool() {
  diagnosisState.crop = { type: '', name: '', stage: '', scale: 'commercial' };
  diagnosisState.affectedPart = '';
  diagnosisState.symptoms = [];
  diagnosisState.distribution = '';
  diagnosisState.onsetSpeed = '';
  diagnosisState.fieldConditions = { recentWeather: '', wateringHistory: '', recentSprayOrFertilizer: '', drainageStatus: '' };
  diagnosisState.observations = { insectsVisible: '', insectType: '', smellOrOoze: '', underleafCheck: '', rootCondition: '' };
  
  document.getElementById('finalResult').classList.add('hidden');
  document.getElementById('startScreen').classList.remove('hidden');
  diagnosisState.currentStep = 0;
  updateStepDisplay();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function saveResult() {
  const resultData = {
    date: new Date().toLocaleDateString(),
    crop: diagnosisState.crop.name,
    diagnosis: diagnosisState.results.primaryDiagnosis ? diagnosisState.results.primaryDiagnosis.name : 'Crop Check',
    immediateAction: diagnosisState.results.primaryDiagnosis ? diagnosisState.results.primaryDiagnosis.immediateAction : ''
  };
  
  localStorage.setItem('agribase_last_crop_diagnosis', JSON.stringify(resultData));
  alert('Your crop diagnosis report has been saved to your browser! You can access it anytime on this device.');
}

function downloadResult() {
  if (!diagnosisState.results.primaryDiagnosis) return;
  const p = diagnosisState.results.primaryDiagnosis;
  
  let reportText = `AGRIBASE CROP DIAGNOSIS REPORT\n`;
  reportText += `==========================================\n`;
  reportText += `Date: ${new Date().toLocaleString()}\n`;
  reportText += `Crop: ${diagnosisState.crop.name} (${diagnosisState.crop.stage} stage)\n`;
  reportText += `Plant Part Affected: ${diagnosisState.affectedPart}\n`;
  reportText += `Diagnosis: ${p.name}\n`;
  reportText += `Category: ${p.category.toUpperCase()}\n`;
  reportText += `Confidence: ${diagnosisState.results.confidence}\n\n`;
  reportText += `WHAT THIS PROBLEM IS:\n${p.description}\n\n`;
  reportText += `IMMEDIATE STOP-LOSS ACTION:\n${p.immediateAction}\n\n`;
  reportText += `RECOMMENDED TREATMENT PLAN:\n`;
  p.treatmentPlan.forEach((step, i) => { reportText += `${i+1}. ${step}\n`; });
  reportText += `\nCULTURAL & NATURAL REMEDIES:\n`;
  p.culturalControl.forEach((step, i) => { reportText += `${i+1}. ${step}\n`; });
  if (p.chemicalOptions && p.chemicalOptions.length > 0) {
    reportText += `\nCHEMICAL OPTIONS (HANDLE WITH GLOVES & MASK):\n`;
    p.chemicalOptions.forEach(c => {
      reportText += `- ${c.name} (${c.type}): Rate ${c.rate} | Waiting Period (PHI): ${c.phi}\n`;
    });
  }
  reportText += `\nFUTURE PREVENTION:\n`;
  p.prevention.forEach((step, i) => { reportText += `${i+1}. ${step}\n`; });
  reportText += `\n==========================================\n`;
  reportText += `AgriBase Decision Tools — Real Help for Farmers\n`;
  
  const blob = new Blob([reportText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `crop-diagnosis-${diagnosisState.crop.type}-${Date.now()}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

document.addEventListener('DOMContentLoaded', () => {
  initCropDiagnosisTool();
});
