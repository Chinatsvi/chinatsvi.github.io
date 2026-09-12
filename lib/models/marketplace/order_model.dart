import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';

class OrderModel {
  final String id;

  // 🔹 Users
  final String buyerId;
  final String buyerName;
  final String sellerId;

  // 🔹 Item snapshot (VERY IMPORTANT)
  final String itemId;
  final String title;
  final String image;
  final double price;
  final int quantity;

  // 🔹 Order values
  final double totalAmount;
  final double deliveryCost;
  final String currency;

  /// pending | paid | cancelled | completed
  final String status;

  /// pending | shipped | delivered | cancelled
  final String deliveryStatus;

  /// unpaid | paid
  final String paymentStatus;

  /// mobile_money | bank | cod
  final String paymentMethod;

  // 🔹 Timestamps
  final Timestamp createdAt;
  final Timestamp? paidAt;
  final Timestamp? cancelledAt;
  final Timestamp? deliveredAt;
  final Timestamp? cancelAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    this.buyerName = 'Unknown buyer',
    required this.sellerId,
    required this.itemId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    this.deliveryCost = 0,
    this.currency = 'ZAR',
    required this.status,
    required this.deliveryStatus,
    this.paymentStatus = 'unpaid',
    required this.paymentMethod,
    required this.createdAt,
    this.paidAt,
    this.cancelledAt,
    this.deliveredAt,
    this.cancelAt,
  });

  // 🔁 COPY WITH (used for updates)
  OrderModel copyWith({
    String? status,
    String? deliveryStatus,
    String? paymentStatus,
    Timestamp? paidAt,
    Timestamp? cancelledAt,
    Timestamp? deliveredAt,
    Timestamp? cancelAt,
  }) {
    return OrderModel(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      itemId: itemId,
      title: title,
      image: image,
      price: price,
      quantity: quantity,
      totalAmount: totalAmount,
      deliveryCost: deliveryCost,
      currency: currency,
      status: status ?? this.status,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelAt: cancelAt ?? this.cancelAt,
    );
  }

  // 🔥 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'itemId': itemId,
      'title': title,
      'image': image,
      'price': price,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'deliveryCost': deliveryCost,
      'currency': currency,
      'status': status,
      'deliveryStatus': deliveryStatus,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'cancelledAt': cancelledAt,
      'deliveredAt': deliveredAt,
      'cancelAt': cancelAt,
    };
  }

  // 🔥 FROM FIRESTORE
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Unknown buyer',
      sellerId: map['sellerId'] ?? '',
      itemId: map['itemId'] ?? '',
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      deliveryCost: (map['deliveryCost'] ?? 0).toDouble(),
      currency: Formatter.normalizeCurrencyCode(
        (map['currencySymbol'] ?? map['currency'] ?? map['currencyCode'])
            ?.toString(),
      ),
      status: map['status'] ?? 'pending',
      deliveryStatus: map['deliveryStatus'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paymentMethod: map['paymentMethod'] ?? 'cod',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      paidAt: map['paidAt'],
      cancelledAt: map['cancelledAt'],
      deliveredAt: map['deliveredAt'],
      cancelAt: map['cancelAt'],
    );
  }
}
