class SellerBadge {
  String? id;
  String? userId;
  final String sellerId;
  final int totalSales;
  final String badgeLevel; // none, bronze, silver, gold, platinum

  SellerBadge({
    this.id,
    this.userId,
    required this.sellerId,
    required this.totalSales,
    required this.badgeLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sellerId': sellerId,
      'totalSales': totalSales,
      'badgeLevel': badgeLevel,
    };
  }

  factory SellerBadge.fromJson(Map<String, dynamic> json) {
    return SellerBadge(
      id: json['id'],
      userId: json['userId'],
      sellerId: json['sellerId'],
      totalSales: json['totalSales'] ?? 0,
      badgeLevel: json['badgeLevel'] ?? 'none',
    );
  }

  SellerBadge copyWith({
    String? id,
    String? userId,
    String? sellerId,
    int? totalSales,
    String? badgeLevel,
  }) {
    return SellerBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      totalSales: totalSales ?? this.totalSales,
      badgeLevel: badgeLevel ?? this.badgeLevel,
    );
  }
}
