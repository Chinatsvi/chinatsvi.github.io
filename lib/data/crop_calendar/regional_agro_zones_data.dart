import '../../models/crop_calendar/crop_calendar_models.dart';

class RegionalAgroZonesData {
  static List<LocationAgroProfile> getAllPresetLocations() {
    return [
      // ==========================================
      // 🇿🇼 ZIMBABWE
      // ==========================================
      const LocationAgroProfile(
        country: 'Zimbabwe',
        countryCode: 'ZW',
        region: 'Masvingo',
        district: 'Masvingo',
        climateZone: 'Middleveld / Lowveld Transition',
        latitude: -20.0744,
        longitude: 30.8328,
        elevationMeters: 1080,
        isSouthernHemisphere: true,
        frostRiskMonths: [6, 7], // June, July light frost in low valleys
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [9, 10, 11, 12, 1],
        seasonalNotes:
            'Warm to hot climate with moderate summer rainfall. Lowveld areas (e.g. Chiredzi, Triangle) are virtually frost-free, allowing winter irrigated tomato and vegetable production.',
      ),
      const LocationAgroProfile(
        country: 'Zimbabwe',
        countryCode: 'ZW',
        region: 'Harare',
        district: 'Harare',
        climateZone: 'Highveld (Natural Region IIa)',
        latitude: -17.8292,
        longitude: 31.0522,
        elevationMeters: 1490,
        isSouthernHemisphere: true,
        frostRiskMonths: [5, 6, 7], // May, June, July
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [9, 10, 11],
        seasonalNotes:
            'High altitude plateau. Mild summers with reliable rain; cool dry winters with notable frost risk between late May and late July in low-lying vleis.',
      ),
      const LocationAgroProfile(
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
        seasonalNotes:
            'Semi-arid with lower erratic rainfall. Irrigation is strongly recommended for commercial horticulture. Winter frost is common in June.',
      ),
      const LocationAgroProfile(
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
        seasonalNotes:
            'Microclimates range from mist-belt mountains (Nyanga, Vumba) to warm irrigated valleys (Honde, Save). Excellent year-round horticultural potential.',
      ),
      const LocationAgroProfile(
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
        seasonalNotes:
            'Highveld zone with sharp winter frosts in open fields. Irrigation essential for dry season horticulture.',
      ),
      const LocationAgroProfile(
        country: 'Zimbabwe',
        countryCode: 'ZW',
        region: 'Mashonaland West',
        district: 'Chinhoyi & Karoi',
        climateZone: 'Intensive Farming Highveld (Region IIa)',
        latitude: -17.3667,
        longitude: 30.2000,
        elevationMeters: 1150,
        isSouthernHemisphere: true,
        frostRiskMonths: [6, 7],
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [9, 10, 11],
        seasonalNotes:
            'Deep fertile soils, high summer rainfall. Warm valley areas near Zambezi are frost-free.',
      ),

      // ==========================================
      // 🇿🇦 SOUTH AFRICA
      // ==========================================
      const LocationAgroProfile(
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
        seasonalNotes:
            'Polokwane has winter frost, whereas Tzaneen and the Lowveld are frost-free subtropics famous for winter tomato, cabbage, and avocado production.',
      ),
      const LocationAgroProfile(
        country: 'South Africa',
        countryCode: 'ZA',
        region: 'Gauteng',
        district: 'Johannesburg & Pretoria',
        climateZone: 'Highveld Plateau',
        latitude: -26.2041,
        longitude: 28.0473,
        elevationMeters: 1750,
        isSouthernHemisphere: true,
        frostRiskMonths: [5, 6, 7, 8], // Severe frost May-August
        wetSeasonMonths: [10, 11, 12, 1, 2, 3],
        hotSeasonMonths: [10, 11, 12, 1],
        seasonalNotes:
            'Severe winter frost between May and August makes open-field tomato/pepper impossible without tunnels or frost protection.',
      ),
      const LocationAgroProfile(
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
        wetSeasonMonths: [5, 6, 7, 8], // Winter rain!
        hotSeasonMonths: [12, 1, 2, 3],
        seasonalNotes:
            'Mediterranean climate: wet, cool winters and dry, warm/windy summers. Summer crops depend 100% on irrigation.',
      ),
      const LocationAgroProfile(
        country: 'South Africa',
        countryCode: 'ZA',
        region: 'KwaZulu-Natal',
        district: 'Durban & Coastal Belt',
        climateZone: 'Humid Subtropical',
        latitude: -29.8587,
        longitude: 31.0218,
        elevationMeters: 20,
        isSouthernHemisphere: true,
        frostRiskMonths: [], // Virtually frost free coast
        wetSeasonMonths: [10, 11, 12, 1, 2, 3],
        hotSeasonMonths: [11, 12, 1, 2, 3],
        seasonalNotes:
            'Frost-free coastal zone with high humidity. High fungal disease pressure in summer; excellent winter vegetable production.',
      ),

      // ==========================================
      // 🇿🇲 ZAMBIA
      // ==========================================
      const LocationAgroProfile(
        country: 'Zambia',
        countryCode: 'ZM',
        region: 'Lusaka',
        district: 'Lusaka',
        climateZone: 'Central Plateau (Region IIa)',
        latitude: -15.3875,
        longitude: 28.3228,
        elevationMeters: 1280,
        isSouthernHemisphere: true,
        frostRiskMonths: [6, 7], // Occasional light frost in low valleys
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [9, 10, 11],
        seasonalNotes:
            'Three distinct seasons: warm wet (Nov–Apr), cool dry (May–Aug), and hot dry (Sep–Nov). Heavy irrigation needed in hot dry season.',
      ),
      const LocationAgroProfile(
        country: 'Zambia',
        countryCode: 'ZM',
        region: 'Copperbelt',
        district: 'Ndola & Kitwe',
        climateZone: 'Northern High Rainfall (Region III)',
        latitude: -12.9694,
        longitude: 28.6366,
        elevationMeters: 1300,
        isSouthernHemisphere: true,
        frostRiskMonths: [],
        wetSeasonMonths: [11, 12, 1, 2, 3, 4],
        hotSeasonMonths: [9, 10, 11],
        seasonalNotes:
            'High annual rainfall. Summer crops face intense foliar disease pressure; winter irrigation is prime for commercial vegetables.',
      ),

      // ==========================================
      // 🇲🇼 MALAWI
      // ==========================================
      const LocationAgroProfile(
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
        seasonalNotes:
            'Subtropical climate with unimodal summer rainy season. Winter dambo and irrigated vegetable gardens are highly productive.',
      ),

      // ==========================================
      // 🇰🇪 KENYA
      // ==========================================
      const LocationAgroProfile(
        country: 'Kenya',
        countryCode: 'KE',
        region: 'Rift Valley / Central',
        district: 'Nakuru & Naivasha',
        climateZone: 'Equatorial Highland (Bimodal)',
        latitude: -0.3031,
        longitude: 36.0800,
        elevationMeters: 1850,
        isSouthernHemisphere: false, // Near Equator
        frostRiskMonths: [], // Rare, only highest peaks
        wetSeasonMonths: [3, 4, 5, 10, 11, 12], // Long rains (Mar-May) & Short rains (Oct-Dec)
        hotSeasonMonths: [1, 2, 3],
        seasonalNotes:
            'Equatorial bimodal rainfall pattern: Long rains (March–May) and Short rains (October–December). Moderate year-round temperatures ideal for horticultural exports.',
      ),
      const LocationAgroProfile(
        country: 'Kenya',
        countryCode: 'KE',
        region: 'Nairobi',
        district: 'Nairobi & Kiambu',
        climateZone: 'Highland Subtropical',
        latitude: -1.2921,
        longitude: 36.8219,
        elevationMeters: 1795,
        isSouthernHemisphere: false,
        frostRiskMonths: [],
        wetSeasonMonths: [3, 4, 5, 10, 11, 12],
        hotSeasonMonths: [1, 2, 3],
        seasonalNotes:
            'Year-round temperate conditions. Two major planting windows matching long and short rains.',
      ),

      // ==========================================
      // 🇳🇬 NIGERIA
      // ==========================================
      const LocationAgroProfile(
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
        seasonalNotes:
            'Single short rainy season (June–September) followed by dry Harmattan period (November–February). Dry season Fadama irrigation is central to tomato/onion output.',
      ),
      const LocationAgroProfile(
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
        wetSeasonMonths: [4, 5, 6, 7, 9, 10], // August break
        hotSeasonMonths: [1, 2, 3],
        seasonalNotes:
            'Bimodal rainfall with early rains (April–July) and late rains (September–November) interrupted by the August dry spell.',
      ),

      // ==========================================
      // 🇬🇭 GHANA
      // ==========================================
      const LocationAgroProfile(
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
        seasonalNotes:
            'Major season (April–July) and minor season (September–November). High relative humidity.',
      ),

      // ==========================================
      // 🇹🇿 TANZANIA
      // ==========================================
      const LocationAgroProfile(
        country: 'Tanzania',
        countryCode: 'TZ',
        region: 'Northern Highlands',
        district: 'Arusha & Kilimanjaro',
        climateZone: 'Volcanic Highland (Bimodal)',
        latitude: -3.3869,
        longitude: 36.6830,
        elevationMeters: 1400,
        isSouthernHemisphere: true,
        frostRiskMonths: [],
        wetSeasonMonths: [3, 4, 5, 10, 11, 12],
        hotSeasonMonths: [1, 2, 3],
        seasonalNotes:
            'Masika (long rains, Mar–May) and Vuli (short rains, Oct–Dec). Very fertile volcanic soils and temperate climate.',
      ),

      // ==========================================
      // 🇧🇼 BOTSWANA
      // ==========================================
      const LocationAgroProfile(
        country: 'Botswana',
        countryCode: 'BW',
        region: 'South-East',
        district: 'Gaborone',
        climateZone: 'Semi-Arid Kalahari Margin',
        latitude: -24.6282,
        longitude: 25.9231,
        elevationMeters: 1010,
        isSouthernHemisphere: true,
        frostRiskMonths: [5, 6, 7], // Frost prone in winter
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [10, 11, 12, 1, 2],
        seasonalNotes:
            'Hot semi-arid climate with high evaporation. 100% drip irrigation required for commercial horticulture. Winter frost in June–July.',
      ),

      // ==========================================
      // 🇳🇦 NAMIBIA
      // ==========================================
      const LocationAgroProfile(
        country: 'Namibia',
        countryCode: 'NA',
        region: 'Khomas',
        district: 'Windhoek',
        climateZone: 'Arid Highland',
        latitude: -22.5609,
        longitude: 17.0658,
        elevationMeters: 1650,
        isSouthernHemisphere: true,
        frostRiskMonths: [5, 6, 7],
        wetSeasonMonths: [1, 2, 3],
        hotSeasonMonths: [10, 11, 12, 1],
        seasonalNotes:
            'Arid climate with low, variable summer rain. Irrigation infrastructure and water conservation techniques are vital.',
      ),

      // ==========================================
      // 🇲🇿 MOZAMBIQUE
      // ==========================================
      const LocationAgroProfile(
        country: 'Mozambique',
        countryCode: 'MZ',
        region: 'Manica & Sofala',
        district: 'Chimoio',
        climateZone: 'Subtropical Plateau',
        latitude: -19.1164,
        longitude: 33.4833,
        elevationMeters: 700,
        isSouthernHemisphere: true,
        frostRiskMonths: [],
        wetSeasonMonths: [11, 12, 1, 2, 3],
        hotSeasonMonths: [10, 11, 12, 1, 2],
        seasonalNotes:
            'Warm subtropical climate with abundant summer rain and frost-free winters suitable for continuous multi-crop vegetable cycles.',
      ),
    ];
  }

  static LocationAgroProfile getDefaultSouthernHemisphereProfile({
    String country = 'Southern Africa',
    String region = 'General Region',
    String district = 'Local District',
    double latitude = -20.0,
    double longitude = 30.0,
  }) {
    return LocationAgroProfile(
      country: country,
      countryCode: 'GEN_SH',
      region: region,
      district: district,
      climateZone: 'Southern Hemisphere Subtropical',
      latitude: latitude,
      longitude: longitude,
      elevationMeters: 1000,
      isSouthernHemisphere: true,
      frostRiskMonths: [6, 7],
      wetSeasonMonths: [11, 12, 1, 2, 3],
      hotSeasonMonths: [10, 11, 12, 1],
      seasonalNotes:
          'Standard Southern Hemisphere seasonal cycle: Summer wet season (Nov–Mar) and Winter dry/cool season (May–Aug).',
    );
  }

  static LocationAgroProfile getDefaultNorthernHemisphereProfile({
    String country = 'Northern Hemisphere',
    String region = 'General Region',
    String district = 'Local District',
    double latitude = 20.0,
    double longitude = 10.0,
  }) {
    return LocationAgroProfile(
      country: country,
      countryCode: 'GEN_NH',
      region: region,
      district: district,
      climateZone: 'Northern Hemisphere Temperate/Subtropical',
      latitude: latitude,
      longitude: longitude,
      elevationMeters: 300,
      isSouthernHemisphere: false,
      frostRiskMonths: [12, 1, 2],
      wetSeasonMonths: [5, 6, 7, 8, 9],
      hotSeasonMonths: [6, 7, 8],
      seasonalNotes:
          'Standard Northern Hemisphere seasonal cycle: Spring/Summer planting (Mar–Jul) and Winter dormancy/frost (Dec–Feb).',
    );
  }
}
