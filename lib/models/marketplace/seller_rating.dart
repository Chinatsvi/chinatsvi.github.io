import 'package:uuid/uuid.dart';

class SellerRating {
  final String id;
  final String sellerId;
  final String buyerId;
  final int stars; // 1 to 5
  final String comment;
  final DateTime createdAt;

  SellerRating({
    String? id,
    required this.sellerId,
    required this.buyerId,
    required this.stars,
    required this.comment,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'stars': stars,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SellerRating.fromJson(Map<String, dynamic> json) {
    return SellerRating(
      id: json['id'],
      sellerId: json['sellerId'],
      buyerId: json['buyerId'],
      stars: json['stars'],
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}