import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fertilizer/fertilizer_crop.dart';
import '../../models/fertilizer/fertilizer_location.dart';
import '../../models/fertilizer/fertilizer_product.dart';
import '../../models/fertilizer/fertilizer_recommendation.dart';
import '../../models/fertilizer/fertilizer_source.dart';
import 'fertilizer_seed_data.dart';

class FertilizerRepository {
  static final FertilizerRepository _instance =
      FertilizerRepository._internal();
  factory FertilizerRepository({bool useOfflineOnly = false}) {
    if (useOfflineOnly) {
      return FertilizerRepository._internal(offlineOnly: true);
    }
    return _instance;
  }
  FertilizerRepository._internal({this.offlineOnly = false});

  final bool offlineOnly;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // In-memory cache
  List<FertilizerCountry>? _cachedCountries;
  List<FertilizerCrop>? _cachedCrops;
  List<FertilizerProduct>? _cachedProducts;
  List<FertilizerRecommendation>? _cachedRecommendations;
  List<FertilizerSource>? _cachedSources;

  DateTime? _lastSyncTime;
  static const Duration _cacheTtl = Duration(hours: 4);

  bool get _isCacheValid =>
      _lastSyncTime != null &&
      DateTime.now().difference(_lastSyncTime!) < _cacheTtl;

  // ---------------------------------------------------------------------------
  // COUNTRIES
  // ---------------------------------------------------------------------------
  Future<List<FertilizerCountry>> getCountries({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCountries != null && _isCacheValid) {
      return _cachedCountries!;
    }
    if (offlineOnly) {
      _cachedCountries = List.from(FertilizerSeedData.countries);
      return _cachedCountries!;
    }
    try {
      final snapshot = await _firestore
          .collection('fertilizer_countries')
          .where('active', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        _cachedCountries = snapshot.docs
            .map((doc) => FertilizerCountry.fromMap(doc.data(), code: doc.id))
            .toList();
      } else {
        _cachedCountries = List.from(FertilizerSeedData.countries);
      }
    } catch (e) {
      developer.log(
        'Offline fallback for fertilizer countries: $e',
        name: 'FertilizerRepo',
      );
      _cachedCountries = List.from(FertilizerSeedData.countries);
    }
    return _cachedCountries!;
  }

  // ---------------------------------------------------------------------------
  // CROPS
  // ---------------------------------------------------------------------------
  Future<List<FertilizerCrop>> getCrops({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCrops != null && _isCacheValid) {
      return _cachedCrops!;
    }
    if (offlineOnly) {
      _cachedCrops = List.from(FertilizerSeedData.crops);
      return _cachedCrops!;
    }
    try {
      final snapshot = await _firestore
          .collection('fertilizer_crops')
          .where('active', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        _cachedCrops = snapshot.docs
            .map((doc) => FertilizerCrop.fromMap(doc.data(), id: doc.id))
            .toList();
      } else {
        _cachedCrops = List.from(FertilizerSeedData.crops);
      }
    } catch (e) {
      developer.log(
        'Offline fallback for fertilizer crops: $e',
        name: 'FertilizerRepo',
      );
      _cachedCrops = List.from(FertilizerSeedData.crops);
    }
    return _cachedCrops!;
  }

  // ---------------------------------------------------------------------------
  // PRODUCTS
  // ---------------------------------------------------------------------------
  Future<List<FertilizerProduct>> getProducts({
    String? countryCode,
    bool forceRefresh = false,
  }) async {
    if (offlineOnly) {
      _cachedProducts = List.from(FertilizerSeedData.products);
    } else if (forceRefresh || _cachedProducts == null || !_isCacheValid) {
      try {
        final snapshot = await _firestore
            .collection('fertilizer_products')
            .where('active', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 4));

        if (snapshot.docs.isNotEmpty) {
          _cachedProducts = snapshot.docs
              .map((doc) => FertilizerProduct.fromMap(doc.data(), id: doc.id))
              .toList();
        } else {
          _cachedProducts = List.from(FertilizerSeedData.products);
        }
      } catch (e) {
        developer.log(
          'Offline fallback for fertilizer products: $e',
          name: 'FertilizerRepo',
        );
        _cachedProducts = List.from(FertilizerSeedData.products);
      }
    }

    if (countryCode == null || countryCode.isEmpty) {
      return _cachedProducts!;
    }

    final code = countryCode.toUpperCase();
    return _cachedProducts!.where((p) {
      final pCode = p.countryCode.toUpperCase();
      return pCode == code || pCode == 'GLOBAL';
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // SOURCES
  // ---------------------------------------------------------------------------
  Future<List<FertilizerSource>> getSources({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSources != null && _isCacheValid) {
      return _cachedSources!;
    }
    if (offlineOnly) {
      _cachedSources = List.from(FertilizerSeedData.sources);
      return _cachedSources!;
    }
    try {
      final snapshot = await _firestore
          .collection('fertilizer_sources')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        _cachedSources = snapshot.docs
            .map((doc) => FertilizerSource.fromMap(doc.data(), id: doc.id))
            .toList();
      } else {
        _cachedSources = List.from(FertilizerSeedData.sources);
      }
    } catch (e) {
      developer.log(
        'Offline fallback for fertilizer sources: $e',
        name: 'FertilizerRepo',
      );
      _cachedSources = List.from(FertilizerSeedData.sources);
    }
    return _cachedSources!;
  }

  Future<FertilizerSource?> getSourceById(String sourceId) async {
    final sources = await getSources();
    try {
      return sources.firstWhere((s) => s.id == sourceId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // RECOMMENDATIONS
  // ---------------------------------------------------------------------------
  Future<List<FertilizerRecommendation>> getRecommendations({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedRecommendations != null && _isCacheValid) {
      return _cachedRecommendations!;
    }
    if (offlineOnly) {
      _cachedRecommendations = List.from(FertilizerSeedData.recommendations);
      _lastSyncTime = DateTime.now();
      return _cachedRecommendations!;
    }
    try {
      final snapshot = await _firestore
          .collection('fertilizer_recommendations')
          .where('active', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        _cachedRecommendations = snapshot.docs
            .map((doc) =>
                FertilizerRecommendation.fromMap(doc.data(), id: doc.id))
            .toList();
      } else {
        _cachedRecommendations = List.from(FertilizerSeedData.recommendations);
      }
      _lastSyncTime = DateTime.now();
    } catch (e) {
      developer.log(
        'Offline fallback for fertilizer recommendations: $e',
        name: 'FertilizerRepo',
      );
      _cachedRecommendations = List.from(FertilizerSeedData.recommendations);
      _lastSyncTime = DateTime.now();
    }
    return _cachedRecommendations!;
  }

  // ---------------------------------------------------------------------------
  // SEED TO FIRESTORE (ADMIN UTILITY)
  // ---------------------------------------------------------------------------
  Future<void> seedInitialDatabaseIfEmpty() async {
    try {
      final testDoc = await _firestore
          .collection('fertilizer_recommendations')
          .limit(1)
          .get();

      if (testDoc.docs.isEmpty) {
        developer.log(
          'Seeding initial fertilizer database to Firestore...',
          name: 'FertilizerRepo',
        );

        final batch = _firestore.batch();

        for (final country in FertilizerSeedData.countries) {
          final doc =
              _firestore.collection('fertilizer_countries').doc(country.code);
          batch.set(doc, country.toMap());
        }

        for (final crop in FertilizerSeedData.crops) {
          final doc = _firestore.collection('fertilizer_crops').doc(crop.id);
          batch.set(doc, crop.toMap());
        }

        for (final source in FertilizerSeedData.sources) {
          final doc =
              _firestore.collection('fertilizer_sources').doc(source.id);
          batch.set(doc, source.toMap());
        }

        for (final product in FertilizerSeedData.products) {
          final doc =
              _firestore.collection('fertilizer_products').doc(product.id);
          batch.set(doc, product.toMap());
        }

        for (final rec in FertilizerSeedData.recommendations) {
          final doc =
              _firestore.collection('fertilizer_recommendations').doc(rec.id);
          batch.set(doc, rec.toMap());
        }

        await batch.commit();
        developer.log('Seeding complete ✅', name: 'FertilizerRepo');
      }
    } catch (e) {
      developer.log(
        'Database seed skipped or error: $e',
        name: 'FertilizerRepo',
      );
    }
  }
}
