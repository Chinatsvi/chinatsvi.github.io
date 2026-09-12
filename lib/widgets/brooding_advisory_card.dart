import 'package:flutter/material.dart';

class BroodingAdvisoryCard extends StatelessWidget {
  final DateTime startDate;
  final int flockSize;

  const BroodingAdvisoryCard({
    super.key,
    required this.startDate,
    required this.flockSize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brooding Period Advisory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAdvisoryItem('Start Date:', _formatDate(startDate)),
            _buildAdvisoryItem('Flock Size:', flockSize.toString()),
            const SizedBox(height: 12),
            const Text(
              'Key Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRecommendation(
              '• Maintain temperature at 35°C for the first week',
            ),
            _buildRecommendation(
              '• Provide 24-hour lighting for the first few days',
            ),
            _buildRecommendation('• Ensure clean water is always available'),
            _buildRecommendation('• Monitor for signs of stress or disease'),
            _buildRecommendation(
              '• Gradually reduce temperature by 2-3°C each week',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(text),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
