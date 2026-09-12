import 'package:cloud_firestore/cloud_firestore.dart';

class PoultryMortalityRecord {
  final String id;
  final String batchId;
  final DateTime date;
  final int deaths;
  final String? notes;
  final double? costLoss; // value lost due to mortality
  final DateTime createdAt;
  final DateTime updatedAt;

  PoultryMortalityRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.deaths,
    this.notes,
    this.costLoss,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /* ───────────────────── FIRESTORE ───────────────────── */

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'date': Timestamp.fromDate(date),
      'deaths': deaths,
      'notes': notes,
      'costLoss': costLoss,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PoultryMortalityRecord.fromMap(String id, Map<String, dynamic> map) {
    return PoultryMortalityRecord(
      id: id,
      batchId: map['batchId'],
      date: (map['date'] as Timestamp).toDate(),
      deaths: map['deaths'],
      notes: map['notes'],
      costLoss: (map['costLoss'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoultryMortalityRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoultryMortalityRecord.fromMap(doc.id, data);
  }

  /* ───────────────────── UTIL ───────────────────── */

  PoultryMortalityRecord copyWith({
    DateTime? date,
    int? deaths,
    String? notes,
    double? costLoss,
  }) {
    return PoultryMortalityRecord(
      id: id,
      batchId: batchId,
      date: date ?? this.date,
      deaths: deaths ?? this.deaths,
      notes: notes ?? this.notes,
      costLoss: costLoss ?? this.costLoss,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Advisory for farmer
  String mortalityAdvisory() {
    if (deaths > 0) {
      return 'Check flock management and health practices. Investigate cause of deaths.';
    }
    return 'Mortality low, maintain hygiene and feeding protocols.';
  }
}
