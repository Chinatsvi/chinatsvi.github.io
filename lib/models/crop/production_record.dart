import 'package:cloud_firestore/cloud_firestore.dart';

/// Production Record Model - Sales and losses
class ProductionRecord {
  final String id;
  final String farmerId;
  final String cropPlanId;
  final String recordType; // 'sale', 'loss', 'harvest'
  final DateTime date;
  final double quantity;
  final String unit; // 'kg', 'tons', 'bags', 'bunches', etc.
  final double? pricePerUnit;
  final double? totalValue;
  final double? cost; // For losses/damages: cost value to be deducted from profit
  final String? buyer;
  final String? buyerContact;
  final String? lossReason; // For losses: 'pests', 'disease', 'weather', 'theft', 'other'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductionRecord({
    required this.id,
    required this.farmerId,
    required this.cropPlanId,
    required this.recordType,
    required this.date,
    required this.quantity,
    required this.unit,
    this.pricePerUnit,
    this.totalValue,
    this.cost,
    this.buyer,
    this.buyerContact,
    this.lossReason,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductionRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductionRecord(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropPlanId: data['cropPlanId'] ?? '',
      recordType: data['recordType'] ?? 'harvest',
      date: (data['date'] as Timestamp).toDate(),
      quantity: data['quantity']?.toDouble() ?? 0,
      unit: data['unit'] ?? 'kg',
      pricePerUnit: data['pricePerUnit']?.toDouble(),
      totalValue: data['totalValue']?.toDouble(),
      cost: data['cost']?.toDouble(),
      buyer: data['buyer'],
      buyerContact: data['buyerContact'],
      lossReason: data['lossReason'],
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
      'recordType': recordType,
      'date': Timestamp.fromDate(date),
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalValue': totalValue,
      'cost': cost,
      'buyer': buyer,
      'buyerContact': buyerContact,
      'lossReason': lossReason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isSale => recordType == 'sale' || recordType == 'other_sale';
  bool get isCropSale => recordType == 'sale';
  bool get isOtherSale => recordType == 'other_sale';
  bool get isLoss => recordType == 'loss';
  bool get isHarvest => recordType == 'harvest';

  double get calculatedValue {
    if (totalValue != null) return totalValue!;
    if (pricePerUnit != null) return quantity * pricePerUnit!;
    return 0;
  }

  String get recordTypeDisplay {
    final Map<String, String> displayNames = {
      'sale': 'Crop Sale',
      'other_sale': 'Other Sale',
      'loss': 'Loss/Damage',
      'harvest': 'Harvest Record',
    };
    return displayNames[recordType] ?? 'Record';
  }

  ProductionRecord copyWith({
    String? id,
    String? farmerId,
    String? cropPlanId,
    String? recordType,
    DateTime? date,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? totalValue,
    double? cost,
    String? buyer,
    String? buyerContact,
    String? lossReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductionRecord(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropPlanId: cropPlanId ?? this.cropPlanId,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalValue: totalValue ?? this.totalValue,
      cost: cost ?? this.cost,
      buyer: buyer ?? this.buyer,
      buyerContact: buyerContact ?? this.buyerContact,
      lossReason: lossReason ?? this.lossReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formats quantity cleanly (e.g. 100 instead of 100.0, 1.5 for decimals)
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

  /// Formats quantity with unit (e.g. 100 cobs, 20 bags)
  String get formattedQuantityWithUnit {
    final qty = formattedQuantity;
    final trimmedUnit = unit.trim();
    if (trimmedUnit.isNotEmpty) {
      return '$qty $trimmedUnit';
    }
    return qty;
  }
}

/// Helper model for tracking harvest stock vs sales/losses per unit
class UnitProductionSummary {
  final String unit;
  final double harvested;
  final double sold;
  final double lost;

  UnitProductionSummary({
    required this.unit,
    required this.harvested,
    required this.sold,
    required this.lost,
  });

  // Only crop sales deduct from harvest stock; losses/damages are separate
  double get remainingStock => (harvested - sold).clamp(0, double.infinity);

  static String formatNum(double val) {
    if (val % 1 == 0 || (val - val.round()).abs() < 0.00001) {
      return val.round().toString();
    }
    String s = val.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Format: "100 cobs harvested - 20 sold"
  String get displaySubtract =>
      '${formatNum(harvested)} $unit harvested - ${formatNum(sold)} sold';

  /// Format: "100 cobs harvested - 20 sold = 80 in stock"
  String get displayBalance =>
      '${formatNum(harvested)} $unit harvested - ${formatNum(sold)} sold = ${formatNum(remainingStock)} $unit in stock';

  /// Map a list of production records into summaries grouped by unit
  static Map<String, UnitProductionSummary> groupRecords(List<ProductionRecord> records) {
    final map = <String, Map<String, double>>{};
    for (final r in records) {
      final u = r.unit.trim();
      if (u.isEmpty) continue;
      final key = u.toLowerCase();
      map.putIfAbsent(key, () => {'harvest': 0.0, 'sale': 0.0, 'loss': 0.0, 'rawUnit': 0.0});
      if (r.isHarvest) {
        map[key]!['harvest'] = (map[key]!['harvest'] ?? 0.0) + r.quantity;
      } else if (r.isCropSale) {
        map[key]!['sale'] = (map[key]!['sale'] ?? 0.0) + r.quantity;
      } else if (r.isLoss) {
        map[key]!['loss'] = (map[key]!['loss'] ?? 0.0) + r.quantity;
      }
    }

    final result = <String, UnitProductionSummary>{};
    for (final entry in map.entries) {
      // Find original casing for the unit
      final originalUnit = records.firstWhere(
        (r) => r.unit.trim().toLowerCase() == entry.key,
        orElse: () => records.first,
      ).unit.trim();

      result[entry.key] = UnitProductionSummary(
        unit: originalUnit,
        harvested: entry.value['harvest'] ?? 0.0,
        sold: entry.value['sale'] ?? 0.0,
        lost: entry.value['loss'] ?? 0.0,
      );
    }
    return result;
  }
}
