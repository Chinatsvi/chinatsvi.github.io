import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agribased/models/mock_product.dart';

/// MockCashHandler simulates purchases locally and updates Firestore
/// so your app can test verification ticks and boosts without real money.
class MockCashHandler {
  MockCashHandler._private();
  static final MockCashHandler instance = MockCashHandler._private();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> purchase(MockProduct product, {required String userId, BuildContext? context}) async {
    debugPrint('Mock purchase: ${product.title} (${product.id}) for ${product.price}');

    final now = Timestamp.now();
    final userRef = _db.collection('farmers').doc(userId);

    try {
      if (product.id == 'verification_tick_monthly') {
        // Mark verification as paid and set paidAt timestamp
        await userRef.set({
          'verificationPaid': true,
          'verificationPaidAt': now,
          'verificationStatus': 'approved',
        }, SetOptions(merge: true));

        debugPrint('✅ Tick activated for user $userId');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Mock: Tick activated for 30 days')),
          );
        }
      } else if (product.id.startsWith('boost_')) {
        // Save a lightweight boost record on the user document
        final boostEntry = {
          'productId': product.id,
          'title': product.title,
          'activatedAt': now,
          'price': product.price,
        };
        await userRef.set({
          'lastBoost': boostEntry,
        }, SetOptions(merge: true));

        debugPrint('🚀 Boost applied for user $userId: ${product.title}');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🚀 Mock: ${product.title} applied')),
          );
        }
      } else {
        debugPrint('ℹ️ Unknown mock product id: ${product.id}');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mock purchase completed: ${product.title}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Mock purchase failed: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mock purchase failed: $e')),
        );
      }
      rethrow;
    }
  }

  // A no-op BuildContext fallback (used only to avoid nullable checks when
  // no context is passed). It will not show SnackBars.
  static final BuildContext? _dummyContext = null;
}
