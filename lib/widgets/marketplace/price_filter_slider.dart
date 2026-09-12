import 'package:flutter/material.dart';
import 'package:agribased/app/utils/formatters.dart';

class PriceFilterSlider extends StatelessWidget {
  final double min;
  final double max;
  final RangeValues values;
  final Function(RangeValues) onChanged;

  const PriceFilterSlider({
    super.key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: 20,
          labels: RangeLabels(
            Formatter.formatCurrency(values.start.toDouble()),
            Formatter.formatCurrency(values.end.toDouble()),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}