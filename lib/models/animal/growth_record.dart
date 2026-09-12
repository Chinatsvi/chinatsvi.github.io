// lib/model/animal/growth_record.dart
class GrowthRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final double weightKg;

  /// ✅ NEW: AI-generated advisory tips
  final List<String>? aiTips;

  const GrowthRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.weightKg,
    this.aiTips, // ✅
  });

  /// Convert GrowthRecord to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'aiTips': aiTips, // ✅ include tips
    };
  }

  /// Create GrowthRecord from Firestore Map
  factory GrowthRecord.fromMap(Map<String, dynamic> map) {
    return GrowthRecord(
      id: map['id'] as String,
      animalId: map['animalId'] as String,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
      aiTips: map['aiTips'] != null
          ? List<String>.from(map['aiTips'] as List)
          : null, // ✅ parse tips safely
    );
  }
}