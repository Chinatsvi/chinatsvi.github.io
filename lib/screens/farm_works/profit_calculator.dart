import 'dart:async';
import 'package:flutter/material.dart';
import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

class ProfitCalculator extends StatefulWidget {
  const ProfitCalculator({super.key});
  @override
  State<ProfitCalculator> createState() => _ProfitCalculatorState();
}

class _ProfitCalculatorState extends State<ProfitCalculator> {
  final _yield = TextEditingController();
  final _price = TextEditingController();
  final _costs = TextEditingController();
  String? _result;
  String? _details;

  @override
  void dispose() {
    _yield.dispose();
    _price.dispose();
    _costs.dispose();
    super.dispose();
  }

  void _calculate() {
    dismissCalculatorKeyboard();
    final yieldUnits = farmNumber(_yield);
    final price = farmNumber(_price);
    final costs = farmNumber(_costs);
    if (yieldUnits == null ||
        yieldUnits <= 0 ||
        price == null ||
        price <= 0 ||
        costs == null ||
        costs < 0) {
      setState(() {
        _result = 'Fill in all fields with valid numbers';
        _details = null;
      });
      return;
    }
    final revenue = yieldUnits * price;
    final profit = revenue - costs;
    final margin = revenue == 0 ? 0 : profit / revenue * 100;
    setState(() {
      _result =
          '${profit >= 0 ? '' : '-'}${profit.abs().toStringAsFixed(2)} ${profit >= 0 ? 'estimated profit' : 'estimated loss'}';
      _details =
          'Revenue: ${revenue.toStringAsFixed(2)} | Costs: ${costs.toStringAsFixed(2)} | Margin: ${margin.toStringAsFixed(1)}%';
    });
    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'profit',
        title: 'Farm Profit',
        inputs: {
          'Expected yield': _yield.text,
          'Price per unit': _price.text,
          'Production costs': _costs.text,
        },
        result: _result!,
        details: _details,
      ),
    );
  }

  void _export() => exportFarmReport(
    'Farm Profit Report',
    {
      'Expected yield': _yield.text,
      'Price per unit': _price.text,
      'Production costs': _costs.text,
    },
    _result!,
    _details,
  );

  @override
  Widget build(BuildContext context) => FarmCalculatorLayout(
    calculatorType: 'profit',
    title: 'Farm Profit',
    description:
        'Estimate seasonal revenue, production costs, profit, and margin.',
    icon: Icons.attach_money,
    fields: [
      FarmField(
        label: 'Expected yield (units)',
        controller: _yield,
        hint: 'e.g. 4000',
      ),
      FarmField(label: 'Price per unit', controller: _price, hint: 'e.g. 0.35'),
      FarmField(
        label: 'Total production costs',
        controller: _costs,
        hint: 'e.g. 900',
      ),
      ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate profit'),
        style: farmButtonStyle(),
      ),
    ],
    result: _result,
    resultDetails: _details,
    onExport: _result == null ? null : _export,
    exportLabel: 'Watch Ad & Export Profit PDF',
  );
}
