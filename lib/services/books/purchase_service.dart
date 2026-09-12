import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseService {
  final _db = FirebaseFirestore.instance;

  Future<void> savePurchase({
    required String userId,
    required String bookId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .doc(bookId)
        .set({
      'purchasedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasPurchased({
    required String userId,
    required String bookId,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .doc(bookId)
        .get();

    return doc.exists;
  }

  Stream<List<String>> purchasedBookIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
