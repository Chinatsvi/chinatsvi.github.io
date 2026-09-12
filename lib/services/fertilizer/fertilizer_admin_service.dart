import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fertilizer/fertilizer_crop.dart';
import '../../models/fertilizer/fertilizer_product.dart';
import '../../models/fertilizer/fertilizer_recommendation.dart';
import '../../models/fertilizer/fertilizer_source.dart';

class FertilizerAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // CROP ADMIN
  // ---------------------------------------------------------------------------
  Future<void> saveCrop(FertilizerCrop crop) async {
    try {
      final docId = crop.id.isNotEmpty
          ? crop.id
          : 'crop_${crop.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      await _firestore
          .collection('fertilizer_crops')
          .doc(docId)
          .set(crop.toMap(), SetOptions(merge: true));
    } catch (e) {
      developer.log('Error saving crop in admin: $e', name: 'FertilizerAdmin');
      rethrow;
    }
  }

  Future<void> toggleCropStatus(String cropId, bool active) async {
    await _firestore
        .collection('fertilizer_crops')
        .doc(cropId)
        .update({'active': active});
  }

  // ---------------------------------------------------------------------------
  // PRODUCT ADMIN
  // ---------------------------------------------------------------------------
  Future<void> saveProduct(FertilizerProduct product) async {
    try {
      final docId = product.id.isNotEmpty
          ? product.id
          : 'prod_${product.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      await _firestore
          .collection('fertilizer_products')
          .doc(docId)
          .set(product.toMap(), SetOptions(merge: true));
    } catch (e) {
      developer.log('Error saving product in admin: $e', name: 'FertilizerAdmin');
      rethrow;
    }
  }

  Future<void> toggleProductStatus(String productId, bool active) async {
    await _firestore
        .collection('fertilizer_products')
        .doc(productId)
        .update({'active': active});
  }

  // ---------------------------------------------------------------------------
  // RECOMMENDATION ADMIN
  // ---------------------------------------------------------------------------
  Future<void> saveRecommendation(FertilizerRecommendation recommendation) async {
    try {
      final docId = recommendation.id.isNotEmpty
          ? recommendation.id
          : 'rec_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore
          .collection('fertilizer_recommendations')
          .doc(docId)
          .set(recommendation.toMap(), SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Error saving recommendation in admin: $e',
        name: 'FertilizerAdmin',
      );
      rethrow;
    }
  }

  Future<void> toggleRecommendationStatus(String recId, bool active) async {
    await _firestore
        .collection('fertilizer_recommendations')
        .doc(recId)
        .update({'active': active});
  }

  // ---------------------------------------------------------------------------
  // SOURCE ADMIN
  // ---------------------------------------------------------------------------
  Future<void> saveSource(FertilizerSource source) async {
    try {
      final docId = source.id.isNotEmpty
          ? source.id
          : 'src_${source.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${source.year}';
      await _firestore
          .collection('fertilizer_sources')
          .doc(docId)
          .set(source.toMap(), SetOptions(merge: true));
    } catch (e) {
      developer.log('Error saving source in admin: $e', name: 'FertilizerAdmin');
      rethrow;
    }
  }
}
