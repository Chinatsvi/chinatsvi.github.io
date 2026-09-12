import 'dart:async';
import 'package:flutter/material.dart';
import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

class SpacingCalculator extends StatefulWidget {
  const SpacingCalculator({super.key});
  @override
  State<SpacingCalculator> createState() => _SpacingCalculatorState();
}

class _SpacingCalculatorState extends State<SpacingCalculator> {
  final _row = TextEditingController();
  final _plant = TextEditingController();
  String? _result;
  String? _details;

  @override
  void dispose() {
    _row.dispose();
    _plant.dispose();
    super.dispose();
  }

  void _calculate() {
    dismissCalculatorKeyboard();
    final row = farmNumber(_row);
    final plant = farmNumber(_plant);
    if (row == null || row <= 0 || plant == null || plant <= 0) {
      setState(() {
        _result = 'Enter valid row and plant spacing';
        _details = null;
      });
      return;
    }
    final perHa = 10000 / ((row / 100) * (plant / 100));
    setState(() {
      _result = '${perHa.round()} plants per hectare';
      _details =
          'About ${(perHa * 0.404686).round()} plants per acre at ${row.toStringAsFixed(0)} cm x ${plant.toStringAsFixed(0)} cm.';
    });
    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'spacing',
        title: 'Crop Spacing',
        inputs: {
          'Row spacing': '${_row.text} cm',
          'Plant spacing': '${_plant.text} cm',
        },
        result: _result!,
        details: _details,
      ),
    );
  }

  void _export() => exportFarmReport(
    'Crop Spacing Report',
    {'Row spacing': '${_row.text} cm', 'Plant spacing': '${_plant.text} cm'},
    _result!,
    _details,
  );

  @override
  Widget build(BuildContext context) => FarmCalculatorLayout(
    calculatorType: 'spacing',
    title: 'Crop Spacing',
    description: 'See the plant density produced by any row and plant spacing.',
    icon: Icons.straighten,
    fields: [
      FarmField(label: 'Row spacing (cm)', controller: _row, hint: 'e.g. 75'),
      FarmField(
        label: 'Plant spacing (cm)',
        controller: _plant,
        hint: 'e.g. 25',
      ),
      ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate density'),
        style: farmButtonStyle(),
      ),
    ],
    result: _result,
    resultDetails: _details,
    onExport: _result == null ? null : _export,
    exportLabel: 'Watch Ad & Export Spacing PDF',
  );
}
