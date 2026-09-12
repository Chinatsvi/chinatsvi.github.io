// lib/model/animal/health_record.dart
class HealthRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String type; // vaccination, deworming, treatment
  final String? product; // vaccine name, drug name
  final String? notes;
  final double? cost; // NEW: cost of treatment/product
  final bool deleted; // NEW: soft delete flag

  /// ✅ NEW: AI-generated advisory tips
  final List<String>? aiTips;

  const HealthRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.type,
    this.product,
    this.notes,
    this.cost, // NEW
    this.deleted = false, // NEW: default to not deleted
    this.aiTips, // ✅
  });

  /// Convert HealthRecord to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'type': type,
      'product': product,
      'notes': notes,
      'cost': cost, // NEW: store cost
      'deleted': deleted, // NEW: store deleted flag
      'aiTips': aiTips, // ✅ store tips
    };
  }

  /// Create HealthRecord from Firestore Map
  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      product: map['product'] as String?,
      notes: map['notes'] as String?,
      cost: map['cost'] != null
          ? (map['cost'] as num).toDouble()
          : null, // NEW: parse cost safely
      deleted:
          map['deleted'] as bool? ?? false, // NEW: parse deleted flag safely
      aiTips: map['aiTips'] != null
          ? List<String>.from(map['aiTips'] as List)
          : null, // ✅ parse tips safely
    );
  }

  /// Create a copy with updated fields
  HealthRecord copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    String? type,
    String? product,
    String? notes,
    double? cost,
    bool? deleted,
    List<String>? aiTips,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      type: type ?? this.type,
      product: product ?? this.product,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      deleted: deleted ?? this.deleted,
      aiTips: aiTips ?? this.aiTips,
    );
  }
}
