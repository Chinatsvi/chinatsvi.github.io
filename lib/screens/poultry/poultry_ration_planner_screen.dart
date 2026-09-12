import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/poultry/poultry_ration_plan.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';

class PoultryRationPlanScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryRationPlanScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryRationPlanScreen> createState() =>
      _PoultryRationPlanScreenState();
}

class _PoultryRationPlanScreenState extends State<PoultryRationPlanScreen> {
  late Future<List<PoultryRationPlan>> _future;

  // Data from other screens
  List<PoultryGrowthRecord> _growthRecords = [];
  List<PoultryFeedingRecord> _feedingRecords = [];
  List<PoultryProductionRecord> _productionRecords = [];
  List<PoultryHealthRecord> _healthRecords = []; // ✅ NEW: Load health records
  int? _batchAgeWeeks;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadPlans() {
    _future = widget.repository.getRationPlans(widget.animal.id);
  }

  Future<void> _loadAllData() async {
    // Load ration plans
    _loadPlans();

    // Load growth, feeding, production, and health records for advisory
    try {
      _growthRecords = await widget.repository.getGrowthRecords(
        widget.animal.id,
      );
      _feedingRecords = await widget.repository.getFeedingRecords(
        widget.animal.id,
      );
      _productionRecords = []; // Empty for now
      _healthRecords = await widget.repository.getHealthRecords(
        widget.animal.id,
      );
      // Try to read canonical batch ageWeeks from poultry_batches
      try {
        final batchDoc = await FirebaseFirestore.instance
            .collection('poultry_batches')
            .doc(widget.animal.id)
            .get();
        if (batchDoc.exists) {
          final data = batchDoc.data() as Map<String, dynamic>;
          _batchAgeWeeks = (data['ageWeeks'] as num?)?.toInt();
        }
      } catch (e) {
        // ignore
      }
    } catch (e) {
      debugPrint(' Error loading data: $e');
    }

    setState(() {});
  }

  Future<void> _refreshPlans() async {
    // Reload all data to get latest counts
    await _loadAllData();
  }

  // Calculate suggested protein based on age and growth
  double _suggestProtein() {
    // Prefer explicit batch age if available
    int ageWeeks;
    if (_batchAgeWeeks != null) {
      ageWeeks = _batchAgeWeeks!;
    } else if (_growthRecords.isNotEmpty) {
      ageWeeks = (_growthRecords.last.ageDays / 7).floor();
    } else {
      final ageDays = DateTime.now().difference(widget.animal.createdAt).inDays;
      ageWeeks = (ageDays / 7).floor();
    }

    if (ageWeeks <= 6) return 22; // starter
    if (ageWeeks <= 18) return 18; // grower
    return 16; // layer
  }

  // Calculate suggested energy based on FCR and production
  double _suggestEnergy() {
    double totalFeed = _feedingRecords.fold<double>(
      0,
      (total, r) => total + r.quantityKg,
    );
    int totalEggs = _productionRecords.fold<int>(
      0,
      (total, r) => total + r.eggsCollected,
    );

    if (totalEggs > 0) {
      double fcr = totalFeed / totalEggs;
      if (fcr < 1.8) return 2800; // efficient birds
      if (fcr < 2.2) return 2700; // moderate
      return 2600; // low efficiency
    }
    return 2700; // default kcal/kg
  }

  // Suggest daily intake (grams/bird/day) based on age and actual feeding data
  double _suggestDailyIntake() {
    // First try to get age from poultry batch registration
    int? ageWeeks;

    // Try to get age from Animal model (which should have the age from batch)
    final ageDays = DateTime.now().difference(widget.animal.createdAt).inDays;
    ageWeeks = (ageDays / 7).floor();

    // If we have a specific age, use age-based recommendations
    if (ageWeeks >= 0) {
      final ageDays = ageWeeks * 7;

      // Age-based daily intake recommendations
      if (ageDays <= 7) {
        // Day 1-7: Starter chicks
        return 10.0 + (ageDays * 1.0); // 10-17g per day
      } else if (ageDays <= 14) {
        // Week 2: Growing chicks
        return 17.0 + ((ageDays - 7) * 2.0); // 17-31g per day
      } else if (ageDays <= 21) {
        // Week 3: Rapid growth
        return 31.0 + ((ageDays - 14) * 3.0); // 31-52g per day
      } else if (ageDays <= 28) {
        // Week 4: Continued growth
        return 52.0 + ((ageDays - 21) * 2.0); // 52-66g per day
      } else if (ageDays <= 56) {
        // Weeks 5-8: Grower phase
        return 66.0 + ((ageDays - 28) * 1.5); // 66-108g per day
      } else {
        // 8+ weeks: Layer phase
        return 108.0 + ((ageDays - 56) * 0.2); // 108-120g per day max
      }
    }

    // If no growth records, use feeding data as fallback
    if (_feedingRecords.isNotEmpty) {
      final totalFeed = _feedingRecords.fold<double>(
        0,
        (total, r) => total + r.quantityKg,
      );
      final flockSize = widget.animal.initialFlockSize ?? 50;
      if (flockSize > 0) {
        final feedPerBird = totalFeed * 1000 / flockSize; // kg -> grams
        return feedPerBird.clamp(10, 120); // reasonable range
      }
    }

    return 50.0; // default for older birds
  }

  // Get health records count
  int _getHealthRecordsCount() {
    return _healthRecords.length; // ✅ FIXED: Use actual loaded health records
  }

  // Build data source item widget
  Widget _buildDataSourceItem(
    IconData icon,
    String title,
    String value,
    bool hasData,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasData ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasData ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasData ? Colors.green.shade700 : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasData
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasData
                        ? Colors.green.shade700
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (hasData)
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16)
          else
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  // Generate AI-powered ration plan
  Future<void> _generateAIRationPlan() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Analyzing your flock data...'),
          ],
        ),
      ),
    );

    try {
      // Calculate AI recommendations based on actual data
      final protein = _suggestProtein();
      final energy = _suggestEnergy();
      final dailyIntake = _suggestDailyIntake();

      // Determine feed type based on age and purpose
      String feedType = 'Balanced Feed';
      if (_growthRecords.isNotEmpty) {
        final ageWeeks =
            _batchAgeWeeks ?? (_growthRecords.last.ageDays / 7).floor();
        if (ageWeeks <= 6) {
          feedType = 'Starter Mash';
        } else if (ageWeeks <= 18) {
          feedType = 'Grower Feed';
        } else {
          feedType = 'Layer Pellets';
        }
      }

      // Create AI-generated plan
      final aiPlan = PoultryRationPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        batchId: widget.animal.id,
        feedType: '$feedType (AI Generated)',
        proteinPercent: protein,
        energyKcal: energy,
        dailyIntakeGrams: dailyIntake,
      );

      // Save the plan
      await widget.repository.addRationPlan(aiPlan);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chinatsvi Ration Plan created successfully!'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh plans
        _refreshPlans();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Chinatsvi plan: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _deletePlan(PoultryRationPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ration Plan'),
        content: Text('Are you sure you want to delete "${plan.feedType}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await widget.repository.deleteRationPlan(plan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ration plan deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshPlans(); // Use the fixed refresh method
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting plan: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.animal.breed} Chinatsvi Ration Plans'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            onPressed: () => _generateAIRationPlan(),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Chinatsvi Plan',
          ),
        ],
      ),
      body: FutureBuilder<List<PoultryRationPlan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chinatsvi Ration Planner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll create optimized feeding plans\nbased on your flock data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade100,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Colors.green.shade700,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Data Sources Used:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDataSourceItem(
                            Icons.monitor_weight,
                            'Growth Tracker',
                            '${_growthRecords.length} records',
                            _growthRecords.isNotEmpty,
                          ),
                          _buildDataSourceItem(
                            Icons.health_and_safety,
                            'Health Records',
                            '${_getHealthRecordsCount()} records',
                            _getHealthRecordsCount() > 0,
                          ),
                          _buildDataSourceItem(
                            Icons.egg,
                            'Egg Production',
                            '${_productionRecords.length} records',
                            _productionRecords.isNotEmpty,
                          ),
                          _buildDataSourceItem(
                            Icons.pets,
                            'Poultry Profile',
                            widget.animal.breed,
                            true,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _generateAIRationPlan(),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Generate Chinatsvi Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.feed, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Ration Plans',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            '${records.length} plan${records.length == 1 ? '' : 's'} saved',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _generateAIRationPlan(),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Generate Chinatsvi Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Plans List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.feed,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          r.feedType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNutrientChip(
                                    'Protein',
                                    '${r.proteinPercent.toStringAsFixed(1)}%',
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNutrientChip(
                                    'Energy',
                                    '${r.energyKcal.toStringAsFixed(0)} kcal',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildNutrientChip(
                              'Daily Intake',
                              '${r.dailyIntakeGrams.toStringAsFixed(0)} g/bird',
                              Colors.green,
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'delete') _deletePlan(r);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build nutrient chip widget for displaying nutritional information
  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
