import 'package:cloud_firestore/cloud_firestore.dart';

class MilkProductionRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String? cowIdentifier; // e.g. "Cattle A", "Cattle B", "Cattle 1", "Cow #101"
  final double morningLiters;
  final double eveningLiters;
  final double totalLiters;
  final double litersSold;
  final double? pricePerLiter;
  final double? revenue;
  final double litersConsumed;
  final double litersSpoiled;
  final double? spoiledCost;
  final int? milkingFemalesCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MilkProductionRecord({
    required this.id,
    required this.animalId,
    required this.date,
    this.cowIdentifier,
    this.morningLiters = 0.0,
    this.eveningLiters = 0.0,
    double? totalLiters,
    this.litersSold = 0.0,
    this.pricePerLiter,
    double? revenue,
    this.litersConsumed = 0.0,
    this.litersSpoiled = 0.0,
    this.spoiledCost,
    this.milkingFemalesCount,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : totalLiters = totalLiters ?? (morningLiters + eveningLiters),
        revenue = revenue ?? ((pricePerLiter != null && pricePerLiter > 0) ? (litersSold * pricePerLiter) : null),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': Timestamp.fromDate(date),
      'cowIdentifier': cowIdentifier,
      'morningLiters': morningLiters,
      'eveningLiters': eveningLiters,
      'totalLiters': totalLiters,
      'litersSold': litersSold,
      'pricePerLiter': pricePerLiter,
      'revenue': revenue,
      'litersConsumed': litersConsumed,
      'litersSpoiled': litersSpoiled,
      'spoiledCost': spoiledCost,
      'milkingFemalesCount': milkingFemalesCount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MilkProductionRecord.fromMap(String id, Map<String, dynamic> map) {
    final dateVal = map['date'];
    DateTime recordDate;
    if (dateVal is Timestamp) {
      recordDate = dateVal.toDate();
    } else if (dateVal is String) {
      recordDate = DateTime.tryParse(dateVal) ?? DateTime.now();
    } else {
      recordDate = DateTime.now();
    }

    final createdVal = map['createdAt'];
    DateTime createdDate = createdVal is Timestamp ? createdVal.toDate() : DateTime.now();

    final updatedVal = map['updatedAt'];
    DateTime updatedDate = updatedVal is Timestamp ? updatedVal.toDate() : DateTime.now();

    final morning = (map['morningLiters'] as num?)?.toDouble() ?? 0.0;
    final evening = (map['eveningLiters'] as num?)?.toDouble() ?? 0.0;
    final total = (map['totalLiters'] as num?)?.toDouble() ?? (morning + evening);

    return MilkProductionRecord(
      id: id,
      animalId: (map['animalId'] ?? '') as String,
      date: recordDate,
      cowIdentifier: map['cowIdentifier'] as String?,
      morningLiters: morning,
      eveningLiters: evening,
      totalLiters: total,
      litersSold: (map['litersSold'] as num?)?.toDouble() ?? 0.0,
      pricePerLiter: (map['pricePerLiter'] as num?)?.toDouble(),
      revenue: (map['revenue'] as num?)?.toDouble(),
      litersConsumed: (map['litersConsumed'] as num?)?.toDouble() ?? 0.0,
      litersSpoiled: (map['litersSpoiled'] as num?)?.toDouble() ?? 0.0,
      spoiledCost: (map['spoiledCost'] as num?)?.toDouble(),
      milkingFemalesCount: (map['milkingFemalesCount'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  factory MilkProductionRecord.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MilkProductionRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── COPY & UTILS ───────────────────── */

  MilkProductionRecord copyWith({
    DateTime? date,
    String? cowIdentifier,
    double? morningLiters,
    double? eveningLiters,
    double? totalLiters,
    double? litersSold,
    double? pricePerLiter,
    double? revenue,
    double? litersConsumed,
    double? litersSpoiled,
    double? spoiledCost,
    int? milkingFemalesCount,
    String? notes,
  }) {
    final m = morningLiters ?? this.morningLiters;
    final e = eveningLiters ?? this.eveningLiters;
    final tot = totalLiters ?? (morningLiters != null || eveningLiters != null ? (m + e) : this.totalLiters);
    final sold = litersSold ?? this.litersSold;
    final price = pricePerLiter ?? this.pricePerLiter;
    final rev = revenue ?? ((price != null && price > 0) ? (sold * price) : this.revenue);

    return MilkProductionRecord(
      id: id,
      animalId: animalId,
      date: date ?? this.date,
      cowIdentifier: cowIdentifier ?? this.cowIdentifier,
      morningLiters: m,
      eveningLiters: e,
      totalLiters: tot,
      litersSold: sold,
      pricePerLiter: price,
      revenue: rev,
      litersConsumed: litersConsumed ?? this.litersConsumed,
      litersSpoiled: litersSpoiled ?? this.litersSpoiled,
      spoiledCost: spoiledCost ?? this.spoiledCost,
      milkingFemalesCount: milkingFemalesCount ?? this.milkingFemalesCount,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Calculates the effective financial loss/cost caused by spoiled milk
  double get effectiveSpoilCost {
    if (spoiledCost != null && spoiledCost! > 0) return spoiledCost!;
    if (pricePerLiter != null && pricePerLiter! > 0 && litersSpoiled > 0) {
      return litersSpoiled * pricePerLiter!;
    }
    return 0.0;
  }

  /// Net remaining milk for this day after subtracting sold, consumed, and spoiled
  double get netRemainingLiters {
    final remaining = totalLiters - litersSold - litersConsumed - litersSpoiled;
    return remaining < 0 ? 0.0 : remaining;
  }

  /// Average yield per female on this day
  double averageYieldPerFemale(int activeFemales) {
    final count = (milkingFemalesCount != null && milkingFemalesCount! > 0) ? milkingFemalesCount! : activeFemales;
    if (count <= 0) return 0.0;
    return totalLiters / count;
  }

  /// Active milking rate percentage on this day
  double milkingRatePercentage(int totalFemales) {
    if (totalFemales <= 0) return 0.0;
    final count = (milkingFemalesCount != null && milkingFemalesCount! > 0) ? milkingFemalesCount! : totalFemales;
    return (count / totalFemales) * 100;
  }
}
