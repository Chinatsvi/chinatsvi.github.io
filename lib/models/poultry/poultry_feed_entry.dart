import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryFeedEntry {
  final String id;
  final String batchId;

  /// Core feed data
  final DateTime date;
  final String feedType;
  final double quantityKg;

  /// Nutrition intelligence
  final double proteinPercent; // % CP
  final double energyMj; // MJ/kg

  /// Cost intelligence
  final double costPerKg;
  final double totalCost;

  /// Performance tracking
  final int birdsCount;
  final double feedPerBirdKg;

  /// Advisory & warnings
  final String advisoryNote;

  /// Audit fields
  final DateTime createdAt;

  PoultryFeedEntry({
    required this.id,
    required this.batchId,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    required this.proteinPercent,
    required this.energyMj,
    required this.costPerKg,
    required this.totalCost,
    required this.birdsCount,
    required this.feedPerBirdKg,
    required this.advisoryNote,
    required this.createdAt,
  });

  /* -------------------- Firestore Mapping -------------------- */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'feedType': feedType,
      'quantityKg': quantityKg,

      // Nutrition
      'proteinPercent': proteinPercent,
      'energyMj': energyMj,

      // Cost
      'costPerKg': costPerKg,
      'totalCost': totalCost,

      // Performance
      'birdsCount': birdsCount,
      'feedPerBirdKg': feedPerBirdKg,

      // Advisory
      'advisoryNote': advisoryNote,

      // Audit
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PoultryFeedEntry.fromMap(Map<String, dynamic> map) {
    return PoultryFeedEntry(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      feedType: map['feedType'] as String,
      quantityKg: (map['quantityKg'] as num).toDouble(),

      proteinPercent: (map['proteinPercent'] as num).toDouble(),
      energyMj: (map['energyMj'] as num).toDouble(),

      costPerKg: (map['costPerKg'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),

      birdsCount: (map['birdsCount'] as num).toInt(),
      feedPerBirdKg: (map['feedPerBirdKg'] as num).toDouble(),

      advisoryNote: map['advisoryNote'] as String,

      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory PoultryFeedEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryFeedEntry.fromMap(data);
  }
}
