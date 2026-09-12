import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/crop_calendar/crop_calendar_models.dart';
import '../../../services/crop_calendar/crop_calendar_service.dart';
import '../../../services/crop_calendar/crop_reminder_service.dart';
import '../../farm_works/fertilizer_calculator.dart';
import '../../farm_works/irrigation_calculator.dart';
import '../../../widgets/ads/farm_native_ad.dart';
import 'stage_detail_sheet.dart';

class SavedCropCalendarsTab extends StatefulWidget {
  final VoidCallback onStartNewPlan;

  const SavedCropCalendarsTab({super.key, required this.onStartNewPlan});

  @override
  State<SavedCropCalendarsTab> createState() => _SavedCropCalendarsTabState();
}

class _SavedCropCalendarsTabState extends State<SavedCropCalendarsTab> {
  final CropCalendarService _service = CropCalendarService();
  final CropReminderService _reminderService = CropReminderService();

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_farmer';
  }

  Future<void> _toggleReminders(SavedCropCalendar plan, bool enabled) async {
    final updated = plan.copyWith(remindersEnabled: enabled);
    await _service.saveCropPlan(updated);
    if (enabled) {
      await _reminderService.scheduleMilestoneReminders(updated);
    } else {
      await _reminderService.cancelCropReminders(updated);
    }
  }

  Future<void> _confirmDelete(SavedCropCalendar plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${plan.cropName} Plan?'),
        content: const Text(
          'This will remove this crop calendar from your saved farm plans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _reminderService.cancelCropReminders(plan);
      await _service.deleteCropPlan(_currentUserId, plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plan.cropName} plan deleted'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    }
  }

  CropGrowthStage _mapStageTypeToGrowthStage(StageType type) {
    switch (type) {
      case StageType.planting:
      case StageType.establishment:
        return CropGrowthStage.initial;
      case StageType.vegetative:
      case StageType.weeding:
      case StageType.fertilizing:
        return CropGrowthStage.development;
      case StageType.flowering:
      case StageType.fruitDevelopment:
        return CropGrowthStage.midSeason;
      case StageType.harvesting:
        return CropGrowthStage.lateSeason;
    }
  }

  void _openStageDetails(CropTimelineMilestone milestone, SavedCropCalendar plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StageDetailSheet(
        milestone: milestone,
        cropName: plan.cropName,
        onOpenFertilizerCalc: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FertilizerCalculator(),
            ),
          );
        },
        onOpenIrrigationCalc: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IrrigationCalculator(
                initialCropName: plan.cropName,
                initialGrowthStage: _mapStageTypeToGrowthStage(milestone.stage.type),
                initialArea: plan.fieldArea,
                initialAreaUnit: plan.areaUnit,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SavedCropCalendar>>(
      stream: _service.getSavedCropPlans(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final plans = snapshot.data ?? [];

        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      size: 64,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Saved Farm Calendars',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a crop plan to track growth stages, harvest countdowns, and fertilizer schedules.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: widget.onStartNewPlan,
                    icon: const Icon(Icons.add),
                    label: const Text('Plan a Crop Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildPlanListWithAds(plans);
      },
    );
  }

  Widget _buildPlanListWithAds(List<SavedCropCalendar> plans) {
    final List<Widget> items = [];
    for (int i = 0; i < plans.length; i++) {
      items.add(_buildPlanCard(plans[i]));
      // Insert native ad starting after index 1 (the 2nd item) and every 4 items after
      if (i == 1 || (i > 1 && (i - 1) % 4 == 0)) {
        items.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: FarmNativeAd(),
          ),
        );
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildPlanCard(SavedCropCalendar plan) {
    final now = DateTime.now();
    final plantingDate = plan.plantingDate;
    final harvestDate = plan.estimatedHarvestEnd;

    final totalDays =
        harvestDate.difference(plantingDate).inDays.clamp(1, 999);
    final daysElapsed =
        now.difference(plantingDate).inDays.clamp(0, totalDays);
    final progress = (daysElapsed / totalDays).clamp(0.0, 1.0);

    final daysToHarvest = harvestDate.difference(now).inDays;

    return GestureDetector(
      onLongPress: () => _confirmDelete(plan),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade50,
                    child: Text(
                      plan.cropEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.cropName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.varietyName != null)
                          Text(
                            plan.varietyName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Location & Field Details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      plan.location.shortName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (plan.fieldArea != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${plan.fieldArea} ${plan.areaUnit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Dates & Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Planted', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      DateFormat('d MMM yyyy').format(plan.plantingDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Est. Harvest', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      DateFormat('d MMM yyyy').format(plan.estimatedHarvestStart),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  daysElapsed == 0
                      ? 'Planting day'
                      : '$daysElapsed days in ground',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  daysToHarvest <= 0
                      ? 'Harvest Window Active 🧺'
                      : '~$daysToHarvest days to harvest',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: daysToHarvest <= 0
                        ? Colors.amber.shade900
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Milestones Preview Chips
            const Text(
              'Growth Milestones (Tap to inspect):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: plan.milestones.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: Icon(
                        _getStageIcon(m.stage.type),
                        size: 14,
                        color: Colors.green.shade800,
                      ),
                      label: Text(
                        m.stage.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade200),
                      onPressed: () => _openStageDetails(m, plan),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Notification toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      plan.remindersEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      size: 16,
                      color: plan.remindersEnabled
                          ? Colors.green.shade700
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plan.remindersEnabled
                          ? 'Reminders Active'
                          : 'Reminders Off',
                      style: TextStyle(
                        fontSize: 12,
                        color: plan.remindersEnabled
                            ? Colors.green.shade800
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: plan.remindersEnabled,
                  activeThumbColor: Colors.green.shade700,
                  onChanged: (val) => _toggleReminders(plan, val),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  IconData _getStageIcon(StageType type) {
    switch (type) {
      case StageType.planting:
        return Icons.spa;
      case StageType.establishment:
        return Icons.eco;
      case StageType.vegetative:
        return Icons.grass;
      case StageType.weeding:
        return Icons.cleaning_services;
      case StageType.fertilizing:
        return Icons.science;
      case StageType.flowering:
        return Icons.local_florist;
      case StageType.fruitDevelopment:
        return Icons.yard;
      case StageType.harvesting:
        return Icons.shopping_basket;
    }
  }
}
