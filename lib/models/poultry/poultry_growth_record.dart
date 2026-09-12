import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryGrowthRecord {
  final String id;
  final String batchId;
  final DateTime date;
  final double averageWeightKg;
  final int ageDays; // can be calculated automatically if needed

  // Optional fields for better integration
  final double? targetWeightKg;
  final String? notes; // tips for farmer
  final DateTime createdAt;
  final DateTime updatedAt;

  PoultryGrowthRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.averageWeightKg,
    required this.ageDays,
    this.targetWeightKg,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── AUTO LOGIC ───────────────────── */

  // Suggest feeding tips based on growth and target weight
  String growthAdvisory() {
    if (targetWeightKg == null) return 'No target set.';
    if (averageWeightKg < targetWeightKg! * 0.9) {
      return 'Birds are under target weight. Increase feed quantity or quality.';
    } else if (averageWeightKg > targetWeightKg! * 1.1) {
      return 'Birds are above target weight. Check feed cost efficiency.';
    }
    return 'Growth on target. Maintain current feed plan.';
  }

  // Optionally, calculate growth rate per day
  double dailyGain() {
    if (ageDays <= 0) return 0;
    return averageWeightKg / ageDays;
  }

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'averageWeightKg': averageWeightKg,
      'ageDays': ageDays,
      'targetWeightKg': targetWeightKg,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryGrowthRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryGrowthRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      averageWeightKg: (map['averageWeightKg'] as num).toDouble(),
      ageDays: map['ageDays'],
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryGrowthRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryGrowthRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryGrowthRecord copyWith({
    DateTime? date,
    double? averageWeightKg,
    int? ageDays,
    double? targetWeightKg,
    String? notes,
  }) {
    return PoultryGrowthRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      averageWeightKg: averageWeightKg ?? this.averageWeightKg,
      ageDays: ageDays ?? this.ageDays,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
