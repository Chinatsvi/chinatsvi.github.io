import 'package:cloud_firestore/cloud_firestore.dart';

/// Budget Item Model - Individual budget line item
class BudgetItem {
  final String id;
  final String category; // 'inputs', 'labor', 'other'
  final String name;
  final double quantity;
  final String? unit;
  final double unitCost;
  final double totalCost;
  final DateTime? expectedDate;
  final String? notes;

  BudgetItem({
    required this.id,
    required this.category,
    required this.name,
    required this.quantity,
    this.unit,
    required this.unitCost,
    required this.totalCost,
    this.expectedDate,
    this.notes,
  });

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'] ?? '',
      category: map['category'] ?? 'other',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0,
      unit: map['unit'],
      unitCost: map['unitCost']?.toDouble() ?? 0,
      totalCost: map['totalCost']?.toDouble() ?? 0,
      expectedDate: map['expectedDate'] != null
          ? (map['expectedDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'expectedDate': expectedDate != null
          ? Timestamp.fromDate(expectedDate!)
          : null,
      'notes': notes,
    };
  }

  BudgetItem copyWith({
    String? id,
    String? category,
    String? name,
    double? quantity,
    String? unit,
    double? unitCost,
    double? totalCost,
    DateTime? expectedDate,
    String? notes,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      expectedDate: expectedDate ?? this.expectedDate,
      notes: notes ?? this.notes,
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
    final trimmedUnit = unit?.trim();
    if (trimmedUnit != null && trimmedUnit.isNotEmpty) {
      return '$qty x $trimmedUnit';
    }
    return qty;
  }
}

/// Budget Model - Budget Planner for a crop plan
class CropBudget {
  final String id;
  final String farmerId;
  final String cropPlanId;
  final String? cropPlanName;
  final List<BudgetItem> items;
  final double expectedIncome;
  final double? expectedYield;
  final String? yieldUnit;
  final double? pricePerUnit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CropBudget({
    required this.id,
    required this.farmerId,
    required this.cropPlanId,
    this.cropPlanName,
    required this.items,
    required this.expectedIncome,
    this.expectedYield,
    this.yieldUnit,
    this.pricePerUnit,
    required this.createdAt,
    this.updatedAt,
  });

  factory CropBudget.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>? ?? [];
    return CropBudget(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropPlanId: data['cropPlanId'] ?? '',
      cropPlanName: data['cropPlanName'],
      items: itemsList.map((e) => BudgetItem.fromMap(e as Map<String, dynamic>)).toList(),
      expectedIncome: data['expectedIncome']?.toDouble() ?? 0,
      expectedYield: data['expectedYield']?.toDouble(),
      yieldUnit: data['yieldUnit'],
      pricePerUnit: data['pricePerUnit']?.toDouble(),
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
      'cropPlanName': cropPlanName,
      'items': items.map((e) => e.toMap()).toList(),
      'expectedIncome': expectedIncome,
      'expectedYield': expectedYield,
      'yieldUnit': yieldUnit,
      'pricePerUnit': pricePerUnit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  double get totalInputCosts => items
      .where((item) => item.category == 'inputs')
      .fold(0, (sum, item) => sum + item.totalCost);

  double get totalLaborCosts => items
      .where((item) => item.category == 'labor')
      .fold(0, (sum, item) => sum + item.totalCost);

  double get totalOtherCosts => items
      .where((item) => item.category == 'other')
      .fold(0, (sum, item) => sum + item.totalCost);

  double get totalCosts => items.fold(0, (sum, item) => sum + item.totalCost);

  double get expectedProfit => expectedIncome - totalCosts;

  /// Formats expected yield cleanly (e.g. 100 instead of 100.0)
  String? get formattedExpectedYield {
    if (expectedYield == null) return null;
    if (expectedYield! % 1 == 0) {
      return expectedYield!.toInt().toString();
    }
    return expectedYield!.toString().replaceAll(RegExp(r'\.0+$'), '');
  }

  CropBudget copyWith({
    String? id,
    String? farmerId,
    String? cropPlanId,
    String? cropPlanName,
    List<BudgetItem>? items,
    double? expectedIncome,
    double? expectedYield,
    String? yieldUnit,
    double? pricePerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropBudget(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropPlanId: cropPlanId ?? this.cropPlanId,
      cropPlanName: cropPlanName ?? this.cropPlanName,
      items: items ?? this.items,
      expectedIncome: expectedIncome ?? this.expectedIncome,
      expectedYield: expectedYield ?? this.expectedYield,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
