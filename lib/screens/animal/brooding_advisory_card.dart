// lib/widgets/brooding_advisory_card.dart
import 'package:flutter/material.dart';

class BroodingAdvisoryCard extends StatelessWidget {
  final DateTime startDate;
  final int flockSize;

  const BroodingAdvisoryCard({
    super.key,
    required this.startDate,
    required this.flockSize,
  });

  String _advisoryNotes() {
    final ageDays = DateTime.now().difference(startDate).inDays;
    final ageWeeks = (ageDays / 7).floor();

    String notes = '🐥 Brooding Advisory (Age: $ageWeeks weeks, Flock: $flockSize birds)\n';

    // Temperature & environment guidance
    if (ageWeeks == 0) {
      notes +=
          '• Keep brooder temperature at 32–35°C.\n'
          '• Provide chick starter feed and clean water.\n'
          '• Stocking density: ~40–50 chicks/m² (adjust for $flockSize birds).\n'
          '• Ensure good ventilation without drafts.\n';
    } else if (ageWeeks <= 2) {
      notes +=
          '• Reduce temperature gradually by 2–3°C per week (target ~30°C).\n'
          '• Bedding must remain dry and clean.\n'
          '• Watch for dehydration and weakness.\n'
          '• Stocking density: ~30–35 chicks/m².\n';
    } else if (ageWeeks <= 4) {
      notes +=
          '• Temperature should be around 26–28°C.\n'
          '• Begin introducing grower feed.\n'
          '• Vaccinate for Newcastle/Gumboro if scheduled.\n'
          '• Stocking density: ~20–25 birds/m².\n';
    } else if (ageWeeks <= 6) {
      notes +=
          '• Temperature should be near ambient (~24°C).\n'
          '• Transition fully to grower feed.\n'
          '• Monitor mortality and cull weak chicks.\n'
          '• Stocking density: ~15–20 birds/m².\n';
    } else {
      notes +=
          '• Brooding period completed.\n'
          '• Focus on growth, feed conversion, and vaccination follow‑ups.\n'
          '• Stocking density: adjust to ~10–12 birds/m² for layers.\n';
    }

    // Feeding strategy suggestions
    if (ageWeeks <= 6) {
      notes += '\n🍽️ Feeding Strategy:\n'
          '• Starter feed (20–22% protein, high energy).\n'
          '• Provide vitamins/electrolytes in water.\n'
          '• Feed ad libitum (always available).\n';
    } else if (ageWeeks <= 18) {
      notes += '\n🍽️ Feeding Strategy:\n'
          '• Switch to grower feed (16–18% protein).\n'
          '• Monitor feed conversion ratio (FCR).\n'
          '• Adjust stocking density as birds grow.\n';
    } else {
      notes += '\n🍽️ Feeding Strategy:\n'
          '• Transition to layer feed (16–17% protein, calcium for eggshells).\n'
          '• Provide grit or limestone for calcium.\n'
          '• Track egg laying percentage daily.\n';
    }

    // Egg laying advisory
    if (ageWeeks >= 18) {
      notes +=
          '\n🥚 Birds may start laying soon. Monitor egg laying percentage and adjust feeding strategy.';
    }

    // Practical AI-style guidance
    notes += '\n\n🤖 AI Tip:\n'
        'Based on $flockSize birds at $ageWeeks weeks:\n'
        '• Ensure spacing matches density guidelines to reduce stress.\n'
        '• Maintain ventilation and monitor temperature daily.\n'
        '• Adjust feed type and quantity as birds transition between growth stages.\n';

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow.shade50,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _advisoryNotes(),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}