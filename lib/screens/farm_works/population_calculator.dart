import 'dart:async';
import 'package:flutter/material.dart';
import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

class PopulationCalculator extends StatefulWidget {
  const PopulationCalculator({super.key});
  @override
  State<PopulationCalculator> createState() => _PopulationCalculatorState();
}

class _PopulationCalculatorState extends State<PopulationCalculator> {
  final _size = TextEditingController();
  final _row = TextEditingController();
  final _plant = TextEditingController();
  String _unit = 'Hectares';
  String? _result;
  String? _details;

  @override
  void dispose() {
    _size.dispose();
    _row.dispose();
    _plant.dispose();
    super.dispose();
  }

  void _calculate() {
    dismissCalculatorKeyboard();
    final size = farmNumber(_size);
    final row = farmNumber(_row);
    final plant = farmNumber(_plant);
    if (size == null ||
        size <= 0 ||
        row == null ||
        row <= 0 ||
        plant == null ||
        plant <= 0) {
      setState(() {
        _result = 'Fill in all fields with valid numbers';
        _details = null;
      });
      return;
    }
    final hectares = _unit == 'Acres' ? size * 0.404686 : size;
    final perHectare = 10000 / ((row / 100) * (plant / 100));
    setState(() {
      _result = '${(hectares * perHectare).round()} plants';
      _details = 'About ${perHectare.round()} plants per hectare.';
    });
    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'population',
        title: 'Plant Population',
        inputs: {
          'Field size': '${_size.text} $_unit',
          'Spacing': '${_row.text} cm x ${_plant.text} cm',
        },
        result: _result!,
        details: _details,
      ),
    );
  }

  void _export() => exportFarmReport(
    'Plant Population Report',
    {
      'Field size': '${_size.text} $_unit',
      'Spacing': '${_row.text} cm x ${_plant.text} cm',
    },
    _result!,
    _details,
  );

  @override
  Widget build(BuildContext context) => FarmCalculatorLayout(
    calculatorType: 'population',
    title: 'Plant Population',
    description:
        'Estimate the number of plants your field can hold from row and plant spacing.',
    icon: Icons.grass,
    fields: [
      FarmField(
        label: 'Field size ($_unit)',
        controller: _size,
        hint: 'e.g. 1',
      ),
      DropdownButtonFormField<String>(
        initialValue: _unit,
        decoration: const InputDecoration(
          labelText: 'Unit',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'Hectares', child: Text('Hectares')),
          DropdownMenuItem(value: 'Acres', child: Text('Acres')),
        ],
        onChanged: (value) => setState(() => _unit = value ?? 'Hectares'),
      ),
      const SizedBox(height: 12),
      FarmField(label: 'Row spacing (cm)', controller: _row, hint: 'e.g. 75'),
      FarmField(
        label: 'Plant spacing (cm)',
        controller: _plant,
        hint: 'e.g. 25',
      ),
      ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate population'),
        style: farmButtonStyle(),
      ),
    ],
    result: _result,
    resultDetails: _details,
    onExport: _result == null ? null : _export,
    exportLabel: 'Watch Ad & Export Population PDF',
  );
}
