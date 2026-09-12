import 'dart:async';
import 'package:flutter/material.dart';
import 'farm_calculator_widgets.dart';
import 'farm_calculator_history.dart';

enum BreakEvenMode { simple, detailed }

class BreakEvenCalculator extends StatefulWidget {
  const BreakEvenCalculator({super.key});

  @override
  State<BreakEvenCalculator> createState() => _BreakEvenCalculatorState();
}

class _BreakEvenCalculatorState extends State<BreakEvenCalculator> {
  BreakEvenMode _mode = BreakEvenMode.simple;

  // Simple Mode Controllers
  final _totalCost = TextEditingController();
  final _simpleSellingPrice = TextEditingController();

  // Detailed Mode Controllers
  final _fixedCosts = TextEditingController();
  final _variableCost = TextEditingController();
  final _sellingPrice = TextEditingController();

  String? _result;
  String? _details;

  @override
  void dispose() {
    _totalCost.dispose();
    _simpleSellingPrice.dispose();
    _fixedCosts.dispose();
    _variableCost.dispose();
    _sellingPrice.dispose();
    super.dispose();
  }

  void _calculateSimple() {
    dismissCalculatorKeyboard();
    final totalCost = farmNumber(_totalCost);
    final sellingPrice = farmNumber(_simpleSellingPrice);

    if (totalCost == null || totalCost <= 0 || sellingPrice == null || sellingPrice <= 0) {
      setState(() {
        _result = 'Enter valid cost and price values';
        _details = null;
      });
      return;
    }

    final units = (totalCost / sellingPrice).ceil();
    final totalRevenueAtBreakEven = units * sellingPrice;

    setState(() {
      _result = 'You need to sell $units units to cover your costs';
      _details =
          'Total cost: ${farmFormatNumber(totalCost)}. Selling price per unit: ${farmFormatNumber(sellingPrice)}. Total sales at break-even: ${farmFormatNumber(totalRevenueAtBreakEven)}.';
    });

    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'break_even',
        title: 'Break-even Calculator (Simple)',
        inputs: {
          'Mode': 'Simple',
          'Total cost of production': _totalCost.text,
          'Selling price per unit': _simpleSellingPrice.text,
        },
        result: _result!,
        details: _details,
      ),
    );
  }

  void _calculateDetailed() {
    dismissCalculatorKeyboard();
    final fixedCosts = farmNumber(_fixedCosts);
    final variableCost = farmNumber(_variableCost);
    final sellingPrice = farmNumber(_sellingPrice);

    if (fixedCosts == null ||
        fixedCosts < 0 ||
        variableCost == null ||
        variableCost < 0 ||
        sellingPrice == null ||
        sellingPrice <= 0) {
      setState(() {
        _result = 'Enter valid cost and price values';
        _details = null;
      });
      return;
    }

    final contribution = sellingPrice - variableCost;
    if (contribution <= 0) {
      setState(() {
        _result = 'Your price needs to be higher than your average cost per unit to break even';
        _details = null;
      });
      return;
    }

    final units = fixedCosts / contribution;
    final sales = units * sellingPrice;
    setState(() {
      _result = '${units.ceil()} units to break even';
      _details =
          'Break-even sales: ${sales.toStringAsFixed(2)}. Contribution per unit: ${contribution.toStringAsFixed(2)}.';
    });

    unawaited(
      FarmCalculatorHistoryService.save(
        calculatorType: 'break_even',
        title: 'Break-even Calculator (Detailed)',
        inputs: {
          'Mode': 'Detailed',
          'Fixed costs': _fixedCosts.text,
          'Variable cost per unit': _variableCost.text,
          'Selling price per unit': _sellingPrice.text,
        },
        result: _result!,
        details: _details,
      ),
    );
  }

  void _export() {
    if (_result == null) return;
    if (_mode == BreakEvenMode.simple) {
      exportFarmReport(
        'Break-even Report (Simple Mode)',
        {
          'Mode': 'Simple',
          'Total cost of production': _totalCost.text,
          'Selling price per unit': _simpleSellingPrice.text,
        },
        _result!,
        _details,
      );
    } else {
      exportFarmReport(
        'Break-even Report (Detailed Mode)',
        {
          'Mode': 'Detailed',
          'Fixed costs': _fixedCosts.text,
          'Variable cost per unit': _variableCost.text,
          'Selling price per unit': _sellingPrice.text,
        },
        _result!,
        _details,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCalculatorLayout(
      calculatorType: 'break_even',
      title: 'Break-even Calculator',
      description:
          'Find the number of units you must sell to cover your farm costs.',
      icon: Icons.balance,
      fields: [
        // Mode Selector Toggle
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Simple')),
                selected: _mode == BreakEvenMode.simple,
                selectedColor: farmLightGreen,
                labelStyle: TextStyle(
                  color:
                      _mode == BreakEvenMode.simple ? farmGreen : Colors.black87,
                  fontWeight: _mode == BreakEvenMode.simple
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _mode = BreakEvenMode.simple;
                      _result = null;
                      _details = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Detailed')),
                selected: _mode == BreakEvenMode.detailed,
                selectedColor: farmLightGreen,
                labelStyle: TextStyle(
                  color: _mode == BreakEvenMode.detailed
                      ? farmGreen
                      : Colors.black87,
                  fontWeight: _mode == BreakEvenMode.detailed
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _mode = BreakEvenMode.detailed;
                      _result = null;
                      _details = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _mode == BreakEvenMode.simple
              ? 'Quick estimate for small-scale farmers. Switch to Detailed for a full cost breakdown.'
              : 'Detailed breakdown using fixed overheads and variable unit costs.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        if (_mode == BreakEvenMode.simple) ...[
          FarmField(
            label: 'Total cost of production',
            controller: _totalCost,
            hint: 'e.g. 500',
          ),
          FarmField(
            label: 'Selling price per unit',
            controller: _simpleSellingPrice,
            hint: 'e.g. 2.50',
          ),
          ElevatedButton.icon(
            onPressed: _calculateSimple,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate break-even'),
            style: farmButtonStyle(),
          ),
        ] else ...[
          FarmField(
            label: 'Fixed costs',
            controller: _fixedCosts,
            hint: 'e.g. 900',
          ),
          FarmField(
            label: 'Variable cost per unit',
            controller: _variableCost,
            hint: 'e.g. 0.15',
          ),
          FarmField(
            label: 'Selling price per unit',
            controller: _sellingPrice,
            hint: 'e.g. 0.35',
          ),
          ElevatedButton.icon(
            onPressed: _calculateDetailed,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate break-even'),
            style: farmButtonStyle(),
          ),
        ],
      ],
      result: _result,
      resultDetails: _details,
      onExport: _result == null ? null : _export,
      exportLabel: 'Watch Ad & Export Break-even PDF',
    );
  }
}
