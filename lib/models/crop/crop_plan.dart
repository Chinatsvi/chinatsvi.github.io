import 'package:cloud_firestore/cloud_firestore.dart';

/// Crop Plan Model - What to grow, when, and where
class CropPlan {
  final String id;
  final String farmerId;
  final String cropName;
  final String? variety;
  final String fieldName;
  final double? fieldSize;
  final String? fieldSizeUnit;
  final DateTime plantingDate;
  final DateTime? expectedHarvestDate;
  final String? purpose;
  final String? notes;
  final String? currency; // Added currency field
  final DateTime createdAt;
  final DateTime? updatedAt;

  CropPlan({
    required this.id,
    required this.farmerId,
    required this.cropName,
    this.variety,
    required this.fieldName,
    this.fieldSize,
    this.fieldSizeUnit,
    required this.plantingDate,
    this.expectedHarvestDate,
    this.purpose,
    this.notes,
    this.currency,
    required this.createdAt,
    this.updatedAt,
  });

  factory CropPlan.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropPlan(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropName: data['cropName'] ?? '',
      variety: data['variety'],
      fieldName: data['fieldName'] ?? '',
      fieldSize: data['fieldSize']?.toDouble(),
      fieldSizeUnit: data['fieldSizeUnit'],
      plantingDate: (data['plantingDate'] as Timestamp).toDate(),
      expectedHarvestDate: data['expectedHarvestDate'] != null
          ? (data['expectedHarvestDate'] as Timestamp).toDate()
          : null,
      purpose: data['purpose'],
      notes: data['notes'],
      currency: data['currency'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropName': cropName,
      'variety': variety,
      'fieldName': fieldName,
      'fieldSize': fieldSize,
      'fieldSizeUnit': fieldSizeUnit,
      'plantingDate': Timestamp.fromDate(plantingDate),
      'expectedHarvestDate': expectedHarvestDate != null
          ? Timestamp.fromDate(expectedHarvestDate!)
          : null,
      'purpose': purpose,
      'notes': notes,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CropPlan copyWith({
    String? id,
    String? farmerId,
    String? cropName,
    String? variety,
    String? fieldName,
    double? fieldSize,
    String? fieldSizeUnit,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    String? purpose,
    String? notes,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropPlan(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropName: cropName ?? this.cropName,
      variety: variety ?? this.variety,
      fieldName: fieldName ?? this.fieldName,
      fieldSize: fieldSize ?? this.fieldSize,
      fieldSizeUnit: fieldSizeUnit ?? this.fieldSizeUnit,
      plantingDate: plantingDate ?? this.plantingDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
