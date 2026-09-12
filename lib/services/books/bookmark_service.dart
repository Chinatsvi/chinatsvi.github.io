import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkService {
  final _db = FirebaseFirestore.instance;

  Future<void> savePosition({
    required String userId,
    required String bookId,
    required int pageIndex,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookId)
        .set({
      'pageIndex': pageIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int?> getPosition({
    required String userId,
    required String bookId,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookId)
        .get();

    if (!doc.exists) return null;
    return doc['pageIndex'];
  }
}
