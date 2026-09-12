import 'package:flutter/material.dart';

import 'farm_works/break_even_calculator.dart';
import 'farm_works/farm_calculator_widgets.dart';
import 'farm_works/fertilizer_calculator.dart';
import 'farm_works/irrigation_calculator.dart';
import 'farm_works/population_calculator.dart';
import 'farm_works/profit_calculator.dart';
import 'farm_works/spacing_calculator.dart';

class FarmWorksScreen extends StatelessWidget {
  const FarmWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farm Works'),
          backgroundColor: farmGreen,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.science), text: 'Fertilizer'),
              Tab(icon: Icon(Icons.grass), text: 'Population'),
              Tab(icon: Icon(Icons.straighten), text: 'Spacing'),
              Tab(icon: Icon(Icons.attach_money), text: 'Profit'),
              Tab(icon: Icon(Icons.water_drop), text: 'Irrigation'),
              Tab(icon: Icon(Icons.balance), text: 'Break-even'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FertilizerCalculator(),
            PopulationCalculator(),
            SpacingCalculator(),
            ProfitCalculator(),
            IrrigationCalculator(),
            BreakEvenCalculator(),
          ],
        ),
      ),
    );
  }
}
