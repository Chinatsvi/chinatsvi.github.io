enum PoultryType {
  broiler,
  layer,
}

/// Comprehensive breed database for automatic purpose detection
class BreedDatabase {
  // ===== LAYER BREEDS (Egg Production) =====
  static const List<String> layerBreeds = [
    // Commercial layer breeds
    'hyline',
    'hy-line',
    'h&n',
    'lohmann',
    'isa brown',
    'isa',
    'shaver',
    'hisex',
    'nickchick',
    'dekalb',
    'novogen',
    'tetra sl',
    'tetra',
    'hisex white',
    'hisex brown',

    // Heritage/Dual-purpose with strong egg production
    'rhode island red',
    'rhode island',
    'rhode',
    'leghorn',
    'white leghorn',
    'brown leghorn',
    'australorp',
    'sussex',
    'wyandotte',
    'orpington',
    'buff orpington',
    'black orpington',
    'blue orpington',
    'red orpington',
    'new hampshire',
    'hamburg',
    'anconas',
    'minorca',
    'polish',
    'araucana',
    'easter egger',
    'black copper maran',
    'copper maran',
    'welsummer',
    'penedesenca',

    // Asian/Ornamental layers
    'cochin',
    'silkie',
    'brahma',
    'brahma cochin',
  ];

  // ===== BROILER BREEDS (Meat Production) =====
  static const List<String> broilerBreeds = [
    // Commercial broiler breeds
    'ross',
    'ross 308',
    'ross 308ff',
    'ross 708',
    'cobb',
    'cobb 500',
    'cobb 700',
    'arbor',
    'arbor acres',
    'hubbard',
    'hubbard classic',
    'hubbard gold',
    'jeghers',

    // Meat-type heritage breeds
    'cornish',
    'cornish rock',
    'cornish cross',
    'cornish game',
    'red broiler',
    'broiler',
    'meat bird',
    'meat type',

    // Dual-purpose heritage (but meat-oriented)
    'plymouth rock',
    'plymouth',
    'rock',
    'wyandotte meat',
    'australorp meat',
  ];

  // ===== DUAL-PURPOSE BREEDS =====
  static const List<String> dualPurposeBreeds = [
    'dual purpose',
    'dual-purpose',
    'pedigree',
    'freedom ranger',
    'ranger',
    'poulet rouge',
    'red ranger',
    'red broiler',
    'black broiler',
    'cotton patch',
  ];

  // ===== BREEDING/SHOW BREEDS =====
  static const List<String> showBreeds = [
    'show',
    'exhibition',
    'bantam',
    'ornamental',
    'seabright',
    'silkie show',
    'polish show',
    'frizzle',
  ];
}

/// Detects poultry purpose based on breed name.
/// Returns 'eggs' for layer breeds, 'meat' for broilers, etc.
String detectPoultryPurpose(String breed) {
  final b = breed.toLowerCase().trim();

  // Check layer breeds
  for (final layerBreed in BreedDatabase.layerBreeds) {
    if (b.contains(layerBreed)) return 'eggs';
  }

  // Check broiler breeds
  for (final broilerBreed in BreedDatabase.broilerBreeds) {
    if (b.contains(broilerBreed)) return 'meat';
  }

  // Check dual-purpose breeds
  for (final dualBreed in BreedDatabase.dualPurposeBreeds) {
    if (b.contains(dualBreed)) return 'dual';
  }

  // Check show/exhibition breeds
  for (final showBreed in BreedDatabase.showBreeds) {
    if (b.contains(showBreed)) return 'show';
  }

  // Default to 'eggs' if not recognized
  return 'eggs';
}

/// Detects poultry type based on breed name (legacy compatibility).
/// Returns [PoultryType.broiler] if breed matches broiler types,
/// otherwise defaults to [PoultryType.layer].
PoultryType detectPoultryType(String breed) {
  final purpose = detectPoultryPurpose(breed);
  return purpose == 'meat' ? PoultryType.broiler : PoultryType.layer;
}
