import 'package:cloud_firestore/cloud_firestore.dart';

/// Egg Stock Transaction - Records sales/breakages from accumulated stock
class EggStockTransaction {
  final String id;
  final String batchId;
  final String type; // 'sale' or 'breakage'
  final int quantity;
  final double? revenue; // for sales
  final DateTime transactionDate;
  final String? notes;
  final DateTime createdAt;

  EggStockTransaction({
    required this.id,
    required this.batchId,
    required this.type,
    required this.quantity,
    this.revenue,
    required this.transactionDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'type': type,
      'quantity': quantity,
      'revenue': revenue,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EggStockTransaction.fromMap(String id, Map<String, dynamic> map) {
    return EggStockTransaction(
      id: id,
      batchId: map['batchId'],
      type: map['type'],
      quantity: map['quantity'] ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble(),
      transactionDate: (map['transactionDate'] as Timestamp).toDate(),
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory EggStockTransaction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EggStockTransaction.fromMap(doc.id, data);
  }
}

/// Egg Stock Summary - Calculated stock levels
class EggStockSummary {
  final int totalCollected;
  final int totalSoldFromDaily; // eggs sold on collection day
  final int totalBrokenFromDaily; // eggs broken on collection day
  final int totalSoldFromStock; // eggs sold from accumulated stock
  final int totalBrokenFromStock; // eggs broken from accumulated stock
  final int currentStock;

  EggStockSummary({
    this.totalCollected = 0,
    this.totalSoldFromDaily = 0,
    this.totalBrokenFromDaily = 0,
    this.totalSoldFromStock = 0,
    this.totalBrokenFromStock = 0,
  }) : currentStock = totalCollected 
            - totalSoldFromDaily 
            - totalBrokenFromDaily 
            - totalSoldFromStock 
            - totalBrokenFromStock;

  int get totalAvailable => currentStock > 0 ? currentStock : 0;
  int get totalSold => totalSoldFromDaily + totalSoldFromStock;
  int get totalBroken => totalBrokenFromDaily + totalBrokenFromStock;
}
