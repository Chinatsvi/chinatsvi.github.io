class SellerModel {
  final String id;
  final String name;
  final String profileImage;
  final double rating;
  final int reviewCount;
  final bool isVerified;

  const SellerModel({
    required this.id,
    required this.name,
    this.profileImage = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
  });

  // Add fromJson and toJson methods if needed for Firebase/Firestore integration
  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
    };
  }
}
