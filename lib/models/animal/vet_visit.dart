// lib/model/animal/vet_visit.dart
class VetVisit {
  final String id;
  final String animalId;
  final DateTime visitDate;
  final String vetName;
  final String? notes;
  final double? cost; // NEW FIELD
  final bool deleted; // NEW FIELD for soft delete

  const VetVisit({
    required this.id,
    required this.animalId,
    required this.visitDate,
    required this.vetName,
    this.notes,
    this.cost, //
    this.deleted = false, // default to not deleted
  });

  /// Convert VetVisit to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'visitDate': visitDate.toIso8601String(),
      'vetName': vetName,
      'notes': notes,
      'cost': cost, // include cost
      'deleted': deleted, // include deleted flag
    };
  }

  /// Create VetVisit from Firestore Map
  factory VetVisit.fromMap(Map<String, dynamic> map) {
    return VetVisit(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      visitDate: DateTime.parse(map['visitDate'] as String),
      vetName: map['vetName'] as String,
      notes: map['notes'] as String?,
      cost: map['cost'] != null
          ? (map['cost'] as num).toDouble()
          : null, // parse cost safely
      deleted: map['deleted'] as bool? ?? false, // parse deleted flag safely
    );
  }

  /// Create a copy with updated fields
  VetVisit copyWith({
    String? id,
    String? animalId,
    DateTime? visitDate,
    String? vetName,
    String? notes,
    double? cost,
    bool? deleted,
  }) {
    return VetVisit(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      visitDate: visitDate ?? this.visitDate,
      vetName: vetName ?? this.vetName,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      deleted: deleted ?? this.deleted,
    );
  }
}
