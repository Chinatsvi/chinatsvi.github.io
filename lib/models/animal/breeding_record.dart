// lib/model/animal/breeding_record.dart
class BreedingRecord {
  final String id;
  final String animalId;
  final DateTime date; // breeding/insemination date
  final String method; // e.g., natural service, AI
  final String? sireId; // optional: link to sire animal
  final String? sireName; // optional: sire name if not linked
  final DateTime? expectedDueDate;
  final String? notes;
  final double? cost; // cost of breeding service
  final bool deleted; // soft delete flag

  const BreedingRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.method,
    this.sireId,
    this.sireName,
    this.expectedDueDate,
    this.notes,
    this.cost,
    this.deleted = false,
  });

  /// Convert BreedingRecord to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'method': method,
      'sireId': sireId,
      'sireName': sireName,
      'expectedDueDate': expectedDueDate?.toIso8601String(),
      'notes': notes,
      'cost': cost,
      'deleted': deleted,
    };
  }

  /// Create BreedingRecord from Firestore Map
  factory BreedingRecord.fromMap(Map<String, dynamic> map) {
    return BreedingRecord(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      date: DateTime.parse(map['date'] as String),
      method: map['method'] as String,
      sireId: map['sireId'] as String?,
      sireName: map['sireName'] as String?,
      expectedDueDate: map['expectedDueDate'] != null
          ? DateTime.parse(map['expectedDueDate'] as String)
          : null,
      notes: map['notes'] as String?,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      deleted: map['deleted'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  BreedingRecord copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    String? method,
    String? sireId,
    String? sireName,
    DateTime? expectedDueDate,
    String? notes,
    double? cost,
    bool? deleted,
  }) {
    return BreedingRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      method: method ?? this.method,
      sireId: sireId ?? this.sireId,
      sireName: sireName ?? this.sireName,
      expectedDueDate: expectedDueDate ?? this.expectedDueDate,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      deleted: deleted ?? this.deleted,
    );
  }
}
