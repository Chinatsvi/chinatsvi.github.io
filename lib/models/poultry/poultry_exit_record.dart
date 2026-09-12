import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryExitRecord {
  final String id;
  final String batchId;

  // Dates
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Exit data
  final int quantity;
  final String reason; // sold, slaughtered, culled
  final double? income; // amount received
  final double? totalCost; // cost of birds exited

  // Notes
  final String? notes;

  PoultryExitRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.quantity,
    required this.reason,
    this.income,
    this.totalCost,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /* ───────────────────── AUTO LOGIC ───────────────────── */

  double get profit {
    if (income == null || totalCost == null) return 0;
    return income! - totalCost!;
  }

  bool get isSold => reason.toLowerCase() == 'sold';
  bool get isSlaughtered => reason.toLowerCase() == 'slaughtered';
  bool get isCulled => reason.toLowerCase() == 'culled';

  String get advisory {
    if (isSold && profit < 0) {
      return 'Loss made on sales. Review pricing or feed costs.';
    } else if (isSold && profit >= 0) {
      return 'Profit made on sales. Good management!';
    } else if (isSlaughtered) {
      return 'Birds slaughtered for consumption. Track feed efficiency.';
    } else if (isCulled) {
      return 'Birds culled due to poor performance or health.';
    }
    return '';
  }

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'quantity': quantity,
      'reason': reason,
      'income': income,
      'totalCost': totalCost,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryExitRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryExitRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      quantity: (map['quantity'] as num).toInt(),
      reason: map['reason'],
      income: (map['income'] as num?)?.toDouble(),
      totalCost: (map['totalCost'] as num?)?.toDouble(),
      notes: map['notes'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryExitRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryExitRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryExitRecord copyWith({
    DateTime? date,
    int? quantity,
    String? reason,
    double? income,
    double? totalCost,
    String? notes,
  }) {
    return PoultryExitRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      income: income ?? this.income,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
