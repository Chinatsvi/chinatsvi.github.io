import 'package:cloud_firestore/cloud_firestore.dart';
import 'poultry_type.dart'; // import your detectPoultryType utility

class PoultryBatch {
  final String id;

  // Identity
  final String name;
  final String breed;
  final String? purpose; // ✅ NEW: meat, eggs, breeding, show, other
  final int? ageWeeks; // ✅ NEW: Age in weeks at registration

  // Numbers
  final int initialCount; // birds at start
  final int currentCount; // live birds now
  final double? chickCost; // ✅ NEW: Cost per batch (stored in same field `chickCost`)
  final double? initialAverageWeightKg; // ✅ NEW: average bird weight at registration

  // Dates
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional
  final String? photoUrl;
  final String? notes;
  final String? userId;

  PoultryBatch({
    required this.id,
    required this.name,
    required this.breed,
    this.purpose, // ✅ NEW
    this.ageWeeks, // ✅ NEW
    required this.initialCount,
    required this.currentCount,
    this.chickCost, // ✅ NEW
    this.initialAverageWeightKg,
    this.userId,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.notes,
  });

  /* ───────────────────── AUTO LOGIC ───────────────────── */

  /// Determines type based on explicit purpose if set, otherwise detects from breed
  PoultryType get type {
    // Priority 1: Use explicit purpose if set
    if (purpose != null) {
      if (purpose == 'meat') return PoultryType.broiler;
      if (purpose == 'eggs') return PoultryType.layer;
      // For other purposes (breeding, show, dual, other), default to layer
      // since they may still produce eggs
      return PoultryType.layer;
    }
    // Priority 2: Fall back to breed-based detection
    return detectPoultryType(breed);
  }

  /// Returns true only if explicitly set to meat production or detected as broiler
  bool get isBroiler => type == PoultryType.broiler;
  
  /// Returns true only if explicitly set to egg production or detected as layer
  /// Does NOT show for meat production, even if breed suggests layers
  bool get isLayer {
    final purposeLower = purpose?.toLowerCase() ?? '';
    // Hide Egg Production tab only for meat production (broilers)
    if (purposeLower.contains('meat') || purposeLower == 'meat') {
      return false;
    }
    // Show Egg Production tab for all other purposes
    // Including: eggs, breeding, show, dual, other
    return type == PoultryType.layer;
  }

  int get ageInDays => DateTime.now().difference(startDate).inDays;
  int get ageInWeeks => (ageInDays / 7).floor();

  double get mortalityRate {
    if (initialCount == 0) return 0;
    return ((initialCount - currentCount) / initialCount) * 100;
  }

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'purpose': purpose, // NEW
      'ageWeeks': ageWeeks, // NEW
      'initialCount': initialCount,
      'currentCount': currentCount,
      'userId': userId,
      'chickCost': chickCost, // NEW (interpreted as batch cost)
      'startDate': Timestamp.fromDate(startDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'photoUrl': photoUrl,
      'notes': notes,
      'initialAverageWeightKg': initialAverageWeightKg,
    };
  }

  factory PoultryBatch.fromMap(String id, Map<String, dynamic> map) {
    return PoultryBatch(
      id: id,
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      purpose: map['purpose'] as String?, // NEW - safe for old records
      ageWeeks: map['ageWeeks'], // NEW
      initialCount: map['initialCount'] ?? map['count'] ?? 0,
      currentCount: map['currentCount'] ?? map['count'] ?? 0,
      chickCost: map['chickCost']?.toDouble(), // NEW (interpreted as batch cost)
      initialAverageWeightKg: map['initialAverageWeightKg']?.toDouble(), // NEW
      userId: map['userId'] as String?,
      startDate: (map['startDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'],
      notes: map['notes'],
    );
  }

  factory PoultryBatch.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryBatch.fromMap(doc.id, data);
  }

  PoultryBatch copyWith({
    String? name,
    String? breed,
    String? purpose, // ✅ NEW
    int? ageWeeks, // ✅ NEW
    int? initialCount,
    int? currentCount,
    DateTime? startDate,
    DateTime? updatedAt,
    String? photoUrl,
    String? notes,
    double? initialAverageWeightKg,
    String? userId,
  }) {
    return PoultryBatch(
      id: id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      purpose: purpose ?? this.purpose, // ✅ NEW
      ageWeeks: ageWeeks ?? this.ageWeeks, // ✅ NEW
      initialCount: initialCount ?? this.initialCount,
      currentCount: currentCount ?? this.currentCount,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      initialAverageWeightKg: initialAverageWeightKg ?? this.initialAverageWeightKg,
      userId: userId ?? this.userId,
    );
  }
}

class PoultryRequirement {
  static double targetProtein({
    required String poultryType, // broiler | layer
    required int ageDays,
    double eggProduction = 0,
  }) {
    if (poultryType == 'broiler') {
      if (ageDays <= 14) return 22;
      if (ageDays <= 28) return 20;
      return 18;
    }

    // Layers
    if (eggProduction >= 80) return 18;
    if (eggProduction >= 60) return 17;
    return 16;
  }
}
