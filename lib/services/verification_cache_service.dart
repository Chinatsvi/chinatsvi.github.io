import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/verification_helpers.dart';

class VerificationCacheService {
  static final VerificationCacheService _instance =
      VerificationCacheService._internal();
  factory VerificationCacheService() => _instance;
  VerificationCacheService._internal();

  // Global user verification cache
  final Map<String, bool> _verifiedCache = {};
  final Map<String, Map<String, dynamic>> _userDataCache = {};

  // Cache timeout
  static const Duration _cacheTimeout = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Get verification status for a user
  bool isVerified(String userId) {
    return _verifiedCache[userId] ?? false;
  }

  /// Get user data for a user
  Map<String, dynamic> getUserData(String userId) {
    return _userDataCache[userId] ?? {};
  }

  /// Check if cache is expired for a user
  bool _isCacheExpired(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp) > _cacheTimeout;
  }

  /// Fetch verification data for missing users
  Future<void> fetchMissingUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;

    // Filter out users that are already cached and not expired
    final missingUsers = userIds
        .where((id) => !_verifiedCache.containsKey(id) || _isCacheExpired(id))
        .toSet()
        .toList();

    if (missingUsers.isEmpty) return;

    // Firestore whereIn has a limit of 10
    final chunks = <List<String>>[];
    for (int i = 0; i < missingUsers.length; i += 10) {
      chunks.add(missingUsers.skip(i).take(10).toList());
    }

    for (final chunk in chunks) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final bool isVerified = _calculateVerificationStatus(data);

          _verifiedCache[doc.id] = isVerified;
          _userDataCache[doc.id] = data;
          _cacheTimestamps[doc.id] = DateTime.now();
        }

        if (kDebugMode) {
          print('✅ Cached verification for ${snapshot.docs.length} users');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error fetching verification data: $e');
        }
      }
    }
  }

  /// Calculate verification status based on user data (matches AiService logic)
  bool _calculateVerificationStatus(Map<String, dynamic> userData) {
    if (userData.isEmpty) return false;

    final verificationStatus = userData['verificationStatus'] as String?;
    final isPaid = userData['verificationPaid'] as bool? ?? false;
    final expiryDate = resolveVerificationExpiryDate(userData);

    if (expiryDate != null && !DateTime.now().isBefore(expiryDate)) {
      debugPrint('Verification expired on $expiryDate');
      return false;
    }

    final isActive =
        verificationStatus != null &&
        verificationStatus.isNotEmpty &&
        isPaid &&
        (expiryDate == null || DateTime.now().isBefore(expiryDate));

    return isActive;
  }

  /// Preload verification data for a list of posts
  Future<void> preloadForPosts(List<Map<String, dynamic>> posts) async {
    final userIds = posts
        .map((post) => post['authorId'] as String? ?? post['userId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    await fetchMissingUsers(userIds);
  }

  /// Clear cache for a specific user (useful when verification status changes)
  void clearUserCache(String userId) {
    _verifiedCache.remove(userId);
    _userDataCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _verifiedCache.clear();
    _userDataCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedUsers': _verifiedCache.length,
      'userDataCache': _userDataCache.length,
      'cacheTimestamps': _cacheTimestamps.length,
    };
  }
}
