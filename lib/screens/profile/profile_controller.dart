import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farmer_model.dart';

/// Controller for managing farmer profiles
class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a single farmer profile by document ID
  Future<FarmerModel?> getFarmerProfile(String docId) async {
    try {
      final doc = await _firestore.collection('farmers').doc(docId).get();

      if (!doc.exists || doc.data() == null) {
        debugLog('PROFILE NOT FOUND: $docId');
        return null;
      }

      final farmer = FarmerModel.fromDocument(doc);

      // If name is empty = incomplete profile → treat as missing
      if (farmer.name.trim().isEmpty) {
        debugLog('PROFILE INVALID (EMPTY NAME): $docId');
        return null;
      }

      return farmer;
    } catch (e) {
      debugLog('Error fetching farmer profile: $e');
      return null;
    }
  }

  /// Alias (followers screen)
  Future<FarmerModel?> getFarmerById(String userId) async {
    return getFarmerProfile(userId);
  }

  /// Stream a single farmer profile by ID
  Stream<FarmerModel?> getFarmerProfileStream(String docId) {
    return _firestore.collection('farmers').doc(docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        debugLog('PROFILE NOT FOUND (STREAM): $docId');
        return null;
      }

      final farmer = FarmerModel.fromDocument(doc);

      if (farmer.name.trim().isEmpty) {
        debugLog('PROFILE INVALID (EMPTY NAME STREAM): $docId');
        return null;
      }

      return farmer;
    });
  }

  /// Create or update a farmer profile
  Future<void> upsertFarmerProfile(FarmerModel farmer) async {
    try {
      await _firestore.collection('farmers').doc(farmer.id).set(
            farmer.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugLog('Error upserting farmer profile: $e');
    }
  }

  /// Fetch multiple farmer profiles by IDs (one-time)
  Future<List<FarmerModel>> getFarmersByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      // Firestore `whereIn` accepts max 10 items. Split into chunks to avoid
      // invalid-argument errors when querying many IDs (e.g., admin followers).
      final List<FarmerModel> farmers = [];
      for (var i = 0; i < ids.length; i += 10) {
        final end = (i + 10 < ids.length) ? i + 10 : ids.length;
        final chunk = ids.sublist(i, end);
        final snapshots = await _firestore
            .collection('farmers')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        farmers.addAll(snapshots.docs
            .map((doc) => FarmerModel.fromDocument(doc))
            .where((farmer) => farmer.name.trim().isNotEmpty)
            .toList());
      }

      return farmers;
    } catch (e) {
      debugLog('Error fetching farmers by IDs: $e');
      return [];
    }
  }

  /// Stream multiple farmer profiles by IDs (real-time updates)
  Stream<List<FarmerModel>> getFarmersByIdsStream(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);

    // If 10 or fewer ids, use a single query
    if (ids.length <= 10) {
      return _firestore
          .collection('farmers')
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => FarmerModel.fromDocument(doc))
            .where((farmer) => farmer.name.trim().isNotEmpty)
            .toList();
      });
    }

    // More than 10 ids: split into chunks and merge snapshot streams.
    final controller = StreamController<List<FarmerModel>>.broadcast();

    final Map<String, FarmerModel> current = {};
    final List<StreamSubscription<QuerySnapshot>> subs = [];

    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final sub = _firestore
          .collection('farmers')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snapshot) {
        for (final doc in snapshot.docs) {
          final farmer = FarmerModel.fromDocument(doc);
          if (farmer.name.trim().isNotEmpty) {
            current[farmer.id] = farmer;
          }
        }

        // Build ordered list based on original ids
        final result = ids.map((id) => current[id]).whereType<FarmerModel>().toList();
        controller.add(result);
      }, onError: (e, st) {
        controller.addError(e, st);
      });

      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

  /// Safe logging
  void debugLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('PROFILE_CONTROLLER: $message');
    }
  }
}