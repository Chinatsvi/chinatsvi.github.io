import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/books/book_model.dart';

class BookService {
  final CollectionReference _booksRef =
      FirebaseFirestore.instance.collection('guidebooks');

  Stream<List<BookModel>> streamBooks() {
    return _booksRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    });
  }

  Future<BookModel> getBookById(String bookId) async {
    final doc = await _booksRef.doc(bookId).get();
    return BookModel.fromMap(
      doc.id,
      doc.data() as Map<String, dynamic>,
    );
  }
}
