import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

// Farmer status levels
enum FarmerStatus {
  good('good', 'Good Farmer', Colors.green),
  warning('warning', 'Under Review', Colors.orange),
  bad('bad', 'Restricted', Colors.red);

  const FarmerStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
}

class FarmerReputationService {
  static const String _reputationCollection = 'farmer_reputation';
  static const Duration _statusRefreshThreshold = Duration(minutes: 5);

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool shouldCountViolationReport(String? status) {
    // Missing status is treated as non-countable to avoid inflating reputation.
    if (status == null) return false;

    final normalizedStatus = status.toString().trim().toLowerCase();

    // Treat resolved/closed/dismissed/rejected reports as non-countable.
    const nonCountable = {
      'closed',
      'resolved',
      'dismissed',
      'rejected',
      'invalid'
    };

    return !nonCountable.contains(normalizedStatus);
  }

  static bool hasActiveManualAdminOverride(Map<String, dynamic>? data) {
    if (data == null) return false;

    final explicitOverride = data['manualAdminOverride'];
    if (explicitOverride is bool) {
      return explicitOverride;
    }

    final updatedBy = (data['reputationUpdatedBy'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return updatedBy == 'admin_manual';
  }

  static Future<bool> _hasNewViolationSince(
    String userId,
    DateTime lastUpdatedAt,
  ) async {
    try {
      final recentReport = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reportedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (recentReport.docs.isEmpty) {
        return false;
      }

      final latestCreatedAt = _parseTimestamp(
        recentReport.docs.first.data()['createdAt'],
      );
      if (latestCreatedAt == null) {
        return false;
      }

      return latestCreatedAt.isAfter(lastUpdatedAt);
    } catch (e) {
      developer.log(
        'Error checking latest moderation report for $userId: $e',
        name: 'FarmerReputationService',
      );
      return false;
    }
  }

  static FarmerStatus determineFarmerStatusFromScore(int totalScore) {
    if (totalScore >= 10) {
      return FarmerStatus.bad;
    } else if (totalScore >= 5) {
      return FarmerStatus.warning;
    }

    return FarmerStatus.good;
  }

  // Store reputation history for analytics and tracking
  static Future<void> _storeReputationHistory(
    String userId,
    FarmerStatus status,
    int totalScore,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(_reputationCollection)
          .doc(userId)
          .collection('history')
          .add({
            'status': status.value,
            'totalScore': totalScore,
            'calculatedAt': FieldValue.serverTimestamp(),
            'violationScore':
                totalScore, // Will be broken down further if needed
          });
    } catch (e) {
      developer.log(
        'Error storing reputation history for $userId: $e',
        name: 'FarmerReputationService',
      );
    }
  }

  // Calculate farmer reputation based on violations and reports
  static Future<FarmerStatus> calculateFarmerStatus(String userId) async {
    try {
      // Get violation reports against this farmer (including pending ones for immediate action)
      final violationReports = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      // Get user warnings
      final warnings = await FirebaseFirestore.instance
          .collection('user_warnings')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Get user bans (including expired ones for history)
      final bans = await FirebaseFirestore.instance
          .collection('user_bans')
          .where('userId', isEqualTo: userId)
          .get();

      developer.log(
        '📊 Farmer $userId moderation query counts: reports=${violationReports.docs.length}, warnings=${warnings.docs.length}, bans=${bans.docs.length}',
        name: 'FarmerReputationService',
      );

      // Calculate scores
      int violationScore = 0;
      int warningScore = warnings.docs.length;
      int banScore = 0;

      // Score violations based on type and recency
      final now = DateTime.now();
      for (final doc in violationReports.docs) {
        final data = doc.data();
        final status = data['status']?.toString();

        if (!shouldCountViolationReport(status)) {
          continue;
        }

        final createdAt = _parseTimestamp(data['createdAt']);

        if (createdAt != null) {
          final daysSince = now.difference(createdAt).inDays;

          // Recent violations (last 30 days) have higher weight
          if (daysSince <= 30) {
            violationScore += 3;
          } else if (daysSince <= 90) {
            violationScore += 2;
          } else {
            violationScore += 1;
          }
        }
      }

      // Score bans (permanent bans are very serious)
      for (final doc in bans.docs) {
        final data = doc.data();
        final isPermanent = data['isPermanent'] ?? false;

        if (isPermanent) {
          banScore += 10;
        } else {
          banScore += 5;
        }
      }

      // Calculate total score
      final totalScore = violationScore + (warningScore * 2) + banScore;

      // Determine status based on score
      final status = determineFarmerStatusFromScore(totalScore);

      // Store reputation history for tracking
      await _storeReputationHistory(userId, status, totalScore);

      developer.log(
        '📊 Farmer $userId status calculated: ${status.value} (score: $totalScore)',
        name: 'FarmerReputationService',
      );

      return status;
    } catch (e) {
      developer.log(
        'Error calculating farmer status: $e',
        name: 'FarmerReputationService',
      );
      return FarmerStatus.good; // Default to good on error
    }
  }

  // Refresh farmer status in their profile immediately
  static Future<FarmerStatus> refreshFarmerStatus(String userId) async {
    try {
      final status = await calculateFarmerStatus(userId);

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .update({
            'reputationStatus': status.value,
            'reputationUpdatedAt': FieldValue.serverTimestamp(),
          });

      developer.log(
        '✅ Refreshed farmer $userId status to ${status.value}',
        name: 'FarmerReputationService',
      );
      return status;
    } catch (e) {
      developer.log(
        '❌ Error refreshing farmer status: $e',
        name: 'FarmerReputationService',
      );
      return FarmerStatus.good;
    }
  }

  // Update farmer status in their profile
  static Future<void> updateFarmerStatus(String userId) async {
    await refreshFarmerStatus(userId);
  }

  // Get farmer current status
  static bool shouldRefreshStatus(
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    bool forceRefresh,
    bool hasRecentViolationRefresh,
  ) {
    final hasManualAdminOverride = hasActiveManualAdminOverride(data);

    if (forceRefresh) {
      return !hasManualAdminOverride || hasRecentViolationRefresh;
    }

    final statusValue = data?['reputationStatus'] as String?;
    final hasStaleStatus =
        statusValue == null ||
        statusValue.isEmpty ||
        updatedAt == null ||
        DateTime.now().difference(updatedAt) > _statusRefreshThreshold;

    return hasStaleStatus || hasRecentViolationRefresh;
  }

  static Future<FarmerStatus> getFarmerStatus(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (!doc.exists) return FarmerStatus.good;

      final data = doc.data();
      final statusValue = data?['reputationStatus'] as String?;
      final updatedAt = _parseTimestamp(data?['reputationUpdatedAt']);
      final hasManualAdminOverride = hasActiveManualAdminOverride(data);
      final needsRecentViolationRefresh = updatedAt != null
          ? await _hasNewViolationSince(userId, updatedAt)
          : true;

      if (hasManualAdminOverride && !needsRecentViolationRefresh) {
        developer.log(
          '🛡️ Preserving manual admin override for $userId without new violations',
          name: 'FarmerReputationService',
        );
        return statusValue == 'warning'
            ? FarmerStatus.warning
            : statusValue == 'bad'
                ? FarmerStatus.bad
                : FarmerStatus.good;
      }

      if (shouldRefreshStatus(
        data,
        updatedAt,
        forceRefresh,
        needsRecentViolationRefresh,
      )) {
        developer.log(
          '🔄 Refreshing stale or missing farmer status for $userId (cachedStatus=$statusValue, needsRecentViolationRefresh=$needsRecentViolationRefresh)',
          name: 'FarmerReputationService',
        );
        await updateFarmerStatus(userId);
        final refreshedDoc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(userId)
            .get();
        final refreshedData = refreshedDoc.data();
        final refreshedStatusValue =
            refreshedData?['reputationStatus'] as String?;

        switch (refreshedStatusValue) {
          case 'warning':
            return FarmerStatus.warning;
          case 'bad':
            return FarmerStatus.bad;
          case 'good':
          default:
            return FarmerStatus.good;
        }
      }

      switch (statusValue) {
        case 'warning':
          return FarmerStatus.warning;
        case 'bad':
          return FarmerStatus.bad;
        case 'good':
        default:
          return FarmerStatus.good;
      }
    } catch (e) {
      developer.log(
        'Error getting farmer status: $e',
        name: 'FarmerReputationService',
      );
      return FarmerStatus.good;
    }
  }

  // Check if farmer can post content
  static Future<bool> canPostContent(String userId) async {
    final status = await getFarmerStatus(userId);
    return status != FarmerStatus.bad;
  }

  static double getVisibilityMultiplierForStatus(FarmerStatus status) {
    switch (status) {
      case FarmerStatus.good:
        return 1.8; // Strong base visibility for trusted farmers
      case FarmerStatus.warning:
        return 0.7; // Reduced visibility while under review
      case FarmerStatus.bad:
        return 0.2; // Much lower visibility for restricted farmers
    }
  }

  // Get content visibility boost factor based on reputation
  static Future<double> getContentVisibilityBoost(String userId) async {
    final status = await getFarmerStatus(userId);
    return getVisibilityMultiplierForStatus(status);
  }

  // Update status when moderation action is taken
  static Future<void> onModerationAction(String userId) async {
    await updateFarmerStatus(userId);
  }

  // Get reputation history for admin
  static Future<Map<String, dynamic>> getReputationHistory(
    String userId,
  ) async {
    try {
      final violations = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reportedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final warnings = await FirebaseFirestore.instance
          .collection('user_warnings')
          .where('userId', isEqualTo: userId)
          .orderBy('issuedAt', descending: true)
          .limit(5)
          .get();

      final bans = await FirebaseFirestore.instance
          .collection('user_bans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return {
        'violations': violations.docs.map((doc) => doc.data()).toList(),
        'warnings': warnings.docs.map((doc) => doc.data()).toList(),
        'bans': bans.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      developer.log(
        'Error getting reputation history: $e',
        name: 'FarmerReputationService',
      );
      return {};
    }
  }
}
