import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global follow state manager to sync follow state across all widgets
class FollowStateManager {
  static final FollowStateManager _instance = FollowStateManager._internal();
  factory FollowStateManager() => _instance;
  FollowStateManager._internal();

  final Map<String, bool> _followCache = {};
  final StreamController<Map<String, bool>> _followStateController =
      StreamController<Map<String, bool>>.broadcast();

  /// Stream that emits follow state changes
  Stream<Map<String, bool>> get followStateStream =>
      _followStateController.stream;

  /// Get cache key for user pair
  String getCacheKey(String currentUserId, String targetUserId) {
    return '${currentUserId}_$targetUserId';
  }

  /// Get follow state from cache
  bool? getFollowState(String currentUserId, String targetUserId) {
    return _followCache[getCacheKey(currentUserId, targetUserId)];
  }

  /// Update follow state and notify listeners
  void updateFollowState(
    String currentUserId,
    String targetUserId,
    bool isFollowing,
  ) {
    final cacheKey = getCacheKey(currentUserId, targetUserId);
    _followCache[cacheKey] = isFollowing;

    // Emit the updated state to all listeners
    _followStateController.add({cacheKey: isFollowing});
  }

  /// Initialize follow state from Firestore
  Future<void> initializeFollowState(
    String currentUserId,
    String targetUserId,
  ) async {
    // Guard against empty IDs
    if (currentUserId.trim().isEmpty || targetUserId.trim().isEmpty) {
      final cacheKey = getCacheKey(currentUserId, targetUserId);
      _followCache[cacheKey] = false;
      return;
    }

    final cacheKey = getCacheKey(currentUserId, targetUserId);

    if (_followCache.containsKey(cacheKey)) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final following = List<String>.from(data['following'] ?? []);
          final isFollowing = following.contains(targetUserId);
          // Set cache directly without notifying to prevent duplicate updates
          _followCache[cacheKey] = isFollowing;
        }
      }
    } catch (e) {
      // On error, default to not following
      _followCache[cacheKey] = false;
    }
  }

  /// Clear cache for a specific user pair (useful for debugging)
  void clearFollowState(String currentUserId, String targetUserId) {
    final cacheKey = getCacheKey(currentUserId, targetUserId);
    _followCache.remove(cacheKey);
  }

  /// Clear all cache (useful for logout)
  void clearAllCache() {
    _followCache.clear();
  }

  /// Dispose resources
  void dispose() {
    _followStateController.close();
  }
}
