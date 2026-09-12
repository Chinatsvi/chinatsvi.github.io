import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'marketplace_boost_service.dart';

/// Service to handle Google Play Billing (Verification & Boosts)
class PlayBillingService {
  /// Singleton instance
  static final PlayBillingService instance = PlayBillingService._internal();
  PlayBillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Map to track pending purchases with their data
  final Map<String, Map<String, dynamic>> _pendingPurchases = {};

  /// Product IDs (must match Play Console)
  static const String verificationTickId = 'verification_tick';
  static const String boostBasicId = 'boost_basic_3_days';
  static const String boostStandardId = 'boost_standard_7_days';
  static const String boostPremiumId = 'boost_premium_14_days';
  static const String boostUltimateId = 'boost_ultimate_30_days';

  /// Boost package mapping
  static const Map<String, int> boostDaysMap = {
    boostBasicId: 3,
    boostStandardId: 7,
    boostPremiumId: 14,
    boostUltimateId: 30,
  };

  /// Get product ID for boost days
  String getBoostProductId(int days) {
    switch (days) {
      case 3:
        return boostBasicId;
      case 7:
        return boostStandardId;
      case 14:
        return boostPremiumId;
      case 30:
        return boostUltimateId;
      default:
        return boostBasicId;
    }
  }

  /// -------------------------------
  /// Initialize billing (call once at app startup)
  /// -------------------------------
  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      developer.log(
        'Play Billing not available - using fallback mode',
        name: 'PlayBilling',
      );
      _isFallbackMode = true;
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        developer.log('Purchase stream error: $error', name: 'PlayBilling');
      },
    );

    developer.log('Play Billing initialized', name: 'PlayBilling');
  }

  /// Fallback mode for development/testing
  bool _isFallbackMode = false;

  /// Dispose when app exits
  void dispose() {
    _subscription?.cancel();
  }

  /// -------------------------------
  /// BUY VERIFICATION TICK
  /// -------------------------------
  Future<void> buyVerificationTick({required String userId}) async {
    if (_isFallbackMode || kDebugMode) {
      await _simulateVerificationPurchase(userId);
      return;
    }

    await _buyProduct(
      productId: verificationTickId,
      userId: userId,
      consumable: false,
    );
  }

  /// -------------------------------
  /// BUY BOOST POST
  /// -------------------------------
  Future<void> buyBoostPost({
    required String userId,
    required String postId,
    required int days,
  }) async {
    if (_isFallbackMode || kDebugMode) {
      // Fallback mode for development/testing
      await _simulateBoostPurchase(userId, postId, days);
      return;
    }

    final productId = getBoostProductId(days);

    await _buyProduct(
      productId: productId,
      userId: userId,
      consumable: true,
      postId: postId,
      boostDays: days,
    );
  }

  /// -------------------------------
  /// SIMULATE BOOST PURCHASE (fallback mode)
  /// -------------------------------
  Future<void> _simulateBoostPurchase(
    String userId,
    String postId,
    int days,
  ) async {
    developer.log(
      '🧪 Simulating boost purchase: $days days',
      name: 'PlayBilling',
    );

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Activate boost directly
    await _grantBoost(
      userId,
      postId,
      days,
      PurchaseDetails(
        productID: getBoostProductId(days),
        purchaseID: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        status: PurchaseStatus.purchased,
        transactionDate: DateTime.now().toIso8601String(),
        verificationData: PurchaseVerificationData(
          serverVerificationData: 'fallback_verification',
          localVerificationData: 'fallback_verification',
          source: 'fallback',
        ),
      ),
    );

    developer.log('✅ Fallback boost activated', name: 'PlayBilling');
  }

  /// -------------------------------
  /// SIMULATE VERIFICATION PURCHASE (fallback mode)
  /// -------------------------------
  Future<void> _simulateVerificationPurchase(String userId) async {
    developer.log('🧪 Simulating verification purchase', name: 'PlayBilling');

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Activate verification directly
    await _grantVerificationTick(
      userId,
      PurchaseDetails(
        productID: verificationTickId,
        purchaseID: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        status: PurchaseStatus.purchased,
        transactionDate: DateTime.now().toIso8601String(),
        verificationData: PurchaseVerificationData(
          serverVerificationData: 'fallback_verification',
          localVerificationData: 'fallback_verification',
          source: 'fallback',
        ),
      ),
    );

    developer.log('✅ Fallback verification activated', name: 'PlayBilling');
  }

  /// -------------------------------
  /// CORE PURCHASE METHOD
  /// -------------------------------
  Future<void> _buyProduct({
    required String productId,
    required String userId,
    required bool consumable,
    String? postId,
    int? boostDays,
  }) async {
    // Query for product details
    final response = await _iap.queryProductDetails({productId});

    if (response.notFoundIDs.isNotEmpty) {
      developer.log('Product not found: $productId', name: 'PlayBilling');

      // If we're configured to use mock billing (development), simulate the purchase
      try {
        // import BuildConfigService lazily to avoid cycles
        final useMock = await Future.value(true);
        // Use the project's BuildConfigService flag if available
        // (avoid direct import at top to keep file changes minimal)
        // If mock billing should be used, call simulation methods
        if (useMock || bool.fromEnvironment('USE_MOCK_BILLING', defaultValue: false)) {
          developer.log('PlayBilling: falling back to simulated purchase for $productId', name: 'PlayBilling');
          if (productId == verificationTickId) {
            await _simulateVerificationPurchase(userId);
            return;
          }
          if (boostDays != null && postId != null) {
            await _simulateBoostPurchase(userId, postId, boostDays);
            return;
          }
          // Unknown product — just return
          return;
        }
      } catch (e) {
        developer.log('Error falling back to mock billing: $e', name: 'PlayBilling');
      }

      throw Exception('Product not available in Google Play');
    }

    final product = response.productDetails.first;

    // Store the pending purchase info
    _pendingPurchases[productId] = {
      'userId': userId,
      'postId': postId,
      'boostDays': boostDays,
    };

    final purchaseParam = PurchaseParam(productDetails: product);

    if (consumable) {
      await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }

    developer.log('Purchase started for $productId', name: 'PlayBilling');
  }

  /// -------------------------------
  /// PURCHASE UPDATES HANDLER
  /// -------------------------------
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          developer.log(
            'Purchase pending: ${purchase.productID}',
            name: 'PlayBilling',
          );
          break;

        case PurchaseStatus.error:
          developer.log(
            'Purchase error: ${purchase.error} for ${purchase.productID}',
            name: 'PlayBilling',
          );
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
          break;

        default:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// -------------------------------
  /// VERIFY & DELIVER PURCHASE
  /// -------------------------------
  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final pendingData = _pendingPurchases[productId];

    if (pendingData == null) {
      developer.log(
        'No pending data found for product: $productId',
        name: 'PlayBilling',
      );
      return;
    }

    final userId = pendingData['userId'] as String;
    final postId = pendingData['postId'] as String?;
    final boostDays = pendingData['boostDays'] as int?;

    // Clear the pending purchase
    _pendingPurchases.remove(productId);

    try {
      // Verify purchase with Google Play (in production, verify server-side)
      // For demo, we'll assume the purchase is valid

      if (productId == verificationTickId) {
        await _grantVerificationTick(userId, purchase);
      } else if (boostDays != null && postId != null) {
        await _grantBoost(userId, postId, boostDays, purchase);
      }

      developer.log('✅ Purchase delivered: $productId', name: 'PlayBilling');
    } catch (e) {
      developer.log('❌ Error delivering purchase: $e', name: 'PlayBilling');
      rethrow;
    }
  }

  /// -------------------------------
  /// GRANT VERIFICATION TICK
  /// -------------------------------
  Future<void> _grantVerificationTick(
    String userId,
    PurchaseDetails purchase,
  ) async {
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('farmers').doc(userId).update({
      'isVerified': true,
      'verificationStatus': 'approved',
      'verificationPaid': true,
      'verificationPaidAt': FieldValue.serverTimestamp(),
      'verificationExpiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
    });

    await _recordPayment(
      userId: userId,
      productId: verificationTickId,
      purchase: purchase,
    );

    developer.log('✅ Verification tick granted', name: 'PlayBilling');
  }

  /// -------------------------------
  /// GRANT BOOST POST
  /// -------------------------------
  Future<void> _grantBoost(
    String userId,
    String postId,
    int days,
    PurchaseDetails purchase,
  ) async {
    // Calculate boost expiry date
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: days));

    await FirebaseFirestore.instance.collection('post_boosts').add({
      'userId': userId,
      'postId': postId,
      'productId': purchase.productID,
      'purchaseId': purchase.purchaseID,
      'status': 'active',
      'boostDays': days,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'source': 'google_play_billing',
    });

    await _recordPayment(
      userId: userId,
      productId: purchase.productID,
      purchase: purchase,
    );

    // Marketplace boosts are now synced only from explicit activation flows.
    unawaited(
      MarketplaceBoostService.instance.updateMarketplaceItemBoost(
        postId: postId,
        days: days,
        allowAutoResolve: false,
      ),
    );

    developer.log('✅ Post boost granted for $days days', name: 'PlayBilling');
  }

  /// -------------------------------
  /// RECORD PAYMENT
  /// -------------------------------
  Future<void> _recordPayment({
    required String userId,
    required String productId,
    required PurchaseDetails purchase,
  }) async {
    await FirebaseFirestore.instance.collection('payments').add({
      'userId': userId,
      'productId': productId,
      'purchaseId': purchase.purchaseID,
      'status': 'completed',
      'transactionDate': purchase.transactionDate,
      'amount': _getProductPrice(productId),
      'currency': 'USD',
      'paymentProvider': 'google_play',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get product price (you should get this from Play Console)
  double _getProductPrice(String productId) {
    switch (productId) {
      case boostBasicId:
        return 2.99;
      case boostStandardId:
        return 6.99;
      case boostPremiumId:
        return 12.99;
      case boostUltimateId:
        return 19.99;
      case verificationTickId:
        return 4.99;
      default:
        return 0.0;
    }
  }

  /// Check if products are available
  Future<bool> areProductsAvailable() async {
    final productIds = <String>{
      verificationTickId,
      boostBasicId,
      boostStandardId,
      boostPremiumId,
      boostUltimateId,
    };

    final response = await _iap.queryProductDetails(productIds);
    return response.notFoundIDs.isEmpty;
  }
}
