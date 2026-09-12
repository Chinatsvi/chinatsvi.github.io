import 'package:cloud_firestore/cloud_firestore.dart';
import 'farmer_status_scheduler.dart';

class ScheduledJobRunner {
  static const String _jobRunsCollection = 'scheduled_job_runs';

  // Run all scheduled checks (call this daily via cron job or serverless function)
  static Future<Map<String, dynamic>> runDailyScheduledChecks() async {
    final result = <String, dynamic>{
      'success': false,
      'timestamp': DateTime.now().toIso8601String(),
      'improvedFarmers': 0,
      'resetFarmers': 0,
      'errors': <String>[],
    };

    try {
      print('🚀 Starting daily scheduled status checks...');

      // Check if we already ran today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final existingRun = await FirebaseFirestore.instance
          .collection(_jobRunsCollection)
          .where('runDate', isGreaterThanOrEqualTo: todayStart)
          .where('runDate', isLessThan: todayEnd)
          .limit(1)
          .get();

      if (existingRun.docs.isNotEmpty) {
        print('⚠️ Daily checks already run today. Skipping.');
        result['message'] = 'Already run today';
        return result;
      }

      // Run the scheduled checks
      await FarmerStatusScheduler.runScheduledChecks();

      // Get detailed results
      final pendingChecks =
          await FarmerStatusScheduler.getPendingStatusChecks();

      // Count improvements by checking recent status changes
      final recentChanges = await FirebaseFirestore.instance
          .collection('farmers')
          .where('reputationUpdatedAt', isGreaterThanOrEqualTo: todayStart)
          .where('reputationUpdatedBy', isEqualTo: 'system')
          .get();

      int improvedCount = 0;
      for (final doc in recentChanges.docs) {
        final data = doc.data();
        if (data['reputationStatus'] == 'good' ||
            data['reputationStatus'] == 'warning') {
          improvedCount++;
        }
      }

      result['success'] = true;
      result['improvedFarmers'] = improvedCount;
      result['pendingChecks'] = pendingChecks.length;

      // Log this run
      await FirebaseFirestore.instance.collection(_jobRunsCollection).add({
        'runDate': todayStart,
        'completedAt': FieldValue.serverTimestamp(),
        'improvedFarmers': improvedCount,
        'pendingChecks': pendingChecks.length,
        'success': true,
      });

      print('✅ Daily scheduled checks completed successfully');
      print(
        '📊 Results: $improvedCount farmers improved, ${pendingChecks.length} pending checks',
      );
    } catch (e) {
      result['errors'].add(e.toString());
      print('❌ Error in daily scheduled checks: $e');

      // Log failed run
      await FirebaseFirestore.instance.collection(_jobRunsCollection).add({
        'runDate': DateTime.now(),
        'completedAt': FieldValue.serverTimestamp(),
        'success': false,
        'error': e.toString(),
      });
    }

    return result;
  }

  // Get status of scheduled jobs
  static Future<Map<String, dynamic>> getJobStatus() async {
    try {
      final lastRun = await FirebaseFirestore.instance
          .collection(_jobRunsCollection)
          .limit(10) // Get more docs to sort manually
          .get();

      final pendingChecks =
          await FarmerStatusScheduler.getPendingStatusChecks();

      // Sort manually in memory to find the most recent run
      Map<String, dynamic>? sortedLastRun;
      if (lastRun.docs.isNotEmpty) {
        final sortedDocs = lastRun.docs.toList()
          ..sort((a, b) {
            final aDate = a.data()['runDate'] as Timestamp?;
            final bDate = b.data()['runDate'] as Timestamp?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate); // descending order
          });
        sortedLastRun = sortedDocs.first.data();
      }

      return {
        'lastRun': sortedLastRun,
        'pendingChecks': pendingChecks.length,
        'nextCheckDate': pendingChecks.isNotEmpty
            ? pendingChecks.first['scheduledCheckDate'].toString()
            : null,
        'status': 'Ready',
      };
    } catch (e) {
      print('Error getting job status: $e');

      // Check if this is an index error and log the URL
      final errorString = e.toString();
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

      return {
        'error': e.toString(),
        'status': 'Error',
        'pendingChecks': 0,
        'lastRun': null,
        'nextCheckDate': null,
      };
    }
  }

  // Manual trigger for testing (bypasses daily limit)
  static Future<Map<String, dynamic>> triggerManualCheck() async {
    print('🔧 Manual trigger of scheduled checks...');

    final result = <String, dynamic>{
      'success': false,
      'timestamp': DateTime.now().toIso8601String(),
      'improvedFarmers': 0,
      'resetFarmers': 0,
      'errors': <String>[],
      'manual': true,
    };

    try {
      print('🚀 Starting manual status checks (bypassing daily limit)...');

      // Run the scheduled checks directly without daily limit check
      await FarmerStatusScheduler.runScheduledChecks();

      // Get detailed results
      final pendingChecks =
          await FarmerStatusScheduler.getPendingStatusChecks();

      // Count improvements by checking recent status changes (last 5 minutes for manual runs)
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final recentChanges = await FirebaseFirestore.instance
          .collection('farmers')
          .where('reputationUpdatedAt', isGreaterThanOrEqualTo: fiveMinutesAgo)
          .where('reputationUpdatedBy', isEqualTo: 'system')
          .get();

      int improvedCount = 0;
      for (final doc in recentChanges.docs) {
        final data = doc.data();
        if (data['reputationStatus'] == 'good' ||
            data['reputationStatus'] == 'warning') {
          improvedCount++;
        }
      }

      result['success'] = true;
      result['improvedFarmers'] = improvedCount;
      result['pendingChecks'] = pendingChecks.length;

      // Log this manual run
      await FirebaseFirestore.instance.collection(_jobRunsCollection).add({
        'runDate': DateTime.now(),
        'completedAt': FieldValue.serverTimestamp(),
        'improvedFarmers': improvedCount,
        'pendingChecks': pendingChecks.length,
        'success': true,
        'manual': true,
        'type': 'manual_trigger',
      });

      print('✅ Manual scheduled checks completed successfully');
      print(
        '📊 Results: $improvedCount farmers improved, ${pendingChecks.length} pending checks',
      );
    } catch (e) {
      result['errors'].add(e.toString());
      result['error'] = e.toString();
      print('❌ Error in manual scheduled checks: $e');

      // Log failed manual run
      await FirebaseFirestore.instance.collection(_jobRunsCollection).add({
        'runDate': DateTime.now(),
        'completedAt': FieldValue.serverTimestamp(),
        'success': false,
        'error': e.toString(),
        'manual': true,
        'type': 'manual_trigger',
      });
    }

    return result;
  }
}
