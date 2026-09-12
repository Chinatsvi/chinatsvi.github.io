import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryProductionRecord {
  final String id;
  final String batchId;
  final DateTime date;
  final int eggsCollected;
  final int eggsSold;
  final int eggsBroken;
  final double? revenue; // income from sold eggs
  final DateTime createdAt;
  final DateTime updatedAt;

  PoultryProductionRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.eggsCollected,
    this.eggsSold = 0,
    this.eggsBroken = 0,
    this.revenue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'eggsCollected': eggsCollected,
      'eggsSold': eggsSold,
      'eggsBroken': eggsBroken,
      'revenue': revenue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryProductionRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryProductionRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      eggsCollected: map['eggsCollected'] ?? 0,
      eggsSold: map['eggsSold'] ?? 0,
      eggsBroken: map['eggsBroken'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryProductionRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryProductionRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryProductionRecord copyWith({
    DateTime? date,
    int? eggsCollected,
    int? eggsSold,
    int? eggsBroken,
    double? revenue,
  }) {
    return PoultryProductionRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsSold: eggsSold ?? this.eggsSold,
      eggsBroken: eggsBroken ?? this.eggsBroken,
      revenue: revenue ?? this.revenue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Advisory based on production
  String productionAdvisory(int targetEggsPerDay) {
    if (eggsCollected < targetEggsPerDay) {
      return 'Production below target. Check feed, health, and environment.';
    }
    return 'Production on target. Maintain current management.';
  }

  /// Calculate egg laying percentage
  double calculateLayingPercentage(int flockSize) {
    if (flockSize <= 0) return 0.0;
    return (eggsCollected / flockSize) * 100;
  }

  /// Calculate available eggs (collected - sold - broken)
  int get availableEggs => eggsCollected - eggsSold - eggsBroken;

  /// Calculate total losses (broken eggs)
  int get totalLosses => eggsBroken;

  /// Calculate sales percentage
  double calculateSalesPercentage() {
    if (eggsCollected <= 0) return 0.0;
    return (eggsSold / eggsCollected) * 100;
  }

  /// Calculate breakage percentage
  double calculateBreakagePercentage() {
    if (eggsCollected <= 0) return 0.0;
    return (eggsBroken / eggsCollected) * 100;
  }
}
