import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryFeedingRecord {
  final String id;
  final String batchId;

  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String feedType; // starter, grower, finisher, layer mash
  final double quantityKg;
  final double? cost; // total cost of feed for this entry (recorded for stock addition)
  final double? proteinPercent; // optional
  final String? notes;
  final String? recordType; // 'stock_addition' or 'daily_feeding'
  final double? bagsCount;
  final double? bagSizeKg;
  final String? unit; // 'bags' or 'kg'

  PoultryFeedingRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    this.cost,
    this.proteinPercent,
    this.notes,
    this.recordType,
    this.bagsCount,
    this.bagSizeKg,
    this.unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isStockAddition =>
      recordType == 'stock_addition' || (cost != null && cost! > 0 && recordType != 'daily_feeding');

  /* ───────────────────── AUTO LOGIC ───────────────────── */

  double feedPerBird(int flockSize) {
    if (flockSize <= 0) return 0;
    return quantityKg / flockSize;
  }

  String advisory(int flockSize, double targetFeedPerBird) {
    final perBird = feedPerBird(flockSize);
    if (perBird < targetFeedPerBird) {
      return 'Feed below target per bird. Increase rations to meet growth goals.';
    } else if (perBird > targetFeedPerBird * 1.2) {
      return 'Feed is above target. Consider optimizing feed to reduce cost.';
    }
    return 'Feed is on target.';
  }

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'feedType': feedType,
      'quantityKg': quantityKg,
      'cost': cost,
      'proteinPercent': proteinPercent,
      'notes': notes,
      'recordType': recordType,
      'bagsCount': bagsCount,
      'bagSizeKg': bagSizeKg,
      'unit': unit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryFeedingRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryFeedingRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      feedType: map['feedType'],
      quantityKg: (map['quantityKg'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      proteinPercent: (map['proteinPercent'] as num?)?.toDouble(),
      notes: map['notes'],
      recordType: map['recordType'] as String?,
      bagsCount: (map['bagsCount'] as num?)?.toDouble(),
      bagSizeKg: (map['bagSizeKg'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryFeedingRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryFeedingRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryFeedingRecord copyWith({
    DateTime? date,
    String? feedType,
    double? quantityKg,
    double? cost,
    double? proteinPercent,
    String? notes,
    String? recordType,
    double? bagsCount,
    double? bagSizeKg,
    String? unit,
  }) {
    return PoultryFeedingRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      feedType: feedType ?? this.feedType,
      quantityKg: quantityKg ?? this.quantityKg,
      cost: cost ?? this.cost,
      proteinPercent: proteinPercent ?? this.proteinPercent,
      notes: notes ?? this.notes,
      recordType: recordType ?? this.recordType,
      bagsCount: bagsCount ?? this.bagsCount,
      bagSizeKg: bagSizeKg ?? this.bagSizeKg,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
