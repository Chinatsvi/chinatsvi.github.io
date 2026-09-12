import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

abstract class IBoostService {
  Future<bool> boostItem(String itemId, int days);
  Future<List<Map<String, dynamic>>> getActiveBoosts(String itemId);
  Future<bool> cancelBoost(String boostId);
}

class BoostService implements IBoostService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BoostService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<bool> boostItem(String itemId, int days) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('User not authenticated', name: 'BoostService');
        return false;
      }


      final endDate = DateTime.now().add(Duration(days: days));

      await _firestore.collection('boosts').add({
        'itemId': itemId,
        'userId': user.uid,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active', // active, cancelled, expired
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Marketplace items have historically been stored with both collection
      // name variants. Update the document wherever it exists.
      final boostData = {
        'isBoosted': true,
        'is_boosted': true,
        'boostExpiresAt': Timestamp.fromDate(endDate),
        'boostEndDate': Timestamp.fromDate(endDate),
        'boostDays': days,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentDate': FieldValue.serverTimestamp(),
        'activatedAt': FieldValue.serverTimestamp(),
        'boostStartedAt': FieldValue.serverTimestamp(),
        'boostUpdatedAt': FieldValue.serverTimestamp(),
      };
      var itemUpdated = false;
      for (final collectionName in ['Marketplace', 'marketplace']) {
        final itemRef = _firestore.collection(collectionName).doc(itemId);
        final itemSnapshot = await itemRef.get();
        if (itemSnapshot.exists) {
          await itemRef.update(boostData);
          itemUpdated = true;
        }
      }

      if (!itemUpdated) {
        developer.log(
          'Marketplace item $itemId was not found in either collection',
          name: 'BoostService',
        );
        return false;
      }

      return true;
    } catch (e) {
      developer.log('Error boosting item: $e', error: e, name: 'BoostService');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveBoosts(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: DateTime.now())
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      developer.log('Error getting active boosts: $e', name: 'BoostService');
      return [];
    }
  }

  @override
  Future<bool> cancelBoost(String boostId) async {
    try {
      await _firestore.collection('boosts').doc(boostId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      developer.log('Error cancelling boost: $e', name: 'BoostService');
      return false;
    }
  }
}
