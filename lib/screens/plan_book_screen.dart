import 'package:flutter/material.dart';
import 'crop_plan_screen.dart';
import 'season_calendar_screen.dart';
import 'budget_planner_screen.dart';
import 'farm_inventory_screen.dart';
import 'plan_history_screen.dart';

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class PlanBookScreen extends StatelessWidget {
  const PlanBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Plan Book'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlanHistoryScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Text('View Plan History'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlanCard(
            icon: Icons.spa,
            title: 'Crop Plan',
            subtitle: 'What to grow, when, and where',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CropPlanScreen()),
              );
            },
          ),
          _PlanCard(
            icon: Icons.calendar_month,
            title: 'Season Calendar',
            subtitle: 'Planting, weeding, harvesting dates',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeasonCalendarScreen(),
                ),
              );
            },
          ),
          _PlanCard(
            icon: Icons.attach_money,
            title: 'Budget Planner',
            subtitle: 'Inputs, labor, expected income',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetPlannerScreen(),
                ),
              );
            },
          ),
          _PlanCard(
            icon: Icons.inventory,
            title: 'Farm Inventory',
            subtitle: 'Seeds, fertilizer, tools in stock',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmInventoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
