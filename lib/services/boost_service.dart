import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple boost service that works without Google Play Billing
class BoostService {
  /// Singleton instance
  static final BoostService instance = BoostService._internal();
  BoostService._internal();

  /// Activate boost for a post directly (no payment required for demo)
  Future<void> activateBoost({
    required String userId,
    required String postId,
    required int days,
  }) async {
    try {
      // Calculate boost expiry date
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: days));

      // Create boost record
      await FirebaseFirestore.instance.collection('post_boosts').add({
        'userId': userId,
        'postId': postId,
        'status': 'active',
        'boostDays': days,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'source': 'direct_activation', // Track how boost was activated
      });

      developer.log('✅ Boost activated for post $postId for $days days', name: 'BoostService');
      
      // Also update the post document so the UI can read boost fields directly
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'isBoosted': true,
          'boostExpiresAt': Timestamp.fromDate(expiresAt),
          'boostEndDate': Timestamp.fromDate(expiresAt),
          'boostUpdatedAt': FieldValue.serverTimestamp(),
        });
        developer.log('✅ Post $postId marked as boosted (post document updated)', name: 'BoostService');
      } catch (e) {
        developer.log('⚠️ Failed to update post document for boost: $e', name: 'BoostService');
        // Don't rethrow — boost record was created and UI can fall back to post_boosts if needed
      }
    } catch (e) {
      developer.log('❌ Error activating boost: $e', name: 'BoostService');
      rethrow;
    }
  }

  /// Check if a post has an active boost
  Future<bool> hasActiveBoost(String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('post_boosts')
          .where('postId', isEqualTo: postId)
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      developer.log('Error checking boost status: $e', name: 'BoostService');
      return false;
    }
  }

  /// Get boost details for a post
  Future<Map<String, dynamic>?> getBoostDetails(String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('post_boosts')
          .where('postId', isEqualTo: postId)
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      developer.log('Error getting boost details: $e', name: 'BoostService');
      return null;
    }
  }
}
