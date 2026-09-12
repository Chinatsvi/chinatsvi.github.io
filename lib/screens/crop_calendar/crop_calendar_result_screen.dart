import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/crop_calendar/crop_calendar_models.dart';
import '../../services/crop_calendar/crop_calendar_service.dart';
import '../../services/crop_calendar/crop_reminder_service.dart';
import '../farm_works/fertilizer_calculator.dart';
import '../farm_works/irrigation_calculator.dart';
import '../farm_works/profit_calculator.dart';
import 'widgets/stage_detail_sheet.dart';
import 'widgets/why_this_date_dialog.dart';
import '../../widgets/ads/farm_banner_ad.dart';
import '../../widgets/ads/farm_native_ad.dart';

class CropCalendarResultScreen extends StatefulWidget {
  final CropRecommendationResult recommendation;

  const CropCalendarResultScreen({super.key, required this.recommendation});

  @override
  State<CropCalendarResultScreen> createState() =>
      _CropCalendarResultScreenState();
}

class _CropCalendarResultScreenState extends State<CropCalendarResultScreen> {
  final CropCalendarService _service = CropCalendarService();
  final CropReminderService _reminderService = CropReminderService();
  bool _isSaving = false;

  void _showWhyThisDate() {
    showDialog(
      context: context,
      builder: (context) =>
          WhyThisDateDialog(recommendation: widget.recommendation),
    );
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

  void _openStageDetails(CropTimelineMilestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StageDetailSheet(
        milestone: milestone,
        cropName: widget.recommendation.crop.name,
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
                initialCropName: widget.recommendation.crop.name,
                initialGrowthStage: _mapStageTypeToGrowthStage(milestone.stage.type),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSavePlanDialog() {
    final areaController = TextEditingController(text: '1.0');
    String areaUnit = 'Hectares';
    String currency = r'$';
    bool reminders = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bookmark_add,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Save to My Farm Calendar',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Saving "${widget.recommendation.crop.name}" lets you track milestones, receive growth-stage reminders, and link farm tools.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Area and Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: areaController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Field Area',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: areaUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Hectares', child: Text('Hectares (ha)')),
                            DropdownMenuItem(
                                value: 'Acres', child: Text('Acres')),
                            DropdownMenuItem(
                                value: 'sq metres', child: Text('Sq Metres (m²)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => areaUnit = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Currency
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(
                      labelText: 'Farm Currency',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: r'$', child: Text('USD (\$)')),
                      DropdownMenuItem(value: 'R', child: Text('ZAR (R)')),
                      DropdownMenuItem(value: 'ZiG', child: Text('ZiG (Zimbabwe)')),
                      DropdownMenuItem(value: 'KSh', child: Text('KES (KSh)')),
                      DropdownMenuItem(value: '₦', child: Text('NGN (₦)')),
                      DropdownMenuItem(value: 'GH₵', child: Text('GHS (GH₵)')),
                      DropdownMenuItem(value: 'MK', child: Text('MWK (MK)')),
                      DropdownMenuItem(value: 'ZMW', child: Text('Zambian Kwacha (K)')),
                      DropdownMenuItem(value: 'TZS', child: Text('TZS (Tsh)')),
                      DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                      DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => currency = val);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text(
                      'Enable Stage Reminders & Notifications',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Get reminders for weeding, fertilizing, and harvest approach',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: reminders,
                    activeThumbColor: Colors.green.shade700,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setSheetState(() => reminders = val);
                    },
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _performSave(
                                double.tryParse(areaController.text) ?? 1.0,
                                areaUnit,
                                currency,
                                reminders,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm & Save Plan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performSave(
    double area,
    String unit,
    String curr,
    bool reminders,
  ) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous_farmer';

      final plan = SavedCropCalendar(
        id: const Uuid().v4(),
        userId: userId,
        cropId: widget.recommendation.crop.id,
        cropName: widget.recommendation.crop.name,
        cropEmoji: widget.recommendation.crop.iconEmoji,
        varietyName: widget.recommendation.selectedVariety?.name,
        location: widget.recommendation.location,
        plantingDate: widget.recommendation.plantingDate,
        productionSystem: widget.recommendation.productionSystem,
        waterSource: widget.recommendation.waterSource,
        fieldArea: area,
        areaUnit: unit,
        currency: curr,
        remindersEnabled: reminders,
        createdAt: DateTime.now(),
        estimatedHarvestStart: widget.recommendation.estimatedHarvestStart,
        estimatedHarvestEnd: widget.recommendation.estimatedHarvestEnd,
        milestones: widget.recommendation.timelineMilestones,
        confidence: widget.recommendation.confidence.name,
      );

      await _service.saveCropPlan(plan);

      if (reminders) {
        await _reminderService.scheduleMilestoneReminders(plan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${plan.cropName} plan saved to My Farm Calendars!'),
            backgroundColor: Colors.green.shade700,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: const FarmBannerAd(),
      appBar: AppBar(
        title: Text(
          '${rec.crop.iconEmoji} ${rec.crop.name} Plan',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Why am I seeing this?',
            icon: const Icon(Icons.help_outline),
            onPressed: _showWhyThisDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary Card
            _buildSummaryHeaderCard(rec),

            const SizedBox(height: 14),

            // Recommended Planting Window Card
            _buildRecommendedWindowCard(rec),

            const SizedBox(height: 14),

            // Climate / Weather Safety Alerts
            if (rec.riskAlerts.isNotEmpty) ...[
              ...rec.riskAlerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRiskAlertCard(alert),
                  )),
              const SizedBox(height: 6),
            ],

            // Milestone Timeline Section
            _buildTimelineSection(rec),

            const SizedBox(height: 16),

            // Harvest Estimate Box
            _buildHarvestEstimateCard(rec),

            const SizedBox(height: 16),

            // Sponsored Native Ad
            const FarmNativeAd(),

            const SizedBox(height: 16),

            // Farm Works Integration Section
            _buildToolIntegrationsCard(rec),

            const SizedBox(height: 24),

            // Save Plan Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _showSavePlanDialog,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bookmark_add),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save to My Farm Calendar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeaderCard(CropRecommendationResult rec) {
    Color confColor;
    String confLabel;

    switch (rec.confidence) {
      case ConfidenceLevel.high:
        confColor = Colors.green.shade700;
        confLabel = '🟢 High Confidence';
        break;
      case ConfidenceLevel.moderate:
        confColor = Colors.orange.shade800;
        confLabel = '🟡 Moderate Confidence';
        break;
      case ConfidenceLevel.low:
        confColor = Colors.red.shade700;
        confLabel = '🔴 Low Confidence';
        break;
    }

    return Card(
      elevation: 0,
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
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.green.shade50,
                  child: Text(
                    rec.crop.iconEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rec.crop.name.toUpperCase()} CROP PLAN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rec.location.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: confColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    confLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: confColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showWhyThisDate,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text(
                    'Why this date?',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedWindowCard(CropRecommendationResult rec) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.green.shade50.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Colors.green.shade800,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '🌱 Recommended Planting Window',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.recommendedWindow.periodDescription,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rec.recommendedWindow.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec.recommendedWindow.rationale,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAlertCard(ClimateRiskAlert alert) {
    Color bg;
    Color border;
    Color textColor;

    switch (alert.severity) {
      case 'danger':
        bg = Colors.red.shade50;
        border = Colors.red.shade200;
        textColor = Colors.red.shade900;
        break;
      case 'warning':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade200;
        textColor = Colors.orange.shade900;
        break;
      default:
        bg = Colors.blue.shade50;
        border = Colors.blue.shade200;
        textColor = Colors.blue.shade900;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.iconEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(CropRecommendationResult rec) {
    return Card(
      elevation: 0,
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
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.green.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  '📅 Your Crop Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap any stage below for deep nutrient management, monitoring tasks, and agronomic guidance.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Timeline Items
            ...List.generate(rec.timelineMilestones.length, (index) {
              final milestone = rec.timelineMilestones[index];
              final isLast = index == rec.timelineMilestones.length - 1;

              return InkWell(
                onTap: () => _openStageDetails(milestone),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline node + connector line
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green.shade700,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getStageIcon(milestone.stage.type),
                              size: 16,
                              color: Colors.green.shade800,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 48,
                              color: Colors.green.shade200,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Stage text details
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      milestone.stage.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                milestone.dateDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                milestone.stage.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestEstimateCard(CropRecommendationResult rec) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📌 ESTIMATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 16, color: Colors.amber.shade900),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected Harvest Window:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rec.harvestWindowDisplay,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Actual maturity varies according to specific variety, temperature, nutrition, water availability, and local field microclimates.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber.shade900.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIntegrationsCard(CropRecommendationResult rec) {
    return Card(
      elevation: 0,
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
            Row(
              children: [
                Icon(Icons.build_circle_outlined,
                    color: Colors.green.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  '💰 Plan Your Farm Works & Budget',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IrrigationCalculator(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.water_drop, size: 16),
                    label: const Text('Irrigation', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade800,
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FertilizerCalculator(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Fertilizer', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfitCalculator(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.attach_money, size: 16),
                    label: const Text('Profit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
