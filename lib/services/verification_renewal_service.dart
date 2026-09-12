import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Service for handling verification renewal reminders
class VerificationRenewalService {
  static final VerificationRenewalService _instance =
      VerificationRenewalService._internal();
  factory VerificationRenewalService() => _instance;
  VerificationRenewalService._internal();

  FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  set firestore(FirebaseFirestore instance) => _customFirestore = instance;

  /// Check for users who need renewal reminders (3 days before expiry)
  Future<void> checkAndSendRenewalReminders() async {
    try {
      developer.log(
        '🔔 Checking for renewal reminders...',
        name: 'VerificationRenewalService',
      );

      // Get all farmers who have verification data (both active and expired)
      // Less restrictive query to catch more users
      final farmersSnapshot = await _firestore
          .collection('farmers')
          .where('verificationPaid', isEqualTo: true)
          .get();

      developer.log(
        '📊 Found ${farmersSnapshot.docs.length} farmers with verificationPaid=true',
        name: 'VerificationRenewalService',
      );

      int remindersSent = 0;
      int expiredUsers = 0;
      int totalChecked = 0;

      for (final doc in farmersSnapshot.docs) {
        final data = doc.data();
        final farmerId = doc.id;
        final farmerName = data['name'] ?? data['user_name'] ?? 'Farmer';
        final verificationExpiresAt =
          data['verificationExpiresAt'] as Timestamp?;
        final verificationPaidAt = (data['verificationPaidAt'] as Timestamp?) ??
          (data['verificationPaidat'] as Timestamp?);
        final verificationStatus = data['verificationStatus'] as String?;

        totalChecked++;

        developer.log(
          '🔍 Checking farmer $farmerId ($farmerName):',
          name: 'VerificationRenewalService',
        );
        developer.log(
          '   - verificationStatus: $verificationStatus',
          name: 'VerificationRenewalService',
        );
        developer.log(
          '   - verificationExpiresAt: $verificationExpiresAt',
          name: 'VerificationRenewalService',
        );

        if (verificationStatus != null) {
          // Determine expiry date: prefer explicit field, fallback to paidAt + 30 days
          DateTime? expiryDate;
          if (verificationExpiresAt != null) {
            expiryDate = verificationExpiresAt.toDate();
          } else if (verificationPaidAt != null) {
            expiryDate = verificationPaidAt.toDate().add(const Duration(days: 30));
            developer.log(
              '   ℹ️ Using fallback expiryDate from verificationPaidAt: $expiryDate',
              name: 'VerificationRenewalService',
            );
          }

          if (expiryDate == null) {
            developer.log(
              '   ❌ Missing expiry information for $farmerId',
              name: 'VerificationRenewalService',
            );
            continue;
          }
          final now = DateTime.now();
          final threeDaysBeforeExpiry = expiryDate.subtract(
            const Duration(days: 3),
          );

          developer.log(
            '   - expiryDate: $expiryDate',
            name: 'VerificationRenewalService',
          );
          developer.log('   - now: $now', name: 'VerificationRenewalService');
          developer.log(
            '   - threeDaysBeforeExpiry: $threeDaysBeforeExpiry',
            name: 'VerificationRenewalService',
          );

          // Case 1: User is still verified but expires in 3 days
          if (now.isBefore(expiryDate) && now.isAfter(threeDaysBeforeExpiry)) {
            developer.log(
              '   ✅ User qualifies for upcoming renewal reminder',
              name: 'VerificationRenewalService',
            );
            final shouldSendReminder = await _shouldSendReminder(
              farmerId,
              expiryDate,
            );

            if (shouldSendReminder) {
              await _sendRenewalReminder(
                farmerId,
                farmerName,
                expiryDate,
                'upcoming',
              );
              remindersSent++;
            } else {
              developer.log(
                '   ⏭️ Reminder already sent recently',
                name: 'VerificationRenewalService',
              );
            }
          }
          // Case 2: User has already expired - send immediate renewal notice
          else if (now.isAfter(expiryDate)) {
            developer.log(
              '   ✅ User qualifies for expired renewal notice',
              name: 'VerificationRenewalService',
            );
            expiredUsers++;
            final shouldSendExpiredReminder = await _shouldSendExpiredReminder(
              farmerId,
              expiryDate,
            );

            if (shouldSendExpiredReminder) {
              await _sendRenewalReminder(
                farmerId,
                farmerName,
                expiryDate,
                'expired',
              );
              remindersSent++;
            } else {
              developer.log(
                '   ⏭️ Expired reminder already sent recently',
                name: 'VerificationRenewalService',
              );
            }
          } else {
            developer.log(
              '   ⏭️ User does not qualify for renewal reminder yet',
              name: 'VerificationRenewalService',
            );
          }
        } else {
          developer.log(
            '   ❌ Missing verificationExpiresAt or verificationStatus',
            name: 'VerificationRenewalService',
          );
        }
      }

      developer.log(
        '🔔 Summary: Checked $totalChecked farmers, sent $remindersSent renewal reminders ($expiredUsers users expired)',
        name: 'VerificationRenewalService',
      );
    } catch (e) {
      developer.log(
        '❌ Error checking renewal reminders: $e',
        name: 'VerificationRenewalService',
      );
    }
  }

  /// Check if we should send a reminder (avoid spamming)
  Future<bool> _shouldSendReminder(String farmerId, DateTime expiryDate) async {
    try {
      // Check if we already sent a reminder for this expiry period
      final reminderSnapshot = await _firestore
          .collection('notifications')
          .doc(farmerId)
          .collection('items')
          .where('type', isEqualTo: 'renewal_reminder')
          .where('expiryDate', isEqualTo: expiryDate.toIso8601String())
          .get();

      return reminderSnapshot.docs.isEmpty;
    } catch (e) {
      developer.log(
        '❌ Error checking reminder status: $e',
        name: 'VerificationRenewalService',
      );
      return false;
    }
  }

  /// Check if we should send expired reminder (avoid spamming)
  Future<bool> _shouldSendExpiredReminder(
    String farmerId,
    DateTime expiryDate,
  ) async {
    try {
      developer.log(
        '🔍 Checking if expired reminder already sent for $farmerId',
        name: 'VerificationRenewalService',
      );

      // Check if we already sent an expired reminder for this expiry period
      final reminderSnapshot = await _firestore
          .collection('notifications')
          .doc(farmerId)
          .collection('items')
          .where('type', isEqualTo: 'renewal_expired')
          .where('expiryDate', isEqualTo: expiryDate.toIso8601String())
          .get();

      developer.log(
        '   - Found ${reminderSnapshot.docs.length} existing expired reminders',
        name: 'VerificationRenewalService',
      );

      return reminderSnapshot.docs.isEmpty;
    } catch (e) {
      developer.log(
        '❌ Error checking expired reminder status: $e',
        name: 'VerificationRenewalService',
      );
      return false;
    }
  }

  /// Send renewal reminder notification to user
  Future<void> _sendRenewalReminder(
    String farmerId,
    String farmerName,
    DateTime expiryDate,
    String reminderType, // 'upcoming' or 'expired'
  ) async {
    try {
      final notificationRef = _firestore
          .collection('notifications')
          .doc(farmerId)
          .collection('items')
          .doc();

      String title, body, type;

      if (reminderType == 'expired') {
        title = '⚠️ Verification Expired';
        body =
            'Hi $farmerName, your verification badge has expired on ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}. Renew now to restore your verified status and continue accessing premium features!';
        type = 'renewal_expired';
      } else {
        title = '🔔 Verification Renewal Reminder';
        body =
            'Hi $farmerName, your verification badge expires in 3 days (${expiryDate.day}/${expiryDate.month}/${expiryDate.year}). Renew now to keep your verified status!';
        type = 'renewal_reminder';
      }

      await notificationRef.set({
        'id': notificationRef.id,
        'userId': farmerId,
        'title': title,
        'body': body,
        'type': type,
        'relatedType': 'verification',
        'expiryDate': expiryDate.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
        'actionText': reminderType == 'expired' ? 'Renew Now' : 'Renew',
        'actionScreen': 'renewal_payment',
      });

      developer.log(
        '🔔 ${reminderType == 'expired' ? 'Expired' : 'Renewal'} reminder sent to $farmerId',
        name: 'VerificationRenewalService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending renewal reminder: $e',
        name: 'VerificationRenewalService',
      );
    }
  }

  /// Create a daily scheduled job to check renewal reminders
  static Future<void> scheduleDailyRenewalCheck() async {
    // This would typically be called by a background job scheduler
    // For now, you can call this manually or set up a cron job
    final service = VerificationRenewalService();
    await service.checkAndSendRenewalReminders();
  }

  /// Test method - send renewal reminder to a specific farmer (for testing)
  Future<void> sendTestRenewalReminder(String farmerId) async {
    try {
      developer.log(
        '🧪 Sending test renewal reminder to $farmerId',
        name: 'VerificationRenewalService',
      );

      // Get farmer data
      final farmerDoc = await _firestore
          .collection('farmers')
          .doc(farmerId)
          .get();

      if (!farmerDoc.exists) {
        developer.log(
          '❌ Farmer $farmerId not found',
          name: 'VerificationRenewalService',
        );
        return;
      }

      final data = farmerDoc.data()!;
      final farmerName = data['name'] ?? data['user_name'] ?? 'Farmer';
      final verificationExpiresAt = data['verificationExpiresAt'] as Timestamp?;

      if (verificationExpiresAt != null) {
        await _sendRenewalReminder(
          farmerId,
          farmerName,
          verificationExpiresAt.toDate(),
          'expired', // Send as expired for testing
        );
      } else {
        // Create a test expiry date (tomorrow)
        final testExpiryDate = DateTime.now().add(const Duration(days: 1));
        await _sendRenewalReminder(
          farmerId,
          farmerName,
          testExpiryDate,
          'expired', // Send as expired for testing
        );
      }

      developer.log(
        '✅ Test renewal reminder sent to $farmerId',
        name: 'VerificationRenewalService',
      );
    } catch (e) {
      developer.log(
        '❌ Error sending test renewal reminder: $e',
        name: 'VerificationRenewalService',
      );
    }
  }
}
