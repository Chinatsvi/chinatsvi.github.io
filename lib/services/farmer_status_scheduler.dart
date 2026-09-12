import 'package:cloud_firestore/cloud_firestore.dart';
import 'farmer_reputation_service.dart';

class FarmerStatusScheduler {
  static const String _statusScheduleCollection = 'status_schedules';

  // Status recovery periods (in days)
  static const Map<String, int> _recoveryPeriods = {
    'warning': 14, // 14 days without violations to go from warning to good
    'bad': 30, // 30 days without violations to go from bad to warning
  };

  // Schedule automatic status check for a farmer
  static Future<void> scheduleStatusCheck(
    String farmerId,
    String currentStatus,
  ) async {
    try {
      final recoveryPeriod = _recoveryPeriods[currentStatus];
      if (recoveryPeriod == null)
        return; // No recovery needed for 'good' status

      final scheduledDate = DateTime.now().add(Duration(days: recoveryPeriod));

      // Create or update schedule document
      await FirebaseFirestore.instance
          .collection(_statusScheduleCollection)
          .doc(farmerId)
          .set({
            'farmerId': farmerId,
            'currentStatus': currentStatus,
            'scheduledCheckDate': scheduledDate.toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });

      print('✅ Status check scheduled for $farmerId on $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling status check: $e');
    }
  }

  // Check if farmer is eligible for status improvement
  static Future<bool> checkStatusImprovement(String farmerId) async {
    try {
      print('🔍 Checking status improvement for farmer: $farmerId');

      // Get current status
      final currentStatusEnum = await FarmerReputationService.getFarmerStatus(
        farmerId,
      );
      final currentStatus = currentStatusEnum.value;
      print('Current status: $currentStatus');

        // Get schedule info
      final scheduleDoc = await FirebaseFirestore.instance
          .collection(_statusScheduleCollection)
          .doc(farmerId)
          .get();

      if (!scheduleDoc.exists) {
        print('No schedule found for farmer: $farmerId');
        return false;
      }

      // If admin manually overrode status, don't auto-change it.
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .get();
      final farmerData = farmerDoc.exists ? farmerDoc.data() : null;
      if (farmerData != null && (farmerData['manualAdminOverride'] == true)) {
        print('🛡️ Manual admin override present — skipping automatic improvement for $farmerId');
        // Mark schedule completed to avoid repeated checks
        await scheduleDoc.reference.update({'status': 'completed'});
        return false;
      }

      final scheduleData = scheduleDoc.data()!;
      final scheduledDate = DateTime.parse(scheduleData['scheduledCheckDate']);
      print('Scheduled date: $scheduledDate');

      if (DateTime.now().isBefore(scheduledDate)) {
        print('Not time yet for status check');
        return false; // Not time yet
      }

      // Check for new violations since last status change
      final createdAt = scheduleData['createdAt'] as Timestamp?;
      if (createdAt == null) {
        print('No createdAt found in schedule');
        return false;
      }

      final hasNewViolations = await _hasNewViolations(farmerId, createdAt);
      print('Has new violations: $hasNewViolations');

      if (!hasNewViolations) {
        // Improve status one step and schedule next check if needed
        await _improveFarmerStatus(farmerId, currentStatus);

        // Mark this schedule as completed
        await scheduleDoc.reference.update({'status': 'completed'});

        print('✅ Farmer $farmerId status improved from $currentStatus');
        return true;
      } else {
        // Reset schedule for another period (start counting again from now)
        await scheduleStatusCheck(farmerId, currentStatus);

        print('⚠️ Farmer $farmerId has new violations, schedule reset');
        return false;
      }
    } catch (e) {
      print('❌ Error checking status improvement for $farmerId: $e');
      return false;
    }
  }

  // Check if farmer has new violations since given date
  static Future<bool> _hasNewViolations(
    String farmerId,
    Timestamp? sinceDate,
  ) async {
    try {
      if (sinceDate == null) return true;

      print('Checking for violations since: ${sinceDate.toDate()}');

      // Check for new violation reports
      try {
        final violationReports = await FirebaseFirestore.instance
            .collection('moderation_reports')
            .where('reportedUserId', isEqualTo: farmerId)
            .where('createdAt', isGreaterThan: sinceDate)
            .get();

        if (violationReports.docs.isNotEmpty) {
          print('Found ${violationReports.docs.length} new violation reports');
          return true;
        }
      } catch (e) {
        print('Error checking violation reports: $e');
        // Continue checking other collections
      }

      // Check for new warnings
      try {
        final warnings = await FirebaseFirestore.instance
            .collection('user_warnings')
            .where('userId', isEqualTo: farmerId)
            .where('issuedAt', isGreaterThan: sinceDate)
            .get();

        if (warnings.docs.isNotEmpty) {
          print('Found ${warnings.docs.length} new warnings');
          return true;
        }
      } catch (e) {
        print('Error checking warnings: $e');
        // Continue checking other collections
      }

      // Check for new bans
      try {
        final bans = await FirebaseFirestore.instance
            .collection('user_bans')
            .where('userId', isEqualTo: farmerId)
            .where('createdAt', isGreaterThan: sinceDate)
            .get();

        if (bans.docs.isNotEmpty) {
          print('Found ${bans.docs.length} new bans');
          return true;
        }
      } catch (e) {
        print('Error checking bans: $e');
        // Continue checking other collections
      }

      print('No new violations found');
      return false;
    } catch (e) {
      print('Error checking for new violations: $e');
      return true; // Assume there are violations on error for safety
    }
  }

  // Improve farmer status by one level
  static Future<void> _improveFarmerStatus(
    String farmerId,
    String currentStatus,
  ) async {
    String newStatus;

    switch (currentStatus) {
      case 'bad':
        newStatus = 'warning';
        break;
      case 'warning':
        newStatus = 'good';
        break;
      default:
        newStatus = 'good';
    }

    await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
      'reputationStatus': newStatus,
      'reputationUpdatedAt': FieldValue.serverTimestamp(),
      'reputationUpdatedBy': 'system',
      'manualAdminOverride': false,
      'reputationChangeReason':
          'Automatic improvement after $currentStatus period without violations',
    });

    print('✅ Farmer $farmerId status automatically improved to $newStatus');

    // If the new status still requires another waiting period (e.g., moved from 'bad'->'warning'),
    // schedule the next automatic check (warning -> good after its own recovery period).
    if (newStatus != 'good') {
      await scheduleStatusCheck(farmerId, newStatus);
      print('🔔 Scheduled next check for $farmerId after improving to $newStatus');
    }
  }

  // Call this when a farmer gets a new violation to reset their schedule
  static Future<void> resetStatusSchedule(String farmerId) async {
    try {
      final currentStatusEnum = await FarmerReputationService.getFarmerStatus(
        farmerId,
      );
      final currentStatus = currentStatusEnum.value;

      await scheduleStatusCheck(farmerId, currentStatus);

      print(
        '🔄 Status schedule reset for $farmerId with status $currentStatus',
      );
    } catch (e) {
      print('❌ Error resetting status schedule: $e');
    }
  }

  // Run scheduled checks (call this periodically, e.g., daily)
  static Future<void> runScheduledChecks() async {
    try {
      print('🔍 Running scheduled status checks...');

      // Check if collection exists and is accessible
      final collectionRef = FirebaseFirestore.instance.collection(
        _statusScheduleCollection,
      );

      final schedules = await collectionRef
          .where('status', isEqualTo: 'pending')
          .where(
            'scheduledCheckDate',
            isLessThanOrEqualTo: DateTime.now().toIso8601String(),
          )
          .get();

      print('Found ${schedules.docs.length} pending schedules to check');

      int improvedCount = 0;
      int resetCount = 0;
      int errorCount = 0;

      for (final schedule in schedules.docs) {
        try {
          final farmerId = schedule['farmerId'] as String;
          print('Processing farmer: $farmerId');

          final improved = await checkStatusImprovement(farmerId);

          if (improved) {
            improvedCount++;
            print('✅ Farmer $farmerId status improved');
          } else {
            resetCount++;
            print('🔄 Farmer $farmerId schedule reset');
          }
        } catch (e) {
          errorCount++;
          print('❌ Error processing schedule ${schedule.id}: $e');
        }
      }

      final result =
          '✅ Scheduled checks completed: $improvedCount improved, $resetCount reset, $errorCount errors';
      print(result);

      // Return success if we processed at least one schedule or had no errors
      if (schedules.docs.isEmpty ||
          (improvedCount + resetCount) > 0 ||
          errorCount == 0) {
        return;
      } else {
        throw Exception('Failed to process all schedules: $errorCount errors');
      }
    } catch (e) {
      final errorMsg = '❌ Error running scheduled checks: $e';
      print(errorMsg);
      throw Exception(errorMsg);
    }
  }

  // Get all farmers with pending status checks
  static Future<List<Map<String, dynamic>>> getPendingStatusChecks() async {
    try {
      print('🔍 Getting pending status checks...');

      final schedules = await FirebaseFirestore.instance
          .collection(_statusScheduleCollection)
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${schedules.docs.length} pending schedules');

      final result = schedules.docs
          .map((doc) {
            try {
              final scheduledDate = DateTime.parse(doc['scheduledCheckDate']);
              final daysUntil =
                  DateTime.now().difference(scheduledDate).inDays * -1;

              return {
                'farmerId': doc['farmerId'],
                'currentStatus': doc['currentStatus'],
                'scheduledCheckDate': scheduledDate,
                'daysUntilCheck': daysUntil,
              };
            } catch (e) {
              print('Error parsing schedule ${doc.id}: $e');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();

      // Sort in memory instead of database query
      result.sort(
        (a, b) => a['scheduledCheckDate'].compareTo(b['scheduledCheckDate']),
      );

      print('Successfully processed ${result.length} pending checks');
      return result;
    } catch (e) {
      print('Error getting pending status checks: $e');
      _logIndexUrlIfPresent(e);
      return [];
    }
  }

  // Helper function to log index URLs
  static void _logIndexUrlIfPresent(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('requires an index') &&
        errorString.contains('https://console.firebase.google.com')) {
      // Extract the URL from the error message
      final urlMatch = RegExp(
        r'https://console\.firebase\.google\.com[^\s]+',
      ).firstMatch(errorString);
      if (urlMatch != null) {
        final indexUrl = urlMatch.group(0)!;
        print('\n🔥 FIRESTORE INDEX REQUIRED 🔥');
        print('Copy this URL to create the index:');
        print(indexUrl);
        print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥\n');
      }
    }
  }

  // Manual status improvement for admin use
  static Future<Map<String, dynamic>> improveFarmerStatusManually(
    String farmerId,
  ) async {
    try {
      print('🔧 Manually improving status for farmer: $farmerId');

      // Get current farmer status
      final currentStatusEnum = await FarmerReputationService.getFarmerStatus(
        farmerId,
      );
      final currentStatus = currentStatusEnum.value;
      print('Current status: $currentStatus');

      if (currentStatus == 'good') {
        return {
          'success': false,
          'message': 'Farmer already has good status',
          'currentStatus': currentStatus,
          'newStatus': currentStatus,
        };
      }

      String newStatus;
      if (currentStatus == 'bad') {
        newStatus = 'warning'; // Move from bad to warning
      } else {
        newStatus = 'good'; // Move from warning to good
      }

      // Update farmer status
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .update({
            'reputationStatus': newStatus,
            'reputationUpdatedAt': FieldValue.serverTimestamp(),
            'reputationUpdatedBy': 'admin_manual',
            'manualAdminOverride': true,
            'reputationChangeReason': 'Manual status improvement by admin',
          });

      print(
        '✅ Manually improved farmer $farmerId status from $currentStatus to $newStatus',
      );

      return {
        'success': true,
        'message': 'Farmer status improved successfully',
        'currentStatus': currentStatus,
        'newStatus': newStatus,
      };
    } catch (e) {
      print('❌ Error manually improving farmer status: $e');
      return {
        'success': false,
        'message': 'Error improving farmer status: ${e.toString()}',
        'currentStatus': 'unknown',
        'newStatus': 'unknown',
      };
    }
  }

  // Get all farmers who need status improvement (not just scheduled ones)
  static Future<List<Map<String, dynamic>>>
  getAllFarmersNeedingImprovement() async {
    try {
      print('🔍 Getting all farmers needing status improvement...');

      // Get all farmers with bad or warning status
      final farmers = await FirebaseFirestore.instance
          .collection('farmers')
          .where('reputationStatus', whereIn: ['bad', 'warning'])
          .get();

      print('Found ${farmers.docs.length} farmers with bad/warning status');

      final result = farmers.docs.map((doc) {
        final data = doc.data();
        return {
          'farmerId': doc.id,
          'name': data['user_name'] ?? 'Unknown',
          'currentStatus': data['reputationStatus'] ?? 'unknown',
          'location': data['location'] ?? 'Unknown',
          'reputationUpdatedAt': data['reputationUpdatedAt'],
        };
      }).toList();

      print(
        'Successfully processed ${result.length} farmers needing improvement',
      );
      return result;
    } catch (e) {
      print('Error getting farmers needing improvement: $e');
      return [];
    }
  }
}
