import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Payment service for handling real boost purchases
class PaymentService {
  /// Singleton instance
  static final PaymentService instance = PaymentService._internal();
  PaymentService._internal();

  /// Boost package prices (in USD)
  static const Map<int, double> boostPrices = {
    3: 2.99, // Basic - 3 days
    7: 6.99, // Standard - 7 days
    14: 12.99, // Premium - 14 days
    30: 19.99, // Ultimate - 30 days
  };

  /// Get price for boost package
  double getPriceForDays(int days) {
    return boostPrices[days] ?? 2.99;
  }

  /// Get package name for days
  String getPackageName(int days) {
    switch (days) {
      case 3:
        return 'Basic';
      case 7:
        return 'Standard';
      case 14:
        return 'Premium';
      case 30:
        return 'Ultimate';
      default:
        return 'Basic';
    }
  }

  /// Process payment for boost (simulated - integrate with real payment gateway)
  Future<bool> processPayment({
    required String userId,
    required String postId,
    required int days,
    required String paymentMethod,
  }) async {
    try {
      final price = getPriceForDays(days);
      final packageName = getPackageName(days);

      // Create payment record
      final paymentRef = await FirebaseFirestore.instance
          .collection('payments')
          .add({
            'userId': userId,
            'postId': postId,
            'type': 'boost',
            'amount': price,
            'currency': 'USD',
            'days': days,
            'packageName': packageName,
            'paymentMethod': paymentMethod,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      developer.log(
        '💳 Payment initiated: $packageName ($days days) - $price USD',
        name: 'PaymentService',
      );

      // Simulate payment processing (replace with real payment gateway)
      // In production, integrate with Stripe, PayPal, or mobile payment SDKs
      await _simulatePaymentProcessing(paymentRef.id);

      // If payment successful, activate boost
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentRef.id)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      // Activate the boost
      await _activateBoostAfterPayment(userId, postId, days, paymentRef.id);

      developer.log(
        '✅ Payment completed and boost activated',
        name: 'PaymentService',
      );
      return true;
    } catch (e) {
      developer.log('❌ Payment failed: $e', name: 'PaymentService');
      return false;
    }
  }

  /// Simulate payment processing (replace with real payment gateway)
  Future<void> _simulatePaymentProcessing(String paymentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 95% success rate
    if (DateTime.now().millisecond % 100 < 95) {
      developer.log('💳 Payment simulation successful', name: 'PaymentService');
    } else {
      throw Exception('Payment declined by bank');
    }
  }

  /// Activate boost after successful payment
  Future<void> _activateBoostAfterPayment(
    String userId,
    String postId,
    int days,
    String paymentId,
  ) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: days));

    developer.log(
      '🚀 Activating boost: userId=$userId, postId=$postId, days=$days',
      name: 'PaymentService',
    );

    final boostRef = await FirebaseFirestore.instance
        .collection('post_boosts')
        .add({
          'userId': userId,
          'postId': postId,
          'paymentId': paymentId,
          'status': 'active',
          'boostDays': days,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'source': 'paid_boost',
        });

    developer.log(
      '✅ Boost created with ID: ${boostRef.id}',
      name: 'PaymentService',
    );

    // Verify the boost was created
    final boostDoc = await boostRef.get();
    if (boostDoc.exists) {
      developer.log('✅ Boost verification successful', name: 'PaymentService');
    } else {
      developer.log('❌ Boost verification failed', name: 'PaymentService');
    }

    // Update the post document (if it's a regular post)
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      final postSnap = await postRef.get();
      if (postSnap.exists) {
        await postRef.update({
          'isBoosted': true,
          'boostEndDate': Timestamp.fromDate(expiresAt),
          'boostExpiresAt': Timestamp.fromDate(expiresAt),
          'boostUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      developer.log('⚠️ Failed to update posts doc for boost: $e', name: 'PaymentService');
    }
  }

  /// Get payment history for user
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
