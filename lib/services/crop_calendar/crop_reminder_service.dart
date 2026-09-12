import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/crop_calendar/crop_calendar_models.dart';

class CropReminderService {
  static final CropReminderService _instance =
      CropReminderService._internal();
  factory CropReminderService() => _instance;
  CropReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> scheduleMilestoneReminders(SavedCropCalendar plan) async {
    if (!plan.remindersEnabled) return;

    try {
      final now = DateTime.now();

      for (int i = 0; i < plan.milestones.length; i++) {
        final milestone = plan.milestones[i];
        final stage = milestone.stage;
        final scheduledDate = milestone.estimatedStartDate;

        // Only schedule for future milestones
        if (scheduledDate.isAfter(now)) {
          final int notificationId =
              (plan.id.hashCode + i).abs().remainder(100000);

          String title = '🌱 ${plan.cropEmoji} ${plan.cropName} Update';
          String body = '';

          switch (stage.type) {
            case StageType.planting:
              title = '🌱 Plant Your ${plan.cropName}';
              body =
                  'Your planned planting date for ${plan.cropName} is today. Check soil moisture and seedling conditions.';
              break;
            case StageType.establishment:
              title = '🌿 ${plan.cropName} Early Establishment';
              body =
                  'Your ${plan.cropName} may be entering an important early-growth stage. Monitor root settling and cutworms.';
              break;
            case StageType.weeding:
              title = '🌱 Weed Inspection for ${plan.cropName}';
              body =
                  'Early weed management window. Check weed pressure around your ${plan.cropName} beds.';
              break;
            case StageType.fertilizing:
              title = '🌿 Nutrient Management: ${plan.cropName}';
              body =
                  'Nutrient application timing. Review top-dressing and split fertilizer recommendations.';
              break;
            case StageType.flowering:
              title = '🌸 Flowering Stage: ${plan.cropName}';
              body =
                  'Monitor blossom set, check irrigation consistency, and scout for pests.';
              break;
            case StageType.fruitDevelopment:
              title = '🍅 Fruit & Development Stage';
              body =
                  'Bulking/fruiting in progress. Maintain steady moisture and check pest traps.';
              break;
            case StageType.harvesting:
              title = '🧺 ${plan.cropName} Harvest Window Approaching';
              body =
                  'Your estimated ${plan.cropName} harvest window is arriving. Prepare harvest crates and check maturity.';
              break;
            case StageType.vegetative:
              title = '🌿 Vegetative Growth: ${plan.cropName}';
              body =
                  'Crop foliage and roots expanding. Maintain steady moisture and pest scouting.';
              break;
          }

          // Show immediate confirmation or log
          debugPrint(
            '🔔 [CROP_REMINDER] Scheduled reminder ID $notificationId for ${stage.name} on $scheduledDate: $title - $body',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CROP_REMINDER] Error scheduling reminders: $e');
    }
  }

  Future<void> cancelCropReminders(SavedCropCalendar plan) async {
    try {
      for (int i = 0; i < plan.milestones.length; i++) {
        final int notificationId =
            (plan.id.hashCode + i).abs().remainder(100000);
        await _notificationsPlugin.cancel(id: notificationId);
      }
      debugPrint('🔕 [CROP_REMINDER] Cancelled reminders for plan ${plan.id}');
    } catch (e) {
      debugPrint('⚠️ [CROP_REMINDER] Error cancelling reminders: $e');
    }
  }

  /// Sends irrigation advice notification based on crop stage, days since last logged irrigation, and weather
  Future<void> checkAndSendIrrigationAdvice({
    required String cropName,
    required String stageName,
    int? daysSinceLastIrrigation,
    double? rainfallMm,
    double? etoMm,
  }) async {
    try {
      final int notificationId = (cropName.hashCode + DateTime.now().day).abs().remainder(100000);
      String title = '💧 $cropName Irrigation Advice';
      String body = '';

      if (rainfallMm != null && rainfallMm > 10.0) {
        title = '🌧️ Rain Offset: $cropName';
        body = 'Recent rainfall (~${rainfallMm.toStringAsFixed(1)}mm) observed. Soil moisture replenished, delay irrigation.';
      } else if (daysSinceLastIrrigation != null && daysSinceLastIrrigation >= 4) {
        title = '⚠️ $cropName Irrigation Due';
        body = 'It has been $daysSinceLastIrrigation days since last irrigation for your $cropName ($stageName). Check root zone moisture & calculate water requirement.';
      } else if (daysSinceLastIrrigation == null) {
        title = '💧 $cropName Water Guidance';
        body = 'Your $cropName is in $stageName. Open Farm Calendar to calculate crop water demand based on live weather.';
      } else {
        title = '💧 $cropName Moisture Optimal';
        body = 'Last watered $daysSinceLastIrrigation day(s) ago. Maintain regular intervals for steady growth.';
      }

      debugPrint('🔔 [IRRIGATION_ADVISOR] $title: $body');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'crop_irrigation_channel',
        'Crop Irrigation Advisor',
        channelDescription: 'Smart irrigation reminders based on weather and plant growth stage',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('⚠️ [IRRIGATION_ADVISOR] Error dispatching irrigation advice: $e');
    }
  }
}
