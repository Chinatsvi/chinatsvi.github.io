import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryRationPlan {
  final String id;
  final String batchId;
  final String feedType;
  final double proteinPercent;
  final double energyKcal;
  final double dailyIntakeGrams;
  final double? costPerKg; // optional cost per kg of this ration
  final DateTime createdAt;
  final DateTime updatedAt;

  PoultryRationPlan({
    required this.id,
    required this.batchId,
    required this.feedType,
    required this.proteinPercent,
    required this.energyKcal,
    required this.dailyIntakeGrams,
    this.costPerKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'feedType': feedType,
      'proteinPercent': proteinPercent,
      'energyKcal': energyKcal,
      'dailyIntakeGrams': dailyIntakeGrams,
      'costPerKg': costPerKg,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryRationPlan.fromMap(String id, Map<String, dynamic> map) {
    return PoultryRationPlan(
      id: id,
      batchId: map['batchId'],
      feedType: map['feedType'],
      proteinPercent: (map['proteinPercent'] as num).toDouble(),
      energyKcal: (map['energyKcal'] as num).toDouble(),
      dailyIntakeGrams: (map['dailyIntakeGrams'] as num).toDouble(),
      costPerKg: (map['costPerKg'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryRationPlan.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryRationPlan.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryRationPlan copyWith({
    double? proteinPercent,
    double? energyKcal,
    double? dailyIntakeGrams,
    double? costPerKg,
  }) {
    return PoultryRationPlan(
      id: id,
      batchId: batchId,
      feedType: feedType,
      proteinPercent: proteinPercent ?? this.proteinPercent,
      energyKcal: energyKcal ?? this.energyKcal,
      dailyIntakeGrams: dailyIntakeGrams ?? this.dailyIntakeGrams,
      costPerKg: costPerKg ?? this.costPerKg,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Suggests daily feed cost based on intake and cost per kg
  double dailyFeedCost() {
    if (costPerKg == null) return 0;
    return (dailyIntakeGrams / 1000) * costPerKg!;
  }

  /// Advisory for the farmer
  String advisory() {
    if (proteinPercent < 18) {
      return 'Protein is low. Consider adjusting ingredients for better growth.';
    }
    return 'Ration is within optimal protein range.';
  }
}
