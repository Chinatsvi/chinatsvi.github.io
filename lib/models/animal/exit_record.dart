// lib/model/animal/exit_record.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ExitRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String reason; // mortality or sale
  final int quantity;
  final String? animalTag; // e.g. "Cattle A", "Cattle 1", "Cow #101"
  final String? sex; // Male / Female / Mixed
  final int? maleQuantity;
  final int? femaleQuantity;
  final double? salePrice;
  final String? notes;

  const ExitRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.reason,
    this.quantity = 1,
    this.animalTag,
    this.sex,
    this.maleQuantity,
    this.femaleQuantity,
    this.salePrice,
    this.notes,
  });

  ExitRecord copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    String? reason,
    int? quantity,
    String? animalTag,
    String? sex,
    int? maleQuantity,
    int? femaleQuantity,
    double? salePrice,
    String? notes,
  }) {
    return ExitRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      animalTag: animalTag ?? this.animalTag,
      sex: sex ?? this.sex,
      maleQuantity: maleQuantity ?? this.maleQuantity,
      femaleQuantity: femaleQuantity ?? this.femaleQuantity,
      salePrice: salePrice ?? this.salePrice,
      notes: notes ?? this.notes,
    );
  }

  /// Convert ExitRecord to Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animalId': animalId,
      'date': date.toIso8601String(),
      'reason': reason,
      'quantity': quantity,
      'animalTag': animalTag,
      'sex': sex,
      'maleQuantity': maleQuantity,
      'femaleQuantity': femaleQuantity,
      'salePrice': salePrice,
      'notes': notes,
    };
  }

  /// Create ExitRecord from Firestore Map
  factory ExitRecord.fromMap(Map<String, dynamic> map) {
    final dateValue = map['date'];
    return ExitRecord(
      id: (map['id'] ?? '') as String,
      animalId: (map['animalId'] ?? '') as String,
      date: dateValue is Timestamp
          ? dateValue.toDate()
          : (dateValue is String
              ? (DateTime.tryParse(dateValue) ?? DateTime.now())
              : DateTime.now()),
      reason: (map['reason'] ?? 'sale') as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      animalTag: map['animalTag'] as String?,
      sex: map['sex'] as String?,
      maleQuantity: (map['maleQuantity'] as num?)?.toInt(),
      femaleQuantity: (map['femaleQuantity'] as num?)?.toInt(),
      salePrice: map['salePrice'] != null
          ? (map['salePrice'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
    );
  }
}

