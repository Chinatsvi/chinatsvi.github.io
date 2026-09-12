import 'package:cloud_firestore/cloud_firestore.dart';

/// Inventory Item Model - Seeds, fertilizer, tools in stock
class InventoryItem {
  final String id;
  final String farmerId;
  final String cropPlanId; // 🔥 Track which crop plan this item belongs to
  final String category; // 'seeds', 'fertilizer', 'tools', 'chemicals', 'other'
  final String name;
  final String? brand;
  final String? supplier;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final double totalCost;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.farmerId,
    required this.cropPlanId,
    required this.category,
    required this.name,
    this.brand,
    this.supplier,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
    required this.totalCost,
    this.purchaseDate,
    this.expiryDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory InventoryItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropPlanId: data['cropPlanId'] ?? '',
      category: data['category'] ?? 'other',
      name: data['name'] ?? '',
      brand: data['brand'],
      supplier: data['supplier'],
      quantity: data['quantity']?.toDouble() ?? 0,
      unit: data['unit'] ?? 'units',
      costPerUnit: data['costPerUnit']?.toDouble() ?? 0,
      totalCost: data['totalCost']?.toDouble() ?? 0,
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : null,
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropPlanId': cropPlanId,
      'category': category,
      'name': name,
      'brand': brand,
      'supplier': supplier,
      'quantity': quantity,
      'unit': unit,
      'costPerUnit': costPerUnit,
      'totalCost': totalCost,
      'purchaseDate': purchaseDate != null
          ? Timestamp.fromDate(purchaseDate!)
          : null,
      'expiryDate': expiryDate != null
          ? Timestamp.fromDate(expiryDate!)
          : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? farmerId,
    String? cropPlanId,
    String? category,
    String? name,
    String? brand,
    String? supplier,
    double? quantity,
    String? unit,
    double? costPerUnit,
    double? totalCost,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropPlanId: cropPlanId ?? this.cropPlanId,
      category: category ?? this.category,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      supplier: supplier ?? this.supplier,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formats quantity cleanly (e.g. 1 instead of 1.0, 1.5 for decimals)
  String get formattedQuantity {
    if (quantity % 1 == 0 || (quantity - quantity.round()).abs() < 0.00001) {
      return quantity.round().toString();
    }
    String s = quantity.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Formats quantity with unit with space and 'x' (e.g., "1 x bags of 25 kg", "2 x kg")
  String get formattedQuantityWithUnit {
    final qty = formattedQuantity;
    final trimmedUnit = unit.trim();
    if (trimmedUnit.isNotEmpty) {
      return '$qty x $trimmedUnit';
    }
    return qty;
  }
}
