import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for loading local assets

import '../../../models/books/book_model.dart';
import '../../../services/books/book_service.dart';
import '../../../services/books/purchase_service.dart';

class BookController extends ChangeNotifier {
  final BookService _bookService = BookService();
  final PurchaseService _purchaseService = PurchaseService();

  List<BookModel> books = [];
  BookModel? currentBook;

  double fontSize = 18;
  bool hasPurchased = false;

  String? currentUserId; // set from auth later

  void setUser(String userId) {
    currentUserId = userId;
  }

  // ---------------- STREAM BOOKS FROM FIREBASE ----------------
  void listenBooks() {
    _bookService.streamBooks().listen((data) {
      books = data;
      notifyListeners();
    });
  }

  // ---------------- LOAD BOOK (REMOTE OR LOCAL) ----------------
  Future<void> loadBook(String bookId, {String? localAsset}) async {
    if (localAsset != null) {
      // Load a local asset (PDF or TXT)
      if (localAsset.endsWith('.pdf')) {
        try {
          // For PDF files, create a placeholder book for now
          // PDF text extraction can be implemented later with proper package
          currentBook = BookModel(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            title: localAsset.split('/').last,
            author: 'Local Asset',
            category: 'Local',
            description: 'PDF book loaded from local assets',
            price: 0,
            isFree: true,
            coverImage: '', // optional local image
            previewPages: [
              'This is a PDF book loaded from local assets.',
              'PDF content will be displayed here.',
              'Full PDF viewer integration coming soon.',
            ],
            fullPages: [
              'PDF Book Content',
              '==================',
              '',
              'This PDF book has been loaded successfully.',
              'The full PDF viewing functionality will be implemented.',
              '',
              'For now, you can see this placeholder content.',
            ],
          );
        } catch (e) {
          debugPrint('Error loading PDF: $e');
          currentBook = BookModel(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            title: localAsset.split('/').last,
            author: 'Local Asset',
            category: 'Local',
            description: 'Error loading PDF file',
            price: 0,
            isFree: true,
            coverImage: '',
            previewPages: ['Error loading PDF'],
            fullPages: [
              'Error loading PDF file. Please check if the file exists.',
            ],
          );
        }
      } else if (localAsset.endsWith('.txt')) {
        String text = await rootBundle.loadString(localAsset);
        currentBook = BookModel(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          title: localAsset.split('/').last,
          author: 'Local Asset',
          category: 'Local',
          description: text.substring(0, text.length > 200 ? 200 : text.length),
          price: 0,
          isFree: true,
          coverImage: '',
          previewPages: text.split('\n\n').take(5).toList(),
          fullPages: text.split('\n\n').toList(),
        );
      }
      hasPurchased = true;
    } else {
      // Load from Firebase
      currentBook = await _bookService.getBookById(bookId);

      if (currentUserId != null) {
        hasPurchased = await _purchaseService.hasPurchased(
          userId: currentUserId!,
          bookId: bookId,
        );
      }
    }

    notifyListeners();
  }

  // ---------------- FONT ----------------
  void increaseFont() {
    if (fontSize < 30) {
      fontSize += 2;
      notifyListeners();
    }
  }

  void decreaseFont() {
    if (fontSize > 12) {
      fontSize -= 2;
      notifyListeners();
    }
  }

  // ---------------- PURCHASE ----------------
  Future<void> unlockBook(String bookId) async {
    if (currentUserId == null) return;

    await _purchaseService.savePurchase(userId: currentUserId!, bookId: bookId);

    hasPurchased = true;
    notifyListeners();
  }
}
