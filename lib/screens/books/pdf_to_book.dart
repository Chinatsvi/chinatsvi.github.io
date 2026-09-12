import 'dart:convert';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';

class PdfToBook {
  final String assetPath; // e.g., 'assets/books/mybook.pdf'
  final String bookId;
  final String title;
  final String author;
  final String category;
  final String coverImage; // URL or local asset path
  final double price;

  PdfToBook({
    required this.assetPath,
    required this.bookId,
    required this.title,
    required this.author,
    required this.category,
    required this.coverImage,
    this.price = 0,
  });

  Future<Map<String, dynamic>> convert() async {
    // Load PDF
    final doc = await PDFDoc.fromPath(assetPath);

    List<String> allPages = [];

    // Extract text page by page
    for (int i = 1; i <= doc.length; i++) {
      String text = await doc.pageAt(i).text;
      allPages.add(text.trim());
    }

    // Define preview pages (first 4 pages or fewer)
    List<String> previewPages = allPages.length <= 4
        ? allPages
        : allPages.sublist(0, 4);

    // JSON structure for Firestore / BookModel
    final bookJson = {
      "id": bookId,
      "title": title,
      "author": author,
      "category": category,
      "coverImage": coverImage,
      "price": price,
      "isFree": price == 0,
      "previewPages": previewPages,
      "fullPages": allPages,
    };

    return bookJson;
  }

  // Optional: convert to JSON string
  Future<String> toJsonString() async {
    final map = await convert();
    return jsonEncode(map);
  }
}
