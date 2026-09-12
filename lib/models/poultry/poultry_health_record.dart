import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryHealthRecord {
  final String id;
  final String batchId;
  final DateTime date;
  final String type; // vaccination, treatment, deworming, etc.
  final String? product;
  final String? notes;
  final double? cost; // cost of medicine or vaccine
  final DateTime createdAt;
  final DateTime updatedAt;

  PoultryHealthRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.type,
    this.product,
    this.notes,
    this.cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'type': type,
      'product': product,
      'notes': notes,
      'cost': cost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryHealthRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryHealthRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'],
      product: map['product'],
      notes: map['notes'],
      cost: (map['cost'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryHealthRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryHealthRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  /// Copy with for easy updates
  PoultryHealthRecord copyWith({
    DateTime? date,
    String? type,
    String? product,
    String? notes,
    double? cost,
  }) {
    return PoultryHealthRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      type: type ?? this.type,
      product: product ?? this.product,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Advisory based on type
  String healthAdvisory() {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return 'Ensure proper vaccination schedule is followed.';
      case 'treatment':
        return 'Monitor birds closely after treatment.';
      case 'deworming':
        return 'Maintain hygiene to prevent re-infestation.';
      default:
        return 'Regular health check recommended.';
    }
  }
}
