class Animal {
  final String id;
  final List<String> animalTags;
  final String species; // cattle, goat, sheep, pig, poultry
  final String breed;
  final int ageMonths;
  final String? photoUrl;
  final String? sex; // Male/Female/Mixed
  final int? maleCount;
  final int? femaleCount;
  final double? targetWeightKg; // ✅ OPTIONAL
  final String? purpose; // ✅ NEW: meat, dairy, breeding, show
  final int? initialFlockSize; // For poultry
  final int totalCount;
  final double totalCost;
  final String? currency;
  final String? notes;
  final DateTime createdAt;

  const Animal({
    required this.id,
    this.animalTags = const [],
    required this.species,
    required this.breed,
    required this.ageMonths,
    this.photoUrl,
    this.sex,
    this.maleCount,
    this.femaleCount,
    this.targetWeightKg, // ✅
    this.purpose, // ✅ NEW
    this.initialFlockSize,
    this.totalCount = 1,
    this.totalCost = 0.0,
    this.currency,
    this.notes,
    required this.createdAt,
  });

  Animal copyWith({
    List<String>? animalTags,
    String? species,
    String? breed,
    int? ageMonths,
    String? photoUrl,
    String? sex,
    int? maleCount,
    int? femaleCount,
    double? targetWeightKg,
    String? purpose, // ✅ NEW
    int? initialFlockSize,
    int? totalCount,
    double? totalCost,
    String? currency,
    String? notes,
  }) {
    return Animal(
      id: id,
      animalTags: animalTags ?? this.animalTags,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageMonths: ageMonths ?? this.ageMonths,
      photoUrl: photoUrl ?? this.photoUrl,
      sex: sex ?? this.sex,
      maleCount: maleCount ?? this.maleCount,
      femaleCount: femaleCount ?? this.femaleCount,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      purpose: purpose ?? this.purpose, // ✅ NEW
      initialFlockSize: initialFlockSize ?? this.initialFlockSize,
      totalCount: totalCount ?? this.totalCount,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  String get currencySymbol {
    if (currency != null && currency!.trim().isNotEmpty) {
      final c = currency!.trim();
      final upper = c.toUpperCase();
      if (upper == 'ZAR' || upper == 'R') return 'R';
      if (upper == 'USD' || upper == r'$') return r'$';
      if (upper == 'EUR' || upper == '€') return '€';
      if (upper == 'GBP' || upper == '£') return '£';
      if (upper == 'KES' || upper == 'KSH') return 'KSh';
      if (upper == 'NGN' || upper == '₦') return '₦';
      if (upper == 'UGX' || upper == 'USH') return 'USh';
      if (upper == 'TZS' || upper == 'TSH') return 'TSh';
      if (upper == 'GHS') return 'GH₵';
      if (upper == 'ZMW' || upper == 'ZK') return 'ZK';
      if (upper == 'INR' || upper == '₹') return '₹';
      return c;
    }
    return r'$';
  }

  String formatMoney(double amount) {
    final sym = currencySymbol;
    final space = sym.length > 1 ? ' ' : '';
    if (amount % 1 == 0 || (amount - amount.round()).abs() < 0.00001) {
      return '$sym$space${amount.round()}';
    }
    return '$sym$space${amount.toStringAsFixed(2)}';
  }

  double calculateProfitLoss({double saleRevenue = 0.0}) {
    return saleRevenue - totalCost;
  }

  int get totalFemales {
    if (femaleCount != null) return femaleCount!;
    if (sex?.toLowerCase() == 'female') return totalCount;
    if (sex?.toLowerCase() == 'male') return 0;
    return totalCount;
  }

  int get totalMales {
    if (maleCount != null) return maleCount!;
    if (sex?.toLowerCase() == 'male') return totalCount;
    if (sex?.toLowerCase() == 'female') return 0;
    return 0;
  }

  bool get isDairyPurpose {
    final p = purpose?.toLowerCase() ?? '';
    return p.contains('dairy') || p.contains('milk');
  }

  Animal applyExit({
    int quantity = 1,
    int? maleQuantity,
    int? femaleQuantity,
    String? removedSex,
  }) {
    final reducedTotal = (totalCount - quantity).clamp(0, totalCount);

    int? newMales = maleCount;
    int? newFemales = femaleCount;

    if (maleQuantity != null || femaleQuantity != null) {
      if (maleQuantity != null && newMales != null) {
        newMales = (newMales - maleQuantity).clamp(0, newMales);
      }
      if (femaleQuantity != null && newFemales != null) {
        newFemales = (newFemales - femaleQuantity).clamp(0, newFemales);
      }
    } else if (removedSex != null) {
      final s = removedSex.toLowerCase();
      if (s == 'female' && newFemales != null) {
        newFemales = (newFemales - quantity).clamp(0, newFemales);
      } else if (s == 'male' && newMales != null) {
        newMales = (newMales - quantity).clamp(0, newMales);
      }
    }

    return copyWith(
      totalCount: reducedTotal,
      maleCount: newMales,
      femaleCount: newFemales,
    );
  }

  Animal addActivityCount(int amount, {int? maleAmount, int? femaleAmount}) {
    if (amount <= 0) return this;
    return copyWith(
      totalCount: totalCount + amount,
      maleCount: (maleAmount != null && maleCount != null) ? maleCount! + maleAmount : maleCount,
      femaleCount: (femaleAmount != null && femaleCount != null) ? femaleCount! + femaleAmount : femaleCount,
    );
  }

  bool get isPoultry => species.toLowerCase() == 'poultry';

  int get daysSinceCreation {
    final diff = DateTime.now().difference(createdAt).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get ageInDays {
    if (isPoultry) {
      if (ageMonths == 0 || daysSinceCreation >= ageMonths * 30) {
        return daysSinceCreation;
      }
      return (ageMonths * 30) + daysSinceCreation;
    }
    return (ageMonths * 30.4375).round() + daysSinceCreation;
  }

  int get ageInMonths {
    if (isPoultry) {
      final months = (ageInDays / 30.4375).floor();
      return months < 0 ? 0 : months;
    }
    final additionalMonths = (daysSinceCreation / 30.4375).floor();
    final total = ageMonths + additionalMonths;
    return total < 0 ? 0 : total;
  }

  int get currentAgeMonths => ageInMonths;

  String get ageDisplayLabel {
    if (isPoultry) {
      final days = ageInDays;
      return days == 1 ? '1 day' : '$days days';
    }

    final months = ageInMonths;
    if (months == 0) {
      final days = ageInDays;
      if (days > 0) {
        return days == 1 ? '1 day' : '$days days';
      }
      return '0 months';
    }

    return months == 1 ? '1 month' : '$months months';
  }

  /// Convert Animal to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalTags': animalTags,
      'species': species,
      'breed': breed,
      'ageMonths': ageMonths,
      'photoUrl': photoUrl,
      'sex': sex,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'targetWeightKg': targetWeightKg, // ✅ saved
      'purpose': purpose, // ✅ NEW
      'initialFlockSize': initialFlockSize,
      'totalCount': totalCount,
      'totalCost': totalCost,
      'currency': currency,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create Animal from Firestore Map (SAFE for old records)
  factory Animal.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime createdDate;
    if (createdAtRaw is String) {
      createdDate = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }

    return Animal(
      id: (map['id'] ?? '') as String,
      animalTags: (map['animalTags'] is List)
          ? (map['animalTags'] as List)
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList()
          : const [],
      species: (map['species'] ?? '') as String,
      breed: (map['breed'] ?? '') as String,
      ageMonths: (map['ageMonths'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl'] as String?,
      sex: map['sex'] as String?,
      maleCount: (map['maleCount'] as num?)?.toInt(),
      femaleCount: (map['femaleCount'] as num?)?.toInt(),
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble(), // ✅ SAFE
      purpose: map['purpose'] as String?, // ✅ NEW - safe for old records
      initialFlockSize: (map['initialFlockSize'] as num?)?.toInt(),
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 1,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String?,
      notes: map['notes'] as String?,
      createdAt: createdDate,
    );
  }
}
