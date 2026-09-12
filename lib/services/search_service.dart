import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile/farmer_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search farmers by name, location, and crop tags
  Future<List<FarmerModel>> searchFarmers(String query) async {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    try {
      // First try a fast prefix query on user_name (requires index)
      final resultsMap = <String, FarmerModel>{};

      try {
        final prefixSnap = await _firestore
            .collection('farmers')
            .where('user_name', isGreaterThanOrEqualTo: query)
            .where('user_name', isLessThanOrEqualTo: '$query\uf8ff')
            .get();

        for (final doc in prefixSnap.docs) {
          try {
            final farmer = FarmerModel.fromMap(doc.data(), doc.id);
            resultsMap[doc.id] = farmer;
          } catch (_) {}
        }
        developer.log('🔎 prefix user_name results=${prefixSnap.docs.length}', name: 'SearchService');
      } catch (e) {
        developer.log('⚠️ prefix user_name query failed: $e', name: 'SearchService');
      }

      // Try exact/location matches (useful when searching by city/district)
      try {
        final locSnap = await _firestore
            .collection('farmers')
            .where('location', isEqualTo: query)
            .get();
        for (final doc in locSnap.docs) {
          try {
            final farmer = FarmerModel.fromMap(doc.data(), doc.id);
            resultsMap[doc.id] = farmer;
          } catch (_) {}
        }
        developer.log('🔎 exact location results=${locSnap.docs.length}', name: 'SearchService');
      } catch (e) {
        developer.log('⚠️ location equality query failed: $e', name: 'SearchService');
      }

      // If we already have results, also filter them by other fields and return
      if (resultsMap.isNotEmpty) {
        final filtered = resultsMap.values.where((farmer) {
          final nameMatch = farmer.name.toLowerCase().contains(lowercaseQuery);
          final locationMatch = farmer.location?.toLowerCase().contains(lowercaseQuery) == true;
          final bioMatch = farmer.bio?.toLowerCase().contains(lowercaseQuery) == true;
          final workMatch = farmer.work?.toLowerCase().contains(lowercaseQuery) == true;
          final workListMatch = farmer.workList.any((w) =>
              (w.role?.toLowerCase().contains(lowercaseQuery) == true) ||
              (w.description?.toLowerCase().contains(lowercaseQuery) == true));
          return nameMatch || locationMatch || bioMatch || workMatch || workListMatch;
        }).toList();
        if (filtered.isNotEmpty) return filtered;
      }

      // Fallback: scan all farmers client-side (slow but reliable)
      final snapshot = await _firestore.collection('farmers').get();
      List<FarmerModel> results = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final farmer = FarmerModel.fromMap(data, doc.id);
        // Search in multiple fields
        bool matches = false;
        if (farmer.name.toLowerCase().contains(lowercaseQuery)) matches = true;
        if (farmer.location?.isNotEmpty == true && farmer.location!.toLowerCase().contains(lowercaseQuery)) matches = true;
        if (farmer.bio?.isNotEmpty == true && farmer.bio!.toLowerCase().contains(lowercaseQuery)) matches = true;
        if (farmer.work?.isNotEmpty == true && farmer.work!.toLowerCase().contains(lowercaseQuery)) matches = true;
        for (var work in farmer.workList) {
          if ((work.role?.toLowerCase().contains(lowercaseQuery) == true) ||
              (work.description?.isNotEmpty == true && work.description?.toLowerCase().contains(lowercaseQuery) == true)) {
            matches = true;
            break;
          }
        }
        if (matches) results.add(farmer);
      }

      developer.log('🔎 fallback scanned farmers=${results.length}', name: 'SearchService');
      return results;
    } catch (e) {
      developer.log('❌ Error searching farmers: $e', name: 'SearchService');
      return [];
    }
  }

  /// Search posts by content and author name
  Future<List<QueryDocumentSnapshot>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    try {
      // Try a simple content query if you have full-text index fields (not always available)
      final snapshot = await _firestore.collection('posts').orderBy('created_at', descending: true).get();

      List<QueryDocumentSnapshot> results = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        bool matches = false;
        if (data['content'] != null && data['content'].toString().toLowerCase().contains(lowercaseQuery)) {
          matches = true;
        }
        if (data['authorName'] != null && data['authorName'].toString().toLowerCase().contains(lowercaseQuery)) {
          matches = true;
        }
        if (data['type'] != null && data['type'].toString().toLowerCase().contains(lowercaseQuery)) {
          matches = true;
        }

        if (matches) results.add(doc);
      }

      developer.log('🔎 posts matched=${results.length}', name: 'SearchService');
      return results;
    } catch (e) {
      developer.log('❌ Error searching posts: $e', name: 'SearchService');
      return [];
    }
  }
}
