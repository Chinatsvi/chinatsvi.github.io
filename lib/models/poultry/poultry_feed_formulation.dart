// Simple smart feed formulation for farmers

enum FeedCategory { energy, protein, mineral }

/// Common feed ingredients with their protein content (the app knows this)
class FeedIngredient {
  final String name;
  final double protein; // Protein percentage
  final String icon; // Emoji for visual appeal
  final FeedCategory category; // Energy or Protein source

  FeedIngredient({
    required this.name,
    required this.protein,
    required this.icon,
    required this.category,
  });
}

/// Smart feed formulation result
class FeedResult {
  final Map<String, double> mixKg; // ingredient -> kg needed
  final double achievedProtein; // final protein %
  final int totalBirds; // number of birds
  final String feedType; // broiler/layer
  final int ageWeeks; // bird age

  FeedResult({
    required this.mixKg,
    required this.achievedProtein,
    required this.totalBirds,
    required this.feedType,
    required this.ageWeeks,
  });
}

/// Smart Feed Calculator - knows what farmers need
class SmartFeedCalculator {
  // Common feeds and their protein content (farmer doesn't need to know this)
  // Categorized as Energy sources (low protein) or Protein sources (high protein)
  static final List<FeedIngredient> commonFeeds = [
    // Energy Sources (low protein, < 15%)
    FeedIngredient(
      name: 'Maize',
      protein: 8.5,
      icon: '🌽',
      category: FeedCategory.energy,
    ),
    FeedIngredient(
      name: 'Bone Meal',
      protein: 0.0,
      icon: '🦴',
      category: FeedCategory.mineral,
    ),
    FeedIngredient(
      name: 'Wheat Bran',
      protein: 14.0,
      icon: '🌾',
      category: FeedCategory.energy,
    ),
    FeedIngredient(
      name: 'Rice Bran',
      protein: 13.0,
      icon: '🌾',
      category: FeedCategory.energy,
    ),
    FeedIngredient(
      name: 'Oats',
      protein: 12.0,
      icon: '🥣',
      category: FeedCategory.energy,
    ),
    // Protein Sources (high protein, >= 15%)
    FeedIngredient(
      name: 'Soybeans',
      protein: 44.0,
      icon: '🫘',
      category: FeedCategory.protein,
    ),
    FeedIngredient(
      name: 'Sunflower Cake',
      protein: 32.0,
      icon: '🌻',
      category: FeedCategory.protein,
    ),
    FeedIngredient(
      name: 'Groundnut Cake',
      protein: 45.0,
      icon: '🥜',
      category: FeedCategory.protein,
    ),
    FeedIngredient(
      name: 'Fish Meal',
      protein: 65.0,
      icon: '🐟',
      category: FeedCategory.protein,
    ),
    FeedIngredient(
      name: 'Blood Meal',
      protein: 80.0,
      icon: '🩸',
      category: FeedCategory.protein,
    ),
  ];

  /// Get energy sources only
  static List<FeedIngredient> get energySources =>
      commonFeeds.where((f) => f.category == FeedCategory.energy).toList();

  /// Get protein sources only
  static List<FeedIngredient> get proteinSources =>
      commonFeeds.where((f) => f.category == FeedCategory.protein).toList();

  /// Validate that selection has exactly one energy and one protein source.
  static String? validateSelection(List<String> selectedFeeds) {
    final selectedIngredients = commonFeeds
      .where((feed) => selectedFeeds.contains(feed.name))
      .toList();

    // Exclude mineral-only ingredients from energy/protein counts
    final energyCount = selectedIngredients
      .where((f) => f.category == FeedCategory.energy)
      .length;
    final proteinCount = selectedIngredients
      .where((f) => f.category == FeedCategory.protein)
      .length;

    if (energyCount == 0) {
      return "Please select at least 1 energy source (e.g., Maize, Wheat Bran)";
    }
    if (proteinCount == 0) {
      return "Please select at least 1 protein source (e.g., Soybeans, Fish Meal)";
    }
    if (energyCount > 1) {
      return "Select only 1 energy source. Remove the extra energy feed before calculating.";
    }
    if (proteinCount > 1) {
      return "Select only 1 protein source. Remove the extra protein feed before calculating.";
    }

    return null;
  }

  /// Calculate protein requirement based on poultry type and age
  static double getRequiredProtein({
    required String feedType, // 'broiler' or 'layer'
    required int ageWeeks,
  }) {
    // More granular CP% recommendations by age (weeks)
    if (feedType.toLowerCase() == 'broiler') {
      if (ageWeeks <= 1) return 24.0; // Day-old/Starter
      if (ageWeeks <= 3) return 22.0; // Starter
      if (ageWeeks <= 5) return 20.0; // Grower
      if (ageWeeks <= 7) return 18.0; // Finisher
      return 16.0; // Maintenance/Finish
    } else {
      // Layers - pullet and layer phases
      if (ageWeeks <= 4) return 20.0; // Pullet starter
      if (ageWeeks <= 12) return 18.0; // Pullet grower
      if (ageWeeks <= 20) return 16.0; // Pre-lay
      // Laying birds: production-phase protein slightly higher
      if (ageWeeks <= 40) return 18.0; // Layer (production)
      return 16.0; // Older birds maintenance
    }
  }

  /// Smart feed formulation - app does all the work
  static FeedResult formulateSmartFeed({
    required List<String> availableFeeds, // Farmer selects what they have
    required String feedType, // From registration
    required int ageWeeks, // From growth tracker
    required int totalBirds, // From registration
    double dailyFeedPerBird = 0.12, // kg per bird per day
  }) {
    final validationError = validateSelection(availableFeeds);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final double targetProtein = getRequiredProtein(
      feedType: feedType,
      ageWeeks: ageWeeks,
    );

    final selectedIngredients = commonFeeds
        .where((f) => availableFeeds.contains(f.name))
        .toList();

    final energyGroup = selectedIngredients
        .where((f) => f.category == FeedCategory.energy)
        .toList();
    final proteinGroup = selectedIngredients
        .where((f) => f.category == FeedCategory.protein)
        .toList();

    final double energyAvgProtein = energyGroup
            .map((f) => f.protein)
            .reduce((a, b) => a + b) /
        energyGroup.length;
    final double proteinAvgProtein = proteinGroup
            .map((f) => f.protein)
            .reduce((a, b) => a + b) /
        proteinGroup.length;

    if (targetProtein <= energyAvgProtein ||
        targetProtein >= proteinAvgProtein) {
      throw Exception(
        'Selected feeds can\'t reach ${targetProtein.toStringAsFixed(1)}% protein. '
        'Try a higher-protein source (e.g. Fish Meal) or a lower-protein energy source.',
      );
    }

    final double proteinSideParts = targetProtein - energyAvgProtein;
    final double energySideParts = proteinAvgProtein - targetProtein;
    final double totalParts = proteinSideParts + energySideParts;

    final double totalDailyFeed = totalBirds * dailyFeedPerBird;

    final double energySideKg =
        (energySideParts / totalParts) * totalDailyFeed;
    final double proteinSideKg =
        (proteinSideParts / totalParts) * totalDailyFeed;

    final Map<String, double> mix = {};

    final double perEnergyFeed = energySideKg / energyGroup.length;
    for (final f in energyGroup) {
      mix[f.name] = double.parse(perEnergyFeed.toStringAsFixed(2));
    }

    final double perProteinFeed = proteinSideKg / proteinGroup.length;
    for (final f in proteinGroup) {
      mix[f.name] = double.parse(perProteinFeed.toStringAsFixed(2));
    }

    double totalProtein = 0;
    double totalKg = 0;
    for (final f in selectedIngredients) {
      final kg = mix[f.name] ?? 0;
      totalProtein += kg * f.protein;
      totalKg += kg;
    }
    final double achievedProtein = totalKg > 0 ? totalProtein / totalKg : 0;

    return FeedResult(
      mixKg: mix,
      achievedProtein: double.parse(achievedProtein.toStringAsFixed(1)),
      totalBirds: totalBirds,
      feedType: feedType,
      ageWeeks: ageWeeks,
    );
  }

  /// Get feed ingredient by name
  static FeedIngredient? getIngredient(String name) {
    try {
      return commonFeeds.firstWhere((feed) => feed.name == name);
    } catch (e) {
      return null;
    }
  }
}
