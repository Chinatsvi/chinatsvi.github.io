import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;

  // BASIC INFO
  final String title;
  final String author;
  final String description;
  final String coverImage; // URL or empty for local
  final String category;

  // SALES
  final double price;
  final bool isFree;

  // CONTENT
  final List<String> previewPages;
  final List<String> fullPages;

  // META
  final DateTime? publishedAt;
  final bool isLocal; // NEW: true if from local asset

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImage,
    required this.category,
    required this.price,
    required this.isFree,
    required this.previewPages,
    required this.fullPages,
    this.publishedAt,
    this.isLocal = false,
  });

  // ---------------- FROM FIREBASE ----------------
  factory BookModel.fromMap(String id, Map<String, dynamic> data) {
    return BookModel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? 'Unknown',
      description: data['description'] ?? '',
      coverImage: data['coverImage'] ?? '',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0).toDouble(),
      isFree: data['isFree'] ?? false,
      previewPages: List<String>.from(data['previewPages'] ?? []),
      fullPages: List<String>.from(data['fullPages'] ?? []),
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      isLocal: false,
    );
  }

  // ---------------- FROM LOCAL ASSET (PDF/TXT) ----------------
  factory BookModel.fromLocal({
    required String id,
    required String title,
    String author = 'Local Asset',
    String description = '',
    String coverImage = '',
    String category = 'Local',
    double price = 0,
    bool isFree = true,
    required List<String> previewPages,
    required List<String> fullPages,
  }) {
    return BookModel(
      id: id,
      title: title,
      author: author,
      description: description,
      coverImage: coverImage,
      category: category,
      price: price,
      isFree: isFree,
      previewPages: previewPages,
      fullPages: fullPages,
      isLocal: true,
    );
  }
}
