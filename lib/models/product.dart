import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final DateTime postedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.postedAt,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      sellerId: data['seller_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['image_url'] ?? '',
      postedAt: (data['posted_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'posted_at': Timestamp.fromDate(postedAt),
    };
  }
}
