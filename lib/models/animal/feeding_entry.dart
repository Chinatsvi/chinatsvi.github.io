// lib/model/animal/feeding_entry.dart

class FeedingEntry {
  final String id;
  final String animalId;
  final DateTime date;
  final String feedType; // e.g., maize bran, concentrate
  final double quantityKg;
  final double cost; // local currency
  final String? notes;
  final bool deleted; // NEW: soft delete flag

  /// ✅ NEW: Link to growth record (weight impact)
  final String? growthRecordId;

  /// ✅ NEW: Link to health record (e.g., special diet after treatment)
  final String? healthRecordId;

  /// ✅ NEW: Link to breeding record (e.g., lactating cow feed)
  final String? breedingRecordId;

  /// ✅ NEW: AI-generated advisory tips
  final List<String>? aiTips;

  const FeedingEntry({
    required this.id,
    required this.animalId,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    required this.cost,
    this.notes,
    this.deleted = false, // NEW: default to not deleted
    this.growthRecordId,
    this.healthRecordId,
    this.breedingRecordId,
    this.aiTips,
  });

  /// Convert FeedingEntry to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'feedType': feedType,
      'quantityKg': quantityKg,
      'cost': cost,
      'notes': notes,
      'deleted': deleted, // NEW: store deleted flag
      'growthRecordId': growthRecordId,
      'healthRecordId': healthRecordId,
      'breedingRecordId': breedingRecordId,
      'aiTips': aiTips, // stored as List<String>
    };
  }

  /// Create FeedingEntry from Firestore Map
  factory FeedingEntry.fromMap(Map<String, dynamic> map) {
    return FeedingEntry(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      feedType: map['feedType'] as String,
      quantityKg: (map['quantityKg'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      notes: map['notes'] as String?,
      deleted:
          map['deleted'] as bool? ?? false, // NEW: parse deleted flag safely
      growthRecordId: map['growthRecordId'] as String?,
      healthRecordId: map['healthRecordId'] as String?,
      breedingRecordId: map['breedingRecordId'] as String?,
      aiTips: map['aiTips'] != null
          ? List<String>.from(map['aiTips'] as List)
          : null,
    );
  }

  /// Create a copy with updated fields
  FeedingEntry copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    String? feedType,
    double? quantityKg,
    double? cost,
    String? notes,
    bool? deleted,
    String? growthRecordId,
    String? healthRecordId,
    String? breedingRecordId,
    List<String>? aiTips,
  }) {
    return FeedingEntry(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      feedType: feedType ?? this.feedType,
      quantityKg: quantityKg ?? this.quantityKg,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      deleted: deleted ?? this.deleted,
      growthRecordId: growthRecordId ?? this.growthRecordId,
      healthRecordId: healthRecordId ?? this.healthRecordId,
      breedingRecordId: breedingRecordId ?? this.breedingRecordId,
      aiTips: aiTips ?? this.aiTips,
    );
  }
}
