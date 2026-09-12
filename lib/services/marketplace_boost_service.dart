import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle marketplace item boosts
class MarketplaceBoostService {
  /// Singleton instance
  static final MarketplaceBoostService instance =
      MarketplaceBoostService._internal();
  MarketplaceBoostService._internal();

  /// Resolve which marketplace item should receive the boost update.
  /// By default, only explicit marketplace item IDs are allowed so the
  /// automatic listener cannot touch unrelated items.
  String? resolveMarketplaceItemId({
    String? marketplaceItemId,
    String? postId,
    bool allowAutoResolve = false,
  }) {
    if (marketplaceItemId != null && marketplaceItemId.isNotEmpty) {
      return marketplaceItemId;
    }

    if (!allowAutoResolve) {
      return null;
    }

    if (postId != null && postId.isNotEmpty) {
      return postId;
    }

    return null;
  }

  /// Update marketplace item when post is boosted
  Future<void> updateMarketplaceItemBoost({
    required String postId,
    required int days,
    String? marketplaceItemId,
    bool allowAutoResolve = false,
  }) async {
    try {
      final resolvedMarketplaceId = resolveMarketplaceItemId(
        marketplaceItemId: marketplaceItemId,
        postId: postId,
        allowAutoResolve: allowAutoResolve,
      );

      if (resolvedMarketplaceId == null) {
        developer.log(
          'Skipping marketplace boost update for $postId because no explicit item ID was provided',
          name: 'MarketplaceBoost',
        );
        return;
      }

      String? marketplaceId = resolvedMarketplaceId;
      final colNames = ['marketplace', 'Marketplace'];

      if (allowAutoResolve && resolvedMarketplaceId == postId) {
        // If auto-resolve is enabled and the caller passed a post ID, try to
        // locate the actual marketplace item document by postId or doc id.
        for (final col in colNames) {
          final byField = await FirebaseFirestore.instance
              .collection(col)
              .where('postId', isEqualTo: postId)
              .limit(1)
              .get();
          if (byField.docs.isNotEmpty) {
            marketplaceId = byField.docs.first.id;
            break;
          }

          final byId = await FirebaseFirestore.instance
              .collection(col)
              .doc(postId)
              .get();
          if (byId.exists) {
            marketplaceId = byId.id;
            break;
          }
        }
      }

      if (marketplaceId == null) {
        developer.log(
          'No marketplace item found for post $postId',
          name: 'MarketplaceBoost',
        );
        return;
      }

      // Calculate boost expiry
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: days));

      // Update marketplace item with boost info
      // Update both collection name variants to be tolerant
      for (final col in colNames) {
        final ref = FirebaseFirestore.instance.collection(col).doc(marketplaceId);
        final snap = await ref.get();
        if (snap.exists) {
          final data = snap.data();
          final status = data?['status']?.toString().toLowerCase().trim();
          if (status == 'sold' || status == 'removed') {
            developer.log(
              'Skipping boost for item $marketplaceId because status is $status',
              name: 'MarketplaceBoost',
            );
            await ref.update({
              'isBoosted': false,
              'boostExpiresAt': null,
              'boostEndDate': null,
            });
            continue;
          }

          await ref.update({
            'isBoosted': true,
            'is_boosted': true,
            'boostExpiresAt': Timestamp.fromDate(expiresAt),
            'boostEndDate': Timestamp.fromDate(expiresAt),
            'boostDays': days,
            'paidAt': FieldValue.serverTimestamp(),
            'paymentDate': FieldValue.serverTimestamp(),
            'activatedAt': FieldValue.serverTimestamp(),
            'boostStartedAt': FieldValue.serverTimestamp(),
            'boostUpdatedAt': FieldValue.serverTimestamp(),
          });
          developer.log(
            'Updated $col/$marketplaceId with active boost metadata',
            name: 'MarketplaceBoost',
          );
        }
      }

      developer.log(
        '✅ Marketplace item $marketplaceId boosted for $days days',
        name: 'MarketplaceBoost',
      );
    } catch (e) {
      developer.log(
        '❌ Error updating marketplace boost: $e',
        name: 'MarketplaceBoost',
      );
    }
  }

  /// Listen to post boosts and update marketplace items.
  /// This is intentionally disabled by default so marketplace boost state is
  /// only updated from explicit payment/approval flows.
  void startBoostListener({bool enabled = false}) {
    if (!enabled) {
      developer.log(
        'Marketplace boost listener disabled; explicit-only sync is active',
        name: 'MarketplaceBoost',
      );
      return;
    }

    FirebaseFirestore.instance
        .collection('post_boosts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final boostData = doc.doc.data();
              final postId = boostData?['postId'] as String?;
              final boostDays = boostData?['boostDays'] as int?;

              if (postId != null && boostDays != null) {
                updateMarketplaceItemBoost(
                  postId: postId,
                  days: boostDays,
                  allowAutoResolve: true,
                );
              }
            }
          }
        });
  }

  /// Clean up expired boosts from both collection variants and posts
  Future<void> cleanupExpiredBoosts() async {
    try {
      final now = DateTime.now();
      int totalCleaned = 0;

      // Try both collection name variants
      for (final collectionName in ['Marketplace', 'marketplace']) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .where('isBoosted', isEqualTo: true)
              .get();

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawBoostEnd =
                data['boostExpiresAt'] ??
                data['boostEndDate'] ??
                data['boost_expires_at'] ??
                data['boost_end_date'] ??
                data['expiresAt'] ??
                data['expires_at'] ??
                data['endDate'] ??
                data['end_date'] ??
                data['boostExpireDate'] ??
                data['boost_expire_date'] ??
                data['boostEnd'] ??
                data['boost_end'] ??
                data['expiryDate'] ??
                data['expiry_date'];

            DateTime? expiryDate;
            if (rawBoostEnd is Timestamp) {
              expiryDate = rawBoostEnd.toDate();
            } else if (rawBoostEnd is DateTime) {
              expiryDate = rawBoostEnd;
            } else if (rawBoostEnd is int) {
              expiryDate = rawBoostEnd > 100000000000
                  ? DateTime.fromMillisecondsSinceEpoch(rawBoostEnd)
                  : DateTime.fromMillisecondsSinceEpoch(rawBoostEnd * 1000);
            } else if (rawBoostEnd is String) {
              expiryDate = DateTime.tryParse(rawBoostEnd);
            }

            final status = data['status']?.toString().toLowerCase().trim();
            final isExpired = status == 'sold' ||
                status == 'removed' ||
                expiryDate == null ||
                !expiryDate.isAfter(now);
            if (isExpired) {
              await doc.reference.update({
                'isBoosted': false,
                'boostExpiresAt': null,
                'boostEndDate': null,
                'boostExpiredAt': FieldValue.serverTimestamp(),
              });
              totalCleaned++;
            }
          }

          developer.log(
            '✅ Cleaned up $totalCleaned expired boosts from "$collectionName"',
            name: 'MarketplaceBoost',
          );
        } catch (e) {
          developer.log(
            '⚠️ Error cleaning from collection "$collectionName": $e',
            name: 'MarketplaceBoost',
          );
        }
      }

      // Also clean up expired boosts in posts collection
      try {
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('isBoosted', isEqualTo: true)
            .get();

        for (final doc in postsSnapshot.docs) {
          final data = doc.data();
          final rawBoostEnd =
              data['boostEndDate'] ??
              data['boostExpiresAt'] ??
              data['boost_end_date'] ??
              data['boost_expires_at'] ??
              data['expiresAt'] ??
              data['endDate'];

          DateTime? expiryDate;
          if (rawBoostEnd is Timestamp) {
            expiryDate = rawBoostEnd.toDate();
          } else if (rawBoostEnd is DateTime) {
            expiryDate = rawBoostEnd;
          } else if (rawBoostEnd is int) {
            expiryDate = rawBoostEnd > 100000000000
                ? DateTime.fromMillisecondsSinceEpoch(rawBoostEnd)
                : DateTime.fromMillisecondsSinceEpoch(rawBoostEnd * 1000);
          } else if (rawBoostEnd is String) {
            expiryDate = DateTime.tryParse(rawBoostEnd);
          }

          final isExpired = expiryDate == null || !expiryDate.isAfter(now);
          if (isExpired) {
            await doc.reference.update({
              'isBoosted': false,
              'boostExpiresAt': null,
              'boostEndDate': null,
              'boostExpiredAt': FieldValue.serverTimestamp(),
            });
            totalCleaned++;
          }
        }
      } catch (e) {
        developer.log(
          '⚠️ Error cleaning expired boosts in posts collection: $e',
          name: 'MarketplaceBoost',
        );
      }

      developer.log(
        '🧹 Cleanup complete: $totalCleaned expired boosts removed across collections',
        name: 'MarketplaceBoost',
      );
    } catch (e) {
      developer.log(
        '❌ Error in cleanupExpiredBoosts: $e',
        name: 'MarketplaceBoost',
      );
    }
  }

  /// Get boosted marketplace items (queries both collection name variants)
  Future<List<Map<String, dynamic>>> getBoostedItems() async {
    try {
      final now = Timestamp.now();
      final allBoosted = <Map<String, dynamic>>[];

      // Try both collection name variants
      for (final collectionName in ['Marketplace', 'marketplace']) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .where('isBoosted', isEqualTo: true)
              .where('boostExpiresAt', isGreaterThan: now)
              .orderBy('boostExpiresAt', descending: true)
              .get();

          allBoosted.addAll(snapshot.docs.map((doc) => doc.data()));
        } catch (e) {
          developer.log(
            '⚠️ Error querying "$collectionName": $e',
            name: 'MarketplaceBoost',
          );
        }
      }

      // Remove duplicates by ID if present in both collections
      final uniqueMap = <String, Map<String, dynamic>>{};
      for (final item in allBoosted) {
        final id = item['id'] ?? item.hashCode.toString();
        uniqueMap[id] = item;
      }

      return uniqueMap.values.toList();
    } catch (e) {
      developer.log(
        '❌ Error getting boosted items: $e',
        name: 'MarketplaceBoost',
      );
      return [];
    }
  }
}
