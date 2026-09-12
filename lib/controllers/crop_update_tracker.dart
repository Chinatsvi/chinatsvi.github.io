import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class CropUpdateTracker {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Updates the crop list for a user and logs the update
  Future<void> updateCrops(String userId, List<String> crops) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('userId cannot be empty');
      }

      await _db.collection('users').doc(userId).update({
        'crops': crops,
        'lastCropUpdate': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'crop_update',
        parameters: {
          'user_id': userId,
          'crop_count': crops.length,
          'crops': crops.join(', '),
        },
      );

      if (kDebugMode) {
        debugPrint('Crops updated successfully for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating crops for user $userId: $e');
      }
      rethrow;
    }
  }
}
