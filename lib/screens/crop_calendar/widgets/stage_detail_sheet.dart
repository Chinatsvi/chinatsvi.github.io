import 'package:flutter/material.dart';
import '../../../models/crop_calendar/crop_calendar_models.dart';

class StageDetailSheet extends StatelessWidget {
  final CropTimelineMilestone milestone;
  final String cropName;
  final VoidCallback? onOpenFertilizerCalc;
  final VoidCallback? onOpenIrrigationCalc;

  const StageDetailSheet({
    super.key,
    required this.milestone,
    required this.cropName,
    this.onOpenFertilizerCalc,
    this.onOpenIrrigationCalc,
  });

  @override
  Widget build(BuildContext context) {
    final stage = milestone.stage;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Date Range
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getStageIcon(stage.type),
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              milestone.dateDisplay,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              // Stage Description
              Text(
                'Stage Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stage.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Why it matters
              if (stage.whyItMatters.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why This Stage Matters',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage.whyItMatters,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // What to Monitor Checklist
              if (stage.whatToMonitor.isNotEmpty) ...[
                Text(
                  '🔍 What to Monitor This Stage',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                ...stage.whatToMonitor.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.isWarning
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: item.isWarning
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isWarning
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: item.isWarning
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: item.isWarning
                                          ? Colors.red.shade900
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.detail,
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
                    )),
                const SizedBox(height: 12),
              ],

              // Water & Irrigation Guidance
              Text(
                '💧 Water & Irrigation Demand',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStageWaterGuidance(stage.type, cropName),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.35,
                      ),
                    ),
                    if (onOpenIrrigationCalc != null) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: onOpenIrrigationCalc,
                        icon: const Icon(Icons.water_drop, size: 16),
                        label: Text('Calculate $cropName Water Need'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nutrient Guidance
              if (stage.nutrientGuidance != null &&
                  stage.nutrientGuidance!.isNotEmpty) ...[
                Text(
                  '🌿 Nutrient Management',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.nutrientGuidance!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          height: 1.35,
                        ),
                      ),
                      if (onOpenFertilizerCalc != null) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: onOpenFertilizerCalc,
                          icon: const Icon(Icons.science, size: 16),
                          label: const Text('Open Fertilizer Calculator'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Weeding Guidance
              if (stage.weedingGuidance != null &&
                  stage.weedingGuidance!.isNotEmpty) ...[
                Text(
                  '🌱 Weed Management',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    stage.weedingGuidance!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Warnings
              if (stage.warnings != null && stage.warnings!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stage.warnings!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Safe disclaimers
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agronomic timing is estimated. Adjust according to field emergence, local weather, and variety vigor.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.green.shade700),
                  ),
                  child: Text(
                    'Close Stage Details',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

  String _getStageWaterGuidance(StageType type, String crop) {
    switch (type) {
      case StageType.planting:
        return 'Initial moisture is vital for germination and transplant settling. Provide light, frequent watering to prevent seedbed crusting without waterlogging.';
      case StageType.establishment:
        return 'Roots are exploring the topsoil. Water deeply enough to encourage downwards root growth, letting top 2-3 cm dry slightly between irrigation events.';
      case StageType.vegetative:
      case StageType.weeding:
      case StageType.fertilizing:
        return 'Rapid canopy expansion increases crop transpiration ($crop demand rising). Maintain consistent root-zone moisture to sustain active growth.';
      case StageType.flowering:
        return '🔥 Peak Critical Water Stage! Water deficit during flowering causes blossom drop and poor pollination. Maintain 70–80% field moisture capacity.';
      case StageType.fruitDevelopment:
        return 'High water volume required for fruit enlargement, grain filling, or tuber bulking. Uneven watering leads to fruit cracking and hollow heart.';
      case StageType.harvesting:
        return 'Taper off or cease irrigation 1-2 weeks prior to harvest to allow fruit/grain curing, enhance sugar content, and prevent post-harvest mold.';
    }
  }
}
